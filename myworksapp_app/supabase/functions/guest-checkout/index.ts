import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { sha256Hex } from "../_shared/guest_ticket.ts";
import { isKillSwitchOn, killSwitchResponse } from "../_shared/kill_switch.ts";
import {
  allowRate,
  clientIp,
  rateLimitExceededMessage,
} from "../_shared/rate_limit.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";
import {
  resolveCallerReturnOrigin,
  resolveReturnUrl,
  signHandoffTicket,
} from "../_shared/security.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { tbkConfig, tbkCreateTransaction } from "../_shared/tbk.ts";
import { turnstileDecision } from "../_shared/turnstile_gate.ts";

type GuestBody = {
  name?: string;
  email?: string;
  phone?: string;
  address?: string;
  workerId?: string;
  serviceId?: string;
  description?: string;
  amountClp?: number;
  scheduledAt?: string;
  returnUrl?: string;
  turnstileToken?: string;
};

function clean(s: unknown, max = 200): string {
  return String(s ?? "").trim().slice(0, max);
}

function isEmail(v: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}

function scheduledOrNull(value: unknown): string | null {
  const raw = clean(value, 40);
  if (!raw) return null;
  const parsed = Date.parse(raw);
  if (!Number.isFinite(parsed)) return null;
  return new Date(parsed).toISOString();
}

const GUEST_WINDOW_MS = 60_000;
const GUEST_MAX_IP = 5;
const GUEST_MAX_EMAIL = 3;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse(req, { error: "Method not allowed" }, 405);
  }

  let guestUserId: string | null = null;
  try {
    if (isKillSwitchOn("MWA_READ_ONLY") || isKillSwitchOn("MWA_KILL_GUEST_CHECKOUT")) {
      return jsonResponse(req, killSwitchResponse(), 503);
    }

    const ip = clientIp(req);
    if (!allowRate(`guest:ip:${ip}`, GUEST_MAX_IP, GUEST_WINDOW_MS)) {
      return jsonResponse(req, { error: rateLimitExceededMessage() }, 429);
    }

    const turnstileSecret = Deno.env.get("TURNSTILE_SECRET_KEY")?.trim() ?? "";
    const turnstile = turnstileDecision(Deno.env.get("TBK_ENV"), turnstileSecret.length > 0);
    if (turnstile === "fail_closed") {
      return jsonResponse(req, { error: "Falta TURNSTILE_SECRET_KEY" }, 503);
    }

    const body = (await req.json()) as GuestBody;
    if (turnstile === "verify") {
      const token = clean(body.turnstileToken, 2048);
      if (!token) {
        return jsonResponse(req, { error: "Confirma que no eres un robot" }, 400);
      }
      const verifyBody = new URLSearchParams({
        secret: turnstileSecret,
        response: token,
      });
      if (ip) verifyBody.set("remoteip", ip);
      const verify = await fetch(
        "https://challenges.cloudflare.com/turnstile/v0/siteverify",
        { method: "POST", body: verifyBody },
      );
      const verdict = await verify.json().catch(() => ({ success: false }));
      if (!verify.ok || verdict?.success !== true) {
        return jsonResponse(req, { error: "No se pudo verificar el captcha" }, 400);
      }
    }

    const name = clean(body.name, 120);
    const email = clean(body.email, 160).toLowerCase();
    const phone = clean(body.phone, 40);
    const address = clean(body.address, 300);
    const workerId = clean(body.workerId, 80);
    const serviceId = clean(body.serviceId, 80);
    const description = clean(body.description, 500) || "Urgencia / visita web (invitado)";
    const amountClp = Number(body.amountClp);

    if (!name || !isEmail(email) || !phone || !address) {
      return jsonResponse(
        req,
        { error: "Nombre, correo, teléfono y dirección son obligatorios" },
        400,
      );
    }
    if (!allowRate(`guest:email:${email}`, GUEST_MAX_EMAIL, GUEST_WINDOW_MS)) {
      return jsonResponse(req, { error: rateLimitExceededMessage() }, 429);
    }
    if (!workerId || !serviceId || !Number.isFinite(amountClp) || amountClp <= 0) {
      return jsonResponse(
        req,
        { error: "workerId, serviceId y amountClp requeridos" },
        400,
      );
    }

    const admin = serviceClient();
    await admin.rpc("limpiar_invitados_sin_pago");

    const { data: existingProfile } = await admin
      .from("perfiles")
      .select("id")
      .eq("correo", email)
      .maybeSingle();

    if (existingProfile) {
      return jsonResponse(req, {
        mode: "guest_redirect",
        needsLogin: true,
        redirectUrl: "",
        jobId: "",
        paymentId: "",
        buyOrder: "",
      });
    }

    const { data: worker, error: workerErr } = await admin
      .from("trabajadores")
      .select("id_usuario, tarifa_visita, disponible, precios_configurados, estado_verificacion")
      .eq("id_usuario", workerId)
      .maybeSingle();

    if (workerErr || !worker) {
      return jsonResponse(req, { error: "Profesional no encontrado" }, 404);
    }
    if (worker.estado_verificacion !== "verificado") {
      return jsonResponse(
        req,
        { error: "Este profesional todavía no está verificado para cobrar" },
        400,
      );
    }
    if (
      Number(worker.disponible) !== 1 ||
      Number(worker.precios_configurados) !== 1
    ) {
      return jsonResponse(req, { error: "El profesional no está disponible" }, 400);
    }

    const expected = Number(worker.tarifa_visita);
    if (!Number.isFinite(expected) || expected <= 0) {
      return jsonResponse(req, { error: "El profesional no tiene tarifa de visita" }, 400);
    }
    if (Math.abs(amountClp - expected) > 1) {
      return jsonResponse(
        req,
        { error: `Monto ${amountClp} no coincide con tarifa ${expected}` },
        400,
      );
    }

    const tempPassword =
      `Gw${crypto.randomUUID().replace(/-/g, "").slice(0, 18)}!9`;

    const { data: created, error: createErr } = await admin.auth.admin.createUser({
      email,
      password: tempPassword,
      email_confirm: false,
      user_metadata: {
        name,
        phone,
        role: "usuario",
        guest_checkout: true,
      },
    });

    if (createErr || !created.user) {
      const raw = createErr?.message ?? "";
      const taken = /already|registered|exists/i.test(raw);
      if (taken) {
        return jsonResponse(req, {
          mode: "guest_redirect",
          needsLogin: true,
          redirectUrl: "",
          jobId: "",
          paymentId: "",
          buyOrder: "",
        });
      }
      return jsonResponse(
        req,
        { error: publicErrorMessage(createErr, "No se pudo crear la cuenta invitada") },
        400,
      );
    }

    const userId = created.user.id;
    guestUserId = userId;
    const discardGuest = async () => {
      await admin.auth.admin.deleteUser(userId);
      guestUserId = null;
    };
    const now = new Date().toISOString();

    const { error: profileErr } = await admin.from("perfiles").upsert({
      id: userId,
      nombre: name,
      correo: email,
      rol: "usuario",
      estado_cuenta: "activo",
      creado_en: now,
    });

    if (profileErr) {
      await discardGuest();
      return jsonResponse(req, { error: publicErrorMessage(profileErr, "No se pudo guardar el perfil") }, 400);
    }

    const jobId = crypto.randomUUID();
    const meta = JSON.stringify({
      guest: true,
      phone,
      source: "web_guest_urgency",
    });

    const { error: jobErr } = await admin.from("trabajos").insert({
      id: jobId,
      id_usuario: userId,
      id_trabajador: workerId,
      id_servicio: serviceId,
      estado: "esperando_pago",
      descripcion: description,
      direccion: address,
      fecha_programada: scheduledOrNull(body.scheduledAt),
      modalidad_cobro: "precio_fijo",
      estado_pago: "pendiente",
      metadatos_servicio: meta,
      creado_en: now,
      actualizado_en: now,
    });

    if (jobErr) {
      await discardGuest();
      return jsonResponse(req, { error: publicErrorMessage(jobErr, "No se pudo crear el trabajo") }, 400);
    }

    const paymentId = crypto.randomUUID();
    const buyOrder = `MWA${paymentId.replace(/-/g, "").slice(0, 20)}`;
    const { env } = tbkConfig();
    const returnUrl = resolveReturnUrl(
      typeof body.returnUrl === "string" ? body.returnUrl : undefined,
    );

    const { token, url } = await tbkCreateTransaction({
      buyOrder,
      sessionId: userId,
      amount: expected,
      returnUrl,
    });

    const altaNonce = crypto.randomUUID().replace(/-/g, "") +
      crypto.randomUUID().replace(/-/g, "");
    const { error: payErr } = await admin.from("pagos").insert({
      id: paymentId,
      id_trabajo: jobId,
      monto: expected,
      moneda: "CLP",
      estado: "pendiente",
      tipo_pago: "principal",
      metodo_pago: "webpay",
      buy_order: buyOrder,
      token_tbk: token,
      url_tbk: url,
      ambiente: env,
      id_transaccion: buyOrder,
      origen_retorno: resolveCallerReturnOrigin(req),
      alta_nonce_hash: await sha256Hex(altaNonce),
      creado_en: now,
      actualizado_en: now,
    });

    if (payErr) {
      await discardGuest();
      return jsonResponse(req, { error: publicErrorMessage(payErr, "No se pudo registrar el pago") }, 400);
    }

    const ticket = await signHandoffTicket(paymentId);
    const handoff =
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/webpay-handoff?t=${encodeURIComponent(ticket)}`;
    guestUserId = null;

    // Invitado: redirección completa a Transbank (única excepción de producto).
    return jsonResponse(req, {
      jobId,
      paymentId,
      buyOrder,
      redirectUrl: handoff,
      ambiente: env,
      mode: "guest_redirect",
      nonce: altaNonce,
    });
  } catch (e) {
    if (guestUserId) {
      try {
        await serviceClient().auth.admin.deleteUser(guestUserId);
      } catch {
        // El barrido de invitados sin pago cubre lo que no se pudo borrar aquí.
      }
    }
    const raw = e instanceof Error ? e.message : String(e);
    const status = raw.includes("WEBPAY_HANDOFF_SECRET")
      ? 503
      : raw.includes("Demasiados")
        ? 429
        : 500;
    return jsonResponse(req, { error: publicErrorMessage(e) }, status);
  }
});

import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { resolveReturnUrl, signHandoffTicket } from "../_shared/security.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { tbkConfig, tbkCreateTransaction } from "../_shared/tbk.ts";

type GuestBody = {
  name?: string;
  email?: string;
  phone?: string;
  address?: string;
  workerId?: string;
  serviceId?: string;
  description?: string;
  amountClp?: number;
  returnUrl?: string;
};

function clean(s: unknown, max = 200): string {
  return String(s ?? "").trim().slice(0, max);
}

function isEmail(v: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}

/** Rate-limit in-memory por IP (Edge isolate; mitiga abuso básico). */
const guestHits = new Map<string, { count: number; resetAt: number }>();
const GUEST_WINDOW_MS = 60_000;
const GUEST_MAX = 8;

function clientIp(req: Request): string {
  return (
    req.headers.get("cf-connecting-ip") ||
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    req.headers.get("x-real-ip") ||
    "unknown"
  );
}

function allowGuest(ip: string): boolean {
  const now = Date.now();
  const row = guestHits.get(ip);
  if (!row || row.resetAt < now) {
    guestHits.set(ip, { count: 1, resetAt: now + GUEST_WINDOW_MS });
    return true;
  }
  if (row.count >= GUEST_MAX) return false;
  row.count += 1;
  return true;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse(req, { error: "Method not allowed" }, 405);
  }

  try {
    const ip = clientIp(req);
    if (!allowGuest(ip)) {
      return jsonResponse(
        req,
        { error: "Demasiados intentos. Espera un minuto e inténtalo de nuevo." },
        429,
      );
    }

    const body = (await req.json()) as GuestBody;
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
    if (!workerId || !serviceId || !Number.isFinite(amountClp) || amountClp <= 0) {
      return jsonResponse(
        req,
        { error: "workerId, serviceId y amountClp requeridos" },
        400,
      );
    }

    const admin = serviceClient();

    const { data: existingProfile } = await admin
      .from("perfiles")
      .select("id")
      .eq("correo", email)
      .maybeSingle();

    if (existingProfile) {
      return jsonResponse(
        req,
        {
          error: "account_exists",
          message:
            "Ya existe una cuenta con este correo. Inicia sesión para pagar sin salir de My Works App.",
        },
        409,
      );
    }

    const { data: worker, error: workerErr } = await admin
      .from("trabajadores")
      .select("id_usuario, tarifa_visita, disponible")
      .eq("id_usuario", workerId)
      .maybeSingle();

    if (workerErr || !worker) {
      return jsonResponse(req, { error: "Profesional no encontrado" }, 404);
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
      email_confirm: true,
      user_metadata: {
        name,
        phone,
        role: "usuario",
        guest_checkout: true,
      },
    });

    if (createErr || !created.user) {
      return jsonResponse(
        req,
        { error: createErr?.message || "No se pudo crear la cuenta invitada" },
        400,
      );
    }

    const userId = created.user.id;
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
      return jsonResponse(req, { error: profileErr.message }, 400);
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
      modalidad_cobro: "precio_fijo",
      estado_pago: "pendiente",
      metadatos_servicio: meta,
      creado_en: now,
      actualizado_en: now,
    });

    if (jobErr) {
      return jsonResponse(req, { error: jobErr.message }, 400);
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
      creado_en: now,
      actualizado_en: now,
    });

    if (payErr) {
      return jsonResponse(req, { error: payErr.message }, 400);
    }

    const ticket = await signHandoffTicket(paymentId);
    const handoff =
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/webpay-handoff?t=${encodeURIComponent(ticket)}`;

    // Invitado: redirección completa a Transbank (única excepción de producto).
    return jsonResponse(req, {
      jobId,
      paymentId,
      buyOrder,
      redirectUrl: handoff,
      ambiente: env,
      mode: "guest_redirect",
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const status = msg.includes("WEBPAY_HANDOFF_SECRET")
      ? 503
      : msg.includes("Demasiados")
        ? 429
        : 500;
    return jsonResponse(req, { error: msg }, status);
  }
});

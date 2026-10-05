import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import {
  guestPasswordConfirmPlan,
  paymentHoldTransitioned,
  sha256Hex,
} from "../_shared/guest_ticket.ts";
import {
  allowRate,
  clientIp,
  rateLimitExceededMessage,
} from "../_shared/rate_limit.ts";
import { verifyGuestPasswordTicket } from "../_shared/security.ts";
import { serviceClient } from "../_shared/supabase.ts";

const LETTER = /[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]/;
const DIGIT = /\d/;

function passwordError(password: string): string | null {
  if (!password) return "La contraseña es requerida";
  if (password.length < 8) return "La contraseña debe tener al menos 8 caracteres";
  if (!LETTER.test(password)) return "Incluye al menos una letra";
  if (!DIGIT.test(password)) return "Incluye al menos un número";
  return null;
}

/** El invitado elige clave. El token lo firma webpay-commit. */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse(req, { error: "Method not allowed" }, 405);
  }

  try {
    if (!allowRate(`alta:${clientIp(req)}`, 8, 60_000)) {
      return jsonResponse(req, { error: rateLimitExceededMessage() }, 429);
    }

    const body = await req.json();
    const token = String(body.token || body.alta || "").trim();
    const password = String(body.password || "");
    const nonce = String(body.nonce || "").trim();
    const policy = passwordError(password);
    if (policy) return jsonResponse(req, { error: policy }, 400);
    if (!nonce) {
      return jsonResponse(req, { error: "Falta la sesión del navegador que pagó" }, 400);
    }

    const verified = await verifyGuestPasswordTicket(token);
    if (!verified.ok) return jsonResponse(req, { error: verified.error }, 403);

    const admin = serviceClient();
    const { data: pago } = await admin
      .from("pagos")
      .select("id, alta_nonce_hash, alta_consumido_en")
      .eq("alta_jti", verified.jti)
      .maybeSingle();
    if (!pago?.alta_nonce_hash || pago.alta_consumido_en) {
      return jsonResponse(req, { error: "Este enlace ya no sirve" }, 403);
    }
    const nonceHash = await sha256Hex(nonce);
    if (nonceHash !== String(pago.alta_nonce_hash)) {
      return jsonResponse(req, { error: "Este enlace no corresponde a este navegador" }, 403);
    }

    const { data: owner, error: readErr } = await admin.auth.admin.getUserById(
      verified.userId,
    );
    if (readErr || !owner.user) {
      return jsonResponse(req, { error: "La cuenta invitada no está disponible" }, 404);
    }
    const meta = owner.user.user_metadata ?? {};
    const guest = meta.guest_checkout === true || meta.guest_checkout === "true";
    if (!guest) {
      return jsonResponse(req, { error: "Esta cuenta ya no es de invitado" }, 403);
    }

    const { data: modeRow } = await admin
      .from("app_config")
      .select("valor")
      .eq("clave", "demo_modo")
      .maybeSingle();
    const plan = guestPasswordConfirmPlan(String(modeRow?.valor || "") === "1");

    const claimedAt = new Date().toISOString();
    const claimed = await admin
      .from("pagos")
      .update({ alta_consumido_en: claimedAt })
      .eq("id", pago.id)
      .is("alta_consumido_en", null)
      .select("id");
    if (!paymentHoldTransitioned(claimed)) {
      return jsonResponse(req, { error: "Este enlace ya no sirve" }, 403);
    }

    const releaseClaim = async () => {
      await admin
        .from("pagos")
        .update({ alta_consumido_en: null })
        .eq("id", pago.id)
        .eq("alta_consumido_en", claimedAt);
    };

    const { error: updErr } = await admin.auth.admin.updateUserById(verified.userId, {
      password,
      email_confirm: plan.emailConfirmed,
    });
    if (updErr) {
      await releaseClaim();
      return jsonResponse(req, { error: "No se pudo guardar la contraseña" }, 400);
    }

    if (plan.resendSignup && owner.user.email) {
      const { error: resendErr } = await admin.auth.resend({
        type: "signup",
        email: owner.user.email,
      });
      if (resendErr) {
        await releaseClaim();
        return jsonResponse(req, { error: "No se pudo enviar el correo de confirmación" }, 502);
      }
    }

    const { error: metaErr } = await admin.auth.admin.updateUserById(verified.userId, {
      user_metadata: { ...meta, guest_checkout: false },
    });
    if (metaErr) {
      await releaseClaim();
      return jsonResponse(req, { error: "No se pudo guardar la contraseña" }, 400);
    }

    return jsonResponse(req, { ok: true, emailConfirmed: plan.emailConfirmed });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "No se pudo guardar la contraseña";
    const status = msg.includes("WEBPAY_HANDOFF_SECRET") ? 503 : 500;
    const safe = status === 503
      ? "Falta configurar el secreto de pagos"
      : "No se pudo guardar la contraseña";
    return jsonResponse(req, { error: safe }, status);
  }
});

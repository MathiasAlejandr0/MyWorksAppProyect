import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
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

/** El invitado elige clave sin SMTP. El token lo firma webpay-commit. */
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
    const policy = passwordError(password);
    if (policy) return jsonResponse(req, { error: policy }, 400);

    const verified = await verifyGuestPasswordTicket(token);
    if (!verified.ok) return jsonResponse(req, { error: verified.error }, 403);

    const admin = serviceClient();
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

    const { error: updErr } = await admin.auth.admin.updateUserById(verified.userId, {
      password,
      email_confirm: true,
      user_metadata: { ...meta, guest_checkout: false },
    });
    if (updErr) {
      return jsonResponse(req, { error: "No se pudo guardar la contraseña" }, 400);
    }

    return jsonResponse(req, { ok: true });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "No se pudo guardar la contraseña";
    const status = msg.includes("WEBPAY_HANDOFF_SECRET") ? 503 : 500;
    const safe = status === 503
      ? "Falta configurar el secreto de pagos"
      : "No se pudo guardar la contraseña";
    return jsonResponse(req, { error: safe }, status);
  }
});

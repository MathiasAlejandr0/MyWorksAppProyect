/** Tickets HMAC de un solo uso para handoff Webpay (sin exponer paymentId crudo). */

function toHex(buf: ArrayBuffer): string {
  return [...new Uint8Array(buf)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** Fail-closed: sin WEBPAY_HANDOFF_SECRET no se firman tickets. */
async function hmacKey(): Promise<CryptoKey> {
  const secret = Deno.env.get("WEBPAY_HANDOFF_SECRET")?.trim();
  if (!secret || secret.length < 16) {
    throw new Error(
      "WEBPAY_HANDOFF_SECRET ausente o demasiado corto (mín. 16). Configura el secret en Edge.",
    );
  }
  const raw = new TextEncoder().encode(secret);
  return crypto.subtle.importKey(
    "raw",
    raw,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

/** Comparación en tiempo constante de hex igual longitud. */
function timingSafeEqualHex(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

export async function signHandoffTicket(
  paymentId: string,
  ttlSec = 600,
): Promise<string> {
  const exp = Math.floor(Date.now() / 1000) + ttlSec;
  const payload = `${paymentId}.${exp}`;
  const key = await hmacKey();
  const sig = toHex(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload)),
  );
  return `${payload}.${sig}`;
}

export async function verifyHandoffTicket(
  ticket: string,
): Promise<{ ok: true; paymentId: string } | { ok: false; error: string }> {
  const parts = ticket.split(".");
  if (parts.length !== 3) return { ok: false, error: "ticket inválido" };
  const [paymentId, expStr, sig] = parts;
  const exp = Number(expStr);
  if (!paymentId || !Number.isFinite(exp)) {
    return { ok: false, error: "ticket inválido" };
  }
  if (exp < Math.floor(Date.now() / 1000)) {
    return { ok: false, error: "ticket expirado" };
  }
  const payload = `${paymentId}.${expStr}`;
  const key = await hmacKey();
  const expected = toHex(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload)),
  );
  if (!timingSafeEqualHex(expected, sig)) {
    return { ok: false, error: "firma inválida" };
  }
  return { ok: true, paymentId };
}

/** return_url de Transbank: solo commit Edge o orígenes allowlist. */
export function resolveReturnUrl(requested: string | undefined): string {
  const base =
    Deno.env.get("WEBPAY_RETURN_URL") ||
    `${Deno.env.get("SUPABASE_URL")}/functions/v1/webpay-commit`;

  if (!requested) return base;

  let url: URL;
  try {
    url = new URL(requested);
  } catch {
    return base;
  }

  const allowed = (Deno.env.get("WEBPAY_ALLOWED_RETURN_ORIGINS") || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);

  const origin = url.origin;
  const commitOrigin = new URL(base).origin;

  if (origin === commitOrigin) return requested;
  if (allowed.includes(origin)) return requested;
  if (
    allowed.length === 0 &&
    /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin)
  ) {
    // Solo en integration se acepta localhost sin lista explícita
    if ((Deno.env.get("TBK_ENV") || "integration") !== "production") {
      return requested;
    }
  }

  return base;
}

const INTEGRATION_WEB_ORIGINS = [
  "http://localhost:5173",
  "http://127.0.0.1:5173",
];

function listedOrigins(raw: string | undefined): string[] {
  return (raw || "")
    .split(",")
    .map((s) => s.trim())
    .filter((s) => s.length > 0 && s !== "*");
}

/** Orígenes a los que puede volver el navegador después de Transbank. */
export function allowedWebReturnOrigins(): string[] {
  const allowed = new Set<string>([
    ...listedOrigins(Deno.env.get("WEBPAY_ALLOWED_RETURN_ORIGINS")),
    ...listedOrigins(Deno.env.get("CORS_ALLOWED_ORIGINS")),
  ]);
  const env = (Deno.env.get("TBK_ENV") || "integration").toLowerCase();
  if (env === "integration") {
    for (const origin of INTEGRATION_WEB_ORIGINS) allowed.add(origin);
  }
  return [...allowed];
}

/**
 * Origin del navegador que llamó a webpay-create o guest-checkout.
 * Solo entra si está en la allowlist. En integración también localhost:5173.
 */
export function resolveCallerReturnOrigin(req: Request): string | null {
  const origin = (req.headers.get("Origin") || "").trim();
  if (!origin) return null;
  try {
    const parsed = new URL(origin);
    if (parsed.origin !== origin) return null;
  } catch {
    return null;
  }
  if (allowedWebReturnOrigins().includes(origin)) return origin;
  return null;
}

/** Si el pago no guardó origen, integración vuelve a localhost. Producción exige secreto o fila. */
export function fallbackWebReturnOrigin(): string {
  const explicit = Deno.env.get("WEBPAY_WEB_RETURN_URL")?.trim();
  if (explicit) return explicit;
  const env = (Deno.env.get("TBK_ENV") || "integration").toLowerCase();
  if (env === "integration") return "http://localhost:5173/";
  throw new Error(
    "origen de retorno ausente. Guarda el Origin del checkout o define WEBPAY_WEB_RETURN_URL.",
  );
}

/** Alta de contraseña del invitado, sin correo. Caduca en 15 minutos y trae jti. */
export async function signGuestPasswordTicket(
  userId: string,
  jti: string,
  ttlSec = 15 * 60,
): Promise<string> {
  const exp = Math.floor(Date.now() / 1000) + ttlSec;
  const payload = `pwd.${userId}.${exp}.${jti}`;
  const key = await hmacKey();
  const sig = toHex(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload)),
  );
  return `${payload}.${sig}`;
}

export async function verifyGuestPasswordTicket(
  ticket: string,
): Promise<{ ok: true; userId: string; jti: string } | { ok: false; error: string }> {
  const parts = ticket.split(".");
  if (parts.length !== 5 || parts[0] !== "pwd") {
    return { ok: false, error: "enlace inválido" };
  }
  const [, userId, expStr, jti, sig] = parts;
  const exp = Number(expStr);
  if (!userId || !jti || !Number.isFinite(exp)) {
    return { ok: false, error: "enlace inválido" };
  }
  if (exp < Math.floor(Date.now() / 1000)) {
    return { ok: false, error: "el enlace para crear la contraseña expiró" };
  }
  const payload = `pwd.${userId}.${expStr}.${jti}`;
  const key = await hmacKey();
  const expected = toHex(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload)),
  );
  if (!timingSafeEqualHex(expected, sig)) {
    return { ok: false, error: "enlace inválido" };
  }
  return { ok: true, userId, jti };
}

/** Orígenes permitidos para postMessage (web return). */
export function webPostMessageOrigins(): string[] {
  const fromEnv = (Deno.env.get("WEBPAY_ALLOWED_RETURN_ORIGINS") || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  if (fromEnv.length) return fromEnv;
  if ((Deno.env.get("TBK_ENV") || "integration") !== "production") {
    return [
      "http://localhost:5173",
      "http://127.0.0.1:5173",
      "http://localhost:3000",
      "http://127.0.0.1:3000",
    ];
  }
  return [];
}

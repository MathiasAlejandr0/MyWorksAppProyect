/** Orígenes del navegador en integración. No incluye *.supabase.co. */
export const INTEGRATION_BROWSER_ORIGINS = [
  "http://localhost:5173",
  "http://127.0.0.1:5173",
  "http://localhost:3001",
  "http://127.0.0.1:3001",
];

/**
 * Web pública desplegada en Vercel. Vale con cualquier TBK_ENV, para CORS y
 * para volver de Transbank. Orígenes exactos: sin comodines ni *.vercel.app.
 */
export const PUBLIC_WEB_ORIGINS: readonly string[] = [
  "https://myworksapp-cl.vercel.app",
];

/** Orígenes de retorno web que se aceptan solo en integración. */
const INTEGRATION_WEB_RETURN_ORIGINS = [
  "http://localhost:5173",
  "http://127.0.0.1:5173",
];

function listedOrigins(raw: string | undefined | null): string[] {
  return (raw || "")
    .split(",")
    .map((s) => s.trim())
    .filter((s) => s.length > 0 && s !== "*");
}

/** Allowlist de CORS: la web pública más CORS_ALLOWED_ORIGINS. */
export function corsAllowlist(raw: string | undefined | null): string[] {
  return [...new Set([...PUBLIC_WEB_ORIGINS, ...listedOrigins(raw)])];
}

/**
 * Orígenes a los que puede volver el navegador después de Transbank:
 * la web pública, WEBPAY_ALLOWED_RETURN_ORIGINS, CORS_ALLOWED_ORIGINS y,
 * solo en integración, el vite local.
 */
export function webReturnOrigins(input: {
  returnOrigins?: string | null;
  corsOrigins?: string | null;
  tbkEnv?: string | null;
}): string[] {
  const allowed = new Set<string>([
    ...PUBLIC_WEB_ORIGINS,
    ...listedOrigins(input.returnOrigins),
    ...listedOrigins(input.corsOrigins),
  ]);
  const env = (input.tbkEnv || "integration").toLowerCase();
  if (env === "integration") {
    for (const origin of INTEGRATION_WEB_RETURN_ORIGINS) allowed.add(origin);
  }
  return [...allowed];
}

/**
 * Allowlist explícita. Sin Origin (curl, redirect de Transbank) queda `*`.
 * Un origen desconocido no se refleja: se responde con el primer origen de la
 * lista (la web pública), que no coincide con el del atacante y el navegador
 * bloquea la lectura. No se responde el literal "null", porque el navegador lo
 * acepta para documentos con Origin: null (iframes sandbox, file://, data:).
 */
export function resolveCorsAllowOrigin(input: {
  origin: string;
  allowlist: string[];
  tbkEnv?: string | null;
}): string {
  const origin = input.origin.trim();
  if (!origin) return "*";
  if (input.allowlist.includes(origin)) return origin;
  const env = (input.tbkEnv || "integration").toLowerCase();
  if (env === "integration") {
    if (INTEGRATION_BROWSER_ORIGINS.includes(origin)) return origin;
    const local = integrationLocalOrigin(origin);
    if (local) return local;
  }
  return input.allowlist[0] ?? PUBLIC_WEB_ORIGINS[0];
}

/** Flutter web elige un puerto libre. En integración vale localhost o 127.0.0.1. */
function integrationLocalOrigin(origin: string): string | null {
  let url: URL;
  try {
    url = new URL(origin);
  } catch {
    return null;
  }
  if (url.protocol !== "http:") return null;
  if (url.hostname !== "localhost" && url.hostname !== "127.0.0.1") return null;
  if (url.username || url.password) return null;
  if (url.pathname !== "/" || url.search || url.hash) return null;
  if (url.port !== "") {
    const port = Number(url.port);
    if (!Number.isInteger(port) || port < 1 || port > 65535) return null;
  }
  return url.origin;
}

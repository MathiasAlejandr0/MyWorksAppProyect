/** Orígenes del navegador en integración. No incluye *.supabase.co. */
export const INTEGRATION_BROWSER_ORIGINS = [
  "http://localhost:5173",
  "http://127.0.0.1:5173",
  "http://localhost:3001",
  "http://127.0.0.1:3001",
];

/**
 * Allowlist explícita. Sin Origin (curl, redirect de Transbank) queda `*`.
 * Un origen desconocido no se refleja.
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
  return "null";
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

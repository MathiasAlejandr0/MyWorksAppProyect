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
  if (env === "integration" && INTEGRATION_BROWSER_ORIGINS.includes(origin)) {
    return origin;
  }
  return "null";
}

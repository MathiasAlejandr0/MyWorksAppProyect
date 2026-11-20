/** Claves de sitio de prueba de Cloudflare Turnstile. Siempre aprueban o siempre bloquean. */
export const TURNSTILE_TEST_SITE_KEYS = [
  "1x00000000000000000000AA",
  "1x00000000000000000000BB",
  "2x00000000000000000000AB",
  "2x00000000000000000000BB",
  "3x00000000000000000000FF",
] as const;

export function isTurnstileTestSiteKey(siteKey: string): boolean {
  return (TURNSTILE_TEST_SITE_KEYS as readonly string[]).includes(siteKey.trim());
}

/** En el build de producción una clave de prueba no se renderiza. */
export function shouldRenderTurnstile(siteKey: string, isProd: boolean): boolean {
  const key = siteKey.trim();
  if (!key) return false;
  if (isProd && isTurnstileTestSiteKey(key)) return false;
  return true;
}

export const TURNSTILE_SITE_KEY = String(import.meta.env.VITE_TURNSTILE_SITE_KEY || '').trim();

export function turnstileSiteKey(): string {
  return TURNSTILE_SITE_KEY;
}

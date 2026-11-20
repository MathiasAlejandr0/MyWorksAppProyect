import { shouldRenderTurnstile } from './turnstileSitePolicy';

export const TURNSTILE_SITE_KEY = String(import.meta.env.VITE_TURNSTILE_SITE_KEY || '').trim();

export function turnstileSiteKey(): string {
  return TURNSTILE_SITE_KEY;
}

export function turnstileCanRender(): boolean {
  const allowed = shouldRenderTurnstile(TURNSTILE_SITE_KEY, import.meta.env.PROD);
  if (!allowed && import.meta.env.PROD && TURNSTILE_SITE_KEY) {
    console.error(
      'Turnstile: la clave de sitio es de prueba y este build es de producción. El widget no se muestra. Configura VITE_TURNSTILE_SITE_KEY.',
    );
  }
  return allowed;
}

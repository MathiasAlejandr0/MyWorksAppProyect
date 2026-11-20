export const DESKTOP_AUTH_CALLBACK = 'myworksapp-admin://auth/callback';

export function isTauriRuntime(): boolean {
  return typeof window !== 'undefined' && '__TAURI_INTERNALS__' in window;
}

/** redirectTo del correo. La variable de entorno gana; si no, deep link en la app instalada. */
export function authRedirectUrl(origin = typeof window === 'undefined' ? '' : window.location.origin): string {
  const fromEnv = import.meta.env?.VITE_AUTH_REDIRECT_URL?.trim();
  if (fromEnv) return fromEnv;
  if (isTauriRuntime()) return DESKTOP_AUTH_CALLBACK;
  const base = origin.replace(/\/+$/, '');
  return `${base}/?restablecer=1`;
}

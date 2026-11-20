import { PASSWORD_SETUP_STORAGE_KEY } from '@myworksapp/shared';

const OTP_TYPES = new Set([
  'signup',
  'invite',
  'magiclink',
  'recovery',
  'email_change',
  'email',
]);

export type AuthDeepLink =
  | { kind: 'code'; code: string; type: string | null }
  | { kind: 'otp'; tokenHash: string; type: string }
  | { kind: 'session'; accessToken: string; refreshToken: string; type: string | null }
  | { kind: 'ignore' };

let pendingAuthCallbacks = 0;

/** Hay un deep link de Auth en curso: no borrar la marca de contraseña todavía. */
export function authDeepLinkPending(): boolean {
  return pendingAuthCallbacks > 0;
}

export function beginAuthDeepLink(): void {
  pendingAuthCallbacks += 1;
}

export function endAuthDeepLink(): void {
  pendingAuthCallbacks = Math.max(0, pendingAuthCallbacks - 1);
}

export function authDeepLinkNeedsPassword(type: string | null | undefined): boolean {
  const value = (type ?? '').toLowerCase();
  return value === 'invite' || value === 'recovery';
}

function clean(value: string | null): string {
  return (value ?? '').trim();
}

/**
 * Lee el retorno `myworksapp-admin://auth/callback`.
 * `code` (PKCE), `token_hash` + `type` (OTP) o el fragmento con los tokens.
 * Una cadena que no es URL queda en `ignore`.
 */
export function parseAuthDeepLink(raw: string): AuthDeepLink {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return { kind: 'ignore' };
  }

  const code = clean(url.searchParams.get('code'));
  const tokenHash = clean(url.searchParams.get('token_hash'));
  const queryType = clean(url.searchParams.get('type')).toLowerCase() || null;
  if (code) return { kind: 'code', code, type: queryType };
  if (tokenHash && queryType && OTP_TYPES.has(queryType)) {
    return { kind: 'otp', tokenHash, type: queryType };
  }

  const hash = new URLSearchParams(url.hash.startsWith('#') ? url.hash.slice(1) : url.hash);
  const accessToken = clean(hash.get('access_token'));
  const refreshToken = clean(hash.get('refresh_token'));
  const hashType = clean(hash.get('type')).toLowerCase() || null;
  if (accessToken && refreshToken) {
    return { kind: 'session', accessToken, refreshToken, type: hashType };
  }
  return { kind: 'ignore' };
}

export function markPasswordSetup(): void {
  sessionStorage.setItem(PASSWORD_SETUP_STORAGE_KEY, '1');
}

export function passwordSetupMarked(): boolean {
  return sessionStorage.getItem(PASSWORD_SETUP_STORAGE_KEY) === '1';
}

export function clearPasswordSetupMark(): void {
  sessionStorage.removeItem(PASSWORD_SETUP_STORAGE_KEY);
}

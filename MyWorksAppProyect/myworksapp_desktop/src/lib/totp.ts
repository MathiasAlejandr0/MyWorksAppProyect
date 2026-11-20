export const TOTP_MAX_AGE_MS = 5 * 60 * 1000;
const KEY = 'mwa-totp-at';

export function markTotpVerified(now = Date.now()): void {
  sessionStorage.setItem(KEY, String(now));
}

export function totpFresh(now = Date.now(), maxAge = TOTP_MAX_AGE_MS): boolean {
  const raw = sessionStorage.getItem(KEY);
  const at = raw ? Number(raw) : Number.NaN;
  return Number.isFinite(at) && now - at >= 0 && now - at < maxAge;
}

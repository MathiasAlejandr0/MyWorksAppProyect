export const IDLE_LOGOUT_MS = 15 * 60 * 1000;
export const IDLE_WARN_MS = 13 * 60 * 1000;

export type IdlePhase = 'active' | 'warning' | 'expired';

export function idlePhase(elapsedMs: number, warnMs = IDLE_WARN_MS, logoutMs = IDLE_LOGOUT_MS): IdlePhase {
  if (elapsedMs >= logoutMs) return 'expired';
  if (elapsedMs >= warnMs) return 'warning';
  return 'active';
}

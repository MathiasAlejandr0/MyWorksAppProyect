/** Misma política que `Validators.validateSecurePassword` en Flutter. */
export const PASSWORD_MIN_LENGTH = 8;

export const PASSWORD_SETUP_STORAGE_KEY = 'mwa-password-setup';

const LETTER = /[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]/;
const DIGIT = /\d/;

/**
 * `null` si la clave cumple 8 caracteres, una letra y un número.
 * El login no usa esta función: las cuentas ya creadas siguen entrando.
 */
export function passwordPolicyMessage(password: string): string | null {
  if (!password) return 'La contraseña es requerida';
  if (password.length < PASSWORD_MIN_LENGTH) {
    return 'La contraseña debe tener al menos 8 caracteres';
  }
  if (!LETTER.test(password)) return 'Incluye al menos una letra';
  if (!DIGIT.test(password)) return 'Incluye al menos un número';
  return null;
}

/** Hash o query de un enlace de invitación o recuperación de Supabase Auth. */
export function authLinkRequiresPassword(raw: string): boolean {
  const trimmed = raw.startsWith('#') || raw.startsWith('?') ? raw.slice(1) : raw;
  if (!trimmed) return false;
  const type = (new URLSearchParams(trimmed).get('type') ?? '').toLowerCase();
  return type === 'invite' || type === 'recovery';
}

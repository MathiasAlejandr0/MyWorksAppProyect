const TRANSLATIONS: Array<[RegExp, string]> = [
  [/auth session missing/i, 'No hay una sesión activa. Abre otra vez el enlace del correo.'],
  [/invalid login credentials|invalid email or password/i, 'Correo o contraseña incorrectos.'],
  [/email not confirmed/i, 'Confirma el correo antes de continuar.'],
  [/password should be at least|password should contain|weak password/i, 'La contraseña no cumple la política. Usa al menos 8 caracteres, con una letra y un número.'],
  [/should be different from the old|same password/i, 'La nueva contraseña debe ser distinta de la anterior.'],
  [/unable to validate email|invalid format|email address.+invalid/i, 'El correo no es válido.'],
  [/rate limit|too many requests|only request this after|over_request_rate_limit/i, 'Demasiados intentos. Espera un momento e inténtalo de nuevo.'],
  [/failed to fetch|networkerror|network request failed|load failed|econn|timeout|503|502|504/i, 'No se pudo conectar. Revisa la red e inténtalo de nuevo.'],
  [/forbidden|permission denied|42501|no autorizado/i, 'No tienes permiso para esta acción.'],
  [/motivo demasiado corto|nota de rechazo/i, 'El motivo debe tener al menos 10 caracteres.'],
  [/could not find the function|schema cache|pgrst202/i, 'Falta aplicar la migración nueva de la consola en la base.'],
  [/no encontrad|not found|pgrst116/i, 'No se encontró el registro.'],
];

const PASSTHROUGH = /último administrador|invitación ya fue aceptada|desde Mi cuenta|No es una cuenta|desde la base|No puedes revocar|solo lectura/i;

const SPANISH = /\b(el|la|los|las|no|se|un|una|de|del|para|con|que|por|al|es|esta|este|tu|tus|clave|contraseña|correo|cuenta|sesión|sesion|incluye)\b/i;

export function friendlyError(
  error: { message?: string } | null | undefined,
  fallback = 'No se pudo completar la acción.',
): string {
  const msg = error?.message?.trim() ?? '';
  if (!msg) return fallback;
  if (PASSTHROUGH.test(msg)) return msg;
  for (const [pattern, text] of TRANSLATIONS) {
    if (pattern.test(msg)) return text;
  }
  if (SPANISH.test(msg)) return msg;
  return fallback;
}

export type LoadFailure = 'not_found' | 'network' | 'forbidden' | 'missing_migration' | 'other';

export function classifyLoadError(
  error: { message?: string; code?: string } | null | undefined,
): LoadFailure {
  const msg = error?.message?.trim() ?? '';
  const code = error?.code ?? '';
  if (/could not find the function|schema cache|pgrst202/i.test(msg) || code === 'PGRST202') {
    return 'missing_migration';
  }
  if (code === 'PGRST116' || /no encontrad|not found|0 rows|json object requested/i.test(msg)) {
    return 'not_found';
  }
  if (/forbidden|permission denied|42501/i.test(msg) || code === '42501') return 'forbidden';
  if (
    !msg
    || /failed to fetch|networkerror|network request failed|load failed|timeout|503|502|504|econn/i.test(msg)
  ) {
    return 'network';
  }
  return 'other';
}

export function loadFailureMessage(kind: LoadFailure, missing: string): string {
  if (kind === 'not_found') return missing;
  if (kind === 'forbidden') return 'No tienes permiso para ver esto.';
  if (kind === 'missing_migration') return 'Falta aplicar la migración nueva de la consola en la base.';
  if (kind === 'network') return 'No se pudo conectar. Revisa la red e inténtalo de nuevo.';
  return 'No se pudo cargar. Revisa la conexión e inténtalo de nuevo.';
}

export function describeLoadError(
  error: { message?: string; code?: string } | null | undefined,
  missing: string,
): string {
  return loadFailureMessage(classifyLoadError(error), missing);
}

export function friendlyError(error: { message?: string } | null | undefined, fallback = 'No se pudo completar la acción.'): string {
  const msg = error?.message?.trim() ?? '';
  if (!msg) return fallback;
  if (/forbidden|permission denied|42501|no autorizado/i.test(msg)) return 'No tienes permiso para esta acción.';
  if (/motivo demasiado corto|nota de rechazo/i.test(msg)) return 'El motivo debe tener al menos 10 caracteres.';
  if (/último administrador/i.test(msg)) return msg;
  if (/no encontrad/i.test(msg)) return 'No se encontró el registro.';
  if (/invitación ya fue aceptada|desde Mi cuenta|último administrador|No es una cuenta|desde la base|No puedes revocar/i.test(msg)) {
    return msg;
  }
  if (/solo lectura/i.test(msg)) return msg;
  return fallback;
}

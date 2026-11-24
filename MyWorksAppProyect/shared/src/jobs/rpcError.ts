/** Texto para la persona. No reexpone el mensaje crudo de la base. */
export function agreementErrorMessage(raw: string, action: 'proponer' | 'responder'): string {
  const text = raw.toLowerCase();
  if (text.includes('no autenticado') || text.includes('jwt')) {
    return 'Entra con tu cuenta para continuar.';
  }
  if (text.includes('permiso') || text.includes('solo el') || text.includes('no es parte')) {
    return 'Solo quien participa en el pedido puede hacer esto.';
  }
  if (text.includes('disputa')) {
    return 'Los acuerdos solo se proponen con una disputa abierta.';
  }
  if (text.includes('cerrado') || text.includes('estado')) {
    return 'Este pedido ya no admite un acuerdo.';
  }
  if (text.includes('ya existe') || text.includes('pendiente')) {
    return 'Ya hay un acuerdo pendiente en este pedido.';
  }
  return action === 'proponer'
    ? 'No se pudo proponer el acuerdo.'
    : 'No se pudo responder el acuerdo.';
}

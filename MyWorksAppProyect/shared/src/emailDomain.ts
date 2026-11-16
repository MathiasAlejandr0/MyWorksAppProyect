/**
 * Dominios reservados (RFC 2606 / RFC 6761): nunca reciben correo y el
 * proveedor de Auth los rechaza. Mejor avisar antes de enviar el formulario.
 */
const RESERVED_DOMAINS = ['example.com', 'example.net', 'example.org'];
const RESERVED_TLDS = ['test', 'example', 'invalid', 'localhost'];

export function isReservedEmailDomain(email: string): boolean {
  const at = email.trim().toLowerCase().lastIndexOf('@');
  if (at < 0) return false;
  const domain = email.trim().toLowerCase().slice(at + 1).replace(/\.$/, '');
  if (!domain) return false;
  if (RESERVED_DOMAINS.some((d) => domain === d || domain.endsWith(`.${d}`))) return true;
  const tld = domain.split('.').pop() ?? '';
  return RESERVED_TLDS.includes(tld);
}

/** `null` si el correo puede recibir mensajes; si no, el texto para mostrar. */
export function reservedEmailMessage(email: string): string | null {
  return isReservedEmailDomain(email)
    ? 'Ese correo es de ejemplo y no recibe mensajes. Usa un correo real para recibir la confirmación.'
    : null;
}

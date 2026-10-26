/** Misma idea que ContentFilter de Flutter y texto_tiene_contacto en Postgres. */
const emailPattern = /[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}/i;
const spelledEmailPattern = /\barroba\b/i;
const phonePattern = /(?:^|[^\d])(?:\+?56[\s.\-]*)?9(?:[\s.\-]?\d){8}(?!\d)/;
const evasionPattern =
  /whats\s*app|\bwsp\b|ll[aá]mame|h[aá]blame\s+al|telegram|\binsta\b|instagram|wa\.me|t\.me/i;
const linkPattern = /https?:\/\/|www\.|\b[\w\-]+\.(?:cl|com|net|org)\b/i;

export function containsContactData(text: string): boolean {
  const value = text.trim();
  if (!value) return false;
  return (
    emailPattern.test(value) ||
    spelledEmailPattern.test(value) ||
    phonePattern.test(value) ||
    evasionPattern.test(value) ||
    linkPattern.test(value)
  );
}

export const contactBlockedMessage =
  'Por seguridad y garantía de pago, no se permite compartir teléfono, correo ni enlaces.';

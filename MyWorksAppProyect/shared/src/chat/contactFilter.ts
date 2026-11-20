/**
 * Misma regla que ContentFilter de Flutter y texto_tiene_contacto en Postgres.
 * Los casos compartidos están en contactCases.json.
 *
 * WhatsApp, «llámame» y un enlace son contacto aunque no traigan usuario.
 * Facebook, TikTok, Instagram y el resto solo cuentan con usuario, enlace o @.
 * Un RUT, una medida o un monto no es un teléfono.
 */
const emailPattern = /[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}/i;
const spelledEmailPattern =
  /\b[a-z0-9._%+\-]+\s+arroba\s+(?:[a-z0-9.-]+\.(?:cl|com|net|org)|gmail|hotmail|outlook|yahoo|icloud)\b/i;
const spelledPhonePattern =
  /(?:cero|uno|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)(?:[\s,\-]+(?:cero|uno|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)){6,}/i;
const channelPattern =
  /whats\s*app|w[aá]ts?a+p+|\bwsp\b|guasap|wasap|wa\.me|t\.me|ll[aá]mame|h[aá]blame\s+al/i;

const network =
  '(?:facebook|\\bfb\\b|instagram|\\binsta\\b|\\big\\b|tik\\s*tok|tiktok|snapchat|twitter|signal|discord|telegram)';
const socialContactPattern = new RegExp(
  `${network}\\s*[:：]\\s*@?[a-z0-9._]{2,}` +
    `|${network}\\s+@\\s*[a-z0-9._]{2,}` +
    `|\\b(?:mi|en)\\s+${network}\\s+(?:es|de)\\s+@?[a-z0-9._]{2,}` +
    `|(?:facebook|fb|instagram|tiktok|twitter|x|snapchat|t)\\.(?:com|me)\\/[a-z0-9._]{2,}` +
    `|fb\\.me\\/[a-z0-9._]{2,}` +
    `|m\\.me\\/[a-z0-9._]{2,}`,
  'i',
);

const linkPattern = /https?:\/\/|www\.|\b[\w\-]+\.(?:cl|com|net|org)\b/i;

const areaCodes =
  '32|33|34|35|41|42|43|45|51|52|53|55|57|58|61|63|64|65|67|71|72|73|75';
const phonePattern = new RegExp(
  `(?:^|[^\\d])(?:\\+?56[\\s.\\-]*)?(?:9(?:[\\s.\\-]?\\d){8}|2(?:[\\s.\\-]?\\d){8}|(?:${areaCodes})(?:[\\s.\\-]?\\d){7})(?!\\d)`,
  'g',
);

const rutPattern =
  /\brut\s*:?\s*\d{7,9}\b|\b\d{1,2}\.\d{3}\.\d{3}-[\dk]\b|\b\d{7,8}-[\dk]\b/gi;
const moneyPattern = /\$\s*\d{1,3}(?:\.\d{3})+|\b\d{1,3}(?:\.\d{3})+\b/g;
const measurePattern =
  /\b\d+(?:[.,]\d+)?\s*(?:cm|mm|km|kg|grs?|g|ml|lts?|lt|mts?|metros?|horas?|hrs?|min|años?)\b/gi;

function maskNonPhones(text: string): string {
  return text
    .replace(rutPattern, ' ')
    .replace(moneyPattern, ' ')
    .replace(measurePattern, ' ');
}

function hasChileanPhone(text: string): boolean {
  const masked = maskNonPhones(text);
  phonePattern.lastIndex = 0;
  for (const match of masked.matchAll(phonePattern)) {
    const digits = match[0].replace(/\D/g, '');
    if (!digits.endsWith('000')) return true;
  }
  return false;
}

export function containsContactData(text: string): boolean {
  const value = text.trim();
  if (!value) return false;
  return (
    emailPattern.test(value) ||
    spelledEmailPattern.test(value) ||
    channelPattern.test(value) ||
    socialContactPattern.test(value) ||
    linkPattern.test(value) ||
    spelledPhonePattern.test(value) ||
    hasChileanPhone(value)
  );
}

export const contactBlockedTitle = 'Mensaje no permitido';

export const contactBlockedMessage =
  'Este tipo de mensaje no está permitido. Para proteger a ambas partes y conservar la garantía de pago, no se puede compartir teléfono, correo electrónico, enlaces ni datos de contacto externos. Continúe la conversación dentro de la aplicación.';

import QRCode from 'qrcode';

const OTPAUTH = /^otpauth:\/\/totp\//i;
const BASE32 = /^[A-Z2-7]+=*$/i;

export function isOtpauthUri(uri: string): boolean {
  const value = uri.trim();
  if (!OTPAUTH.test(value)) return false;
  try {
    const parsed = new URL(value);
    const secret = parsed.searchParams.get('secret') ?? '';
    return secret.length > 0 && BASE32.test(secret);
  } catch {
    return false;
  }
}

/** Supabase entrega un SVG en data URI con '#' en los colores; eso corta el src del <img>. */
export function sanitizeTotpQrDataUri(qrCode: string): string {
  const trimmed = qrCode.trim();
  const comma = trimmed.indexOf(',');
  if (!trimmed.startsWith('data:image/svg+xml') || comma < 0) return trimmed;
  const header = trimmed.slice(0, comma);
  if (/;base64/i.test(header)) return trimmed;
  return header + ',' + trimmed.slice(comma + 1).replace(/#/g, '%23');
}

export async function makeScannableTotpQr(totp: {
  qr_code?: string | null;
  uri?: string | null;
}): Promise<string | null> {
  const uri = totp.uri?.trim() ?? '';
  if (isOtpauthUri(uri)) {
    return QRCode.toDataURL(uri, {
      width: 240,
      margin: 2,
      errorCorrectionLevel: 'M',
      color: { dark: '#000000', light: '#ffffff' },
    });
  }
  const qrCode = totp.qr_code?.trim() ?? '';
  if (!qrCode) return null;
  return sanitizeTotpQrDataUri(qrCode);
}

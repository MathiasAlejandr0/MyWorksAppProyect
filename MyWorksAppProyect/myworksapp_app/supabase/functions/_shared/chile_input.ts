const LETTER = /[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]/;

/** Teléfono de Chile en E.164 (+56 y 9 dígitos). null si no calza. */
export function chileE164(raw: string): string | null {
  const compact = raw.trim().replace(/[\s().-]/g, "");
  let value = compact;
  if (/^56\d{9}$/.test(value)) value = `+${value}`;
  if (/^9\d{8}$/.test(value)) value = `+56${value}`;
  if (!/^\+56\d{9}$/.test(value)) return null;
  return value;
}

/** Dirección con al menos dos palabras y una letra. null si no calza. */
export function postalAddress(raw: string): string | null {
  const value = raw.trim().replace(/\s+/g, " ");
  if (value.length < 8 || value.length > 300) return null;
  if (!LETTER.test(value)) return null;
  if (!value.includes(" ")) return null;
  return value;
}

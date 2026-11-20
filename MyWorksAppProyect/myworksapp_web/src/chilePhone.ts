/** Misma regla que el servidor: +56 y 9 dígitos. */
export function chileE164(raw: string): string | null {
  const compact = raw.trim().replace(/[\s().-]/g, '');
  let value = compact;
  if (/^56\d{9}$/.test(value)) value = `+${value}`;
  if (/^9\d{8}$/.test(value)) value = `+56${value}`;
  if (!/^\+56\d{9}$/.test(value)) return null;
  return value;
}

/** dHash de 64 bits. Igual que `dhash_desde_luma` en Postgres. */
export function dhashDesdeLuma(luma: Uint8Array): string {
  if (luma.length !== 72) {
    throw new Error('la muestra perceptual debe tener 72 bytes');
  }
  let hex = '';
  let nibble = 0;
  let count = 0;
  for (let row = 0; row < 8; row += 1) {
    for (let col = 0; col < 8; col += 1) {
      const left = luma[row * 9 + col] ?? 0;
      const right = luma[row * 9 + col + 1] ?? 0;
      nibble = nibble * 2 + (left > right ? 1 : 0);
      count += 1;
      if (count === 4) {
        hex += nibble.toString(16);
        nibble = 0;
        count = 0;
      }
    }
  }
  return hex;
}

export async function sha256Hex(bytes: Uint8Array): Promise<string> {
  const copy = new Uint8Array(bytes.byteLength);
  copy.set(bytes);
  const digest = await crypto.subtle.digest('SHA-256', copy);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

export function byteaHex(bytes: Uint8Array): string {
  return `\\x${[...bytes].map((byte) => byte.toString(16).padStart(2, '0')).join('')}`;
}

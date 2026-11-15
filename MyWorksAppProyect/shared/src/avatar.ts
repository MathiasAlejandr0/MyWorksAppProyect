/**
 * Avatar con iniciales para quien no subió foto. Antes todos los
 * profesionales sin foto mostraban la misma foto de stock (un hombre),
 * lo que confundía en el listado y en el mapa.
 */
const PALETTE = ['#ff5e03', '#2563eb', '#0f766e', '#7c3aed', '#b45309', '#be123c', '#0369a1', '#4d7c0f'];

export function nameInitials(name: string): string {
  const parts = name
    .trim()
    .split(/\s+/)
    .filter(Boolean);
  const letters = parts.length > 1 ? [parts[0], parts[parts.length - 1]] : parts.slice(0, 1);
  return letters.map((part) => part[0]?.toLocaleUpperCase('es-CL') ?? '').join('') || '?';
}

function colorFor(seed: string): string {
  let hash = 0;
  for (const char of seed) hash = (hash * 31 + char.codePointAt(0)!) >>> 0;
  return PALETTE[hash % PALETTE.length];
}

/** `data:` SVG (permitido por la CSP en img-src) con iniciales y color estable. */
export function initialsAvatarDataUrl(name: string, seed = name): string {
  const initials = nameInitials(name)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;');
  const svg =
    `<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">` +
    `<rect width="200" height="200" fill="${colorFor(seed || name)}"/>` +
    `<text x="50%" y="50%" dy=".35em" text-anchor="middle" font-family="DM Sans,Arial,sans-serif" ` +
    `font-size="84" font-weight="700" fill="#ffffff">${initials}</text></svg>`;
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
}

/** Foto del perfil o, si no hay, avatar con iniciales. */
export function profilePhotoOrInitials(url: string | null | undefined, name: string, seed?: string): string {
  return url && url.trim() ? url : initialsAvatarDataUrl(name, seed ?? name);
}

/**
 * Texto comparable para buscar: minúsculas y sin tildes ni diéresis.
 * «electrico» encuentra «Eléctrico». Misma regla que `foldSearchText` de la app
 * Flutter (`lib/core/utils/search_text.dart`).
 */
export function foldSearchText(value: string): string {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

/** True si `haystack` contiene `query`, sin distinguir tildes ni mayúsculas. */
export function matchesSearchText(haystack: string, query: string): boolean {
  const needle = foldSearchText(query).trim();
  if (!needle) return true;
  return foldSearchText(haystack).includes(needle);
}

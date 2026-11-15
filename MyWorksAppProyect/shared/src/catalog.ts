/** Constantes de catálogo público (ahorro de MAU/egress en plan Free). */

export const CATALOG_PAGE_SIZE = 20;
export const CATALOG_PAGE_SIZE_MAX = 40;
export const CATALOG_STALE_MS = 5 * 60_000;
export const CATALOG_GC_MS = 30 * 60_000;

export type CatalogCursor = {
  rating: number;
  id: string;
};

/**
 * Si availableIds es null, el catálogo todavía no respondió: se muestran todas.
 * Si es un conjunto, se ocultan los oficios sin profesionales.
 */
export function categoriesWithPros<T extends { id: string }>(
  categories: readonly T[],
  availableIds: ReadonlySet<string> | null,
): T[] {
  if (availableIds == null) return [...categories];
  return categories.filter((category) => availableIds.has(category.id));
}

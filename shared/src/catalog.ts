/** Constantes de catálogo público (ahorro de MAU/egress en plan Free). */

export const CATALOG_PAGE_SIZE = 20;
export const CATALOG_PAGE_SIZE_MAX = 40;
export const CATALOG_STALE_MS = 5 * 60_000;
export const CATALOG_GC_MS = 30 * 60_000;

export type CatalogCursor = {
  rating: number;
  id: string;
};

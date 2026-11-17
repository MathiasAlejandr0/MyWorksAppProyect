import { sortCatalog } from '@myworksapp/shared';
import type { SearchWorker } from './components/SearchResultsView';

export type CatalogSort = 'recommended' | 'price' | 'rating';

/**
 * Orden por defecto = orden único del catálogo (cercanía, nota, precio), el
 * mismo de la RPC y de la app. Precio y nota son vistas opcionales que
 * desempatan con ese mismo orden.
 */
export function sortSearchWorkers(
  list: readonly SearchWorker[],
  sort: CatalogSort,
  origin: { latitude: number; longitude: number } | null,
): SearchWorker[] {
  const base = sortCatalog(
    list,
    (worker) => ({
      id: worker.id,
      rating: worker.rating,
      price: worker.pricePerVisit,
      latitude: worker.latitude,
      longitude: worker.longitude,
    }),
    origin,
  );
  if (sort === 'price') return [...base].sort((a, b) => a.pricePerVisit - b.pricePerVisit);
  if (sort === 'rating') return [...base].sort((a, b) => b.rating - a.rating);
  return base;
}

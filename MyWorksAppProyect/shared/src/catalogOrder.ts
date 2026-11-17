import { haversineKm } from './geo/distance';

/**
 * Orden único del catálogo de profesionales (web, app y RPC).
 *
 * Es la misma regla que `listar_profesionales_catalogo` en Postgres
 * (migraciones 20261117215046_catalogo_orden_cercania_nota_precio y
 * 20261117215659_catalogo_orden_tarifa_cero_al_final) y que
 * `lib/core/domain/catalog_order.dart` en la app:
 *   1. Cercanía: banda de 1 km (floor de la distancia haversine) ASC.
 *      Sin ubicación del cliente o sin base del profesional va al final.
 *   2. Calificación pública DESC (0 si no tiene reseñas).
 *   3. Tarifa de visita ASC (sin tarifa o tarifa 0 al final).
 *   4. id del profesional ASC (desempate estable).
 * La base del profesional se compara redondeada a 2 decimales, como la
 * entrega la RPC pública.
 */
export type CatalogOrderItem = {
  id: string;
  rating: number | null | undefined;
  price: number | null | undefined;
  latitude: number | null | undefined;
  longitude: number | null | undefined;
};

export type CatalogOrderOrigin = { latitude: number; longitude: number } | null | undefined;

/** Redondeo a 2 decimales igual a round(numeric, 2) de Postgres (mitad lejos de cero). */
export function roundCoord2(value: number): number {
  const sign = value < 0 ? -1 : 1;
  return (sign * Math.round(Math.abs(value) * 100 + 1e-9)) / 100;
}

function finite(value: number | null | undefined): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}

/** Banda de cercanía en km completos, o null si no se puede calcular. */
export function catalogDistanceBand(
  item: Pick<CatalogOrderItem, 'latitude' | 'longitude'>,
  origin: CatalogOrderOrigin,
): number | null {
  if (!origin || !finite(origin.latitude) || !finite(origin.longitude)) return null;
  if (!finite(item.latitude) || !finite(item.longitude)) return null;
  const km = haversineKm(
    roundCoord2(item.latitude),
    roundCoord2(item.longitude),
    origin.latitude,
    origin.longitude,
  );
  return Math.floor(km);
}

export function compareCatalogOrder(
  a: CatalogOrderItem,
  b: CatalogOrderItem,
  origin: CatalogOrderOrigin,
): number {
  const bandA = catalogDistanceBand(a, origin);
  const bandB = catalogDistanceBand(b, origin);
  if (bandA !== bandB) {
    if (bandA == null) return 1;
    if (bandB == null) return -1;
    return bandA - bandB;
  }
  const ratingA = finite(a.rating) ? a.rating : 0;
  const ratingB = finite(b.rating) ? b.rating : 0;
  if (ratingA !== ratingB) return ratingB - ratingA;
  const priceA = finite(a.price) && a.price > 0 ? a.price : null;
  const priceB = finite(b.price) && b.price > 0 ? b.price : null;
  if (priceA !== priceB) {
    if (priceA == null) return 1;
    if (priceB == null) return -1;
    return priceA - priceB;
  }
  return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
}

/** Devuelve una copia ordenada; `toItem` adapta el tipo de cada cliente. */
export function sortCatalog<T>(
  list: readonly T[],
  toItem: (value: T) => CatalogOrderItem,
  origin: CatalogOrderOrigin,
): T[] {
  return [...list]
    .map((value) => ({ value, item: toItem(value) }))
    .sort((x, y) => compareCatalogOrder(x.item, y.item, origin))
    .map((entry) => entry.value);
}

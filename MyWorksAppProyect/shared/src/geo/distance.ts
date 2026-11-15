/** Distancia en kilómetros (haversine). No usa un proveedor de tráfico. */
export function haversineKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const earth = 6371;
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return earth * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Minutos a velocidad urbana constante. Es una estimación, no tráfico en vivo. */
export function estimateEtaMinutes(
  distanceKm: number,
  speedKmh = 28,
): number | null {
  if (!Number.isFinite(distanceKm) || distanceKm < 0) return null;
  if (!Number.isFinite(speedKmh) || speedKmh <= 0) return null;
  if (distanceKm < 0.05) return 1;
  return Math.max(1, Math.round((distanceKm / speedKmh) * 60));
}

export const LIVE_GPS_STATUSES = ['en_camino', 'en_curso'] as const;

export function publishesLiveGps(status: string | null | undefined): boolean {
  if (!status) return false;
  return (LIVE_GPS_STATUSES as readonly string[]).includes(status);
}

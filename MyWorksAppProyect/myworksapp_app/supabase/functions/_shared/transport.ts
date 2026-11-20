/** Misma regla que shared/src/geo/transport.ts. */

export const NEARBY_SERVICE_RADIUS_KM = 7;
export const MAX_TRAVEL_WITH_SURCHARGE_KM = 30;
export const TRANSPORT_CLP_PER_EXTRA_KM = 1200;
export const TRANSPORT_MIN_SURCHARGE_CLP = 3000;
export const TRANSPORT_MAX_SURCHARGE_CLP = 18000;

function finite(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
}

export function asCoord(value: unknown): number | null {
  if (value == null || value === "") return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

/** Igual que `km_entre_puntos`: asin, y el cobro usa el km a 3 decimales. */
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
  const clamped = Math.min(1, Math.max(0, a));
  return earth * 2 * Math.asin(Math.sqrt(clamped));
}

export function quantizeChargeKm(kilometers: number): number {
  if (!Number.isFinite(kilometers) || kilometers <= 0) return 0;
  return Math.round(kilometers * 1000) / 1000;
}

/** El ,5 sube. Sirve para tarifa_visita numeric antes de sumar el traslado. */
export function roundClp(value: number): number {
  if (!Number.isFinite(value)) return 0;
  const negative = value < 0;
  const magnitude = Math.abs(value);
  const whole = Math.trunc(magnitude);
  const fraction = magnitude - whole;
  const rounded = fraction >= 0.5 ? whole + 1 : whole;
  return negative ? -rounded : rounded;
}

export function resolveServiceRadiusKm(radiusKm?: number | null): number {
  if (!finite(radiusKm) || radiusKm <= 0) return NEARBY_SERVICE_RADIUS_KM;
  return radiusKm;
}

export function withinTravelRange(distanceKm: number | null | undefined): boolean {
  if (distanceKm == null || !Number.isFinite(distanceKm)) return true;
  return quantizeChargeKm(distanceKm) <= MAX_TRAVEL_WITH_SURCHARGE_KM;
}

export function transportQuote(input: {
  workerLat?: number | null;
  workerLng?: number | null;
  jobLat?: number | null;
  jobLng?: number | null;
  radiusKm?: number | null;
}): { distanceKm: number | null; extraClp: number } {
  if (
    !finite(input.workerLat) ||
    !finite(input.workerLng) ||
    !finite(input.jobLat) ||
    !finite(input.jobLng)
  ) {
    return { distanceKm: null, extraClp: 0 };
  }
  const radiusKm = resolveServiceRadiusKm(input.radiusKm);
  const distanceKm = quantizeChargeKm(haversineKm(
    input.workerLat,
    input.workerLng,
    input.jobLat,
    input.jobLng,
  ));
  const extraKm = Math.max(0, distanceKm - radiusKm);
  if (extraKm <= 0) return { distanceKm, extraClp: 0 };
  const raw = Math.round(extraKm * TRANSPORT_CLP_PER_EXTRA_KM);
  return {
    distanceKm,
    extraClp: Math.min(
      TRANSPORT_MAX_SURCHARGE_CLP,
      Math.max(TRANSPORT_MIN_SURCHARGE_CLP, raw),
    ),
  };
}

export function transportExtraClp(input: {
  workerLat?: number | null;
  workerLng?: number | null;
  jobLat?: number | null;
  jobLng?: number | null;
  radiusKm?: number | null;
}): number {
  return transportQuote(input).extraClp;
}

import { haversineKm } from './distance';

/** Radio cercano realista: unos 10–15 min en auto, sin extra de traslado. */
export const NEARBY_SERVICE_RADIUS_KM = 7;

/** Más lejos que esto no se ofrece el viaje, ni con recargo. */
export const MAX_TRAVEL_WITH_SURCHARGE_KM = 30;

/** Pesos chilenos por kilómetro fuera del radar (combustible + tiempo). */
export const TRANSPORT_CLP_PER_EXTRA_KM = 1200;

export const TRANSPORT_MIN_SURCHARGE_CLP = 3000;
export const TRANSPORT_MAX_SURCHARGE_CLP = 18000;

export type TransportQuote = {
  distanceKm: number | null;
  radiusKm: number;
  extraKm: number;
  extraClp: number;
  insideRadar: boolean | null;
};

function finiteCoord(value: number | null | undefined): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}

export function resolveServiceRadiusKm(radiusKm?: number | null): number {
  if (!finiteCoord(radiusKm) || radiusKm <= 0) return NEARBY_SERVICE_RADIUS_KM;
  return radiusKm;
}

export function withinTravelRange(
  distanceKm: number | null | undefined,
): boolean {
  if (distanceKm == null || !Number.isFinite(distanceKm)) return true;
  return distanceKm <= MAX_TRAVEL_WITH_SURCHARGE_KM;
}

export function tooFarToBookCopy(): string {
  return `Este profesional queda a más de ${MAX_TRAVEL_WITH_SURCHARGE_KM} km. Elige a alguien más cercano.`;
}

/** Recargo solo por los km fuera del radar. Cero si el trabajo queda cerca. */
export function transportSurcharge(input: {
  workerLat?: number | null;
  workerLng?: number | null;
  jobLat?: number | null;
  jobLng?: number | null;
  radiusKm?: number | null;
}): TransportQuote {
  const radiusKm = resolveServiceRadiusKm(input.radiusKm);
  if (
    !finiteCoord(input.workerLat) ||
    !finiteCoord(input.workerLng) ||
    !finiteCoord(input.jobLat) ||
    !finiteCoord(input.jobLng)
  ) {
    return {
      distanceKm: null,
      radiusKm,
      extraKm: 0,
      extraClp: 0,
      insideRadar: null,
    };
  }

  const distanceKm = haversineKm(
    input.workerLat,
    input.workerLng,
    input.jobLat,
    input.jobLng,
  );
  const extraKm = Math.max(0, distanceKm - radiusKm);
  if (extraKm <= 0) {
    return {
      distanceKm,
      radiusKm,
      extraKm: 0,
      extraClp: 0,
      insideRadar: true,
    };
  }

  const raw = Math.round(extraKm * TRANSPORT_CLP_PER_EXTRA_KM);
  const extraClp = Math.min(
    TRANSPORT_MAX_SURCHARGE_CLP,
    Math.max(TRANSPORT_MIN_SURCHARGE_CLP, raw),
  );
  return {
    distanceKm,
    radiusKm,
    extraKm,
    extraClp,
    insideRadar: false,
  };
}

/** Texto de checkout: extra, cerca, o GPS aún no leído. */
export function transportCheckoutCopy(quote: {
  extraClp: number;
  insideRadar: boolean | null;
}): string {
  if (quote.insideRadar === false && quote.extraClp > 0) {
    const extra = Math.round(quote.extraClp).toLocaleString('es-CL');
    return `+$${extra} (fuera del área cercana)`;
  }
  if (quote.insideRadar === true) {
    return 'Incluido: el trabajo queda cerca';
  }
  return 'Sin extra por ahora. Usa el GPS, escribe una dirección o marca el punto en el mapa.';
}

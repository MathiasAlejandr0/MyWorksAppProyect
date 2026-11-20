import { quantizeChargeKm } from './money';

export { roundClp } from './money';

/** Haversine con `asin`, la misma expresión que `km_entre_puntos` en Postgres. */
export function haversineKmForCharge(
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

/** Piso a 1 decimal. No promete un radio gratis mayor al que cobra el servidor. */
export function formatServiceRadiusKm(radiusKm?: number | null): string {
  const radius = resolveServiceRadiusKm(radiusKm);
  const tenths = Math.floor(Math.round(radius * 1000) / 100);
  const whole = Math.floor(tenths / 10);
  const fraction = tenths % 10;
  if (fraction === 0) return String(whole);
  return `${whole},${fraction}`;
}

/** El pin del catálogo puede mentir ~1 km. Se oculta pasado este margen sobre 30 km. */
export const CATALOG_PIN_HIDE_BEYOND_KM = 31.5;

export function catalogPinTooFar(distanceKm: number | null | undefined): boolean {
  if (distanceKm == null || !Number.isFinite(distanceKm)) return false;
  return distanceKm > CATALOG_PIN_HIDE_BEYOND_KM;
}

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
  /** Base del catálogo, redondeada. extraClp no se cobra. */
  catalogBaseIsApproximate?: boolean;
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
  return quantizeChargeKm(distanceKm) <= MAX_TRAVEL_WITH_SURCHARGE_KM;
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
  catalogBaseIsApproximate?: boolean;
}): TransportQuote {
  const radiusKm = resolveServiceRadiusKm(input.radiusKm);
  const approximate = input.catalogBaseIsApproximate === true;
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
      catalogBaseIsApproximate: approximate,
    };
  }

  const distanceKm = quantizeChargeKm(
    haversineKmForCharge(
      input.workerLat,
      input.workerLng,
      input.jobLat,
      input.jobLng,
    ),
  );
  if (approximate) {
    return {
      distanceKm,
      radiusKm,
      extraKm: 0,
      extraClp: 0,
      insideRadar: null,
      catalogBaseIsApproximate: true,
    };
  }
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

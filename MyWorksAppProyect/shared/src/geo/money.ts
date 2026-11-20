/** Kilómetros del cobro: 3 decimales, half-away. */
export function quantizeChargeKm(kilometers: number): number {
  if (!Number.isFinite(kilometers) || kilometers <= 0) return 0;
  return Math.round(kilometers * 1000) / 1000;
}

/** Pesos enteros. El ,5 sube, igual que `round(numeric)` de Postgres. */
export function roundClp(value: number): number {
  if (!Number.isFinite(value)) return 0;
  const negative = value < 0;
  const magnitude = Math.abs(value);
  const whole = Math.trunc(magnitude);
  const fraction = magnitude - whole;
  const rounded = fraction >= 0.5 ? whole + 1 : whole;
  return negative ? -rounded : rounded;
}

/** `round(numerador / denominador)` para montos positivos, sin un double intermedio. */
export function roundHalfAway(numerator: number, denominator: number): number {
  if (!Number.isFinite(numerator) || !Number.isFinite(denominator) || denominator <= 0) {
    return 0;
  }
  if (numerator <= 0) return 0;
  const quotient = Math.trunc(numerator / denominator);
  const remainder = numerator % denominator;
  if (remainder * 2 >= denominator) return quotient + 1;
  return quotient;
}

/** 8 % entero de una orden de cambio. Coincide con `round(monto * 0.08)` en numeric. */
export function changeOrderFeeClp(amountClp: number): number {
  return roundHalfAway(Math.trunc(amountClp) * 8, 100);
}

export function publishedServiceClp(rate: number, squareMeters?: number | null): number {
  const unit = roundClp(rate);
  if (unit <= 0) return 0;
  if (squareMeters != null && squareMeters > 0) return unit * Math.trunc(squareMeters);
  return unit;
}

const COMUNA_HUNDREDTHS: Record<string, number> = {
  osorno: 98,
  providencia: 108,
  las_condes: 110,
  maipu: 95,
  puente_alto: 92,
};

/** Horas extra: un solo redondeo de monto × comuna × 1,15. */
export function overtimeAmountClp(input: {
  hourlyRateClp: number;
  extraHours: number;
  comunaKey?: string | null;
}): number {
  if (input.hourlyRateClp <= 0 || input.extraHours <= 0) return 0;
  const hundredths = COMUNA_HUNDREDTHS[input.comunaKey?.toLowerCase() ?? ''] ?? 100;
  return roundHalfAway(
    Math.trunc(input.hourlyRateClp) * Math.trunc(input.extraHours) * hundredths * 115,
    10000,
  );
}

/// Pesos enteros con la misma regla que `round(numeric)` de Postgres:
/// el ,5 sube, y un entero no se vuelve a redondear.
int roundClp(num value) {
  if (value is int) return value;
  final number = value.toDouble();
  if (number.isNaN || number.isInfinite) return 0;
  final negative = number < 0;
  final magnitude = negative ? -number : number;
  final whole = magnitude.truncate();
  final fraction = magnitude - whole;
  final rounded = fraction >= 0.5 ? whole + 1 : whole;
  return negative ? -rounded : rounded;
}

/// `round(numerador / denominador)` para montos positivos.
/// El resto se compara con la mitad del denominador, sin pasar por un double.
int roundHalfAway(int numerator, int denominator) {
  if (denominator <= 0) return 0;
  if (numerator <= 0) return 0;
  final quotient = numerator ~/ denominator;
  final remainder = numerator % denominator;
  if (remainder * 2 >= denominator) return quotient + 1;
  return quotient;
}

/// Kilómetros que entran al recargo: 3 decimales (1 metro), half-away.
/// Así la fórmula `asin` y la `atan2` no mueven el peso por ruido de punto flotante.
double quantizeChargeKm(double kilometers) {
  if (kilometers.isNaN || kilometers.isInfinite || kilometers <= 0) return 0;
  return (kilometers * 1000).round() / 1000.0;
}

/// Tarifa publicada en pesos. Por m² se redondea la unidad y después se multiplica,
/// que es lo que hace `monto_esperado_trabajo`.
int publishedServiceClp({
  required num rate,
  int? squareMeters,
}) {
  final unit = roundClp(rate);
  if (unit <= 0) return 0;
  if (squareMeters != null && squareMeters > 0) return unit * squareMeters;
  return unit;
}

/// 8 % de una orden de cambio. Igual que `(monto * 8 + 50) / 100` en Postgres,
/// que coincide con `round(numeric * 0.08)` para un monto entero.
int changeOrderFeeClp(int amountClp) => roundHalfAway(amountClp * 8, 100);

int changeOrderTotalClp(int amountClp) {
  if (amountClp <= 0) return 0;
  return amountClp + changeOrderFeeClp(amountClp);
}

/// Tarifa hora que cobra un bloque: visita redondeada × 2,5, entre $15.000 y $120.000.
int hourlyRateFromVisitFee(int visitFeeClp) {
  if (visitFeeClp <= 0) return 15000;
  final rate = roundHalfAway(visitFeeClp * 5, 2);
  if (rate < 15000) return 15000;
  if (rate > 120000) return 120000;
  return rate;
}

/// Factores de comuna en centésimas, para no multiplicar por 1,08 en binario.
const Map<String, int> comunaFactorHundredths = {
  'osorno': 98,
  'providencia': 108,
  'las_condes': 110,
  'maipu': 95,
  'puente_alto': 92,
};

int applyComunaFactor(int amountClp, String? comunaKey) {
  final hundredths = comunaFactorHundredths[comunaKey?.toLowerCase()] ?? 100;
  return roundHalfAway(amountClp * hundredths, 100);
}

/// Horas extra: monto × factor de comuna × 1,15, un solo redondeo al final.
int overtimeAmountClp({
  required int hourlyRateClp,
  required int extraHours,
  String? comunaKey,
}) {
  if (hourlyRateClp <= 0 || extraHours <= 0) return 0;
  final hundredths = comunaFactorHundredths[comunaKey?.toLowerCase()] ?? 100;
  return roundHalfAway(hourlyRateClp * extraHours * hundredths * 115, 10000);
}

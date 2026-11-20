/// El catálogo redondea la base del profesional. El cobro usa la coordenada
/// real, así que el total de la pantalla no se muestra hasta leer el servidor.
const String chargeNotReadyMessage =
    'No pudimos calcular el total. Reintenta antes de pagar.';

int? payableTotalClp(int? serverTotal) {
  if (serverTotal == null || serverTotal <= 0) return null;
  return serverTotal;
}

/// Un rechazo de monto no reescribe el total en pantalla: se vuelve a leer.
bool paymentMismatchNeedsReload(String message) =>
    expectedChargeFromMismatch(message) != null;

/// El servidor responde «Monto 40220 no coincide con tarifa/cotización 39830»
/// cuando el mapa usa la base redondeada y el cobro usa la ubicación real.
int? expectedChargeFromMismatch(String message) {
  final match = RegExp(
    r'monto\s+(\d+)\s+no coincide con (?:la )?(?:tarifa/cotizaci[oó]n|tarifa|cotizaci[oó]n)(?: esperada)?\s+(\d+)',
    caseSensitive: false,
  ).firstMatch(message);
  if (match == null) return null;
  return int.tryParse(match.group(2)!);
}

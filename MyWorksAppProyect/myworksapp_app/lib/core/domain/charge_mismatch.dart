/// El catálogo redondea la base del profesional. El cobro usa la coordenada
/// real, así que el total de la pantalla no se muestra hasta leer el servidor.
const String chargeNotReadyMessage =
    'No pudimos calcular el total. Reintenta antes de pagar.';

int? payableTotalClp(int? serverTotal) {
  if (serverTotal == null || serverTotal <= 0) return null;
  return serverTotal;
}

/// Lo que se cobra en este toque.
///
/// [shownClp] es la suma que armó la pantalla (a veces con la base redondeada
/// del mapa). Si el servidor trae otro entero, se cobra ese, sin pedir
/// confirmar otra vez.
({int amountClp, bool replacedShownTotal})? chargeForTap({
  required int shownClp,
  required int? serverTotalClp,
}) {
  final amount = payableTotalClp(serverTotalClp);
  if (amount == null) return null;
  return (amountClp: amount, replacedShownTotal: amount != shownClp);
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

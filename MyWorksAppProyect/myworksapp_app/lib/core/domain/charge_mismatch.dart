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

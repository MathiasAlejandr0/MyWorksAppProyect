/// Precio acordado de un trabajo, en CLP, si el snapshot o los metadatos lo traen.
///
/// Devuelve null cuando no hay un monto positivo. Así el rango de mercado
/// no se calcula con ceros ni con precios inventados.
double? agreedJobPriceClp({
  Map<String, dynamic>? pricingSnapshot,
  Map<String, dynamic>? serviceMetadata,
}) {
  final fromSnapshot = _positiveAmount(pricingSnapshot, const [
    'total_clp',
    'subtotal_clp',
  ]);
  if (fromSnapshot != null) return fromSnapshot;

  return _positiveAmount(serviceMetadata, const [
    'total_clp',
    'monto',
    'monto_clp',
    'price',
    'estimatedPrice',
  ]);
}

double? _positiveAmount(Map<String, dynamic>? source, List<String> keys) {
  if (source == null) return null;
  for (final key in keys) {
    final value = source[key];
    if (value is num && value > 0) return value.toDouble();
  }
  return null;
}

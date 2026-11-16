/// Precio acordado de un trabajo, en CLP, si ya está registrado.
///
/// Devuelve null cuando no hay un monto positivo. Así el rango de mercado
/// no se calcula con ceros ni con precios inventados, y la tarjeta solo
/// dice «por cotizar» cuando realmente no hay precio.
double? agreedJobPriceClp({
  Map<String, dynamic>? pricingSnapshot,
  Map<String, dynamic>? serviceMetadata,
  num? recordedAmountClp,
}) {
  final fromSnapshot = _positiveAmount(pricingSnapshot, const [
    'total_clp',
    'totalClp',
    'quoted_total_clp',
    'quotedTotalClp',
    'subtotal_clp',
    'subtotalClp',
  ]);
  if (fromSnapshot != null) return fromSnapshot;

  final fromMetadata = _positiveAmount(serviceMetadata, const [
    'worker_tier_price_clp',
    'total_clp',
    'totalClp',
    'monto',
    'monto_clp',
    'price',
    'estimatedPrice',
  ]);
  if (fromMetadata != null) return fromMetadata;

  if (recordedAmountClp != null && recordedAmountClp > 0) {
    return recordedAmountClp.toDouble();
  }
  return null;
}

double? _positiveAmount(Map<String, dynamic>? source, List<String> keys) {
  if (source == null) return null;
  for (final key in keys) {
    final value = source[key];
    if (value is num && value > 0) return value.toDouble();
    if (value is String) {
      final parsed = num.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (parsed != null && parsed > 0) return parsed.toDouble();
    }
  }
  return null;
}

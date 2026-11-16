import 'pricing_constants.dart';

/// Resultado de cálculo de precio (snapshot congelable en [JobModel.pricingSnapshot]).
class PriceQuote {
  final String pricingMode;
  final int totalClp;
  final int subtotalClp;
  final int platformFeeClp;

  /// Monto neto que recibe el profesional cuando la comisión se descuenta de su
  /// pago (en lugar de sumarse al cobro del cliente). `null` cuando no aplica.
  final int? workerPayoutClp;
  final String currency;
  final Map<String, dynamic> breakdown;
  final String? message;

  const PriceQuote({
    required this.pricingMode,
    required this.totalClp,
    required this.subtotalClp,
    this.platformFeeClp = 0,
    this.workerPayoutClp,
    this.currency = 'CLP',
    this.breakdown = const {},
    this.message,
  });

  /// Indica si la comisión se descuenta del pago al profesional.
  bool get feeDeductedFromWorker => workerPayoutClp != null;

  Map<String, dynamic> toJson() => {
    'pricing_mode': pricingMode,
    'total_clp': totalClp,
    'subtotal_clp': subtotalClp,
    'platform_fee_clp': platformFeeClp,
    if (workerPayoutClp != null) 'worker_payout_clp': workerPayoutClp,
    'currency': currency,
    'breakdown': breakdown,
    if (message != null) 'message': message,
  };

  /// Copia visible en `metadatos_servicio`. El servidor borra
  /// `instantanea_precio` al crear el trabajo; estos campos permiten
  /// reconstruir el cobro en el detalle.
  Map<String, dynamic> toJobMetadata() => {
    'quoted_total_clp': totalClp,
    'quoted_subtotal_clp': subtotalClp,
    'quoted_fee_clp': platformFeeClp,
    if (workerPayoutClp != null) 'quoted_worker_payout_clp': workerPayoutClp,
    'quoted_pricing_mode': pricingMode,
    if (message != null) 'quoted_message': message,
  };

  factory PriceQuote.fromJson(Map<String, dynamic> json) {
    return PriceQuote(
      pricingMode:
          (json['pricing_mode'] as String?) ??
          (json['pricingMode'] as String?) ??
          PricingConstants.modeLegacy,
      totalClp:
          _firstInt(json, const [
            'total_clp',
            'totalClp',
            'quoted_total_clp',
            'quotedTotalClp',
          ]) ??
          0,
      subtotalClp:
          _firstInt(json, const [
            'subtotal_clp',
            'subtotalClp',
            'quoted_subtotal_clp',
          ]) ??
          0,
      platformFeeClp:
          _firstInt(json, const ['platform_fee_clp', 'platformFeeClp']) ?? 0,
      workerPayoutClp: _firstInt(json, const [
        'worker_payout_clp',
        'workerPayoutClp',
      ]),
      currency: json['currency'] as String? ?? 'CLP',
      breakdown: Map<String, dynamic>.from(json['breakdown'] as Map? ?? {}),
      message: json['message'] as String?,
    );
  }
}

int? _firstInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num && value > 0) return value.toInt();
  }
  return null;
}

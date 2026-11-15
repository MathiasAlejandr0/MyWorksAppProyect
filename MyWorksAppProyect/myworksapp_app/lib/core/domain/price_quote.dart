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
      pricingMode: json['pricing_mode'] as String? ?? PricingConstants.modeLegacy,
      totalClp: (json['total_clp'] as num?)?.toInt() ?? 0,
      subtotalClp: (json['subtotal_clp'] as num?)?.toInt() ?? 0,
      platformFeeClp: (json['platform_fee_clp'] as num?)?.toInt() ?? 0,
      workerPayoutClp: (json['worker_payout_clp'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'CLP',
      breakdown: Map<String, dynamic>.from(
        json['breakdown'] as Map? ?? {},
      ),
      message: json['message'] as String?,
    );
  }
}

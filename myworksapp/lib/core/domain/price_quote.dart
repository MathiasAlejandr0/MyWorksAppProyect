import 'pricing_constants.dart';

/// Resultado de cálculo de precio (snapshot congelable en [JobModel.pricingSnapshot]).
class PriceQuote {
  final String pricingMode;
  final int totalClp;
  final int subtotalClp;
  final int platformFeeClp;
  final String currency;
  final Map<String, dynamic> breakdown;
  final String? message;

  const PriceQuote({
    required this.pricingMode,
    required this.totalClp,
    required this.subtotalClp,
    this.platformFeeClp = 0,
    this.currency = 'CLP',
    this.breakdown = const {},
    this.message,
  });

  Map<String, dynamic> toJson() => {
        'pricing_mode': pricingMode,
        'total_clp': totalClp,
        'subtotal_clp': subtotalClp,
        'platform_fee_clp': platformFeeClp,
        'currency': currency,
        'breakdown': breakdown,
        if (message != null) 'message': message,
      };

  factory PriceQuote.fromJson(Map<String, dynamic> json) {
    return PriceQuote(
      pricingMode: json['pricing_mode'] as String? ?? PricingConstants.modeLegacy,
      totalClp: (json['total_clp'] as num?)?.toInt() ?? 0,
      subtotalClp: (json['subtotal_clp'] as num?)?.toInt() ?? 0,
      platformFeeClp: (json['platform_fee_clp'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'CLP',
      breakdown: Map<String, dynamic>.from(
        json['breakdown'] as Map? ?? {},
      ),
      message: json['message'] as String?,
    );
  }
}

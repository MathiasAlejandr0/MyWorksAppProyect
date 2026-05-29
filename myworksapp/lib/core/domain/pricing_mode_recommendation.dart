import 'pricing_constants.dart';

/// Resultado del cuestionario de modalidad de cobro.
class PricingModeRecommendation {
  final String mode;
  final String title;
  final String explanation;
  final String? skuCode;
  final String? variantKey;
  final int? blockHours;
  final Map<String, dynamic> questionnaireAnswers;

  const PricingModeRecommendation({
    required this.mode,
    required this.title,
    required this.explanation,
    this.skuCode,
    this.variantKey,
    this.blockHours,
    this.questionnaireAnswers = const {},
  });

  bool get needsWorker =>
      mode == PricingConstants.modeFixedPrice ||
      mode == PricingConstants.modeHourlyBlock ||
      mode == PricingConstants.modeOpenQuote;

  PricingModeRecommendation copyWith({
    String? mode,
    String? title,
    String? explanation,
    String? skuCode,
    String? variantKey,
    int? blockHours,
    Map<String, dynamic>? questionnaireAnswers,
  }) {
    return PricingModeRecommendation(
      mode: mode ?? this.mode,
      title: title ?? this.title,
      explanation: explanation ?? this.explanation,
      skuCode: skuCode ?? this.skuCode,
      variantKey: variantKey ?? this.variantKey,
      blockHours: blockHours ?? this.blockHours,
      questionnaireAnswers: questionnaireAnswers ?? this.questionnaireAnswers,
    );
  }
}

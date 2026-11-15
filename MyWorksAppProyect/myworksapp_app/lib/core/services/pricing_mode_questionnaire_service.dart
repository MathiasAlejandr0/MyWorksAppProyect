import '../domain/pricing_constants.dart';
import '../domain/pricing_mode_recommendation.dart';

/// Reglas del cuestionario → modalidad de cobro recomendada.
class PricingModeQuestionnaireService {
  PricingModeQuestionnaireService._();
  static final PricingModeQuestionnaireService instance =
      PricingModeQuestionnaireService._();

  /// Tipos de trabajo (pregunta 1).
  static const jobRepair = 'repair';
  static const jobByHours = 'by_hours';
  static const jobMajorProject = 'major_project';
  static const jobDiagnosis = 'diagnosis';

  /// Reparaciones puntuales (pregunta 2a).
  static const repairFaucet = 'faucet';
  static const repairLock = 'lock';
  static const repairWaterHeater = 'water_heater';
  static const repairElectrical = 'electrical_point';
  static const repairOther = 'other_repair';

  /// Duración (pregunta 2b).
  static const hours2 = 2;
  static const hours4 = 4;
  static const hours8 = 8;

  PricingModeRecommendation recommend({
    required String jobType,
    String? repairType,
    int? blockHours,
    required bool workerPreselected,
  }) {
    var result = _build(jobType, repairType, blockHours);
    result = _adjustIfNoWorker(result, workerPreselected);
    return result;
  }

  PricingModeRecommendation _build(
    String jobType,
    String? repairType,
    int? blockHours,
  ) {
    switch (jobType) {
      case jobRepair:
        return _recommendRepair(repairType ?? repairOther);
      case jobByHours:
        final h = blockHours ?? hours4;
        return PricingModeRecommendation(
          mode: PricingConstants.modeHourlyBlock,
          title: 'Por bloque de horas',
          explanation:
              'Tu trabajo se extiende en el tiempo. Pagas un bloque de $h horas por adelantado; si se necesita más, se cotiza aparte.',
          blockHours: h,
          questionnaireAnswers: {
            'job_type': jobType,
            'block_hours': h,
          },
        );
      case jobMajorProject:
        return PricingModeRecommendation(
          mode: PricingConstants.modeOpenQuote,
          title: 'Cotización abierta',
          explanation:
              'Proyectos grandes requieren una evaluación detallada. El profesional que elegiste revisará tu pedido y te enviará una propuesta con costos antes de pagar.',
          questionnaireAnswers: {'job_type': jobType},
        );
      case jobDiagnosis:
        return PricingModeRecommendation(
          mode: PricingConstants.modeOpenQuote,
          title: 'Cotización abierta',
          explanation:
              'El profesional evaluará el problema y te enviará una propuesta con el monto y alcance antes de pagar.',
          questionnaireAnswers: {'job_type': jobType},
        );
      default:
        return PricingModeRecommendation(
          mode: PricingConstants.modeOpenQuote,
          title: 'Cotización abierta',
          explanation:
              'El profesional que elegiste revisará tu solicitud y te enviará una propuesta personalizada.',
          questionnaireAnswers: {'job_type': jobType},
        );
    }
  }

  PricingModeRecommendation _recommendRepair(String repairType) {
    switch (repairType) {
      case repairFaucet:
        return PricingModeRecommendation(
          mode: PricingConstants.modeFixedPrice,
          title: 'Precio fijo',
          explanation:
              'Cambiar o instalar un grifo, llave de paso o artefacto sanitario tiene un precio referencial conocido. El monto queda en garantía hasta completar el trabajo.',
          skuCode: 'FAUCET_REPLACE',
          variantKey: 'grifo',
          questionnaireAnswers: {
            'job_type': jobRepair,
            'repair_type': repairType,
          },
        );
      case repairLock:
        return PricingModeRecommendation(
          mode: PricingConstants.modeFixedPrice,
          title: 'Precio fijo',
          explanation:
              'Cambio de cerradura o cilindro es un trabajo estándar con precio fijo estimado + pago en garantía.',
          skuCode: 'LOCK_CYLINDER_REPLACE',
          variantKey: 'cerradura',
          questionnaireAnswers: {
            'job_type': jobRepair,
            'repair_type': repairType,
          },
        );
      case repairWaterHeater:
        return PricingModeRecommendation(
          mode: PricingConstants.modeFixedPrice,
          title: 'Precio fijo',
          explanation:
              'Instalación o cambio de calefón/termo entra en catálogo con precio fijo referencial.',
          skuCode: 'WATER_HEATER_INSTALL',
          variantKey: 'calefont',
          questionnaireAnswers: {
            'job_type': jobRepair,
            'repair_type': repairType,
          },
        );
      case repairElectrical:
        return PricingModeRecommendation(
          mode: PricingConstants.modeHourlyBlock,
          title: 'Por bloque de horas',
          explanation:
              'Trabajos eléctricos puntuales suelen medirse por tiempo (enchufes, tableros, luminarias). Recomendamos un bloque de 4 horas.',
          blockHours: hours4,
          questionnaireAnswers: {
            'job_type': jobRepair,
            'repair_type': repairType,
          },
        );
      case repairOther:
      default:
        return PricingModeRecommendation(
          mode: PricingConstants.modeFixedPrice,
          title: 'Precio fijo',
          explanation:
              'Reparación acotada con precio estimado de referencia. El detalle final se confirma con el profesional antes de iniciar.',
          skuCode: 'FAUCET_REPLACE',
          variantKey: 'grifo',
          questionnaireAnswers: {
            'job_type': jobRepair,
            'repair_type': repairType,
          },
        );
    }
  }

  PricingModeRecommendation _adjustIfNoWorker(
    PricingModeRecommendation r,
    bool workerPreselected,
  ) {
    if (workerPreselected) return r;
    return r.copyWith(
      explanation:
          '${r.explanation} Entra al perfil del profesional que te interese y crea la solicitud desde ahí.',
      questionnaireAnswers: {
        ...r.questionnaireAnswers,
        'needs_worker_profile': true,
      },
    );
  }
}

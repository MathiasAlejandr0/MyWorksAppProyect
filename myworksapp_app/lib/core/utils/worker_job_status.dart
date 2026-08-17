import '../database/models/job_model.dart';
import '../domain/pricing_constants.dart';
import 'constants.dart';

/// Estados de trabajo que mantienen al profesional "ocupado" (no recibe nuevas solicitudes).
class WorkerJobStatus {
  WorkerJobStatus._();

  static const List<String> activeStatuses = [
    AppConstants.jobStatusAccepted,
    AppConstants.jobStatusInProgress,
    PricingConstants.jobAwaitingClientApproval,
    PricingConstants.jobAwaitingPayment,
    PricingConstants.jobPausedChangeOrder,
    PricingConstants.jobQuoteSelected,
  ];

  static bool isActive(String status) => activeStatuses.contains(status);

  /// Prioriza el trabajo que requiere acción inmediata del profesional.
  static JobModel? pickHighlightJob(List<JobModel> activeJobs) {
    if (activeJobs.isEmpty) return null;
    for (final job in activeJobs) {
      if (job.status == AppConstants.jobStatusInProgress) return job;
    }
    for (final job in activeJobs) {
      if (job.status == AppConstants.jobStatusAccepted) return job;
    }
    return activeJobs.first;
  }

  static String activeBannerTitle(String status) {
    switch (status) {
      case PricingConstants.jobAwaitingPayment:
        return 'Esperando pago del cliente';
      case PricingConstants.jobQuoteSelected:
        return 'Cotización aceptada';
      case PricingConstants.jobPausedChangeOrder:
        return 'Cobro adicional pendiente';
      case PricingConstants.jobAwaitingClientApproval:
        return 'Esperando aprobación del cliente';
      case AppConstants.jobStatusAccepted:
        return 'Trabajo aceptado';
      default:
        return 'Trabajo en curso';
    }
  }
}

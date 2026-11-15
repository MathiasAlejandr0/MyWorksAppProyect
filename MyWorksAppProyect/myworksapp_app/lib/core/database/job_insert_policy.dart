import '../domain/pricing_constants.dart';
import '../utils/constants.dart';

/// Misma regla que trabajos_insert: sin profesional solo pendiente o
/// esperando cotizaciones; con profesional, esperando pago o cotizaciones.
bool jobInsertMatchesPolicy({String? workerId, required String status}) {
  final assigned = workerId != null && workerId.isNotEmpty;
  if (!assigned) {
    return status == AppConstants.jobStatusPending ||
        status == PricingConstants.jobAwaitingQuotes;
  }
  return status == PricingConstants.jobAwaitingPayment ||
      status == PricingConstants.jobAwaitingQuotes;
}

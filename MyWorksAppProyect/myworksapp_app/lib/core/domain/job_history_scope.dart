import '../utils/constants.dart';
import 'pricing_constants.dart';

/// Trabajos con el pago ya retenido y todavía abiertos.
///
/// `esperando_pago` no entra: el cobro aún no quedó en garantía.
/// `pausado_orden_cambio` sí: el trabajo sigue abierto y el pago retenido.
const jobHistoryOpenStatuses = <String>[
  AppConstants.jobStatusPending,
  AppConstants.jobStatusAccepted,
  AppConstants.jobStatusEnRoute,
  AppConstants.jobStatusInProgress,
  PricingConstants.jobAwaitingClientApproval,
  PricingConstants.jobPausedChangeOrder,
];

bool jobHistoryIsLive(String status) => jobHistoryOpenStatuses.contains(status);

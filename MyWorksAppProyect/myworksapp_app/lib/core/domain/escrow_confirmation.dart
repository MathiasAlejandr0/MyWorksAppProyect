import '../utils/constants.dart';
import 'pricing_constants.dart';

/// El cobro ya dejó el trabajo retenido. Confirmar otra vez no debe fallar.
bool escrowHoldAlreadyConfirmed(String status) {
  const held = {
    AppConstants.jobStatusPending,
    AppConstants.jobStatusAccepted,
    AppConstants.jobStatusEnRoute,
    AppConstants.jobStatusInProgress,
    PricingConstants.jobAwaitingClientApproval,
    AppConstants.jobStatusCompleted,
  };
  return held.contains(status);
}

/// La conformidad del cliente ya liberó el pago.
bool escrowReleaseAlreadyConfirmed(String status) =>
    status == AppConstants.jobStatusCompleted;

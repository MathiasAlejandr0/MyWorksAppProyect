import '../database/models/job_model.dart';
import '../domain/pricing_constants.dart';
import '../utils/app_error.dart';
import '../utils/constants.dart';
import 'payment_guard_ports.dart';

/// Valida que las transiciones cumplan requisitos de escrow según modalidad.
class PaymentGuard {
  PaymentGuard._();

  static Future<void> validate({
    required JobModel job,
    required String targetStatus,
    PaymentGuardPorts? ports,
  }) async {
    final p = ports ?? PaymentGuardPorts.production();
    final mode = job.pricingMode;

    if (mode == PricingConstants.modeLegacy) {
      await _validateTierCompletionPayment(job, targetStatus, p);
      await _validateChangeOrdersOnComplete(job, targetStatus, p);
      return;
    }

    final payment = await p.getPrimaryPayment(job.id);

    if (requiresAuthorizedForAccepted(mode, targetStatus)) {
      if (payment == null || payment.status != 'authorized') {
        throw AppError.validation(
          'El pago debe estar autorizado (en garantía) antes de continuar',
        );
      }
    }

    if (targetStatus == AppConstants.jobStatusInProgress) {
      if (payment == null || payment.status != 'authorized') {
        throw AppError.validation(
          'No se puede iniciar el trabajo sin pago en garantía',
        );
      }
      final pending = await p.countPendingChangeOrders(job.id);
      if (pending > 0) {
        throw AppError.validation('Hay órdenes de cambio pendientes de aprobación');
      }
    }

    if (fromAwaitingPaymentToAccepted(job, targetStatus)) {
      if (payment == null || payment.status != 'authorized') {
        throw AppError.validation(
          'Confirma el pago antes de aceptar el trabajo',
        );
      }
    }

    if (targetStatus == AppConstants.jobStatusInProgress &&
        job.status == PricingConstants.jobPausedChangeOrder) {
      final unpaid = await p.countApprovedUnpaidChangeOrders(job.id);
      if (unpaid > 0) {
        throw AppError.validation('Aprueba y paga las órdenes de cambio pendientes');
      }
    }

    await _validateChangeOrdersOnComplete(job, targetStatus, p);
  }

  /// Indica si la modalidad exige pago autorizado antes de pasar a [accepted].
  static bool requiresAuthorizedForAccepted(String mode, String target) {
    if (target != AppConstants.jobStatusAccepted) return false;
    return mode == PricingConstants.modeOpenQuote;
  }

  static bool fromAwaitingPaymentToAccepted(JobModel job, String target) {
    return job.status == PricingConstants.jobAwaitingPayment &&
        target == AppConstants.jobStatusAccepted;
  }

  static bool _isWorkerTierInvitation(JobModel job) {
    return job.serviceMetadata?['request_type'] == 'worker_tier_invitation';
  }

  static Future<void> _validateTierCompletionPayment(
    JobModel job,
    String targetStatus,
    PaymentGuardPorts ports,
  ) async {
    if (targetStatus != AppConstants.jobStatusCompleted) return;
    if (!_isWorkerTierInvitation(job)) return;
    if (job.status != PricingConstants.jobAwaitingClientApproval) return;

    final hasPayment = await ports.hasAuthorizedPrimaryPayment(job.id);
    if (!hasPayment) {
      throw AppError.validation(
        'Debes completar el pago antes de aprobar la finalización',
      );
    }
  }

  static Future<void> _validateChangeOrdersOnComplete(
    JobModel job,
    String targetStatus,
    PaymentGuardPorts ports,
  ) async {
    if (targetStatus != AppConstants.jobStatusCompleted) return;

    final pending = await ports.countPendingChangeOrders(job.id);
    if (pending > 0) {
      throw AppError.validation(
        'No puedes completar el trabajo con órdenes de cambio sin resolver',
      );
    }

    final unpaid = await ports.countApprovedUnpaidChangeOrders(job.id);
    if (unpaid > 0) {
      throw AppError.validation(
        'Hay cobros adicionales aprobados pendientes de pago',
      );
    }
  }
}

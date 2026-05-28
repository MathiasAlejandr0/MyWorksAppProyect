import '../database/models/job_model.dart';
import '../database/repositories/change_order_repository.dart';
import '../domain/pricing_constants.dart';
import '../utils/app_error.dart';
import '../utils/constants.dart';
import 'payment_service.dart';

/// Valida que las transiciones cumplan requisitos de escrow según modalidad.
class PaymentGuard {
  PaymentGuard._();

  static final ChangeOrderRepository _changeOrders = ChangeOrderRepository();

  static Future<void> validate({
    required JobModel job,
    required String targetStatus,
  }) async {
    final mode = job.pricingMode;

    if (mode == PricingConstants.modeLegacy) {
      await _validateChangeOrdersOnComplete(job, targetStatus);
      return;
    }

    final payment = await PaymentService.instance.getPrimaryPayment(job.id);

    if (_requiresAuthorizedForAccepted(mode, targetStatus)) {
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
      final pending = await _changeOrders.countPendingClient(job.id);
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

    if (targetStatus == PricingConstants.jobPausedChangeOrder) {
      // Permitido desde in_progress; el pago principal puede pasar a held en PaymentService.
    }

    if (targetStatus == AppConstants.jobStatusInProgress &&
        job.status == PricingConstants.jobPausedChangeOrder) {
      final unpaid = await _changeOrders.countApprovedUnpaid(job.id);
      if (unpaid > 0) {
        throw AppError.validation('Aprueba y paga las órdenes de cambio pendientes');
      }
    }

    await _validateChangeOrdersOnComplete(job, targetStatus);
  }

  static bool _requiresAuthorizedForAccepted(String mode, String target) {
    if (target != AppConstants.jobStatusAccepted) return false;
    return mode == PricingConstants.modeOpenQuote;
  }

  static bool fromAwaitingPaymentToAccepted(JobModel job, String target) {
    return job.status == PricingConstants.jobAwaitingPayment &&
        target == AppConstants.jobStatusAccepted;
  }

  static Future<void> _validateChangeOrdersOnComplete(
    JobModel job,
    String targetStatus,
  ) async {
    if (targetStatus != AppConstants.jobStatusCompleted) return;

    final pending = await _changeOrders.countPendingClient(job.id);
    if (pending > 0) {
      throw AppError.validation(
        'No puedes completar el trabajo con órdenes de cambio sin resolver',
      );
    }

    final unpaid = await _changeOrders.countApprovedUnpaid(job.id);
    if (unpaid > 0) {
      throw AppError.validation(
        'Hay cobros adicionales aprobados pendientes de pago',
      );
    }
  }
}

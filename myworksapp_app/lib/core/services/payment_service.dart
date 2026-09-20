import 'package:uuid/uuid.dart';
import '../database/repositories/payment_repository.dart';
import '../database/repositories/job_repository.dart';
import '../database/models/payment_model.dart';
import '../domain/pricing_constants.dart';
import '../domain/price_quote.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';

/// Servicio de pagos — escrow vía Webpay (Edge) + RPCs admin.
///
/// Crear intención: Edge `webpay-create` / RPC `crear_intencion_pago`.
/// Autorizar: `webpay-commit` (servidor).
/// Liberar/reembolsar: `liberar_escrow` / `reembolsar_escrow` (admin).
class PaymentService {
  PaymentService({
    PaymentRepository? paymentRepository,
    JobRepository? jobRepository,
  })  : _paymentRepository = paymentRepository ?? PaymentRepository(),
        _jobRepository = jobRepository ?? JobRepository();

  static final PaymentService instance = PaymentService();

  final PaymentRepository _paymentRepository;
  final JobRepository _jobRepository;

  /// Crea un pago para un job (MOCK)
  /// 
  /// En producción, esto autorizaría el pago en la pasarela.
  Future<PaymentModel> createPayment({
    required String jobId,
    required double amount,
    String currency = 'CLP',
    String? paymentMethod,
  }) async {
    throw AppError.validation(
      'Usa Webpay (TransbankWebpayGateway) para crear pagos. Insert directo deshabilitado.',
    );
  }

  /// Autoriza un pago (MOCK)
  /// 
  /// En producción, esto autorizaría el pago en la pasarela (escrow).
  Future<PaymentModel> authorizePayment(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        throw AppError.notFound('Pago no encontrado');
      }

      if (payment.status != PricingConstants.paymentPending) {
        throw AppError.validation('El pago ya fue procesado');
      }

      final updated = payment.copyWith(
        status: PricingConstants.paymentAuthorized,
        authorizedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final persisted = await _paymentRepository.transitionPaymentStatus(
        paymentId: paymentId,
        newStatus: PricingConstants.paymentAuthorized,
      );

      AppLogger.i('Pago autorizado (MOCK): $paymentId');
      return persisted.copyWith(
        authorizedAt: updated.authorizedAt ?? persisted.authorizedAt,
      );
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error autorizando pago', e);
      throw AppError.database('Error al autorizar pago: ${e.toString()}');
    }
  }

  /// Retiene un pago (por disputa)
  Future<PaymentModel> holdPayment(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        throw AppError.notFound('Pago no encontrado');
      }

      if (payment.status != PricingConstants.paymentAuthorized) {
        throw AppError.validation('Solo se pueden retener pagos autorizados');
      }

      final persisted = await _paymentRepository.transitionPaymentStatus(
        paymentId: paymentId,
        newStatus: PricingConstants.paymentHeld,
      );

      AppLogger.i('Pago retenido: $paymentId');
      return persisted;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error reteniendo pago', e);
      throw AppError.database('Error al retener pago: ${e.toString()}');
    }
  }

  /// Libera un pago al trabajador (liquidación manual con referencia bancaria).
  Future<PaymentModel> releasePayment(
    String paymentId, {
    required String transferRef,
    String? notes,
  }) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        throw AppError.notFound('Pago no encontrado');
      }

      if (![PricingConstants.paymentAuthorized, PricingConstants.paymentHeld]
          .contains(payment.status)) {
        throw AppError.validation('El pago no puede ser liberado desde este estado');
      }

      final persisted = await _paymentRepository.transitionPaymentStatus(
        paymentId: paymentId,
        newStatus: PricingConstants.paymentReleased,
        transferRef: transferRef,
        notes: notes,
      );

      AppLogger.i('Pago liberado: $paymentId');
      return persisted;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error liberando pago', e);
      throw AppError.database('Error al liberar pago: ${e.toString()}');
    }
  }

  /// Reembolsa un pago
  Future<PaymentModel> refundPayment(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        throw AppError.notFound('Pago no encontrado');
      }

      if (![PricingConstants.paymentAuthorized, PricingConstants.paymentHeld]
          .contains(payment.status)) {
        throw AppError.validation('El pago no puede ser reembolsado desde este estado');
      }

      final persisted = await _paymentRepository.transitionPaymentStatus(
        paymentId: paymentId,
        newStatus: PricingConstants.paymentRefunded,
      );

      AppLogger.i('Pago reembolsado: $paymentId');
      return persisted;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error reembolsando pago', e);
      throw AppError.database('Error al reembolsar pago: ${e.toString()}');
    }
  }

  /// Pago principal del job (escrow).
  Future<PaymentModel?> getPrimaryPayment(String jobId) async {
    try {
      return await _paymentRepository.getPrimaryByJobId(jobId);
    } catch (e) {
      AppLogger.e('Error obteniendo pago del job', e);
      return null;
    }
  }

  Future<PaymentModel?> getPaymentByJobId(String jobId) => getPrimaryPayment(jobId);

  /// Pago adicional (orden de cambio) — solo vía Webpay Edge.
  Future<PaymentModel> createSupplementalPayment({
    required String jobId,
    required String changeOrderId,
    required String paymentType,
    required PriceQuote quote,
    String? paymentMethod,
  }) async {
    throw AppError.validation(
      'Órdenes de cambio: pagar con Webpay (webpay-create). Insert local deshabilitado.',
    );
  }

  /// Crea checkout del pago principal a partir de [PriceQuote].
  Future<PaymentModel> createPrimaryPayment({
    required String jobId,
    required PriceQuote quote,
    String? paymentMethod,
  }) async {
    throw AppError.validation(
      'El pago principal se crea vía Webpay (webpay-create), no localmente.',
    );
  }

  /// Confirma escrow tras Webpay (Edge ya escribió estado) o lee estado actual.
  Future<PaymentModel> authorizePrimaryForJob(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    if (payment == null) {
      throw AppError.notFound('No hay pago principal para este trabajo');
    }
    if (payment.status == PricingConstants.paymentAuthorized ||
        payment.status == PricingConstants.paymentHeld) {
      await _syncJobPaymentStatus(jobId, payment.status);
      return payment;
    }
    if (payment.status != PricingConstants.paymentPending) {
      throw AppError.validation('El pago ya fue procesado');
    }
    // Esperar confirmación Webpay (no simular transición local).
    throw AppError.validation(
      'Completa el pago en Webpay. El estado se actualizará al volver de Transbank.',
    );
  }

  /// Libera fondos al completar el trabajo (requiere referencia de transferencia).
  Future<PaymentModel?> releasePrimaryOnJobCompleted(
    String jobId, {
    required String transferRef,
    String? notes,
  }) async {
    final payment = await getPrimaryPayment(jobId);
    if (payment == null) return null;
    if (payment.status == PricingConstants.paymentReleased) return payment;
    final released = await releasePayment(
      payment.id,
      transferRef: transferRef,
      notes: notes,
    );
    await _syncJobPaymentStatus(jobId, PricingConstants.paymentReleased);
    return released;
  }

  Future<void> refundPrimaryOnCancellation(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    if (payment == null) return;
    if ([PricingConstants.paymentAuthorized, PricingConstants.paymentHeld]
        .contains(payment.status)) {
      await refundPayment(payment.id);
      await _syncJobPaymentStatus(jobId, PricingConstants.paymentRefunded);
    }
  }

  Future<void> _syncJobPaymentStatus(String jobId, String paymentStatus) async {
    final job = await _jobRepository.getJobById(jobId);
    if (job == null) return;
    await _jobRepository.updateJob(
      job.copyWith(paymentStatus: paymentStatus, updatedAt: DateTime.now()),
    );
  }

  /// Verifica si un job tiene pago principal autorizado (garantía).
  Future<bool> hasAuthorizedPrimaryPayment(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    return payment != null &&
        payment.status == PricingConstants.paymentAuthorized;
  }

  Future<bool> hasPayment(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    return payment != null;
  }
}


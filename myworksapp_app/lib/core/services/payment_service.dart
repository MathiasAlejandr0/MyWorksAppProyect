import 'package:uuid/uuid.dart';
import '../database/repositories/payment_repository.dart';
import '../database/repositories/job_repository.dart';
import '../database/models/payment_model.dart';
import '../domain/pricing_constants.dart';
import '../domain/price_quote.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';

/// Servicio de pagos (MOCK - Preparado para integración futura)
/// 
/// NO implementa pasarela real todavía.
/// Solo prepara la arquitectura para:
/// - Escrow (pago retenido)
/// - Liberación de pago
/// - Reembolsos
/// - Estados de pago
class PaymentService {
  static final PaymentService instance = PaymentService._();
  PaymentService._();

  final PaymentRepository _paymentRepository = PaymentRepository();
  final JobRepository _jobRepository = JobRepository();

  /// Crea un pago para un job (MOCK)
  /// 
  /// En producción, esto autorizaría el pago en la pasarela.
  Future<PaymentModel> createPayment({
    required String jobId,
    required double amount,
    String currency = 'USD',
    String? paymentMethod,
  }) async {
    try {
      AppLogger.i('Creando pago (MOCK) para job: $jobId');

      final now = DateTime.now();
      final payment = PaymentModel(
        id: const Uuid().v4(),
        jobId: jobId,
        amount: amount,
        currency: currency,
        status: 'pending', // En producción, esto sería 'authorized' después de autorizar
        paymentMethod: paymentMethod ?? 'card',
        createdAt: now,
        updatedAt: now,
      );

      await _paymentRepository.createPayment(payment);

      AppLogger.i('Pago creado (MOCK): ${payment.id}');
      return payment;
    } catch (e) {
      AppLogger.e('Error creando pago', e);
      throw AppError.database('Error al crear pago: ${e.toString()}');
    }
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

      if (payment.status != 'pending') {
        throw AppError.validation('El pago ya fue procesado');
      }

      final updated = payment.copyWith(
        status: 'authorized',
        authorizedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _paymentRepository.updatePayment(updated);

      AppLogger.i('Pago autorizado (MOCK): $paymentId');
      return updated;
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

      if (payment.status != 'authorized') {
        throw AppError.validation('Solo se pueden retener pagos autorizados');
      }

      final updated = payment.copyWith(
        status: 'held',
        updatedAt: DateTime.now(),
      );

      await _paymentRepository.updatePayment(updated);

      AppLogger.i('Pago retenido: $paymentId');
      return updated;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error reteniendo pago', e);
      throw AppError.database('Error al retener pago: ${e.toString()}');
    }
  }

  /// Libera un pago al trabajador
  Future<PaymentModel> releasePayment(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        throw AppError.notFound('Pago no encontrado');
      }

      if (!['authorized', 'held'].contains(payment.status)) {
        throw AppError.validation('El pago no puede ser liberado desde este estado');
      }

      final updated = payment.copyWith(
        status: 'released',
        releasedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _paymentRepository.updatePayment(updated);

      AppLogger.i('Pago liberado: $paymentId');
      return updated;
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

      if (!['authorized', 'held'].contains(payment.status)) {
        throw AppError.validation('El pago no puede ser reembolsado desde este estado');
      }

      final updated = payment.copyWith(
        status: 'refunded',
        refundedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _paymentRepository.updatePayment(updated);

      AppLogger.i('Pago reembolsado: $paymentId');
      return updated;
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

  /// Pago adicional (orden de cambio / overtime).
  Future<PaymentModel> createSupplementalPayment({
    required String jobId,
    required String changeOrderId,
    required String paymentType,
    required PriceQuote quote,
    String? paymentMethod,
  }) async {
    final now = DateTime.now();
    final payment = PaymentModel(
      id: const Uuid().v4(),
      jobId: jobId,
      changeOrderId: changeOrderId,
      paymentType: paymentType,
      amount: quote.totalClp.toDouble(),
      currency: quote.currency,
      status: 'pending',
      paymentMethod: paymentMethod ?? 'card',
      createdAt: now,
      updatedAt: now,
    );
    await _paymentRepository.createPayment(payment);
    return payment;
  }

  /// Crea checkout del pago principal a partir de [PriceQuote].
  Future<PaymentModel> createPrimaryPayment({
    required String jobId,
    required PriceQuote quote,
    String? paymentMethod,
  }) async {
    final existing = await getPrimaryPayment(jobId);
    if (existing != null && existing.status != 'refunded') {
      throw AppError.validation('Este trabajo ya tiene un pago registrado');
    }

    final now = DateTime.now();
    final payment = PaymentModel(
      id: const Uuid().v4(),
      jobId: jobId,
      paymentType: PricingConstants.paymentTypePrimary,
      amount: quote.totalClp.toDouble(),
      currency: quote.currency,
      status: 'pending',
      paymentMethod: paymentMethod ?? 'card',
      createdAt: now,
      updatedAt: now,
    );

    await _paymentRepository.createPayment(payment);
    await _syncJobPaymentStatus(jobId, PricingConstants.paymentPending);
    return payment;
  }

  /// Autoriza escrow (mock pasarela) y habilita transición a accepted / in_progress.
  Future<PaymentModel> authorizePrimaryForJob(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    if (payment == null) {
      throw AppError.notFound('No hay pago principal para este trabajo');
    }
    final authorized = await authorizePayment(payment.id);
    await _syncJobPaymentStatus(jobId, PricingConstants.paymentAuthorized);
    return authorized;
  }

  /// Libera fondos al completar el trabajo.
  Future<PaymentModel?> releasePrimaryOnJobCompleted(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    if (payment == null) return null;
    if (payment.status == 'released') return payment;
    final released = await releasePayment(payment.id);
    await _syncJobPaymentStatus(jobId, PricingConstants.paymentReleased);
    return released;
  }

  Future<void> refundPrimaryOnCancellation(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    if (payment == null) return;
    if (['authorized', 'held'].contains(payment.status)) {
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
    return payment != null && payment.status == 'authorized';
  }

  Future<bool> hasPayment(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    return payment != null;
  }
}


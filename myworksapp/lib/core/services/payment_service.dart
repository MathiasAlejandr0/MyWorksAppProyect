import 'package:uuid/uuid.dart';
import '../database/repositories/payment_repository.dart';
import '../database/models/payment_model.dart';
import '../database/models/job_model.dart';
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

  /// Obtiene el pago de un job
  Future<PaymentModel?> getPaymentByJobId(String jobId) async {
    try {
      return await _paymentRepository.getPaymentByJobId(jobId);
    } catch (e) {
      AppLogger.e('Error obteniendo pago del job', e);
      return null;
    }
  }

  /// Verifica si un job tiene pago
  Future<bool> hasPayment(String jobId) async {
    final payment = await getPaymentByJobId(jobId);
    return payment != null;
  }
}


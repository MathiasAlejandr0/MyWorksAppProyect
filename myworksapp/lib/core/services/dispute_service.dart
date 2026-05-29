import 'package:uuid/uuid.dart';
import '../database/repositories/dispute_repository.dart';
import '../database/repositories/job_repository.dart';
import '../database/models/dispute_model.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';
import 'payment_service.dart';

/// Servicio de disputas
/// 
/// Maneja:
/// - Apertura de disputas
/// - Congelamiento de rating y pago
/// - Resolución de disputas
class DisputeService {
  static final DisputeService instance = DisputeService._();
  DisputeService._();

  final DisputeRepository _disputeRepository = DisputeRepository();
  final JobRepository _jobRepository = JobRepository();
  final PaymentService _paymentService = PaymentService.instance;

  /// Abre una disputa para un job
  /// 
  /// Congela:
  /// - Rating (no se puede calificar)
  /// - Pago (se retiene si está autorizado)
  Future<DisputeModel> openDispute({
    required String jobId,
    required String openedBy,
    required String reason,
    String? description,
  }) async {
    try {
      AppLogger.i('Abriendo disputa para job: $jobId');

      // 1. Verificar que el job existe
      final job = await _jobRepository.getJobById(jobId);
      if (job == null) {
        throw AppError.notFound('Trabajo no encontrado');
      }

      // 2. Verificar que el usuario tiene permiso
      if (job.userId != openedBy && job.workerId != openedBy) {
        throw AppError.permission('No tienes permiso para abrir una disputa en este trabajo');
      }

      // 3. Verificar que no hay disputa abierta
      final existingDispute = await _disputeRepository.getDisputeByJobId(jobId);
      if (existingDispute != null && existingDispute.status == 'open') {
        throw AppError.validation('Ya existe una disputa abierta para este trabajo');
      }

      // 4. Crear disputa
      final now = DateTime.now();
      final dispute = DisputeModel(
        id: const Uuid().v4(),
        jobId: jobId,
        openedBy: openedBy,
        reason: reason,
        description: description,
        status: 'open',
        createdAt: now,
        updatedAt: now,
      );

      await _disputeRepository.createDispute(dispute);

      // 5. Congelar pago si existe
      final payment = await _paymentService.getPaymentByJobId(jobId);
      if (payment != null && payment.status == 'authorized') {
        await _paymentService.holdPayment(payment.id);
        AppLogger.i('Pago retenido por disputa: ${payment.id}');
      }

      AppLogger.i('Disputa abierta: ${dispute.id}');
      return dispute;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error abriendo disputa', e);
      throw AppError.database('Error al abrir disputa: ${e.toString()}');
    }
  }

  /// Resuelve una disputa (solo admin en producción)
  /// 
  /// En producción, esto requeriría permisos de admin.
  Future<DisputeModel> resolveDispute({
    required String disputeId,
    required String resolvedBy,
    required String resolution,
  }) async {
    try {
      final dispute = await _disputeRepository.getDisputeById(disputeId);
      if (dispute == null) {
        throw AppError.notFound('Disputa no encontrada');
      }

      if (dispute.status != 'open' && dispute.status != 'under_review') {
        throw AppError.validation('La disputa ya fue resuelta');
      }

      final updated = dispute.copyWith(
        status: 'resolved',
        resolution: resolution,
        resolvedBy: resolvedBy,
        resolvedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _disputeRepository.updateDispute(updated);

      // Si el pago estaba retenido, decidir qué hacer
      final payment = await _paymentService.getPaymentByJobId(dispute.jobId);
      if (payment != null && payment.status == 'held') {
        // Por defecto, liberar el pago (en producción, esto dependería de la resolución)
        await _paymentService.releasePayment(payment.id);
        AppLogger.i('Pago liberado después de resolución de disputa');
      }

      AppLogger.i('Disputa resuelta: $disputeId');
      return updated;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error resolviendo disputa', e);
      throw AppError.database('Error al resolver disputa: ${e.toString()}');
    }
  }

  /// Verifica si un job tiene disputa abierta
  Future<bool> hasOpenDispute(String jobId) async {
    try {
      final dispute = await _disputeRepository.getDisputeByJobId(jobId);
      return dispute != null && dispute.status == 'open';
    } catch (e) {
      AppLogger.e('Error verificando disputa', e);
      return false;
    }
  }

  /// Verifica si se puede calificar un job (no tiene disputa abierta)
  Future<bool> canRateJob(String jobId) async {
    final hasDispute = await hasOpenDispute(jobId);
    return !hasDispute;
  }

  /// Obtiene la disputa de un job
  Future<DisputeModel?> getDisputeByJobId(String jobId) async {
    try {
      return await _disputeRepository.getDisputeByJobId(jobId);
    } catch (e) {
      AppLogger.e('Error obteniendo disputa', e);
      return null;
    }
  }
}


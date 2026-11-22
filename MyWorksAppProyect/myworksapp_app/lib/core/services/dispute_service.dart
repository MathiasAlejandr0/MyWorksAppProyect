import 'package:uuid/uuid.dart';
import '../database/repositories/dispute_repository.dart';
import '../database/repositories/job_repository.dart';
import '../database/models/dispute_model.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';
import '../utils/error_handler.dart';
import 'evento_service.dart';
import 'dispute_rules.dart';
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
        throw AppError.permission(
            'No tienes permiso para abrir una disputa en este trabajo');
      }

      // 3. Verificar que no hay disputa abierta
      final existingDispute = await _disputeRepository.getDisputeByJobId(jobId);
      if (disputeIsOpen(existingDispute?.status)) {
        throw AppError.validation(
            'Ya existe una disputa abierta para este trabajo');
      }

      // 4. Crear disputa
      final now = DateTime.now();
      final dispute = DisputeModel(
        id: const Uuid().v4(),
        jobId: jobId,
        openedBy: openedBy,
        reason: reason,
        description: description,
        status: 'abierta',
        createdAt: now,
        updatedAt: now,
      );

      await _disputeRepository.createDispute(dispute);
      registrarEvento(tipo: 'disputa', entidadId: jobId);
      // El cliente no escribe pagos. El commit de Webpay ya dejó el cobro retenido.

      AppLogger.i('Disputa abierta: ${dispute.id}');
      return dispute;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error abriendo disputa', e);
      throw AppError.database(
          'No se pudo abrir la disputa. Inténtalo de nuevo.');
    }
  }

  /// Cierra la disputa y mueve el dinero: [decision] es `liberar` o `reembolsar`.
  Future<DisputeModel> resolveDispute({
    required String disputeId,
    required String resolvedBy,
    required String resolution,
    required String decision,
  }) async {
    try {
      final dispute = await _disputeRepository.getDisputeById(disputeId);
      if (dispute == null) {
        throw AppError.notFound('Disputa no encontrada');
      }

      if (dispute.status != 'abierta' && dispute.status != 'en_revision') {
        throw AppError.validation('La disputa ya fue resuelta');
      }
      if (decision != 'liberar' && decision != 'reembolsar') {
        throw AppError.validation(
            'Elige liberar el pago o devolverlo a la tarjeta');
      }

      await _paymentService.resolveDisputeFunds(
        disputeId: disputeId,
        decision: decision,
        resolution: resolution,
      );

      final updated = await _disputeRepository.getDisputeById(disputeId);
      AppLogger.i('Disputa $disputeId cerrada por $resolvedBy: $decision');
      return updated ??
          dispute.copyWith(
            status: 'resuelta',
            resolution: resolution,
            resolvedBy: resolvedBy,
            resolvedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error resolviendo disputa', e);
      throw AppError.validation(ErrorHandler.userMessageFor(e));
    }
  }

  Future<void> addComment({
    required String disputeId,
    required String comment,
  }) async {
    final text = comment.trim();
    if (text.isEmpty) {
      throw AppError.validation('El comentario es requerido');
    }
    await _disputeRepository.addComment(disputeId, text);
  }

  /// Estados en los que la disputa sigue abierta (bloquea calificar).
  static bool isOpenStatus(String? status) =>
      status == 'abierta' ||
      status == 'en_revision' ||
      status == 'requiere_humano' ||
      status == 'reembolso_pendiente';

  /// Verifica si un job tiene disputa abierta
  Future<bool> hasOpenDispute(String jobId) async {
    try {
      final dispute = await _disputeRepository.getDisputeByJobId(jobId);
      return dispute != null && isOpenStatus(dispute.status);
    } catch (e) {
      AppLogger.e('Error verificando disputa', e);
      return true;
    }
  }

  /// Verifica si se puede calificar un job (no tiene disputa abierta)
  Future<bool> canRateJob(String jobId) async {
    final hasDispute = await hasOpenDispute(jobId);
    return !hasDispute;
  }

  Future<void> proposeAgreement({
    required String jobId,
    required String type,
  }) async {
    await _disputeRepository.proposeAgreement(
      id: const Uuid().v4(),
      jobId: jobId,
      type: type,
    );
  }

  Future<Map<String, dynamic>?> pendingAgreement(String jobId) {
    return _disputeRepository.pendingAgreement(jobId);
  }

  Future<void> respondAgreement({
    required String id,
    required bool accept,
  }) {
    return _disputeRepository.respondAgreement(id: id, accept: accept);
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

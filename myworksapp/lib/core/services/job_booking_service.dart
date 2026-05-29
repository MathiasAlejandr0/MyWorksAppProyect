import 'package:uuid/uuid.dart';

import '../database/models/job_model.dart';
import '../database/repositories/job_repository.dart';
import '../domain/price_quote.dart';
import '../domain/pricing_constants.dart';
import '../utils/app_error.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import 'job_state_machine.dart';
import 'pricing_service.dart';

/// Creación de trabajos con modalidades de cobro + escrow mock (sin pasarela real).
class JobBookingService {
  JobBookingService._();
  static final JobBookingService instance = JobBookingService._();

  final JobRepository _jobs = JobRepository();
  final JobStateMachine _stateMachine = JobStateMachine.instance;

  /// Reserva visita (precio fijo por tarifa de visita).
  Future<({JobModel job, PriceQuote quote})> createVisitBooking({
    required String userId,
    required String workerId,
    required String serviceId,
    required String address,
    required int visitFeeClp,
    required DateTime scheduledDate,
    String? description,
    String? comunaKey,
    double? latitude,
    double? longitude,
  }) async {
    final quote = PricingService.instance.calculateVisitBooking(
      visitFeeClp: visitFeeClp,
      comunaKey: comunaKey,
    );
    return _createEscrowJob(
      userId: userId,
      workerId: workerId,
      serviceId: serviceId,
      address: address,
      description: description,
      scheduledDate: scheduledDate,
      comunaKey: comunaKey,
      latitude: latitude,
      longitude: longitude,
      pricingMode: PricingConstants.modeFixedPrice,
      quote: quote,
    );
  }

  /// Precio fijo por SKU (solicitud de servicio con ítem catalogado).
  Future<({JobModel job, PriceQuote quote})> createFixedSkuBooking({
    required String userId,
    required String workerId,
    required String serviceId,
    required String address,
    required String skuCode,
    String? description,
    DateTime? scheduledDate,
    String? comunaKey,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? serviceMetadata,
  }) async {
    final quote = await PricingService.instance.calculateFixedPrice(
      skuCode: skuCode,
      comunaKey: comunaKey,
    );
    final result = await _createEscrowJob(
      userId: userId,
      workerId: workerId,
      serviceId: serviceId,
      address: address,
      description: description,
      scheduledDate: scheduledDate,
      comunaKey: comunaKey,
      latitude: latitude,
      longitude: longitude,
      pricingMode: PricingConstants.modeFixedPrice,
      quote: quote,
      serviceSkuId: skuCode,
      serviceMetadata: serviceMetadata,
    );
    return result;
  }

  /// Bloque de horas prepagado (2, 4 u 8 h).
  Future<({JobModel job, PriceQuote quote})> createHourlyBlockBooking({
    required String userId,
    required String workerId,
    required String serviceId,
    required String address,
    required int hourlyRateClp,
    required int blockHours,
    String? description,
    DateTime? scheduledDate,
    String? comunaKey,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? serviceMetadata,
  }) async {
    final quote = await PricingService.instance.calculateHourlyBlock(
      hourlyRateClp: hourlyRateClp,
      blockHours: blockHours,
      comunaKey: comunaKey,
    );
    final result = await _createEscrowJob(
      userId: userId,
      workerId: workerId,
      serviceId: serviceId,
      address: address,
      description: description,
      scheduledDate: scheduledDate,
      comunaKey: comunaKey,
      latitude: latitude,
      longitude: longitude,
      pricingMode: PricingConstants.modeHourlyBlock,
      quote: quote,
      hourlyBlockHours: blockHours,
      serviceMetadata: serviceMetadata,
    );
    return result;
  }

  /// Cotización abierta: el cliente elige un profesional y este envía su propuesta.
  Future<JobModel> createOpenQuoteJob({
    required String userId,
    required String invitedWorkerId,
    required String serviceId,
    required String address,
    required String description,
    DateTime? scheduledDate,
    String? comunaKey,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? serviceMetadata,
  }) async {
    final meta = <String, dynamic>{
      if (serviceMetadata != null) ...serviceMetadata,
      'invited_worker_id': invitedWorkerId,
    };
    final now = DateTime.now();
    final job = JobModel(
      id: const Uuid().v4(),
      userId: userId,
      workerId: invitedWorkerId,
      serviceId: serviceId,
      status: PricingConstants.jobAwaitingQuotes,
      address: address,
      description: description,
      latitude: latitude,
      longitude: longitude,
      scheduledDate: scheduledDate,
      serviceMetadata: meta.isEmpty ? null : meta,
      pricingMode: PricingConstants.modeOpenQuote,
      paymentStatus: PricingConstants.paymentNone,
      comunaId: comunaKey,
      createdAt: now,
      updatedAt: now,
    );
    await _jobs.createJob(job);
    AppLogger.i('Solicitud open_quote: ${job.id}');
    return job;
  }

  Future<({JobModel job, PriceQuote quote})> _createEscrowJob({
    required String userId,
    required String workerId,
    required String serviceId,
    required String address,
    required String pricingMode,
    required PriceQuote quote,
    String? description,
    DateTime? scheduledDate,
    String? comunaKey,
    double? latitude,
    double? longitude,
    String? serviceSkuId,
    int? hourlyBlockHours,
    Map<String, dynamic>? serviceMetadata,
  }) async {
    final now = DateTime.now();
    final job = JobModel(
      id: const Uuid().v4(),
      userId: userId,
      workerId: workerId,
      serviceId: serviceId,
      status: PricingConstants.jobAwaitingPayment,
      address: address,
      description: description,
      latitude: latitude,
      longitude: longitude,
      scheduledDate: scheduledDate,
      serviceMetadata: serviceMetadata,
      pricingMode: pricingMode,
      paymentStatus: PricingConstants.paymentNone,
      comunaId: comunaKey,
      pricingSnapshot: quote.toJson(),
      serviceSkuId: serviceSkuId,
      hourlyBlockHours: hourlyBlockHours,
      createdAt: now,
      updatedAt: now,
    );
    await _jobs.createJob(job);
    AppLogger.i('Job escrow $pricingMode: ${job.id}');
    return (job: job, quote: quote);
  }

  /// Tras checkout mock: escrow autorizado → trabajo aceptado.
  Future<JobModel> confirmEscrowAndAccept({
    required String jobId,
    required String userId,
  }) async {
    final job = await _jobs.getJobById(jobId);
    if (job == null) throw AppError.notFound('Trabajo no encontrado');
    if (job.userId != userId) throw AppError.permission('Sin permiso');

    if (job.status != PricingConstants.jobAwaitingPayment) {
      throw AppError.validation('El trabajo no está pendiente de pago');
    }

    return _stateMachine.transitionTo(
      jobId: jobId,
      newStatus: AppConstants.jobStatusAccepted,
      userId: userId,
    );
  }
}

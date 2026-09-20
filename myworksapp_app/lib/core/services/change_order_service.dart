import 'package:uuid/uuid.dart';

import '../database/models/change_order_model.dart';
import '../database/repositories/change_order_repository.dart';
import '../database/repositories/job_repository.dart';
import '../domain/pricing_constants.dart';
import '../domain/price_quote.dart';
import '../utils/app_error.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import 'job_state_machine.dart';

/// Órdenes de cambio (cobros adicionales durante el trabajo).
class ChangeOrderService {
  ChangeOrderService._();
  static final ChangeOrderService instance = ChangeOrderService._();

  final ChangeOrderRepository _repository = ChangeOrderRepository();
  final JobRepository _jobRepository = JobRepository();
  final JobStateMachine _stateMachine = JobStateMachine.instance;

  Future<ChangeOrderModel> submit({
    required String jobId,
    required String workerId,
    required String titulo,
    required String descripcion,
    required int montoClp,
    String tipo = 'extra_work',
  }) async {
    final job = await _jobRepository.getJobById(jobId);
    if (job == null) throw AppError.notFound('Trabajo no encontrado');
    if (job.workerId != workerId) {
      throw AppError.permission('Solo el trabajador asignado puede solicitar cobros extra');
    }
    if (job.status != AppConstants.jobStatusInProgress) {
      throw AppError.validation('Solo se pueden enviar órdenes de cambio con el trabajo en curso');
    }

    final order = ChangeOrderModel(
      id: const Uuid().v4(),
      jobId: jobId,
      workerId: workerId,
      tipo: tipo,
      titulo: titulo,
      descripcion: descripcion,
      montoClp: montoClp,
      estado: PricingConstants.changeOrderPending,
      createdAt: DateTime.now(),
    );

    await _repository.create(order);

    await _stateMachine.transitionTo(
      jobId: jobId,
      newStatus: PricingConstants.jobPausedChangeOrder,
      userId: workerId,
    );

    AppLogger.i('Change order creada: ${order.id}');
    return order;
  }

  Future<void> approveAndPay({
    required ChangeOrderModel order,
    required String clientUserId,
    String? paymentMethod,
  }) async {
    final job = await _jobRepository.getJobById(order.jobId);
    if (job == null) throw AppError.notFound('Trabajo no encontrado');
    if (job.userId != clientUserId) {
      throw AppError.permission('Solo el cliente puede aprobar');
    }
    if (!order.isPendingClient) {
      throw AppError.validation('La orden de cambio ya fue respondida');
    }

    final quote = PriceQuote(
      pricingMode: PricingConstants.modeFixedPrice,
      subtotalClp: order.montoClp,
      platformFeeClp: (order.montoClp * 0.08).round(),
      totalClp: order.montoClp + (order.montoClp * 0.08).round(),
      breakdown: {'change_order_id': order.id},
    );

    // Pago adicional solo por Webpay (Edge). La UI debe abrir TransbankWebpayGateway.
    throw AppError.validation(
      'Para pagar la orden de cambio (\$${quote.totalClp} CLP) usa Webpay. '
      'El cobro local/mock está deshabilitado.',
    );
  }

  Future<void> reject({
    required ChangeOrderModel order,
    required String clientUserId,
  }) async {
    final job = await _jobRepository.getJobById(order.jobId);
    if (job == null) throw AppError.notFound('Trabajo no encontrado');
    if (job.userId != clientUserId) throw AppError.permission('Sin permiso');

    await _repository.update(ChangeOrderModel(
      id: order.id,
      jobId: order.jobId,
      workerId: order.workerId,
      tipo: order.tipo,
      titulo: order.titulo,
      descripcion: order.descripcion,
      montoClp: order.montoClp,
      estado: PricingConstants.changeOrderRejected,
      paymentId: order.paymentId,
      createdAt: order.createdAt,
      respondedAt: DateTime.now(),
    ));

    if (job.status == PricingConstants.jobPausedChangeOrder) {
      await _stateMachine.transitionTo(
        jobId: job.id,
        newStatus: AppConstants.jobStatusInProgress,
        userId: clientUserId,
      );
    }
  }
}

import 'package:uuid/uuid.dart';

import '../database/models/job_model.dart';
import '../database/models/quote_proposal_model.dart';
import '../database/repositories/job_repository.dart';
import '../database/repositories/quote_proposal_repository.dart';
import '../domain/pricing_constants.dart';
import '../utils/app_error.dart';
import '../utils/app_logger.dart';
import 'job_state_machine.dart';
import 'notification_service.dart';
import 'pricing_service.dart';
import '../utils/open_quote_utils.dart';

/// Cotizaciones abiertas (modalidad open_quote).
class QuoteProposalService {
  QuoteProposalService._();
  static final QuoteProposalService instance = QuoteProposalService._();

  final QuoteProposalRepository _proposals = QuoteProposalRepository();
  final JobRepository _jobs = JobRepository();
  final JobStateMachine _stateMachine = JobStateMachine.instance;

  Future<List<QuoteProposalModel>> listForJob(String jobId) =>
      _proposals.getByJobId(jobId);

  /// Trabajador envía propuesta mientras el job está en `awaiting_quotes`.
  Future<QuoteProposalModel> submit({
    required String jobId,
    required String workerId,
    required int montoTotalClp,
    required String descripcion,
    int validezDias = 7,
    int? materialesClp,
    int? manoObraClp,
    int? horasEstimadas,
  }) async {
    final job = await _jobs.getJobById(jobId);
    if (job == null) throw AppError.notFound('Trabajo no encontrado');
    if (job.pricingMode != PricingConstants.modeOpenQuote) {
      throw AppError.validation('Este trabajo no acepta cotizaciones abiertas');
    }
    if (job.status != PricingConstants.jobAwaitingQuotes) {
      throw AppError.validation('El plazo de cotización ya cerró');
    }
    if (!OpenQuoteUtils.canWorkerSubmitQuote(job, workerId)) {
      throw AppError.permission(
        'Esta solicitud fue enviada a otro profesional',
      );
    }
    if (montoTotalClp < 5000) {
      throw AppError.validation('El monto mínimo es \$5.000');
    }

    final existing = await _proposals.getByJobId(jobId);
    if (existing.any((p) =>
        p.workerId == workerId && p.estado == PricingConstants.quoteSubmitted)) {
      throw AppError.validation('Ya enviaste una cotización activa para este trabajo');
    }

    final desglose = <String, dynamic>{
      if (materialesClp != null) 'materiales_clp': materialesClp,
      if (manoObraClp != null) 'mano_obra_clp': manoObraClp,
      if (horasEstimadas != null) 'horas_estimadas': horasEstimadas,
    };

    final proposal = QuoteProposalModel(
      id: const Uuid().v4(),
      jobId: jobId,
      workerId: workerId,
      montoTotalClp: montoTotalClp,
      descripcion: _buildProposalDescription(
        descripcion.trim(),
        desglose,
        montoTotalClp,
      ),
      validezHasta: DateTime.now().add(Duration(days: validezDias)),
      desglose: desglose.isEmpty ? null : desglose,
      estado: PricingConstants.quoteSubmitted,
      createdAt: DateTime.now(),
    );

    await _proposals.create(proposal);

    await NotificationService.instance.showNotification(
      title: 'Llegó una cotización',
      body:
          'Un profesional respondió tu solicitud. Revisa el desglose de materiales y mano de obra, y acepta el precio si te convence.',
      userId: job.userId,
      type: 'quote_received',
      relatedId: jobId,
    );

    AppLogger.i('Cotización enviada: ${proposal.id}');
    return proposal;
  }

  String _buildProposalDescription(
    String detalle,
    Map<String, dynamic> desglose,
    int total,
  ) {
    final buffer = StringBuffer();
    if (detalle.isNotEmpty) buffer.writeln(detalle);
    if (desglose.isNotEmpty) {
      buffer.writeln('\n--- Desglose ---');
      final mat = desglose['materiales_clp'];
      final mo = desglose['mano_obra_clp'];
      final hrs = desglose['horas_estimadas'];
      if (mat != null) buffer.writeln('Materiales: \$$mat');
      if (mo != null) buffer.writeln('Mano de obra: \$$mo');
      if (hrs != null) buffer.writeln('Tiempo estimado: $hrs h');
      buffer.writeln('Total propuesto: \$$total');
    }
    return buffer.toString().trim();
  }

  /// Cliente elige una propuesta → `awaiting_payment` con snapshot.
  Future<JobModel> selectProposal({
    required String jobId,
    required String proposalId,
    required String clientUserId,
  }) async {
    final job = await _jobs.getJobById(jobId);
    if (job == null) throw AppError.notFound('Trabajo no encontrado');
    if (job.userId != clientUserId) throw AppError.permission('Sin permiso');
    if (job.status != PricingConstants.jobAwaitingQuotes) {
      throw AppError.validation('No hay cotizaciones pendientes de elegir');
    }

    final proposal = await _proposals.getById(proposalId);
    if (proposal == null || proposal.jobId != jobId) {
      throw AppError.notFound('Cotización no encontrada');
    }
    if (proposal.estado != PricingConstants.quoteSubmitted) {
      throw AppError.validation('Esta cotización ya no está disponible');
    }

    await _rejectOtherProposals(jobId, proposalId);

    final quote = PricingService.instance.quoteFromOpenProposal(
      proposalAmountClp: proposal.montoTotalClp,
    );

    var updated = await _stateMachine.transitionTo(
      jobId: jobId,
      newStatus: PricingConstants.jobQuoteSelected,
      userId: clientUserId,
    );

    updated = updated.copyWith(
      workerId: proposal.workerId,
      selectedQuoteId: proposal.id,
      pricingSnapshot: quote.toJson(),
      updatedAt: DateTime.now(),
    );
    await _jobs.updateJob(updated);

    await _proposals.update(QuoteProposalModel(
      id: proposal.id,
      jobId: proposal.jobId,
      workerId: proposal.workerId,
      montoTotalClp: proposal.montoTotalClp,
      descripcion: proposal.descripcion,
      validezHasta: proposal.validezHasta,
      desglose: proposal.desglose,
      estado: PricingConstants.quoteAccepted,
      createdAt: proposal.createdAt,
    ));

    return _stateMachine.transitionTo(
      jobId: jobId,
      newStatus: PricingConstants.jobAwaitingPayment,
      userId: clientUserId,
    );
  }

  Future<void> withdraw({
    required String proposalId,
    required String workerId,
  }) async {
    final proposal = await _proposals.getById(proposalId);
    if (proposal == null) throw AppError.notFound('Cotización no encontrada');
    if (proposal.workerId != workerId) throw AppError.permission('Sin permiso');
    if (proposal.estado != PricingConstants.quoteSubmitted) {
      throw AppError.validation('No se puede retirar esta cotización');
    }

    await _proposals.update(QuoteProposalModel(
      id: proposal.id,
      jobId: proposal.jobId,
      workerId: proposal.workerId,
      montoTotalClp: proposal.montoTotalClp,
      descripcion: proposal.descripcion,
      validezHasta: proposal.validezHasta,
      desglose: proposal.desglose,
      estado: PricingConstants.quoteWithdrawn,
      createdAt: proposal.createdAt,
    ));
  }

  Future<void> _rejectOtherProposals(String jobId, String acceptedId) async {
    final all = await _proposals.getByJobId(jobId);
    for (final p in all) {
      if (p.id == acceptedId || p.estado != PricingConstants.quoteSubmitted) continue;
      await _proposals.update(QuoteProposalModel(
        id: p.id,
        jobId: p.jobId,
        workerId: p.workerId,
        montoTotalClp: p.montoTotalClp,
        descripcion: p.descripcion,
        validezHasta: p.validezHasta,
        desglose: p.desglose,
        estado: PricingConstants.quoteRejected,
        createdAt: p.createdAt,
      ));
    }
  }
}

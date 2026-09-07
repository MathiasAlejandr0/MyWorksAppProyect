// El State pasa isMounted()/getContext(); el analyzer no reconoce ese guard.
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/models/change_order_model.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/models/quote_proposal_model.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/database/repositories/job_photo_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/services/change_order_service.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/services/job_booking_service.dart';
import '../../../../core/services/job_state_machine.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/services/quote_proposal_service.dart';
import '../../../../core/services/worker_job_rejection_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/open_quote_utils.dart';
import '../../../../core/widgets/escrow_checkout_sheet.dart';
import '../../../user/presentation/widgets/worker_unavailable_dialog.dart';
import '../utils/job_detail_helpers.dart';
import '../widgets/worker_quote_form_dialog.dart';

/// Lógica de negocio de acciones del detalle de trabajo.
///
/// La page aporta dependencias y callbacks (reload, snackbars, navegación);
/// este controller no conoce el State privado.
class JobDetailController {
  JobDetailController({
    required this.jobId,
    required this.getJob,
    required this.getUser,
    required this.isMounted,
    required this.getContext,
    required this.onReload,
    required this.onLoadAddress,
    required this.onLoadQuoteProposals,
    required this.onRequestWorkerHomeRefresh,
    required this.onRejectionDialogShown,
    JobRepository? jobRepository,
    UserRepository? userRepository,
    JobPhotoRepository? jobPhotoRepository,
    WorkerRepository? workerRepository,
    JobStateMachine? stateMachine,
  })  : _jobRepository = jobRepository ?? JobRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _jobPhotoRepository = jobPhotoRepository ?? JobPhotoRepository(),
        _workerRepository = workerRepository ?? WorkerRepository(),
        _stateMachine = stateMachine ?? JobStateMachine.instance;

  final String jobId;
  final JobModel? Function() getJob;
  final UserModel? Function() getUser;
  final bool Function() isMounted;
  final BuildContext Function() getContext;
  final Future<void> Function() onReload;
  final void Function(JobModel job) onLoadAddress;
  final Future<void> Function(String jobId) onLoadQuoteProposals;
  final void Function({int? openTabIndex}) onRequestWorkerHomeRefresh;
  final VoidCallback onRejectionDialogShown;

  final JobRepository _jobRepository;
  final UserRepository _userRepository;
  final JobPhotoRepository _jobPhotoRepository;
  final WorkerRepository _workerRepository;
  final JobStateMachine _stateMachine;

  BuildContext get _context => getContext();

  void _snack(String message, {Color? backgroundColor}) {
    if (!isMounted()) return;
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> maybeShowRejectionDialog(
    JobModel job, {
    required bool alreadyShown,
  }) async {
    if (alreadyShown || !isMounted()) return;

    final user = getUser();
    if (user == null || user.id != job.userId) return;
    if (job.status != AppConstants.jobStatusCancelled) return;
    if (job.serviceMetadata?['rejection_reason'] != 'worker_unavailable') {
      return;
    }

    onRejectionDialogShown();
    final rejectedWorkerId =
        job.serviceMetadata?['rejected_by_worker_id'] as String?;
    final rejectedUser = rejectedWorkerId != null
        ? await _userRepository.getUserById(rejectedWorkerId)
        : null;
    final alternatives =
        await WorkerJobRejectionService.instance.alternativesForJob(job);

    if (!isMounted()) return;
    await WorkerUnavailableDialog.show(
      _context,
      workerName: rejectedUser?.name ?? 'El profesional',
      alternatives: alternatives,
      serviceId: job.serviceId,
    );
  }

  Future<void> openDispute(String reason, String? description) async {
    final user = getUser();
    final job = getJob();
    if (user == null || job == null) return;

    try {
      await DisputeService.instance.openDispute(
        jobId: job.id,
        openedBy: user.id,
        reason: reason,
        description: description,
      );

      final notifyUserId =
          user.id == job.userId ? job.workerId : job.userId;
      if (notifyUserId != null) {
        await NotificationService.instance.showNotification(
          title: 'Disputa abierta',
          body: 'Se abrió una disputa en el trabajo. Revisa los detalles.',
          userId: notifyUserId,
          type: 'dispute_opened',
          relatedId: job.id,
        );
      }

      await onReload();
      _snack('Disputa registrada');
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    }
  }

  Future<void> submitQuoteProposal() async {
    final job = getJob();
    final user = getUser();
    if (job == null || user == null) return;

    if (!OpenQuoteUtils.canWorkerSubmitQuote(job, user.id)) {
      _snack(
        'Esta solicitud fue enviada a otro profesional',
        backgroundColor: AppColors.error,
      );
      return;
    }

    final form = await WorkerQuoteFormDialog.show(_context);
    if (form == null || !isMounted()) return;

    try {
      await QuoteProposalService.instance.submit(
        jobId: job.id,
        workerId: user.id,
        montoTotalClp: form.montoTotalClp,
        descripcion: form.descripcion,
        materialesClp: form.materialesClp,
        manoObraClp: form.manoObraClp,
        horasEstimadas: form.horasEstimadas,
      );
      await onLoadQuoteProposals(job.id);
      _snack(
        'Propuesta enviada. El cliente fue notificado y podrá aceptar el precio.',
      );
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    }
  }

  Future<void> selectQuoteProposal(QuoteProposalModel proposal) async {
    final user = getUser();
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: _context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Aceptas esta cotización?'),
        content: Text(
          'Al aceptar, confirmas el precio total de \$${proposal.montoTotalClp} propuesto por el profesional.\n\n'
          'Después deberás completar el pago en garantía (demo) para reservar el trabajo.\n\n'
          '${proposal.descripcion}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Rechazar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aceptar precio'),
          ),
        ],
      ),
    );

    if (confirm != true || !isMounted()) return;

    try {
      await QuoteProposalService.instance.selectProposal(
        jobId: jobId,
        proposalId: proposal.id,
        clientUserId: user.id,
      );
      await onReload();
      _snack(
        'Cotización aceptada. Usa el botón de pago para confirmar en garantía.',
      );
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    }
  }

  Future<void> requestOvertimeHours() async {
    final job = getJob();
    final user = getUser();
    if (job == null || user == null || job.workerId != user.id) return;

    final worker = await _workerRepository.getWorkerByUserId(user.id);
    if (worker == null) return;
    if (!isMounted()) return;

    final hoursCtrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: _context,
      builder: (ctx) => AlertDialog(
        title: const Text('Horas extra'),
        content: TextField(
          controller: hoursCtrl,
          decoration: const InputDecoration(
            labelText: 'Horas adicionales (1-8)',
            helperText: 'Fuera del bloque ya pagado por el cliente',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );

    final extra = int.tryParse(hoursCtrl.text.trim());
    hoursCtrl.dispose();
    if (ok != true || !isMounted() || extra == null) return;

    try {
      final rate = PricingService.instance
          .estimateHourlyRateFromVisitFee(worker.visitFee.round());
      final quote = PricingService.instance.calculateHourlyOvertime(
        hourlyRateClp: rate,
        extraHours: extra,
        comunaKey: job.comunaId,
      );
      await ChangeOrderService.instance.submit(
        jobId: job.id,
        workerId: user.id,
        titulo: 'Horas extra ($extra h)',
        descripcion: quote.message ?? 'Horas adicionales',
        montoClp: quote.subtotalClp,
        tipo: 'overtime',
      );
      await onReload();
      _snack('Solicitud de horas extra enviada');
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    }
  }

  void goToDashboard() {
    final user = getUser();
    if (user == null) return;
    if (user.role == AppConstants.roleWorker) {
      onRequestWorkerHomeRefresh();
      _context.go(AppConstants.routeWorkerHome);
      return;
    }
    _context.go(AppConstants.routeUserHome);
  }

  Future<void> payEscrow() async {
    final job = getJob();
    final auth = getUser();
    if (job == null || auth == null) return;

    final quote = JobDetailHelpers.quoteFromJob(job);
    if (quote == null) {
      _snack('No hay cotización para este trabajo');
      return;
    }

    final paid = await EscrowCheckoutSheet.show(
      _context,
      jobId: job.id,
      quote: quote,
    );

    if (!paid || !isMounted()) return;

    try {
      await JobBookingService.instance.confirmEscrowAndAccept(
        jobId: job.id,
        userId: auth.id,
      );
      await onReload();
      _snack('Pago confirmado y en garantía.');
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    }
  }

  Future<void> approveCompletion() async {
    final job = getJob();
    final auth = getUser();
    if (job == null || auth == null) return;

    final quote = JobDetailHelpers.quoteFromJob(job);
    if (quote == null) {
      _snack('No hay monto definido para este trabajo');
      return;
    }

    final confirm = await showDialog<bool>(
      context: _context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar finalización'),
        content: const Text(
          'Al aprobar confirmas que el trabajo fue realizado correctamente y procederás al pago.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar al pago'),
          ),
        ],
      ),
    );
    if (confirm != true || !isMounted()) return;

    final paid = await EscrowCheckoutSheet.show(
      _context,
      jobId: job.id,
      quote: quote,
    );
    if (!paid || !isMounted()) return;

    try {
      await JobBookingService.instance.confirmCompletionAndPay(
        jobId: job.id,
        userId: auth.id,
      );

      if (job.workerId != null) {
        onRequestWorkerHomeRefresh();
        await NotificationService.instance.showNotification(
          title: 'Pago confirmado',
          body:
              'El cliente aprobó tu trabajo. Activa tu disponibilidad cuando quieras recibir nuevos trabajos.',
          userId: job.workerId!,
          type: 'job_completion_approved',
          relatedId: job.id,
        );
      }

      await onReload();
      if (!isMounted()) return;
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(content: Text('Trabajo aprobado y pago realizado.')),
      );
      _context.push('${AppConstants.routeRating}/$jobId');
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    }
  }

  Future<void> rejectCompletion() async {
    final job = getJob();
    final auth = getUser();
    if (job == null || auth == null) return;

    final confirm = await showDialog<bool>(
      context: _context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar finalización'),
        content: const Text(
          'El trabajo volverá a estado "En curso" para que el profesional pueda corregir o subir nueva evidencia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _stateMachine.transitionTo(
        jobId: jobId,
        newStatus: AppConstants.jobStatusInProgress,
        userId: auth.id,
      );

      if (job.workerId != null) {
        await NotificationService.instance.showNotification(
          title: 'Finalización rechazada',
          body:
              'El cliente solicitó revisar el trabajo. Sube nueva evidencia cuando esté listo.',
          userId: job.workerId!,
          type: 'job_completion_rejected',
          relatedId: job.id,
        );
      }

      await onReload();
      _snack('Finalización rechazada. El trabajo sigue en curso.');
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    }
  }

  Future<void> requestChangeOrder() async {
    final job = getJob();
    final user = getUser();
    if (job == null || user == null) return;

    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final montoCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: _context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solicitar cobro adicional'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              TextField(
                controller: montoCtrl,
                decoration: const InputDecoration(labelText: 'Monto (CLP)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    final titulo = tituloCtrl.text.trim();
    final descripcion = descCtrl.text.trim();
    final monto = int.tryParse(montoCtrl.text.trim());
    tituloCtrl.dispose();
    descCtrl.dispose();
    montoCtrl.dispose();

    if (ok != true || !isMounted()) return;

    if (titulo.isEmpty || monto == null || monto < 1000) {
      _snack('Completa título y monto válido (mín. 1000 CLP)');
      return;
    }

    try {
      await ChangeOrderService.instance.submit(
        jobId: job.id,
        workerId: user.id,
        titulo: titulo,
        descripcion: descripcion.isEmpty ? titulo : descripcion,
        montoClp: monto,
      );
      await onReload();
      _snack('Cobro adicional enviado al cliente');
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    }
  }

  Future<void> approveChangeOrder(ChangeOrderModel order) async {
    final user = getUser();
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: _context,
      builder: (ctx) => AlertDialog(
        title: Text(order.titulo),
        content: Text(
          '${order.descripcion}\n\nMonto: \$${order.montoClp}\n\nSe autorizará el cobro adicional (demo).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Rechazar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aprobar y pagar'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      await ChangeOrderService.instance
          .reject(order: order, clientUserId: user.id);
      await onReload();
      return;
    }

    try {
      await ChangeOrderService.instance.approveAndPay(
        order: order,
        clientUserId: user.id,
      );
      await onReload();
      _snack('Cobro adicional aprobado');
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    }
  }

  Future<void> updateJobStatus(String newStatus) async {
    try {
      final user = getUser();
      final job = getJob();
      if (user == null || job == null) return;

      if (!_stateMachine.isValidTransition(
        job.status,
        newStatus,
        pricingMode: job.pricingMode,
      )) {
        _snack(
          'No se puede cambiar el estado de ${job.status} a $newStatus',
          backgroundColor: AppColors.error,
        );
        return;
      }

      await _stateMachine.transitionTo(
        jobId: jobId,
        newStatus: newStatus,
        userId: user.id,
      );

      await onReload();

      final updated = getJob();
      if (updated != null) {
        final otherUserId =
            user.id == updated.userId ? updated.workerId : updated.userId;
        if (otherUserId != null) {
          String title = '';
          String body = '';

          switch (newStatus) {
            case AppConstants.jobStatusAccepted:
              title = 'Trabajo Aceptado';
              body = 'Tu solicitud ha sido aceptada por el trabajador';
              break;
            case AppConstants.jobStatusInProgress:
              title = 'Trabajo Iniciado';
              body = 'El trabajador ha iniciado el trabajo';
              break;
            case AppConstants.jobStatusCompleted:
              title = 'Trabajo Completado';
              body = 'El trabajo ha sido finalizado. ¡Califica al trabajador!';
              break;
            case AppConstants.jobStatusCancelled:
              title = 'Trabajo Cancelado';
              body = 'El trabajo ha sido cancelado';
              break;
          }

          if (title.isNotEmpty) {
            await NotificationService.instance.showNotification(
              title: title,
              body: body,
              userId: otherUserId,
              type: 'job_$newStatus',
              relatedId: jobId,
            );
          }
        }
      }

      _snack('Estado actualizado');
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    } catch (e) {
      _snack('Error: ${e.toString()}', backgroundColor: AppColors.error);
    }
  }

  Future<void> acceptJob() async {
    final user = getUser();
    final job = getJob();
    if (user == null || job == null) return;

    if (!_stateMachine.isValidTransition(
      job.status,
      AppConstants.jobStatusAccepted,
      pricingMode: job.pricingMode,
    )) {
      _snack(
        'No se puede aceptar un trabajo en estado: ${job.status}',
        backgroundColor: AppColors.error,
      );
      return;
    }

    final hasActiveJobs = await _jobRepository.hasActiveJobs(user.id);
    if (hasActiveJobs) {
      _snack(
        'No puedes aceptar más trabajos. Completa o cancela tus trabajos actuales primero.',
        backgroundColor: AppColors.warning,
      );
      return;
    }

    try {
      await _stateMachine.transitionTo(
        jobId: jobId,
        newStatus: AppConstants.jobStatusAccepted,
        userId: user.id,
      );

      await _jobRepository.assignWorker(job.id, user.id);

      final WorkerRepository workerRepository = WorkerRepository();
      await workerRepository.updateAvailability(user.id, false);
      await workerRepository.enforceUnavailableWhileBusy(user.id);

      await onReload();

      final reloaded = getJob();
      if (reloaded != null) {
        onLoadAddress(reloaded);
      }

      await NotificationService.instance.showNotification(
        title: 'Trabajo Aceptado',
        body: 'Tu solicitud ha sido aceptada por ${user.name}',
        userId: (reloaded ?? job).userId,
        type: 'job_accepted',
        relatedId: jobId,
      );

      onRequestWorkerHomeRefresh(openTabIndex: 1);

      if (!isMounted()) return;
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(
          content: Text(
            'Trabajo aceptado. Revisa los detalles en la pestaña En curso.',
          ),
        ),
      );
      _context.go(AppConstants.routeWorkerHome);
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    } catch (e) {
      _snack('Error: ${e.toString()}', backgroundColor: AppColors.error);
    }
  }

  Future<void> completeJob() async {
    final job = getJob();
    if (job == null) return;

    final targetStatus = JobDetailHelpers.completionTargetStatus(job);

    if (!_stateMachine.isValidTransition(
      job.status,
      targetStatus,
      pricingMode: job.pricingMode,
    )) {
      _snack(
        'No se puede finalizar un trabajo en estado: ${job.status}',
        backgroundColor: AppColors.error,
      );
      return;
    }

    final evidenceCount =
        await _jobPhotoRepository.getEvidenceCountByJobId(jobId);

    if (evidenceCount == 0) {
      if (!isMounted()) return;
      final confirm = await showDialog<bool>(
        context: _context,
        builder: (context) => AlertDialog(
          title: const Text('Evidencia requerida'),
          content: const Text(
            'Debes subir al menos una foto o un video del trabajo antes de finalizarlo. ¿Quieres subir evidencia ahora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
                _context.push('${AppConstants.routeJobPhotos}/$jobId');
              },
              child: const Text('Subir evidencia'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      return;
    }

    try {
      final user = getUser();
      if (user == null) return;

      await _stateMachine.transitionTo(
        jobId: jobId,
        newStatus: targetStatus,
        userId: user.id,
      );

      if (targetStatus == PricingConstants.jobAwaitingClientApproval) {
        await NotificationService.instance.showNotification(
          title: 'Trabajo finalizado',
          body:
              'El profesional subió evidencia. Revisa y aprueba para completar el pago.',
          userId: job.userId,
          type: 'job_completion_review',
          relatedId: jobId,
        );
      }

      await onReload();

      if (targetStatus == AppConstants.jobStatusCompleted) {
        if (user.role == AppConstants.roleWorker) {
          onRequestWorkerHomeRefresh();
          _snack(
            'Trabajo finalizado. Activa tu disponibilidad cuando quieras recibir nuevos trabajos.',
          );
        }
        if (user.role == AppConstants.roleUser) {
          if (!isMounted()) return;
          _context.push('${AppConstants.routeRating}/$jobId');
        }
      } else if (!isMounted()) {
        return;
      } else {
        onRequestWorkerHomeRefresh();
        ScaffoldMessenger.of(_context).showSnackBar(
          const SnackBar(
            content: Text(
              'Evidencia enviada. Cuando el cliente apruebe podrás activar tu disponibilidad.',
            ),
          ),
        );
      }
    } on AppError catch (e) {
      _snack(e.message, backgroundColor: AppColors.error);
    } catch (e) {
      _snack('Error: ${e.toString()}', backgroundColor: AppColors.error);
    }
  }

  Future<void> cancelJob() async {
    final job = getJob();
    if (job == null) return;

    if (!_stateMachine.isValidTransition(
      job.status,
      AppConstants.jobStatusCancelled,
      pricingMode: job.pricingMode,
    )) {
      _snack(
        'No se puede cancelar un trabajo en estado: ${job.status}',
        backgroundColor: AppColors.error,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: _context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Solicitud'),
        content: const Text(
          '¿Estás seguro de que quieres cancelar esta solicitud?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = getUser();
        if (user == null) return;

        await _stateMachine.transitionTo(
          jobId: jobId,
          newStatus: AppConstants.jobStatusCancelled,
          userId: user.id,
        );

        await onReload();
        if (!isMounted()) return;
        Navigator.pop(_context);
      } on AppError catch (e) {
        _snack(e.message, backgroundColor: AppColors.error);
      } catch (e) {
        _snack('Error: ${e.toString()}', backgroundColor: AppColors.error);
      }
    }
  }

  Future<void> rejectJob() async {
    final confirm = await showDialog<bool>(
      context: _context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Trabajo'),
        content: const Text(
          '¿Estás seguro de que quieres rechazar este trabajo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sí, rechazar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = getUser();
      final job = getJob();
      if (user == null || job == null) return;

      final isTierInvitation =
          job.serviceMetadata?['request_type'] == 'worker_tier_invitation';

      if (isTierInvitation) {
        try {
          await WorkerJobRejectionService.instance.rejectAndSuggestAlternatives(
            jobId: jobId,
            workerId: user.id,
          );
          onRequestWorkerHomeRefresh();
          if (!isMounted()) return;
          ScaffoldMessenger.of(_context).showSnackBar(
            const SnackBar(content: Text('Solicitud rechazada correctamente')),
          );
          _context.go(AppConstants.routeWorkerHome);
        } on AppError catch (e) {
          _snack(e.message, backgroundColor: AppColors.error);
        }
        return;
      }

      await updateJobStatus(AppConstants.jobStatusCancelled);
      onRequestWorkerHomeRefresh();
      if (!isMounted()) return;
      Navigator.pop(_context);
    }
  }
}

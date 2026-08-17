import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/database/models/change_order_model.dart';
import '../../../../core/database/models/dispute_model.dart';
import '../../../../core/database/models/quote_proposal_model.dart';
import '../../../../core/database/repositories/change_order_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/job_state_machine.dart';
import '../../../../core/services/job_booking_service.dart';
import '../../../../core/services/change_order_service.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/services/quote_proposal_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../widgets/quote_proposals_section.dart';
import '../widgets/open_quote_status_banner.dart';
import '../widgets/worker_quote_form_dialog.dart';
import '../../../../core/utils/open_quote_utils.dart';
import '../../../../core/widgets/escrow_checkout_sheet.dart';
import '../../../../core/widgets/pricing_quote_card.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/database/repositories/job_photo_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../worker/presentation/providers/worker_home_refresh_provider.dart';
import '../../../../core/services/worker_job_rejection_service.dart';
import '../../../user/presentation/widgets/worker_unavailable_dialog.dart';
import '../widgets/job_accepted_location_card.dart';
import '../widgets/job_location_preview_section.dart';
import '../widgets/change_orders_section.dart';
import '../widgets/dispute_section.dart';
import '../utils/job_detail_helpers.dart';
import '../widgets/job_detail_status_header.dart';
import '../widgets/job_detail_client_approval_card.dart';
import '../widgets/job_detail_actions_section.dart';

class JobDetailPage extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  final JobRepository _jobRepository = JobRepository();
  final UserRepository _userRepository = UserRepository();
  final JobPhotoRepository _jobPhotoRepository = JobPhotoRepository();
  final JobStateMachine _stateMachine = JobStateMachine.instance;
  final ChangeOrderRepository _changeOrderRepository = ChangeOrderRepository();

  JobModel? _job;
  List<ChangeOrderModel> _changeOrders = [];
  DisputeModel? _dispute;
  List<QuoteProposalModel> _quoteProposals = [];
  final WorkerRepository _workerRepository = WorkerRepository();
  String? _invitedWorkerName;
  bool _isLoading = true;
  String? _error;
  String _displayAddress = '';
  bool _isLoadingAddress = true;
  
  // Estados de transiciones válidas (cache)
  Map<String, bool> _canTransition = {};
  bool _rejectionDialogShown = false;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final job = await _jobRepository.getJobById(widget.jobId);
      setState(() {
        _job = job;
        _isLoading = false;
      });
      
      if (job != null) {
        _loadAddress(job);
        _loadValidTransitions(job);
        await _loadChangeOrders(job.id);
        await _loadDispute(job.id);
        if (job.pricingMode == PricingConstants.modeOpenQuote) {
          await _loadQuoteProposals(job.id);
          await _loadInvitedWorkerName(job);
        }
        await _maybeShowRejectionDialog(job);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Carga las transiciones válidas para el estado actual del job
  Future<void> _loadValidTransitions(JobModel job) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    final transitions = <String, bool>{};
    
    // Verificar cada transición posible
    final possibleStatuses = [
      PricingConstants.jobAwaitingPayment,
      PricingConstants.jobAwaitingClientApproval,
      AppConstants.jobStatusAccepted,
      AppConstants.jobStatusInProgress,
      AppConstants.jobStatusCompleted,
      AppConstants.jobStatusCancelled,
      PricingConstants.jobPausedChangeOrder,
    ];

    for (final status in possibleStatuses) {
      final canTransition = _stateMachine.isValidTransition(
        job.status,
        status,
        pricingMode: job.pricingMode,
      );
      transitions[status] = canTransition;
    }

    setState(() {
      _canTransition = transitions;
    });
  }

  Future<void> _loadChangeOrders(String jobId) async {
    final orders = await _changeOrderRepository.getByJobId(jobId);
    if (mounted) setState(() => _changeOrders = orders);
  }

  Future<void> _loadDispute(String jobId) async {
    final dispute = await DisputeService.instance.getDisputeByJobId(jobId);
    if (mounted) setState(() => _dispute = dispute);
  }

  bool _canOpenDispute(JobModel job) =>
      JobDetailHelpers.canOpenDispute(job, _dispute);

  Future<void> _openDispute(String reason, String? description) async {
    final user = ref.read(authProvider).user;
    final job = _job;
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

      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disputa registrada')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _loadQuoteProposals(String jobId) async {
    final list = await QuoteProposalService.instance.listForJob(jobId);
    if (mounted) setState(() => _quoteProposals = list);
  }

  Future<void> _maybeShowRejectionDialog(JobModel job) async {
    if (_rejectionDialogShown || !mounted) return;

    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || user.id != job.userId) return;
    if (job.status != AppConstants.jobStatusCancelled) return;
    if (job.serviceMetadata?['rejection_reason'] != 'worker_unavailable') return;

    _rejectionDialogShown = true;
    final rejectedWorkerId = job.serviceMetadata?['rejected_by_worker_id'] as String?;
    final rejectedUser = rejectedWorkerId != null
        ? await _userRepository.getUserById(rejectedWorkerId)
        : null;
    final alternatives =
        await WorkerJobRejectionService.instance.alternativesForJob(job);

    if (!mounted) return;
    await WorkerUnavailableDialog.show(
      context,
      workerName: rejectedUser?.name ?? 'El profesional',
      alternatives: alternatives,
      serviceId: job.serviceId,
    );
  }

  Future<void> _loadInvitedWorkerName(JobModel job) async {
    final invitedId = OpenQuoteUtils.invitedWorkerId(job);
    if (invitedId == null) {
      if (mounted) setState(() => _invitedWorkerName = null);
      return;
    }
    final user = await _userRepository.getUserById(invitedId);
    if (mounted) setState(() => _invitedWorkerName = user?.name);
  }

  Future<void> _submitQuoteProposal() async {
    final job = _job;
    final user = ref.read(authProvider).user;
    if (job == null || user == null) return;

    if (!OpenQuoteUtils.canWorkerSubmitQuote(job, user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta solicitud fue enviada a otro profesional'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final form = await WorkerQuoteFormDialog.show(context);
    if (form == null || !mounted) return;

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
      await _loadQuoteProposals(job.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Propuesta enviada. El cliente fue notificado y podrá aceptar el precio.'),
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _selectQuoteProposal(QuoteProposalModel proposal) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Aceptas esta cotización?'),
        content: Text(
          'Al aceptar, confirmas el precio total de \$${proposal.montoTotalClp} propuesto por el profesional.\n\n'
          'Después deberás completar el pago en garantía (demo) para reservar el trabajo.\n\n'
          '${proposal.descripcion}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Rechazar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aceptar precio')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await QuoteProposalService.instance.selectProposal(
        jobId: widget.jobId,
        proposalId: proposal.id,
        clientUserId: user.id,
      );
      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cotización aceptada. Usa el botón de pago para confirmar en garantía.'),
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _requestOvertimeHours() async {
    final job = _job;
    final user = ref.read(authProvider).user;
    if (job == null || user == null || job.workerId != user.id) return;

    final worker = await _workerRepository.getWorkerByUserId(user.id);
    if (worker == null) return;
    if (!mounted) return;

    final hoursCtrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Solicitar')),
        ],
      ),
    );

    final extra = int.tryParse(hoursCtrl.text.trim());
    hoursCtrl.dispose();
    if (ok != true || !mounted || extra == null) return;

    try {
      final rate =
          PricingService.instance.estimateHourlyRateFromVisitFee(worker.visitFee.round());
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
      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud de horas extra enviada')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  void _goToDashboard() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (user.role == AppConstants.roleWorker) {
      requestWorkerHomeRefresh(ref);
      context.go(AppConstants.routeWorkerHome);
      return;
    }
    context.go(AppConstants.routeUserHome);
  }

  Future<void> _payEscrow() async {
    final job = _job;
    final auth = ref.read(authProvider).user;
    if (job == null || auth == null) return;

    final quote = JobDetailHelpers.quoteFromJob(job);
    if (quote == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cotización para este trabajo')),
      );
      return;
    }

    final paid = await EscrowCheckoutSheet.show(
      context,
      jobId: job.id,
      quote: quote,
    );

    if (!paid || !mounted) return;

    try {
      await JobBookingService.instance.confirmEscrowAndAccept(
        jobId: job.id,
        userId: auth.id,
      );
      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago confirmado y en garantía.')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _approveCompletion() async {
    final job = _job;
    final auth = ref.read(authProvider).user;
    if (job == null || auth == null) return;

    final quote = JobDetailHelpers.quoteFromJob(job);
    if (quote == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay monto definido para este trabajo')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
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
    if (confirm != true || !mounted) return;

    final paid = await EscrowCheckoutSheet.show(
      context,
      jobId: job.id,
      quote: quote,
    );
    if (!paid || !mounted) return;

    try {
      await JobBookingService.instance.confirmCompletionAndPay(
        jobId: job.id,
        userId: auth.id,
      );

      if (job.workerId != null) {
        requestWorkerHomeRefresh(ref);
        await NotificationService.instance.showNotification(
          title: 'Pago confirmado',
          body:
              'El cliente aprobó tu trabajo. Activa tu disponibilidad cuando quieras recibir nuevos trabajos.',
          userId: job.workerId!,
          type: 'job_completion_approved',
          relatedId: job.id,
        );
      }

      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trabajo aprobado y pago realizado.')),
      );
      context.push('${AppConstants.routeRating}/${widget.jobId}');
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _rejectCompletion() async {
    final job = _job;
    final auth = ref.read(authProvider).user;
    if (job == null || auth == null) return;

    final confirm = await showDialog<bool>(
      context: context,
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
        jobId: widget.jobId,
        newStatus: AppConstants.jobStatusInProgress,
        userId: auth.id,
      );

      if (job.workerId != null) {
        await NotificationService.instance.showNotification(
          title: 'Finalización rechazada',
          body: 'El cliente solicitó revisar el trabajo. Sube nueva evidencia cuando esté listo.',
          userId: job.workerId!,
          type: 'job_completion_rejected',
          relatedId: job.id,
        );
      }

      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finalización rechazada. El trabajo sigue en curso.')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _requestChangeOrder() async {
    final job = _job;
    final user = ref.read(authProvider).user;
    if (job == null || user == null) return;

    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final montoCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
        ],
      ),
    );

    final titulo = tituloCtrl.text.trim();
    final descripcion = descCtrl.text.trim();
    final monto = int.tryParse(montoCtrl.text.trim());
    tituloCtrl.dispose();
    descCtrl.dispose();
    montoCtrl.dispose();

    if (ok != true || !mounted) return;

    if (titulo.isEmpty || monto == null || monto < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa título y monto válido (mín. 1000 CLP)')),
      );
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
      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cobro adicional enviado al cliente')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _approveChangeOrder(ChangeOrderModel order) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(order.titulo),
        content: Text(
          '${order.descripcion}\n\nMonto: \$${order.montoClp}\n\nSe autorizará el cobro adicional (demo).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Rechazar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aprobar y pagar')),
        ],
      ),
    );

    if (confirm != true) {
      await ChangeOrderService.instance.reject(order: order, clientUserId: user.id);
      await _loadJobDetails();
      return;
    }

    try {
      await ChangeOrderService.instance.approveAndPay(
        order: order,
        clientUserId: user.id,
      );
      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cobro adicional aprobado')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _loadAddress(JobModel job) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final address = await LocationUtils.getLocationTextForJob(
        address: job.address,
        status: job.status,
        latitude: job.latitude,
        longitude: job.longitude,
      );

      if (mounted) {
        setState(() {
          _displayAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      final fallback = job.status == AppConstants.jobStatusPending
          ? 'Ubicación aproximada'
          : await LocationUtils.resolveExactAddress(
              address: job.address,
              latitude: job.latitude,
              longitude: job.longitude,
            );
      if (mounted) {
        setState(() {
          _displayAddress = fallback;
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _updateJobStatus(String newStatus) async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null || _job == null) return;

      // Validar transición usando JobStateMachine
      if (!_stateMachine.isValidTransition(
        _job!.status,
        newStatus,
        pricingMode: _job!.pricingMode,
      )) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se puede cambiar el estado de ${_job!.status} a $newStatus'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Ejecutar transición usando JobStateMachine
      await _stateMachine.transitionTo(
        jobId: widget.jobId,
        newStatus: newStatus,
        userId: user.id,
      );

      await _loadJobDetails();
      
      // Enviar notificación
      if (_job != null) {
        final otherUserId = user.id == _job!.userId ? _job!.workerId : _job!.userId;
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
              relatedId: widget.jobId,
            );
          }
        }
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _acceptJob() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || _job == null) return;

    // Validar transición usando JobStateMachine
    if (!_stateMachine.isValidTransition(
      _job!.status,
      AppConstants.jobStatusAccepted,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede aceptar un trabajo en estado: ${_job!.status}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Verificar si el trabajador ya tiene trabajos activos
    final hasActiveJobs = await _jobRepository.hasActiveJobs(user.id);
    if (hasActiveJobs) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes aceptar más trabajos. Completa o cancela tus trabajos actuales primero.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      // Usar JobStateMachine para la transición
      await _stateMachine.transitionTo(
        jobId: widget.jobId,
        newStatus: AppConstants.jobStatusAccepted,
        userId: user.id,
      );

      // Asignar trabajador
      await _jobRepository.assignWorker(_job!.id, user.id);
      
      final WorkerRepository workerRepository = WorkerRepository();
      await workerRepository.updateAvailability(user.id, false);
      await workerRepository.enforceUnavailableWhileBusy(user.id);
      
      await _loadJobDetails();
      
      // Recargar la dirección ahora que el trabajo está aceptado
      if (_job != null) {
        _loadAddress(_job!);
      }

      // Enviar notificación al usuario
      await NotificationService.instance.showNotification(
        title: 'Trabajo Aceptado',
        body: 'Tu solicitud ha sido aceptada por ${user.name}',
        userId: _job!.userId,
        type: 'job_accepted',
        relatedId: widget.jobId,
      );

      requestWorkerHomeRefresh(ref, openTabIndex: 1);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trabajo aceptado. Revisa los detalles en la pestaña En curso.'),
        ),
      );
      context.go(AppConstants.routeWorkerHome);
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _completeJob() async {
    if (_job == null) return;

    final targetStatus = JobDetailHelpers.completionTargetStatus(_job!);

    if (!_stateMachine.isValidTransition(
      _job!.status,
      targetStatus,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede finalizar un trabajo en estado: ${_job!.status}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final evidenceCount =
        await _jobPhotoRepository.getEvidenceCountByJobId(widget.jobId);

    if (evidenceCount == 0) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
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
                context.push('${AppConstants.routeJobPhotos}/${widget.jobId}');
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
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null) return;

      await _stateMachine.transitionTo(
        jobId: widget.jobId,
        newStatus: targetStatus,
        userId: user.id,
      );

      if (targetStatus == PricingConstants.jobAwaitingClientApproval) {
        await NotificationService.instance.showNotification(
          title: 'Trabajo finalizado',
          body: 'El profesional subió evidencia. Revisa y aprueba para completar el pago.',
          userId: _job!.userId,
          type: 'job_completion_review',
          relatedId: widget.jobId,
        );
      }

      await _loadJobDetails();

      if (targetStatus == AppConstants.jobStatusCompleted) {
        if (user.role == AppConstants.roleWorker) {
          requestWorkerHomeRefresh(ref);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Trabajo finalizado. Activa tu disponibilidad cuando quieras recibir nuevos trabajos.',
              ),
            ),
          );
        }
        if (user.role == AppConstants.roleUser) {
          if (!mounted) return;
          context.push('${AppConstants.routeRating}/${widget.jobId}');
        }
      } else if (!mounted) {
        return;
      } else {
        requestWorkerHomeRefresh(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Evidencia enviada. Cuando el cliente apruebe podrás activar tu disponibilidad.',
            ),
          ),
        );
      }
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cancelJob() async {
    if (_job == null) return;

    if (!_stateMachine.isValidTransition(
      _job!.status,
      AppConstants.jobStatusCancelled,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede cancelar un trabajo en estado: ${_job!.status}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Solicitud'),
        content: const Text('¿Estás seguro de que quieres cancelar esta solicitud?'),
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
        final authState = ref.read(authProvider);
        final user = authState.user;
        if (user == null) return;

        // Usar JobStateMachine para la transición
        await _stateMachine.transitionTo(
          jobId: widget.jobId,
          newStatus: AppConstants.jobStatusCancelled,
          userId: user.id,
        );

        await _loadJobDetails();
        if (!mounted) return;
        Navigator.pop(context);
      } on AppError catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Trabajo'),
        content: const Text('¿Estás seguro de que quieres rechazar este trabajo?'),
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
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null || _job == null) return;

      final isTierInvitation =
          _job!.serviceMetadata?['request_type'] == 'worker_tier_invitation';

      if (isTierInvitation) {
        try {
          await WorkerJobRejectionService.instance.rejectAndSuggestAlternatives(
            jobId: widget.jobId,
            workerId: user.id,
          );
          requestWorkerHomeRefresh(ref);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solicitud rechazada correctamente')),
          );
          context.go(AppConstants.routeWorkerHome);
        } on AppError catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      await _updateJobStatus(AppConstants.jobStatusCancelled);
      requestWorkerHomeRefresh(ref);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: null,
        body: LoadingWidget(),
      );
    }

    if (_error != null || _job == null) {
      return Scaffold(
        appBar: const AppGradientAppBar(),
        body: ErrorStateWidget(
          title: 'Trabajo no disponible',
          message: _error ?? 'Trabajo no encontrado',
          actionLabel: 'Reintentar',
          onRetry: _loadJobDetails,
        ),
      );
    }

    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isWorker = currentUser?.role == AppConstants.roleWorker;
    final isOwner = currentUser?.id == _job!.userId || currentUser?.id == _job!.workerId;
    final hasCoordinates =
        _job!.latitude != null && _job!.longitude != null;
    final workerShowsLocationCard = isWorker &&
        currentUser?.id == _job!.workerId &&
        _job!.status != AppConstants.jobStatusPending &&
        hasCoordinates;
    final clientShowsLocationPreview = !isWorker &&
        _job!.status != AppConstants.jobStatusPending &&
        hasCoordinates;

    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Detalles del Trabajo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: isWorker ? 'Volver al panel' : 'Volver al inicio',
            onPressed: _goToDashboard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: LayoutUtils.scrollPadding(context, top: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobDetailStatusHeader(job: _job!),
            if (_job!.scheduledDate != null && !workerShowsLocationCard) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event, color: AppColors.brandOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solicitado: ${DateFormat('EEE d MMM · HH:mm', 'es_CL').format(_job!.scheduledDate!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            if (workerShowsLocationCard) ...[
              const SizedBox(height: 12),
              JobAcceptedLocationCard(
                address: _isLoadingAddress ? 'Obteniendo dirección...' : _displayAddress,
                latitude: _job!.latitude!,
                longitude: _job!.longitude!,
                scheduledDate: _job!.scheduledDate,
                isLoadingAddress: _isLoadingAddress,
              ),
            ],
            if (_job!.pricingMode != PricingConstants.modeLegacy &&
                _job!.paymentStatus != PricingConstants.paymentNone) ...[
              const SizedBox(height: 12),
              Text(
                'Pago: ${JobDetailHelpers.paymentStatusLabel(_job!.paymentStatus)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_job!.pricingMode == PricingConstants.modeOpenQuote) ...[
              const SizedBox(height: 12),
              OpenQuoteStatusBanner(
                jobStatus: _job!.status,
                isClient: !isWorker && currentUser?.id == _job!.userId,
                workerName: _invitedWorkerName,
                proposalsCount: _quoteProposals
                    .where((p) => p.estado == PricingConstants.quoteSubmitted)
                    .length,
              ),
            ],
            if (_job!.status == PricingConstants.jobAwaitingPayment &&
                !isWorker &&
                currentUser?.id == _job!.userId) ...[
              const SizedBox(height: 16),
              if (JobDetailHelpers.quoteFromJob(_job!) != null)
                PricingQuoteCard(quote: JobDetailHelpers.quoteFromJob(_job!)!),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _payEscrow,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Pagar y confirmar reserva'),
              ),
            ],
            if (_job!.status == PricingConstants.jobAwaitingPayment && isWorker) ...[
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('El cliente debe completar el pago en garantía para confirmar el trabajo.'),
                ),
              ),
            ],
            if (_job!.status == PricingConstants.jobAwaitingClientApproval &&
                !isWorker &&
                currentUser?.id == _job!.userId) ...[
              const SizedBox(height: 16),
              JobDetailClientApprovalCard(
                jobId: widget.jobId,
                quote: JobDetailHelpers.quoteFromJob(_job!),
                onApprove: _approveCompletion,
                onReject: _rejectCompletion,
              ),
            ],
            if (_job!.status == PricingConstants.jobAwaitingClientApproval &&
                isWorker &&
                currentUser?.id == _job!.workerId) ...[
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Evidencia enviada. Esperando que el cliente apruebe la finalización para liberar el pago.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Descripción',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _job!.description ?? 'Sin descripción',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (clientShowsLocationPreview) ...[
              JobLocationPreviewSection(
                address: _isLoadingAddress
                    ? 'Obteniendo ubicación...'
                    : _displayAddress,
                latitude: _job!.latitude!,
                longitude: _job!.longitude!,
                isLoadingAddress: _isLoadingAddress,
              ),
            ] else if (!workerShowsLocationCard) ...[
              JobLocationPreviewSection(
                address: _isLoadingAddress
                    ? 'Obteniendo ubicación...'
                    : _displayAddress,
                latitude: _job!.latitude ?? 0,
                longitude: _job!.longitude ?? 0,
                isLoadingAddress: _isLoadingAddress,
                showApproximateHint:
                    _job!.status == AppConstants.jobStatusPending,
              ),
            ],
            if (_job!.pricingMode == PricingConstants.modeHourlyBlock &&
                _job!.hourlyBlockHours != null) ...[
              const SizedBox(height: 8),
              Text(
                'Bloque prepagado: ${_job!.hourlyBlockHours} horas',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_job!.pricingMode == PricingConstants.modeOpenQuote) ...[
              const SizedBox(height: 16),
              QuoteProposalsSection(
                proposals: _quoteProposals,
                isClient: !isWorker && currentUser?.id == _job!.userId,
                jobStatus: _job!.status,
                onSubmitQuote: isWorker ? _submitQuoteProposal : null,
                onSelect: !isWorker && currentUser?.id == _job!.userId
                    ? _selectQuoteProposal
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            ChangeOrdersSection(
              orders: _changeOrders,
              isWorker: isWorker,
              canRequest: isWorker &&
                  _job!.status == AppConstants.jobStatusInProgress,
              onRequest: _requestChangeOrder,
              onReview: !isWorker ? _approveChangeOrder : null,
            ),
            const SizedBox(height: 16),
            DisputeSection(
              dispute: _dispute,
              isParticipant: isOwner,
              canOpenDispute: _canOpenDispute(_job!),
              onOpenDispute: _openDispute,
            ),
            JobDetailActionsSection(
              jobId: widget.jobId,
              job: _job!,
              isWorker: isWorker,
              isOwner: isOwner,
              canTransition: _canTransition,
              onGoToDashboard: _goToDashboard,
              onCancelJob: _cancelJob,
              onAcceptJob: _acceptJob,
              onRejectJob: _rejectJob,
              onStartJob: () => _updateJobStatus(AppConstants.jobStatusInProgress),
              onRequestOvertimeHours: _requestOvertimeHours,
              onCompleteJob: _completeJob,
            ),
          ],
        ),
      ),
    );
  }

}


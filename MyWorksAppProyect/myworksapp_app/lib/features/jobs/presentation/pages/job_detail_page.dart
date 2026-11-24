import 'package:myworksapp/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/domain/clp_rounding.dart';
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
import '../../../../core/services/job_transition_matrix.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/database/repositories/rating_repository.dart';
import '../../../ratings/domain/rating_gate.dart';
import '../../../../core/services/job_booking_service.dart';
import '../../../../core/services/change_order_service.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/services/quote_proposal_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../widgets/quote_proposals_section.dart';
import '../widgets/worker_quote_form_dialog.dart';
import '../widgets/reschedule_section.dart';
import '../../../../core/utils/open_quote_utils.dart';
import '../../../../core/widgets/escrow_checkout_sheet.dart';
import '../../../../core/domain/price_quote.dart';
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
import '../widgets/job_detail_actions_section.dart';
import '../widgets/job_detail_payment_escrow_section.dart';
import '../widgets/job_detail_scheduled_date_row.dart';
import '../widgets/job_detail_description_section.dart';
import '../widgets/job_status_timeline.dart';
import '../widgets/worker_gps_publisher.dart';
import '../widgets/client_live_tracking.dart';
import '../widgets/client_start_pin_card.dart';
import '../../../../core/widgets/design_system/service_pin_dialog.dart';
import '../../../../core/services/gps_publish_gate.dart';
import '../../../../core/utils/plural.dart';

part 'job_detail_workflows.dart';
part 'job_detail_status.dart';

class JobDetailPage extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  /// Las extensiones de este archivo no pueden llamar [setState] directo.
  void refreshView(VoidCallback update) => setState(update);

  final JobRepository _jobRepository = JobRepository();
  final UserRepository _userRepository = UserRepository();
  final JobPhotoRepository _jobPhotoRepository = JobPhotoRepository();
  final JobStateMachine _stateMachine = JobStateMachine.instance;
  final ChangeOrderRepository _changeOrderRepository = ChangeOrderRepository();

  JobModel? _job;
  String? _clientStartPin;
  List<ChangeOrderModel> _changeOrders = [];
  DisputeModel? _dispute;
  bool _alreadyRated = false;
  String? _pendingAgreementId;
  String? _pendingAgreementType;
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
      final clientId = ref.read(authProvider).user?.id;
      String? startPin;
      if (job != null &&
          clientId == job.userId &&
          (job.status == AppConstants.jobStatusAccepted ||
              job.status == AppConstants.jobStatusEnRoute)) {
        try {
          startPin = await _jobRepository.fetchClientStartPin(job.id);
        } catch (e) {
          AppLogger.e('No se pudo leer el PIN de inicio', e);
        }
      }
      setState(() {
        _job = job;
        _clientStartPin = startPin;
        _isLoading = false;
      });

      if (job != null) {
        _loadAddress(job);
        _loadValidTransitions(job);
        await Future.wait([
          _loadChangeOrders(job.id),
          _loadDispute(job.id),
          _loadRatingStatus(job),
          if (job.pricingMode == PricingConstants.modeOpenQuote) ...[
            _loadQuoteProposals(job.id),
            _loadInvitedWorkerName(job),
          ],
        ]);
        await _maybeShowRejectionDialog(job);
      }
    } catch (e) {
      setState(() {
        _error = ErrorHandler.userMessage(
          e,
          fallback: 'No pudimos cargar este trabajo. Intenta de nuevo.',
        );
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
      AppConstants.jobStatusEnRoute,
      AppConstants.jobStatusInProgress,
      AppConstants.jobStatusCompleted,
      AppConstants.jobStatusCancelled,
      PricingConstants.jobPausedChangeOrder,
    ];

    // Una sola consulta: antes se pedía la misma lista una vez por estado.
    List<String> allowed;
    try {
      allowed = await JobTransitionMatrix.allowedTargets(
        job.pricingMode,
        job.status,
      );
    } catch (e) {
      AppLogger.e('No se pudieron cargar las transiciones del trabajo', e);
      allowed = const [];
    }
    for (final status in possibleStatuses) {
      transitions[status] = allowed.contains(status);
    }

    if (!mounted) return;
    setState(() {
      _canTransition = transitions;
    });
  }

  Future<void> _loadChangeOrders(String jobId) async {
    final orders = await _changeOrderRepository.getByJobId(jobId);
    if (mounted) setState(() => _changeOrders = orders);
  }

  /// La nota puede haberse puesto desde la web: se pregunta a la base y, si ya
  /// existe, se oculta el botón de calificar.
  Future<void> _loadRatingStatus(JobModel job) async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || job.status != AppConstants.jobStatusCompleted) {
      return;
    }
    final direction = userId == job.workerId
        ? RatingDirection.workerToClient
        : RatingDirection.clientToWorker;
    try {
      final existing = await RatingRepository().getRatingByJobId(
        job.id,
        direction: direction,
      );
      if (mounted) setState(() => _alreadyRated = existing != null);
    } catch (e) {
      AppLogger.e('No se pudo leer la calificación del trabajo', e);
    }
  }

  Future<void> _loadDispute(String jobId) async {
    final results = await Future.wait<Object?>([
      DisputeService.instance.getDisputeByJobId(jobId),
      _safePendingAgreement(jobId),
    ]);
    final dispute = results[0] as DisputeModel?;
    final agreement = results[1] as Map<String, dynamic>?;
    if (mounted) {
      setState(() {
        _dispute = dispute;
        _pendingAgreementId = agreement?['id'] as String?;
        _pendingAgreementType = agreement?['tipo'] as String?;
      });
    }
  }

  /// El acuerdo pendiente es opcional: si la función de soporte aún no existe
  /// en la base (o falla), el detalle del trabajo debe abrir igual.
  Future<Map<String, dynamic>?> _safePendingAgreement(String jobId) async {
    try {
      return await DisputeService.instance.pendingAgreement(jobId);
    } catch (e) {
      AppLogger.w('Acuerdo pendiente no disponible: $e');
      return null;
    }
  }

  Future<void> _respondAgreement(bool accept) async {
    final id = _pendingAgreementId;
    final job = _job;
    if (id == null || job == null) return;
    try {
      await DisputeService.instance.respondAgreement(id: id, accept: accept);
      await _loadJobDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'Acuerdo confirmado.' : 'Acuerdo rechazado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.userMessage(e)), backgroundColor: AppColors.error),
      );
    }
  }

  bool _canOpenDispute(JobModel job) =>
      JobDetailHelpers.canOpenDispute(job, _dispute);

  Future<void> _appealDispute(String motivo) async {
    final dispute = _dispute;
    if (dispute == null) return;
    try {
      await DisputeService.instance.appeal(
        disputeId: dispute.id,
        motivo: motivo,
      );
      await _loadDispute(dispute.jobId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La revisión quedó pedida. El dinero no se movió otra vez.')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is AppError ? e.message : 'No se pudo pedir la revisión';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _addDisputeComment(String comment) async {
    final dispute = _dispute;
    if (dispute == null) return;
    try {
      await DisputeService.instance.addComment(
        disputeId: dispute.id,
        comment: comment,
      );
      await _loadDispute(dispute.jobId);
    } catch (e) {
      if (!mounted) return;
      final message =
          e is AppError ? e.message : 'No se pudo agregar el comentario';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _openDispute(
    String reason,
    String? description, [
    String? outcome,
  ]) async {
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
      var agreementFailed = false;
      if (outcome != null && outcome.isNotEmpty) {
        try {
          await DisputeService.instance.proposeAgreement(
            jobId: job.id,
            type: outcome,
          );
        } catch (e) {
          agreementFailed = true;
          AppLogger.w('La disputa quedó abierta, pero el acuerdo no se envió: $e');
        }
      }

      final notifyUserId = user.id == job.userId ? job.workerId : job.userId;
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
        SnackBar(
          backgroundColor: agreementFailed ? AppColors.error : null,
          content: Text(
            agreementFailed
                ? 'La disputa quedó abierta, pero no se registró la opción elegida. Avísale a la otra parte por el chat.'
                : 'Disputa abierta. El trabajo queda en pausa y el pago sigue retenido.',
          ),
        ),
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
    if (job.serviceMetadata?['rejection_reason'] != 'worker_unavailable') {
      return;
    }

    _rejectionDialogShown = true;
    final rejectedWorkerId =
        job.serviceMetadata?['rejected_by_worker_id'] as String?;
    final rejectedUser = rejectedWorkerId != null
        ? await _userRepository.getPublicProfile(rejectedWorkerId)
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
    final user = await _userRepository.getPublicProfile(invitedId);
    if (mounted) setState(() => _invitedWorkerName = user?.name);
  }

  @override
  Widget build(BuildContext context) =>
      JobDetailWorkflows(this).buildJobDetail(context);
}

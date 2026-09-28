import 'package:flutter/material.dart';
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
import '../widgets/worker_quote_form_dialog.dart';
import '../../../../core/utils/open_quote_utils.dart';
import '../../../payments/presentation/pages/payment_screen.dart';
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

part 'job_detail_workflows.dart';
part 'job_detail_status.dart';

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
      final canTransition = await _stateMachine.isValidTransition(
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
        const SnackBar(
          content: Text(
            'Ticket abierto. El pago sigue retenido hasta que atención al cliente lo resuelva.',
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

  @override
  Widget build(BuildContext context) =>
      JobDetailWorkflows(this).buildJobDetail(context);
}

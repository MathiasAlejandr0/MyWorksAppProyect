import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/database/models/change_order_model.dart';
import '../../../../core/database/models/dispute_model.dart';
import '../../../../core/database/models/quote_proposal_model.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';
import '../../../../core/widgets/pricing_quote_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../worker/presentation/providers/worker_home_refresh_provider.dart';
import '../widgets/quote_proposals_section.dart';
import '../widgets/open_quote_status_banner.dart';
import '../widgets/job_accepted_location_card.dart';
import '../widgets/job_location_preview_section.dart';
import '../widgets/change_orders_section.dart';
import '../widgets/dispute_section.dart';
import '../utils/job_detail_helpers.dart';
import '../widgets/job_detail_status_header.dart';
import '../widgets/job_detail_client_approval_card.dart';
import '../widgets/job_detail_actions_section.dart';
import 'job_detail_controller.dart';
import 'job_detail_loader.dart';

class JobDetailPage extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  late final JobRepository _jobRepository;
  late final JobDetailLoader _loader;
  late final JobDetailController _controller;

  JobModel? _job;
  List<ChangeOrderModel> _changeOrders = [];
  DisputeModel? _dispute;
  List<QuoteProposalModel> _quoteProposals = [];
  String? _invitedWorkerName;
  bool _isLoading = true;
  String? _error;
  String _displayAddress = '';
  bool _isLoadingAddress = true;
  Map<String, bool> _canTransition = {};
  bool _rejectionDialogShown = false;

  @override
  void initState() {
    super.initState();
    _jobRepository = ref.read(jobRepositoryProvider);
    _loader = JobDetailLoader(
      userRepository: ref.read(userRepositoryProvider),
    );
    _controller = JobDetailController(
      jobId: widget.jobId,
      getJob: () => _job,
      getUser: () => ref.read(authProvider).user,
      isMounted: () => mounted,
      getContext: () => context,
      onReload: _loadJobDetails,
      onLoadAddress: _loadAddress,
      onLoadQuoteProposals: _loadQuoteProposals,
      onRequestWorkerHomeRefresh: ({int? openTabIndex}) {
        requestWorkerHomeRefresh(ref, openTabIndex: openTabIndex);
      },
      onRejectionDialogShown: () => _rejectionDialogShown = true,
      jobRepository: _jobRepository,
      userRepository: ref.read(userRepositoryProvider),
      workerRepository: ref.read(workerRepositoryProvider),
    );
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
        await _controller.maybeShowRejectionDialog(
          job,
          alreadyShown: _rejectionDialogShown,
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadValidTransitions(JobModel job) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final transitions = await _loader.loadValidTransitions(job);
    if (mounted) setState(() => _canTransition = transitions);
  }

  Future<void> _loadChangeOrders(String jobId) async {
    final orders = await _loader.loadChangeOrders(jobId);
    if (mounted) setState(() => _changeOrders = orders);
  }

  Future<void> _loadDispute(String jobId) async {
    final dispute = await _loader.loadDispute(jobId);
    if (mounted) setState(() => _dispute = dispute);
  }

  Future<void> _loadQuoteProposals(String jobId) async {
    final list = await _loader.loadQuoteProposals(jobId);
    if (mounted) setState(() => _quoteProposals = list);
  }

  Future<void> _loadInvitedWorkerName(JobModel job) async {
    final name = await _loader.loadInvitedWorkerName(job);
    if (mounted) setState(() => _invitedWorkerName = name);
  }

  Future<void> _loadAddress(JobModel job) async {
    setState(() => _isLoadingAddress = true);
    final address = await _loader.loadAddress(job);
    if (mounted) {
      setState(() {
        _displayAddress = address;
        _isLoadingAddress = false;
      });
    }
  }

  bool _canOpenDispute(JobModel job) =>
      JobDetailHelpers.canOpenDispute(job, _dispute);

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
    final isOwner = currentUser?.id == _job!.userId ||
        currentUser?.id == _job!.workerId;
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
            onPressed: _controller.goToDashboard,
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
                address: _isLoadingAddress
                    ? 'Obteniendo dirección...'
                    : _displayAddress,
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
                onPressed: _controller.payEscrow,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Pagar y confirmar reserva'),
              ),
            ],
            if (_job!.status == PricingConstants.jobAwaitingPayment &&
                isWorker) ...[
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'El cliente debe completar el pago en garantía para confirmar el trabajo.',
                  ),
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
                onApprove: _controller.approveCompletion,
                onReject: _controller.rejectCompletion,
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
                onSubmitQuote:
                    isWorker ? _controller.submitQuoteProposal : null,
                onSelect: !isWorker && currentUser?.id == _job!.userId
                    ? _controller.selectQuoteProposal
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            ChangeOrdersSection(
              orders: _changeOrders,
              isWorker: isWorker,
              canRequest: isWorker &&
                  _job!.status == AppConstants.jobStatusInProgress,
              onRequest: _controller.requestChangeOrder,
              onReview: !isWorker ? _controller.approveChangeOrder : null,
            ),
            const SizedBox(height: 16),
            DisputeSection(
              dispute: _dispute,
              isParticipant: isOwner,
              canOpenDispute: _canOpenDispute(_job!),
              onOpenDispute: _controller.openDispute,
            ),
            JobDetailActionsSection(
              jobId: widget.jobId,
              job: _job!,
              isWorker: isWorker,
              isOwner: isOwner,
              canTransition: _canTransition,
              onGoToDashboard: _controller.goToDashboard,
              onCancelJob: _controller.cancelJob,
              onAcceptJob: _controller.acceptJob,
              onRejectJob: _controller.rejectJob,
              onStartJob: () =>
                  _controller.updateJobStatus(AppConstants.jobStatusInProgress),
              onRequestOvertimeHours: _controller.requestOvertimeHours,
              onCompleteJob: _controller.completeJob,
            ),
          ],
        ),
      ),
    );
  }
}

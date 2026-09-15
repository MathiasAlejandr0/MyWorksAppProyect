import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/notification_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/design_system/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/open_quote_utils.dart';
import '../../../../core/utils/worker_job_status.dart';
import '../../../../core/widgets/design_system/app_brand_logo.dart';
import '../../../../core/widgets/design_system/auth_soft_background.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/design_system/loading_skeleton.dart';
import '../../../../core/widgets/app_guided_tour.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/worker_home_refresh_provider.dart';
import '../widgets/worker_active_job_banner.dart';
import '../widgets/worker_demo_tour_overlay.dart';
import '../widgets/worker_earnings_summary.dart';
import '../widgets/worker_header.dart';
import '../widgets/worker_job_card.dart';
import '../widgets/worker_onboarding_card.dart';
import '../widgets/worker_quick_actions_row.dart';
import '../widgets/worker_stats_row.dart';

class WorkerHomePage extends ConsumerStatefulWidget {
  const WorkerHomePage({super.key});

  @override
  ConsumerState<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends ConsumerState<WorkerHomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final JobRepository _jobRepository = JobRepository();
  final WorkerRepository _workerRepository = WorkerRepository();
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  bool _isAvailable = true;
  bool _hasActiveJobs = false;
  _WorkerDashboard? _dashboard;
  bool _loadingDashboard = true;
  String? _dashboardError;
  int _jobsListGeneration = 0;

  final _availabilityKey = GlobalKey();
  final _statsKey = GlobalKey();
  final _earningsKey = GlobalKey();
  final _actionsKey = GlobalKey();
  final _tabsKey = GlobalKey();
  final _profileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _refresh();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _applyOpenTabFromProvider());
  }

  void _applyOpenTabFromProvider() {
    final tabIndex = ref.read(workerHomeRefreshProvider).openTabIndex;
    if (tabIndex == null || !mounted) return;
    if (tabIndex >= 0 && tabIndex < _tabController.length) {
      _tabController.animateTo(tabIndex);
    }
    clearWorkerHomeOpenTab(ref);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    setState(() {
      _loadingDashboard = true;
      _dashboardError = null;
    });

    try {
      await _workerRepository.enforceUnavailableWhileBusy(user.id);
      final worker = await _workerRepository.getWorkerByUserId(user.id);
      final hasActiveJobs = await _jobRepository.hasActiveJobs(user.id);
      final pending = await _fetchPendingJobs(user.id);
      final active = await _fetchActiveJobs(user.id);
      final completed = await _fetchCompletedJobs(user.id);
      final unread = await _notificationRepository.getUnreadCount(user.id);

      final highlight = WorkerJobStatus.pickHighlightJob(active);

      if (mounted) {
        setState(() {
          _jobsListGeneration++;
          _hasActiveJobs = hasActiveJobs;
          _isAvailable = worker?.isAvailable == true;
          _dashboard = _WorkerDashboard(
            worker: worker,
            userName: user.name,
            pendingCount: pending.length,
            activeCount: active.length,
            completedCount: completed.length,
            unreadNotifications: unread,
            highlightJob: highlight,
          );
          _loadingDashboard = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDashboard = false;
        _dashboardError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el panel: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleAvailability() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (_hasActiveJobs) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tienes un trabajo en curso. Finalízalo antes de activar disponibilidad.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      final newAvailability = !_isAvailable;
      if (newAvailability) {
        final stillBusy = await _jobRepository.hasActiveJobs(user.id);
        if (stillBusy) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aún tienes un trabajo activo. Finalízalo antes de activar disponibilidad.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
          await _refresh();
          return;
        }
      }
      await _workerRepository.updateAvailability(user.id, newAvailability);
      setState(() => _isAvailable = newAvailability);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newAvailability
              ? 'Estás disponible para nuevos trabajos'
              : 'Modo no disponible activado'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  List<GuidedTourStep> _workerTourSteps() => [
        const GuidedTourStep(
          title: 'Panel del profesional',
          description:
              'Desde aquí gestionas solicitudes, trabajos en curso y tu disponibilidad para nuevos clientes.',
          align: TourTooltipAlign.center,
        ),
        GuidedTourStep(
          targetKey: _availabilityKey,
          title: 'Tu disponibilidad',
          description:
              'Activa o desactiva si puedes recibir nuevas solicitudes. Si tienes un trabajo activo, quedarás como ocupado.',
          align: TourTooltipAlign.below,
        ),
        GuidedTourStep(
          targetKey: _statsKey,
          title: 'Resumen de trabajos',
          description:
              'Pendientes, en curso y finalizados. Toca cada tarjeta para ir a la pestaña correspondiente.',
          align: TourTooltipAlign.below,
        ),
        GuidedTourStep(
          targetKey: _earningsKey,
          title: 'Mis cobros',
          description:
              'Vista demo de pagos en garantía y liberados. En producción se conectará a la pasarela real.',
          align: TourTooltipAlign.below,
        ),
        GuidedTourStep(
          targetKey: _actionsKey,
          title: 'Accesos rápidos',
          description:
              'Tarifas, calendario, estadísticas, historial y alertas sin salir del panel.',
          align: TourTooltipAlign.below,
        ),
        GuidedTourStep(
          targetKey: _tabsKey,
          title: 'Listas de trabajos',
          description:
              'Revisa solicitudes nuevas, trabajos activos (incluye espera de pago del cliente) y el historial completado.',
          align: TourTooltipAlign.above,
        ),
        GuidedTourStep(
          targetKey: _profileKey,
          title: 'Perfil y ajustes',
          description:
              'Actualiza foto, portafolio y zona de trabajo. Las notificaciones están en la campana.',
          align: TourTooltipAlign.below,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    ref.listen<WorkerHomeRefreshState>(workerHomeRefreshProvider,
        (previous, next) {
      if (previous != null && previous.token != next.token) {
        _refresh().then((_) => _applyOpenTabFromProvider());
      }
    });

    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Usuario no encontrado')));
    }

    final firstName = user.name.split(' ').first;

    return WorkerDemoTourOverlay(
      steps: _workerTourSteps(),
      child: Scaffold(
          backgroundColor: AppDecorations.canvasOf(context),
          body: AuthSoftBackground(
            showDecorations: true,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WorkerTopBar(
                    userName: user.name,
                    photoPath: user.profilePhotoPath,
                    profileTourKey: _profileKey,
                    unreadNotifications: _dashboard?.unreadNotifications ?? 0,
                    onNotifications: () =>
                        context.push(AppConstants.routeNotifications),
                    onProfile: () =>
                        context.push(AppConstants.routeWorkerProfile),
                    onSettings: () => context.push(AppConstants.routeSettings),
                  ),
                  WorkerHeader(
                    firstName: firstName,
                    worker: _dashboard?.worker,
                    isAvailable: _isAvailable,
                    hasActiveJobs: _hasActiveJobs,
                    loading: _loadingDashboard,
                    availabilityTourKey: _availabilityKey,
                    onToggleAvailability: _toggleAvailability,
                  ),
                  WorkerOnboardingCard(
                    workerId: user.id,
                    onCompleted: _refresh,
                  ),
                  if (_dashboardError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Material(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: _refresh,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Error al cargar. Toca para reintentar.',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(Icons.refresh,
                                    color:
                                        AppColors.error.withValues(alpha: 0.8),
                                    size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_loadingDashboard)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: AppColors.brandOrange,
                        backgroundColor: AppColors.brandOrangeSoft,
                      ),
                    )
                  else if (_dashboard != null) ...[
                  TourTarget(
                    tourKey: _statsKey,
                    width: double.infinity,
                    child: WorkerStatsRow(
                      pending: _dashboard!.pendingCount,
                      active: _dashboard!.activeCount,
                      completed: _dashboard!.completedCount,
                      selectedIndex: _tabController.index,
                      onTap: (i) => _tabController.animateTo(i),
                    ),
                  ),
                  TourTarget(
                    tourKey: _earningsKey,
                    width: double.infinity,
                    child: WorkerEarningsSummary(
                      key: ValueKey('earnings-$_jobsListGeneration'),
                      workerId: user.id,
                      onViewDetails: () =>
                          context.push(AppConstants.routeStatistics),
                    ),
                  ),
                  TourTarget(
                    tourKey: _actionsKey,
                    width: double.infinity,
                    child: WorkerQuickActionsRow(
                      onNewJob: () => _tabController.animateTo(0),
                      onCalendar: () =>
                          context.push(AppConstants.routeJobSchedule),
                      onJobMap: () =>
                          context.push(AppConstants.routeJobHistory),
                      onInvoices: () =>
                          context.push(AppConstants.routeStatistics),
                    ),
                  ),
                  if (_dashboard!.highlightJob != null)
                    WorkerActiveJobBanner(
                      job: _dashboard!.highlightJob!,
                      onTap: () => context.push(
                        '${AppConstants.routeJobDetail}/${_dashboard!.highlightJob!.id}',
                      ),
                      onChat: () => context.push(
                        '${AppConstants.routeChat}/${_dashboard!.highlightJob!.id}',
                      ),
                    ),
                ],
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      AppBreakpoints.screenPadding(context) - 4,
                      8,
                      AppBreakpoints.screenPadding(context) - 4,
                      0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      border: Border.all(
                        color: AppColors.hairlineOf(
                          context,
                          accent: AppColors.brandOrange,
                        ),
                      ),
                      boxShadow: AppDecorations.appleCardShadow(
                        isDark:
                            Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                    child: Column(
                      children: [
                        TourTarget(
                          tourKey: _tabsKey,
                          width: double.infinity,
                          child: TabBar(
                            controller: _tabController,
                            labelColor: AppColors.brandOrange,
                            unselectedLabelColor: AppColors.onCanvasMuted(
                              Theme.of(context).brightness,
                            ),
                            indicatorColor: AppColors.brandOrange,
                            indicatorWeight: 3,
                            indicatorSize: TabBarIndicatorSize.label,
                            dividerColor: AppColors.hairlineOf(context),
                            labelStyle: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                            unselectedLabelStyle: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            tabs: [
                              Tab(
                                  text:
                                      'Pendientes${_badge(_dashboard?.pendingCount)}'),
                              Tab(
                                  text:
                                      'En curso${_badge(_dashboard?.activeCount)}'),
                              Tab(
                                  text:
                                      'Finalizados${_badge(_dashboard?.completedCount)}'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _JobsTab(
                                key: ValueKey('pending-$user.id'),
                                reloadToken: _jobsListGeneration,
                                loader: () => _fetchPendingJobs(user.id),
                                emptyTitle: 'Sin solicitudes nuevas',
                                emptyMessage:
                                    'Activa tu disponibilidad para recibir trabajos cerca de ti.',
                                emptyActionLabel: _isAvailable
                                    ? null
                                    : 'Activar disponibilidad',
                                onEmptyAction:
                                    _isAvailable ? null : _toggleAvailability,
                                onJobTap: _openJob,
                                onRefresh: _refresh,
                              ),
                              _JobsTab(
                                key: ValueKey('active-$user.id'),
                                reloadToken: _jobsListGeneration,
                                loader: () => _fetchActiveJobs(user.id),
                                emptyTitle: 'Nada en curso',
                                emptyMessage:
                                    'Acepta una solicitud pendiente o revisa tu calendario.',
                                emptyActionLabel: 'Ver calendario',
                                onEmptyAction: () =>
                                    context.push(AppConstants.routeJobSchedule),
                                onJobTap: _openJob,
                                onRefresh: _refresh,
                              ),
                              _JobsTab(
                                key: ValueKey('done-$user.id'),
                                reloadToken: _jobsListGeneration,
                                loader: () => _fetchCompletedJobs(user.id),
                                emptyTitle: 'Sin historial aún',
                                emptyMessage:
                                    'Tus trabajos completados aparecerán aquí con calificaciones.',
                                emptyActionLabel: 'Ver estadísticas',
                                onEmptyAction: () =>
                                    context.push(AppConstants.routeStatistics),
                                onJobTap: _openJob,
                                onRefresh: _refresh,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _badge(int? count) {
    if (count == null || count == 0) return '';
    return ' ($count)';
  }

  Future<void> _openJob(JobModel job) async {
    await context.push('${AppConstants.routeJobDetail}/${job.id}');
    if (mounted) await _refresh();
  }

  Future<List<JobModel>> _fetchPendingJobs(String workerId) async {
    final hasActiveJobs = await _jobRepository.hasActiveJobs(workerId);
    if (hasActiveJobs) return [];
    final assigned = await _jobRepository.getPendingJobsForWorker(workerId);
    final openQuotes = await _jobRepository.getJobsByStatus(
      PricingConstants.jobAwaitingQuotes,
    );
    final openForWorker = openQuotes.where((j) {
      return OpenQuoteUtils.canWorkerSubmitQuote(j, workerId);
    });
    final legacy = (await _jobRepository.getJobsByStatus(
      AppConstants.jobStatusPending,
    ))
        .where((j) => j.workerId == null)
        .toList();
    return [...assigned, ...legacy, ...openForWorker];
  }

  Future<List<JobModel>> _fetchActiveJobs(String workerId) async {
    return _jobRepository.getActiveJobsByWorkerId(workerId);
  }

  Future<List<JobModel>> _fetchCompletedJobs(String workerId) async {
    final allJobs = await _jobRepository.getJobsByWorkerId(workerId);
    return allJobs
        .where((j) => j.status == AppConstants.jobStatusCompleted)
        .toList();
  }
}

class _WorkerDashboard {
  final WorkerModel? worker;
  final String userName;
  final int pendingCount;
  final int activeCount;
  final int completedCount;
  final int unreadNotifications;
  final JobModel? highlightJob;

  const _WorkerDashboard({
    required this.worker,
    required this.userName,
    required this.pendingCount,
    required this.activeCount,
    required this.completedCount,
    required this.unreadNotifications,
    required this.highlightJob,
  });
}

class _WorkerTopBar extends StatelessWidget {
  const _WorkerTopBar({
    required this.userName,
    required this.photoPath,
    required this.profileTourKey,
    required this.unreadNotifications,
    required this.onNotifications,
    required this.onProfile,
    required this.onSettings,
  });

  final String userName;
  final String? photoPath;
  final GlobalKey profileTourKey;
  final int unreadNotifications;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = AppColors.headlineOnScreen(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppBrandLogo(
                horizontal: true,
                size: 34,
                textSize: 15,
              ),
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              backgroundColor: AppColors.brandOrange,
              child: Icon(
                Icons.notifications_outlined,
                color: iconColor,
              ),
            ),
          ),
          TourTarget(
            tourKey: profileTourKey,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: onProfile,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.hairlineOf(context),
                          width: 2,
                        ),
                      ),
                      child: ProfileAvatarView(
                        displayName: userName,
                        photoPath: photoPath,
                        radius: 20,
                        onDarkBackground: isDark,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: onSettings,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.brandOrangeVibrant,
                              AppColors.brandOrange,
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppDecorations.canvasOf(context),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobsTab extends StatefulWidget {
  const _JobsTab({
    super.key,
    required this.reloadToken,
    required this.loader,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onJobTap,
    required this.onRefresh,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final int reloadToken;
  final Future<List<JobModel>> Function() loader;
  final String emptyTitle;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final void Function(JobModel) onJobTap;
  final Future<void> Function() onRefresh;

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  late Future<List<JobModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  @override
  void didUpdateWidget(covariant _JobsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      setState(() {
        _future = widget.loader();
      });
    }
  }

  Future<void> _reload() async {
    await widget.onRefresh();
    setState(() {
      _future = widget.loader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<JobModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const JobListSkeleton(itemCount: 6);
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyStateWidget(
                    icon: Icons.error_outline,
                    title: 'No se pudo cargar',
                    message: 'Tira hacia abajo para reintentar.',
                    actionLabel: 'Reintentar',
                    onAction: _reload,
                  ),
                ),
              ],
            );
          }

          final jobs = snapshot.data ?? [];
          if (jobs.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.35,
                  child: EmptyStateWidget(
                    icon: Icons.work_outline,
                    title: widget.emptyTitle,
                    message: widget.emptyMessage,
                    actionLabel: widget.emptyActionLabel,
                    onAction: widget.onEmptyAction,
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: jobs.length,
            itemBuilder: (context, index) => WorkerJobCard(
              job: jobs[index],
              onTap: () => widget.onJobTap(jobs[index]),
            ),
          );
        },
      ),
    );
  }
}

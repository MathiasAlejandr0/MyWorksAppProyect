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
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/open_quote_utils.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/utils/job_display_utils.dart';
import '../../../../core/widgets/design_system/app_brand_logo.dart';
import '../../../../core/widgets/design_system/auth_soft_background.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/worker_home_refresh_provider.dart';

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
  final NotificationRepository _notificationRepository = NotificationRepository();
  bool _isAvailable = true;
  bool _hasActiveJobs = false;
  _WorkerDashboard? _dashboard;
  bool _loadingDashboard = true;
  int _jobsListGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyOpenTabFromProvider());
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

    setState(() => _loadingDashboard = true);

    try {
      await _workerRepository.enforceUnavailableWhileBusy(user.id);
      final worker = await _workerRepository.getWorkerByUserId(user.id);
      final hasActiveJobs = await _jobRepository.hasActiveJobs(user.id);
      final pending = await _fetchPendingJobs(user.id);
      final active = await _fetchActiveJobs(user.id);
      final completed = await _fetchCompletedJobs(user.id);
      final unread = await _notificationRepository.getUnreadCount(user.id);

      JobModel? highlight;
      for (final job in active) {
        highlight = job;
        break;
      }

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
    } catch (_) {
      if (mounted) setState(() => _loadingDashboard = false);
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
          backgroundColor: Colors.orange,
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
              backgroundColor: Colors.orange,
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
          content: Text(newAvailability ? 'Estás disponible para nuevos trabajos' : 'Modo no disponible activado'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WorkerHomeRefreshState>(workerHomeRefreshProvider, (previous, next) {
      if (previous != null && previous.token != next.token) {
        _refresh().then((_) => _applyOpenTabFromProvider());
      }
    });

    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Usuario no encontrado')));
    }

    final firstName = user.name.split(' ').first;

    return Scaffold(
      body: AuthSoftBackground(
        showDecorations: false,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WorkerTopBar(
                userName: user.name,
                photoPath: user.profilePhotoPath,
                unreadNotifications: _dashboard?.unreadNotifications ?? 0,
                onNotifications: () => context.push(AppConstants.routeNotifications),
                onProfile: () => context.push(AppConstants.routeWorkerProfile),
                onSettings: () => context.push(AppConstants.routeSettings),
              ),
              _WorkerHeader(
                firstName: firstName,
                dashboard: _dashboard,
                isAvailable: _isAvailable,
                hasActiveJobs: _hasActiveJobs,
                loading: _loadingDashboard,
                onToggleAvailability: _toggleAvailability,
              ),
            if (_loadingDashboard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.brandOrange,
                  backgroundColor: AppColors.brandOrangeSoft,
                ),
              )
            else if (_dashboard != null) ...[
              _StatsRow(
                pending: _dashboard!.pendingCount,
                active: _dashboard!.activeCount,
                completed: _dashboard!.completedCount,
                selectedIndex: _tabController.index,
                onTap: (i) => _tabController.animateTo(i),
              ),
              _QuickActionsRow(
                unread: _dashboard!.unreadNotifications,
                onCalendar: () => context.push(AppConstants.routeJobSchedule),
                onStats: () => context.push(AppConstants.routeStatistics),
                onNotifications: () => context.push(AppConstants.routeNotifications),
                onEditPricing: () => context.push(
                  '${AppConstants.routeWorkerPricingSetup}?edit=1',
                ),
              ),
              if (_dashboard!.highlightJob != null)
                _ActiveJobBanner(
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
                  6,
                  AppBreakpoints.screenPadding(context) - 4,
                  0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(
                    color: AppColors.grayMedium.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.brandOrange,
                      unselectedLabelColor: AppColors.grayMedium,
                      indicatorColor: AppColors.brandOrange,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: AppColors.grayMedium.withValues(alpha: 0.15),
                      labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
                      tabs: [
                        Tab(text: 'Pendientes${_badge(_dashboard?.pendingCount)}'),
                        Tab(text: 'En curso${_badge(_dashboard?.activeCount)}'),
                        Tab(text: 'Finalizados${_badge(_dashboard?.completedCount)}'),
                      ],
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
                            emptyMessage: 'Activa tu disponibilidad para recibir trabajos cerca de ti.',
                            emptyActionLabel: _isAvailable ? null : 'Activar disponibilidad',
                            onEmptyAction: _isAvailable ? null : _toggleAvailability,
                            onJobTap: _openJob,
                            onRefresh: _refresh,
                          ),
                          _JobsTab(
                            key: ValueKey('active-$user.id'),
                            reloadToken: _jobsListGeneration,
                            loader: () => _fetchActiveJobs(user.id),
                            emptyTitle: 'Nada en curso',
                            emptyMessage: 'Acepta una solicitud pendiente o revisa tu calendario.',
                            emptyActionLabel: 'Ver calendario',
                            onEmptyAction: () => context.push(AppConstants.routeJobSchedule),
                            onJobTap: _openJob,
                            onRefresh: _refresh,
                          ),
                          _JobsTab(
                            key: ValueKey('done-$user.id'),
                            reloadToken: _jobsListGeneration,
                            loader: () => _fetchCompletedJobs(user.id),
                            emptyTitle: 'Sin historial aún',
                            emptyMessage: 'Tus trabajos completados aparecerán aquí con calificaciones.',
                            emptyActionLabel: 'Ver estadísticas',
                            onEmptyAction: () => context.push(AppConstants.routeStatistics),
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
    final allJobs = await _jobRepository.getJobsByWorkerId(workerId);
    return allJobs
        .where((j) =>
            j.status == AppConstants.jobStatusInProgress ||
            j.status == AppConstants.jobStatusAccepted ||
            j.status == PricingConstants.jobAwaitingClientApproval)
        .toList();
  }

  Future<List<JobModel>> _fetchCompletedJobs(String workerId) async {
    final allJobs = await _jobRepository.getJobsByWorkerId(workerId);
    return allJobs.where((j) => j.status == AppConstants.jobStatusCompleted).toList();
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
    required this.unreadNotifications,
    required this.onNotifications,
    required this.onProfile,
    required this.onSettings,
  });

  final String userName;
  final String? photoPath;
  final int unreadNotifications;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          const AppBrandLogo(size: 32, textSize: 16),
          const Spacer(),
          IconButton(
            onPressed: onNotifications,
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              backgroundColor: AppColors.brandOrange,
              child: Icon(
                Icons.notifications_outlined,
                color: AppColors.brandNavy.withValues(alpha: 0.85),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: onProfile,
                  child: ProfileAvatarView(
                    displayName: userName,
                    photoPath: photoPath,
                    radius: 20,
                    onDarkBackground: false,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: GestureDetector(
                    onTap: onSettings,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.brandOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
        ],
      ),
    );
  }
}

class _WorkerHeader extends StatelessWidget {
  const _WorkerHeader({
    required this.firstName,
    required this.dashboard,
    required this.isAvailable,
    required this.hasActiveJobs,
    required this.loading,
    required this.onToggleAvailability,
  });

  final String firstName;
  final _WorkerDashboard? dashboard;
  final bool isAvailable;
  final bool hasActiveJobs;
  final bool loading;
  final VoidCallback onToggleAvailability;

  @override
  Widget build(BuildContext context) {
    final worker = dashboard?.worker;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¡Hola de nuevo, $firstName!',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.grayDark,
            ),
          ),
          if (worker != null) ...[
            const SizedBox(height: 4),
            Text(
              worker.profession,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.grayMedium.withValues(alpha: 0.95),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (worker != null)
                Expanded(
                  child: _HeaderChip(
                    icon: Icons.star_rounded,
                    label: worker.rating.toStringAsFixed(1),
                    color: AppColors.brandOrange,
                  ),
                ),
              if (worker != null) const SizedBox(width: 8),
              if (!loading)
                _AvailabilityPill(
                  isAvailable: isAvailable,
                  hasActiveJobs: hasActiveJobs,
                  onTap: onToggleAvailability,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grayMedium.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grayDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({
    required this.isAvailable,
    required this.hasActiveJobs,
    required this.onTap,
  });

  final bool isAvailable;
  final bool hasActiveJobs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final busy = hasActiveJobs;
    final available = !busy && isAvailable;
    final color = busy
        ? AppColors.warning
        : available
            ? AppColors.success
            : AppColors.grayMedium;
    final bg = busy
        ? AppColors.warning.withValues(alpha: 0.12)
        : available
            ? AppColors.brandOrangeSoft
            : AppColors.grayLight;
    final label = busy
        ? 'Ocupado'
        : available
            ? 'Disponible'
            : 'No disp.';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                available ? Icons.circle : Icons.circle_outlined,
                size: 10,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.pending,
    required this.active,
    required this.completed,
    required this.selectedIndex,
    required this.onTap,
  });

  final int pending;
  final int active;
  final int completed;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Pendientes',
              value: '$pending',
              icon: Icons.inbox_outlined,
              color: AppColors.brandOrange,
              selected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'En curso',
              value: '$active',
              icon: Icons.engineering_outlined,
              color: AppColors.brandNavy,
              selected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Finalizados',
              value: '$completed',
              icon: Icons.check_circle_outline,
              color: AppColors.brandTeal,
              selected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.55)
                  : AppColors.grayMedium.withValues(alpha: 0.2),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.grayDark,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.grayMedium,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.unread,
    required this.onCalendar,
    required this.onStats,
    required this.onNotifications,
    required this.onEditPricing,
  });

  final int unread;
  final VoidCallback onCalendar;
  final VoidCallback onStats;
  final VoidCallback onNotifications;
  final VoidCallback onEditPricing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ActionChip(
            icon: Icons.payments_outlined,
            label: 'Mis tarifas',
            onTap: onEditPricing,
          ),
          const SizedBox(width: 8),
          _ActionChip(icon: Icons.calendar_month, label: 'Calendario', onTap: onCalendar),
          const SizedBox(width: 8),
          _ActionChip(icon: Icons.bar_chart_rounded, label: 'Estadísticas', onTap: onStats),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.notifications_active_outlined,
            label: unread > 0 ? 'Alertas ($unread)' : 'Alertas',
            onTap: onNotifications,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.brandNavy),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: AppColors.grayMedium.withValues(alpha: 0.22)),
      labelStyle: const TextStyle(
        color: AppColors.brandNavy,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}

class _ActiveJobBanner extends StatelessWidget {
  const _ActiveJobBanner({
    required this.job,
    required this.onTap,
    required this.onChat,
  });

  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.brandOrange.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrangeSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work_outline, color: AppColors.brandOrange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trabajo en curso',
                        style: TextStyle(
                          color: AppColors.brandOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        JobDisplayUtils.title(job),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.grayDark,
                        ),
                      ),
                      if (JobDisplayUtils.priceLine(job) != null)
                        Text(
                          JobDisplayUtils.priceLine(job)!,
                          style: TextStyle(
                            color: AppColors.brandOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        JobDisplayUtils.dateLine(job),
                        style: TextStyle(
                          color: AppColors.grayMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.brandTeal),
                  tooltip: 'Chat',
                ),
                Icon(Icons.chevron_right, color: AppColors.grayMedium.withValues(alpha: 0.8)),
              ],
            ),
          ),
        ),
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
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.35,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.brandOrange),
                  ),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: ${snapshot.error}'),
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
            itemBuilder: (context, index) => _JobCard(
              job: jobs[index],
              onTap: () => widget.onJobTap(jobs[index]),
            ),
          );
        },
      ),
    );
  }
}

class _JobCard extends StatefulWidget {
  const _JobCard({required this.job, required this.onTap});

  final JobModel job;
  final VoidCallback onTap;

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  String _displayAddress = '';
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    try {
      final address = await LocationUtils.getLocationTextForJob(
        address: widget.job.address,
        status: widget.job.status,
        latitude: widget.job.latitude,
        longitude: widget.job.longitude,
      );
      if (mounted) {
        setState(() {
          _displayAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _displayAddress = widget.job.address;
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.grayMedium.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      JobDisplayUtils.title(widget.job),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.grayDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(status: widget.job.status),
                ],
              ),
              if (JobDisplayUtils.priceLine(widget.job) != null) ...[
                const SizedBox(height: 4),
                Text(
                  JobDisplayUtils.priceLine(widget.job)!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandOrange,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    widget.job.status == AppConstants.jobStatusPending
                        ? Icons.location_searching
                        : Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.brandTeal,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _isLoadingAddress ? 'Cargando ubicación...' : _displayAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grayMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppColors.grayMedium.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text(
                    JobDisplayUtils.dateLine(widget.job),
                    style: TextStyle(
                      color: AppColors.grayMedium,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      AppConstants.jobStatusPending => (AppColors.brandOrange, 'Pendiente'),
      AppConstants.jobStatusAccepted => (AppColors.brandNavy, 'Aceptado'),
      AppConstants.jobStatusInProgress => (AppColors.brandTeal, 'En curso'),
      AppConstants.jobStatusCompleted => (AppColors.success, 'Completado'),
      AppConstants.jobStatusCancelled => (AppColors.error, 'Cancelado'),
      PricingConstants.jobAwaitingQuotes => (AppColors.brandOrange, 'Cotizar'),
      PricingConstants.jobAwaitingPayment => (AppColors.brandOrange, 'Pago cliente'),
      PricingConstants.jobPausedChangeOrder => (AppColors.warning, 'Cobro extra'),
      PricingConstants.jobAwaitingClientApproval =>
        (AppColors.brandTeal, 'Esperando cliente'),
      _ => (AppColors.grayMedium, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

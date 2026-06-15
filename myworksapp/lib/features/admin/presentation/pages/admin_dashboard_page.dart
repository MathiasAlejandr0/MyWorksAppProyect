import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../widgets/admin_nav_tile.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  AdminMetrics? _metrics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final metrics = await _repo.getMetrics();
      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando métricas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _metrics;

    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Panel administrador'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: LayoutUtils.scrollPadding(context),
                children: [
                  Text(
                    'Resumen de la plataforma',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (m!.totalIncidents > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _AlertBanner(count: m.totalIncidents),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _MetricsGrid(metrics: m),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle('Operación'),
                  AdminNavTile(
                    icon: Icons.people_outline,
                    title: 'Usuarios',
                    subtitle: '${m.usersCount} cuentas registradas',
                    onTap: () => context.push(AppConstants.routeAdminUsers),
                  ),
                  AdminNavTile(
                    icon: Icons.engineering_outlined,
                    title: 'Trabajadores',
                    subtitle: '${m.workersCount} perfiles activos',
                    onTap: () => context.push(AppConstants.routeAdminWorkers),
                  ),
                  AdminNavTile(
                    icon: Icons.work_outline,
                    title: 'Trabajos',
                    subtitle: '${m.activeJobsCount} activos de ${m.jobsCount}',
                    onTap: () => context.push(AppConstants.routeAdminJobs),
                  ),
                  AdminNavTile(
                    icon: Icons.home_repair_service_outlined,
                    title: 'Servicios',
                    subtitle: 'Activar o desactivar catálogo',
                    onTap: () => context.push(AppConstants.routeAdminServices),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionTitle('Incidencias y reclamos'),
                  AdminNavTile(
                    icon: Icons.flag_outlined,
                    title: 'Reclamos de usuarios',
                    subtitle: 'Reportes entre clientes y trabajadores',
                    badge: m.pendingReportsCount,
                    onTap: () => context.push(AppConstants.routeAdminReports),
                  ),
                  AdminNavTile(
                    icon: Icons.gavel_outlined,
                    title: 'Disputas de trabajos',
                    subtitle:
                        '${m.openDisputesCount} abiertas · ${m.underReviewDisputesCount} en revisión',
                    badge: m.openDisputesCount + m.underReviewDisputesCount,
                    onTap: () => context.push(AppConstants.routeAdminDisputes),
                  ),
                  AdminNavTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Errores y sincronización',
                    subtitle: 'Crashes, sync fallido y abuso',
                    badge: m.newErrorsCount + m.failedSyncCount + m.unresolvedAbuseCount,
                    onTap: () => context.push(AppConstants.routeAdminErrors),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionTitle('Configuración'),
                  AdminNavTile(
                    icon: Icons.tune_outlined,
                    title: 'Feature flags',
                    subtitle: 'Activar funciones por rol o versión',
                    onTap: () =>
                        context.push(AppConstants.routeAdminFeatureFlags),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.brandOrange,
            ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandOrangeSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandOrange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.brandOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count incidencia${count == 1 ? '' : 's'} requiere${count == 1 ? '' : 'n'} atención',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final AdminMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Usuarios', metrics.usersCount, Icons.person_outline),
      ('Trabajadores', metrics.workersCount, Icons.engineering_outlined),
      ('Trabajos', metrics.jobsCount, Icons.work_outline),
      ('Activos', metrics.activeJobsCount, Icons.play_circle_outline),
      ('Reclamos', metrics.pendingReportsCount, Icons.flag_outlined),
      ('Disputas', metrics.openDisputesCount, Icons.gavel),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items
          .map(
            (item) => Card(
              color: AppColors.brandOrangeSoft,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.$3, color: AppColors.brandOrange),
                    const Spacer(),
                    Text(
                      '${item.$2}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(item.$1),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

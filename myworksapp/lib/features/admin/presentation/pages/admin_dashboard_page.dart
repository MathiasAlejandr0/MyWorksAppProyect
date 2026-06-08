import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  final AdminRepository _repo = AdminRepository();
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
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Resumen de la plataforma',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _MetricsGrid(metrics: m!),
                  const SizedBox(height: 24),
                  _NavTile(
                    icon: Icons.people_outline,
                    title: 'Usuarios',
                    subtitle: '${m.usersCount} cuentas registradas',
                    onTap: () => context.push(AppConstants.routeAdminUsers),
                  ),
                  _NavTile(
                    icon: Icons.gavel_outlined,
                    title: 'Disputas',
                    subtitle: '${m.openDisputesCount} abiertas',
                    onTap: () => context.push(AppConstants.routeAdminDisputes),
                  ),
                ],
              ),
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
      ('Disputas abiertas', metrics.openDisputesCount, Icons.gavel),
      ('Reportes', metrics.reportsCount, Icons.flag_outlined),
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
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.brandOrange),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

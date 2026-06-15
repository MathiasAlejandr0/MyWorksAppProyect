import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../widgets/admin_search_field.dart';

class AdminJobsPage extends ConsumerStatefulWidget {
  const AdminJobsPage({super.key});

  @override
  ConsumerState<AdminJobsPage> createState() => _AdminJobsPageState();
}

class _AdminJobsPageState extends ConsumerState<AdminJobsPage> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  List<JobModel> _jobs = [];
  bool _loading = true;
  String _filter = 'all';
  String _search = '';

  static const _filters = [
    ('all', 'Todos'),
    ('pending', 'Pendientes'),
    ('accepted', 'Aceptados'),
    ('in_progress', 'En curso'),
    ('completed', 'Completados'),
    ('cancelled', 'Cancelados'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.listJobs(
        status: _filter == 'all' ? null : _filter,
        search: _search.isEmpty ? null : _search,
      );
      if (!mounted) return;
      setState(() {
        _jobs = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _cancelJob(JobModel job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar trabajo'),
        content: Text(
          '¿Cancelar el trabajo ${job.id.substring(0, 8)}… como administrador?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar trabajo'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _repo.updateJobStatus(job.id, AppConstants.jobStatusCancelled);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.brandOrange;
      case 'accepted':
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppColors.brandOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Trabajos')),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Buscar por dirección, ID o descripción…',
            onSearch: (q) {
              _search = q;
              _load();
            },
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: _filters
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f.$2),
                        selected: _filter == f.$1,
                        onSelected: (_) {
                          setState(() => _filter = f.$1);
                          _load();
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _jobs.isEmpty
                    ? const Center(child: Text('Sin trabajos'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: LayoutUtils.scrollPadding(
                            context,
                            top: AppSpacing.sm,
                          ),
                          itemCount: _jobs.length,
                          itemBuilder: (context, index) {
                            final job = _jobs[index];
                            final canCancel = job.status != 'completed' &&
                                job.status != 'cancelled';
                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  Icons.work_outline,
                                  color: _statusColor(job.status),
                                ),
                                title: Text(job.address),
                                subtitle: Text(
                                  '${job.status} · ${job.id.substring(0, 8)}…\n'
                                  'Cliente: ${job.userId.substring(0, 8)}…',
                                ),
                                isThreeLine: true,
                                onTap: () => context.push(
                                  '${AppConstants.routeAdminJobDetail}/${job.id}',
                                ),
                                trailing: canCancel
                                    ? IconButton(
                                        icon: const Icon(Icons.cancel_outlined),
                                        tooltip: 'Cancelar',
                                        onPressed: () => _cancelJob(job),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/services/admin_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../widgets/admin_search_field.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  List<AdminReportEntry> _reports = [];
  bool _loading = true;
  String _filter = 'pending';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.listReports(
        status: _filter == 'all' ? null : _filter,
        search: _search.isEmpty ? null : _search,
      );
      if (!mounted) return;
      setState(() {
        _reports = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e);
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }

  Future<void> _updateStatus(AdminReportEntry entry, String status) async {
    try {
      await _repo.updateReportStatus(entry.report.id, status);
      await AdminNotificationService.instance.notifyReportStatusChange(
        reporterId: entry.report.reporterId,
        reportedUserId: entry.report.reportedUserId,
        status: status,
        reportId: entry.report.id,
        reason: entry.report.reason,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reclamo marcado como $status')),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'reviewed':
        return 'En revisión';
      case 'resolved':
        return 'Resuelto';
      case 'dismissed':
        return 'Descartado';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.brandOrange;
      case 'reviewed':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Reclamos y reportes')),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Buscar por motivo o descripción…',
            onSearch: (q) {
              _search = q;
              _load();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pending', label: Text('Pendientes')),
                ButtonSegment(value: 'reviewed', label: Text('En revisión')),
                ButtonSegment(value: 'resolved', label: Text('Resueltos')),
                ButtonSegment(value: 'all', label: Text('Todos')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) {
                setState(() => _filter = s.first);
                _load();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? const Center(child: Text('Sin reclamos'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final entry = _reports[index];
                            final r = entry.report;
                            return Card(
                              child: ExpansionTile(
                                leading: Icon(
                                  Icons.flag_outlined,
                                  color: _statusColor(r.status),
                                ),
                                title: Text(r.reason),
                                subtitle: Text(
                                  '${entry.reporterName ?? r.reporterId} → '
                                  '${entry.reportedName ?? r.reportedUserId}\n'
                                  '${_statusLabel(r.status)}',
                                ),
                                children: [
                                  if (r.description != null &&
                                      r.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(r.description!),
                                      ),
                                    ),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (r.status == 'pending')
                                        TextButton(
                                          onPressed: () =>
                                              _updateStatus(entry, 'reviewed'),
                                          child: const Text('Marcar en revisión'),
                                        ),
                                      if (r.status != 'resolved')
                                        TextButton(
                                          onPressed: () =>
                                              _updateStatus(entry, 'resolved'),
                                          child: const Text('Resolver'),
                                        ),
                                      if (r.status != 'dismissed')
                                        TextButton(
                                          onPressed: () =>
                                              _updateStatus(entry, 'dismissed'),
                                          child: const Text('Descartar'),
                                        ),
                                    ],
                                  ),
                                ],
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

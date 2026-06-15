import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/models/dispute_model.dart';
import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/admin_notification_service.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/admin_search_field.dart';

class AdminDisputesPage extends ConsumerStatefulWidget {
  const AdminDisputesPage({super.key});

  @override
  ConsumerState<AdminDisputesPage> createState() => _AdminDisputesPageState();
}

class _AdminDisputesPageState extends ConsumerState<AdminDisputesPage> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  List<DisputeModel> _disputes = [];
  bool _loading = true;
  String _filter = 'open';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.listDisputes(
        status: _filter == 'all' ? null : _filter,
        search: _search.isEmpty ? null : _search,
      );
      if (!mounted) return;
      setState(() {
        _disputes = list;
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

  Future<void> _markUnderReview(DisputeModel dispute) async {
    try {
      await _repo.markDisputeUnderReview(dispute.id);
      final detail = await _repo.getJobDetail(dispute.jobId);
      if (detail != null) {
        await AdminNotificationService.instance.notifyDisputeUnderReview(
          userId: detail.job.userId,
          workerId: detail.job.workerId,
          jobId: dispute.jobId,
          disputeId: dispute.id,
        );
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disputa marcada en revisión')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _resolve(DisputeModel dispute) async {
    final admin = ref.read(authProvider).user;
    if (admin == null) return;

    final resolutionCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver disputa'),
        content: TextField(
          controller: resolutionCtrl,
          decoration: const InputDecoration(
            labelText: 'Resolución para las partes',
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resolver'),
          ),
        ],
      ),
    );
    final resolutionText = resolutionCtrl.text.trim();
    resolutionCtrl.dispose();
    if (ok != true || !mounted) return;

    try {
      final resolution = resolutionText.isEmpty
          ? 'Resuelta por administrador'
          : resolutionText;
      await DisputeService.instance.resolveDispute(
        disputeId: dispute.id,
        resolvedBy: admin.id,
        resolution: resolution,
      );
      final detail = await _repo.getJobDetail(dispute.jobId);
      if (detail != null) {
        await AdminNotificationService.instance.notifyDisputeResolved(
          userId: detail.job.userId,
          workerId: detail.job.workerId,
          disputeId: dispute.id,
          resolution: resolution,
        );
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Disputas')),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Buscar por motivo, descripción o ID de trabajo…',
            onSearch: (q) {
              _search = q;
              _load();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'open', label: Text('Abiertas')),
                ButtonSegment(
                  value: 'under_review',
                  label: Text('En revisión'),
                ),
                ButtonSegment(value: 'resolved', label: Text('Resueltas')),
                ButtonSegment(value: 'all', label: Text('Todas')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) {
                setState(() => _filter = s.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _disputes.isEmpty
                    ? const Center(child: Text('Sin disputas'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _disputes.length,
                          itemBuilder: (context, index) {
                            final d = _disputes[index];
                            return Card(
                              child: ListTile(
                                title: Text('Trabajo ${d.jobId.substring(0, 8)}…'),
                                subtitle: Text(
                                  '${d.reason} · ${d.status}\n${d.description ?? ''}',
                                ),
                                isThreeLine: true,
                                onTap: () => context.push(
                                  '${AppConstants.routeAdminJobDetail}/${d.jobId}',
                                ),
                                trailing: d.status == 'open' ||
                                        d.status == 'under_review'
                                    ? PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'review') {
                                            _markUnderReview(d);
                                          } else {
                                            _resolve(d);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          if (d.status == 'open')
                                            const PopupMenuItem(
                                              value: 'review',
                                              child: Text('Marcar en revisión'),
                                            ),
                                          const PopupMenuItem(
                                            value: 'resolve',
                                            child: Text('Resolver'),
                                          ),
                                        ],
                                      )
                                    : null,
                                leading: Icon(
                                  Icons.gavel,
                                  color: d.status == 'resolved'
                                      ? AppColors.success
                                      : AppColors.brandOrange,
                                ),
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

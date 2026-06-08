import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/models/dispute_model.dart';
import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminDisputesPage extends ConsumerStatefulWidget {
  const AdminDisputesPage({super.key});

  @override
  ConsumerState<AdminDisputesPage> createState() => _AdminDisputesPageState();
}

class _AdminDisputesPageState extends ConsumerState<AdminDisputesPage> {
  final AdminRepository _repo = AdminRepository();
  List<DisputeModel> _disputes = [];
  bool _loading = true;
  String _filter = 'open';

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
      await DisputeService.instance.resolveDispute(
        disputeId: dispute.id,
        resolvedBy: admin.id,
        resolution: resolutionText.isEmpty
            ? 'Resuelta por administrador'
            : resolutionText,
      );
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'open', label: Text('Abiertas')),
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
                          padding: const EdgeInsets.all(12),
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
                                  '${AppConstants.routeJobDetail}/${d.jobId}',
                                ),
                                trailing: d.status == 'open'
                                    ? TextButton(
                                        onPressed: () => _resolve(d),
                                        child: const Text('Resolver'),
                                      )
                                    : null,
                                leading: Icon(
                                  Icons.gavel,
                                  color: d.status == 'open'
                                      ? AppColors.brandOrange
                                      : AppColors.success,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myworksapp/core/utils/santiago_time.dart';

import '../../../../core/database/models/dispute_model.dart';
import '../../../../core/database/repositories/dispute_repository.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MyDisputesPage extends ConsumerStatefulWidget {
  const MyDisputesPage({super.key});

  @override
  ConsumerState<MyDisputesPage> createState() => _MyDisputesPageState();
}

class _MyDisputesPageState extends ConsumerState<MyDisputesPage> {
  final _repo = DisputeRepository();
  List<DisputeModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.listForParticipant(user.id);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorHandler.getErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Mis disputas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: 'No se pudieron cargar',
                  message: _error!,
                  actionLabel: 'Reintentar',
                  onAction: _load,
                )
              : _items.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.gavel_outlined,
                      title: 'Sin disputas',
                      message:
                          'Cuando abras o recibas una disputa, aparecerá aquí.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final dispute = _items[index];
                        final date = DateFormat('d MMM y', 'es_CL');
                        return Card(
                          child: ListTile(
                            title: Text(_status(dispute.status)),
                            subtitle: Text(
                              '${dispute.reason}\n${date.format(SantiagoTime.wall(dispute.createdAt))}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              '${AppConstants.routeJobDetail}/${dispute.jobId}',
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  String _status(String status) {
    switch (status) {
      case 'abierta':
        return 'Abierta';
      case 'en_revision':
        return 'En revisión';
      case 'resuelta':
        return 'Resuelta';
      default:
        return status;
    }
  }
}

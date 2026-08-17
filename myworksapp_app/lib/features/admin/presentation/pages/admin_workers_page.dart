import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../widgets/admin_search_field.dart';

class AdminWorkersPage extends ConsumerStatefulWidget {
  const AdminWorkersPage({super.key});

  @override
  ConsumerState<AdminWorkersPage> createState() => _AdminWorkersPageState();
}

class _AdminWorkersPageState extends ConsumerState<AdminWorkersPage> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  List<AdminWorkerEntry> _workers = [];
  bool _loading = true;
  String _search = '';
  bool? _availableFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.listWorkers(
        search: _search.isEmpty ? null : _search,
        availableOnly: _availableFilter,
      );
      if (!mounted) return;
      setState(() {
        _workers = list;
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

  Future<void> _toggleAvailability(AdminWorkerEntry entry) async {
    try {
      await _repo.setWorkerAvailability(
        entry.worker.userId,
        !entry.worker.isAvailable,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _setAccountStatus(AdminWorkerEntry entry, String status) async {
    try {
      await _repo.updateAccountStatus(entry.worker.userId, status);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entry.name}: $status')),
      );
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
      appBar: const AppGradientAppBar(title: Text('Trabajadores')),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Buscar por nombre, oficio o zona…',
            onSearch: (q) {
              _search = q;
              _load();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _availableFilter == null,
                  onSelected: (_) {
                    setState(() => _availableFilter = null);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Disponibles'),
                  selected: _availableFilter == true,
                  onSelected: (_) {
                    setState(() => _availableFilter = true);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('No disponibles'),
                  selected: _availableFilter == false,
                  onSelected: (_) {
                    setState(() => _availableFilter = false);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _workers.isEmpty
                        ? ListView(
                            children: const [
                              Center(child: Text('Sin trabajadores')),
                            ],
                          )
                        : ListView.builder(
                            padding: LayoutUtils.scrollPadding(
                              context,
                              top: AppSpacing.sm,
                            ),
                            itemCount: _workers.length,
                            itemBuilder: (context, index) {
                              final entry = _workers[index];
                              final w = entry.worker;
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.brandOrangeSoft,
                                    child: Text(
                                      entry.name.isNotEmpty
                                          ? entry.name[0]
                                          : '?',
                                    ),
                                  ),
                                  title: Text('${entry.name} · ${w.profession}'),
                                  subtitle: Text(
                                    '${entry.email ?? ''}\n'
                                    '${w.isAvailable ? 'Disponible' : 'No disponible'} · '
                                    '★ ${w.rating.toStringAsFixed(1)} · '
                                    '${entry.accountStatus}'
                                    '${w.workZone != null ? ' · ${w.workZone}' : ''}',
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'toggle_avail') {
                                        _toggleAvailability(entry);
                                      } else {
                                        _setAccountStatus(entry, v);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'toggle_avail',
                                        child: Text(
                                          w.isAvailable
                                              ? 'Marcar no disponible'
                                              : 'Marcar disponible',
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'active',
                                        child: Text('Activar cuenta'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'suspended',
                                        child: Text('Suspender cuenta'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'blocked',
                                        child: Text('Bloquear cuenta'),
                                      ),
                                    ],
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

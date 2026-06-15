import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../widgets/admin_search_field.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  List<UserModel> _users = [];
  bool _loading = true;
  String _search = '';
  String? _roleFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await _repo.listUsers(
        search: _search.isEmpty ? null : _search,
        role: _roleFilter,
        accountStatus: _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _users = users;
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

  Future<void> _setStatus(UserModel user, String status) async {
    await _repo.updateAccountStatus(user.id, status);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.name}: $status')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Usuarios')),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Buscar por nombre o email…',
            onSearch: (q) {
              _search = q;
              _load();
            },
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                FilterChip(
                  label: const Text('Todos los roles'),
                  selected: _roleFilter == null,
                  onSelected: (_) {
                    setState(() => _roleFilter = null);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Clientes'),
                  selected: _roleFilter == 'user',
                  onSelected: (_) {
                    setState(() => _roleFilter = 'user');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Trabajadores'),
                  selected: _roleFilter == 'worker',
                  onSelected: (_) {
                    setState(() => _roleFilter = 'worker');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Admin'),
                  selected: _roleFilter == 'admin',
                  onSelected: (_) {
                    setState(() => _roleFilter = 'admin');
                    _load();
                  },
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: const Text('Activos'),
                  selected: _statusFilter == 'active',
                  onSelected: (_) {
                    setState(() =>
                        _statusFilter = _statusFilter == 'active' ? null : 'active');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Suspendidos'),
                  selected: _statusFilter == 'suspended',
                  onSelected: (_) {
                    setState(() => _statusFilter =
                        _statusFilter == 'suspended' ? null : 'suspended');
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
                    child: _users.isEmpty
                        ? ListView(
                            children: const [
                              Center(child: Text('Sin usuarios')),
                            ],
                          )
                        : ListView.builder(
                            padding: LayoutUtils.scrollPadding(
                              context,
                              top: AppSpacing.sm,
                            ),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Card(
                                child: ListTile(
                                  title: Text(user.name),
                                  subtitle: Text(
                                    '${user.email} · ${user.role} · ${user.accountStatus}',
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) => _setStatus(user, v),
                                    itemBuilder: (ctx) => const [
                                      PopupMenuItem(
                                        value: 'active',
                                        child: Text('Activar'),
                                      ),
                                      PopupMenuItem(
                                        value: 'suspended',
                                        child: Text('Suspender'),
                                      ),
                                      PopupMenuItem(
                                        value: 'blocked',
                                        child: Text('Bloquear'),
                                      ),
                                    ],
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.brandOrangeSoft,
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0] : '?',
                                    ),
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

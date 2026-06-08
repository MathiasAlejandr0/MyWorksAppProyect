import 'package:flutter/material.dart';

import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminRepository _repo = AdminRepository();
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await _repo.listUsers();
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    child: ListTile(
                      title: Text(user.name),
                      subtitle: Text('${user.email} · ${user.role} · ${user.accountStatus}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) => _setStatus(user, v),
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'active', child: Text('Activar')),
                          PopupMenuItem(value: 'suspended', child: Text('Suspender')),
                          PopupMenuItem(value: 'blocked', child: Text('Bloquear')),
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.brandOrangeSoft,
                        child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

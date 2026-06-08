import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => _isDarkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          // Notificaciones
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificaciones'),
            subtitle: const Text('Recibir notificaciones de la app'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _saveNotifications,
            ),
          ),
          const Divider(),
          // Tema
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Modo Oscuro'),
            subtitle: const Text('Activar tema oscuro'),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _saveDarkMode,
            ),
          ),
          const Divider(),
          // Información
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Rol'),
              subtitle: Text(
                user.role == AppConstants.roleAdmin
                    ? 'Administrador'
                    : user.role == AppConstants.roleUser
                        ? 'Usuario'
                        : 'Trabajador',
              ),
            ),
            if (user.role == AppConstants.roleAdmin) ...[
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Panel administrador'),
                subtitle: const Text('Usuarios, disputas y métricas'),
                onTap: () => context.push(AppConstants.routeAdminDashboard),
              ),
            ],
            const Divider(),
          ],
          // Acerca de
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            subtitle: Text('${AppConstants.appBrandDisplayName} v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppConstants.appBrandDisplayName,
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 ${AppConstants.appBrandDisplayName}',
              );
            },
          ),
          const Divider(),
          // Cerrar sesión
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              context.go(AppConstants.routeWelcome);
            },
          ),
        ],
      ),
    );
  }
}


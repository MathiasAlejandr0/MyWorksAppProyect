import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../gdpr/presentation/pages/user_rights_page.dart';
import '../../../gdpr/presentation/pages/privacy_policy_page.dart';
import '../../../gdpr/presentation/pages/terms_page.dart';

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
      appBar: AppBar(
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
              subtitle: Text(user.role == AppConstants.roleUser ? 'Usuario' : 'Trabajador'),
            ),
            const Divider(),
          ],
          // Acerca de
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            subtitle: const Text('MyWorksApp v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'MyWorksApp',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 MyWorksApp',
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


import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/providers/theme_mode_provider.dart';
import '../../../../core/services/notification_opt_in.dart';
import '../../../../core/services/notification_permission_gateway.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _saveNotifications(bool value) async {
    if (!value) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', false);
      if (mounted) setState(() => _notificationsEnabled = false);
      return;
    }
    final outcome =
        await const NotificationOptIn(NotificationPermissionGateway()).enable();
    if (!mounted) return;
    if (outcome == NotificationPermissionOutcome.granted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', true);
      if (mounted) setState(() => _notificationsEnabled = true);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', false);
    if (!mounted) return;
    setState(() => _notificationsEnabled = false);
    if (outcome == NotificationPermissionOutcome.permanentlyDenied) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notificaciones bloqueadas'),
          content: const Text(
            'El permiso quedó desactivado en el sistema. Ábrelo en Ajustes para recibir avisos de trabajos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Abrir Ajustes'),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se activaron las notificaciones.')),
    );
  }

  Future<void> _saveDarkMode(bool value) async {
    await ref.read(themeModeProvider.notifier).setDarkMode(value);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: const AppGradientAppBar(
        title: Text('Configuración'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
            bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom),
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
              value: isDarkMode,
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
            subtitle: Text(
              _appVersion == null
                  ? AppConstants.appBrandDisplayName
                  : '${AppConstants.appBrandDisplayName} v$_appVersion',
            ),
            onTap: () async {
              final info = await PackageInfo.fromPlatform();
              if (!context.mounted) return;
              showAboutDialog(
                context: context,
                applicationName: AppConstants.appBrandDisplayName,
                applicationVersion: info.version,
                applicationLegalese:
                    '© ${DateTime.now().year} ${AppConstants.appBrandDisplayName}',
              );
            },
          ),
          const Divider(),
          // Cerrar sesión
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go(AppConstants.routeWelcome);
            },
          ),
        ],
      ),
    );
  }
}

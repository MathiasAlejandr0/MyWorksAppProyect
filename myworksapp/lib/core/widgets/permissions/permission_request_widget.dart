import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../design_system/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../design_system/primary_button.dart';

/// Widget para solicitar permisos con explicación previa
class PermissionRequestWidget extends StatelessWidget {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const PermissionRequestWidget({
    super.key,
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    this.onGranted,
    this.onDenied,
  });

  Future<void> _requestPermission(BuildContext context) async {
    final status = await permission.request();
    
    if (status.isGranted) {
      onGranted?.call();
    } else if (status.isPermanentlyDenied) {
      // Mostrar diálogo para ir a configuración
      _showSettingsDialog(context);
    } else {
      onDenied?.call();
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso Requerido'),
        content: const Text(
          'Este permiso es necesario para usar esta funcionalidad. '
          'Por favor, habilítalo en la configuración de la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grayMedium.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.primaryLight,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grayMedium,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Permitir',
            onPressed: () => _requestPermission(context),
            icon: Icons.check_circle,
          ),
          SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDenied?.call();
            },
            child: const Text('Ahora no'),
          ),
        ],
      ),
    );
  }
}


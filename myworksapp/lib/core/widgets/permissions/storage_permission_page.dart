import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../design_system/app_spacing.dart';
import '../../theme/app_theme.dart';
import 'permission_request_widget.dart';

/// Pantalla explicativa para solicitar permiso de almacenamiento
class StoragePermissionPage extends StatelessWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const StoragePermissionPage({
    super.key,
    this.onGranted,
    this.onDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permiso de Almacenamiento'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: PermissionRequestWidget(
            permission: Permission.storage,
            title: 'Necesitamos acceso al almacenamiento',
            description:
                'Para guardar y acceder a las fotos de los trabajos, necesitamos permiso de almacenamiento.\n\n'
                'Esto nos permite:\n\n'
                '• Guardar fotos del trabajo\n'
                '• Acceder a tu galería para seleccionar fotos\n'
                '• Mantener un historial visual de trabajos\n\n'
                'Solo accedemos a las fotos que tú seleccionas o tomas con la app.',
            icon: Icons.folder,
            onGranted: () {
              Navigator.pop(context);
              onGranted?.call();
            },
            onDenied: () {
              Navigator.pop(context);
              onDenied?.call();
            },
          ),
        ),
      ),
    );
  }
}


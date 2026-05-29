import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../design_system/app_spacing.dart';
import 'permission_request_widget.dart';

/// Pantalla explicativa para solicitar permiso de cámara
class CameraPermissionPage extends StatelessWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const CameraPermissionPage({
    super.key,
    this.onGranted,
    this.onDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Permiso de Cámara'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: PermissionRequestWidget(
            permission: Permission.camera,
            title: 'Necesitamos acceso a tu cámara',
            description:
                'Para poder tomar fotos de los trabajos realizados, necesitamos acceso a tu cámara.\n\n'
                'Esto nos permite:\n\n'
                '• Tomar fotos del trabajo en progreso\n'
                '• Documentar el trabajo completado\n'
                '• Compartir evidencia con el cliente\n\n'
                'Solo usamos la cámara cuando tú lo solicitas y nunca accedemos sin tu permiso.',
            icon: Icons.camera_alt,
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


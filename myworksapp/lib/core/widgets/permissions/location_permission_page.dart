import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../design_system/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../design_system/primary_button.dart';
import 'permission_request_widget.dart';

/// Pantalla explicativa para solicitar permiso de ubicación
class LocationPermissionPage extends StatelessWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const LocationPermissionPage({
    super.key,
    this.onGranted,
    this.onDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Permiso de Ubicación'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: PermissionRequestWidget(
            permission: Permission.location,
            title: 'Necesitamos tu ubicación',
            description:
                'Para ofrecerte el mejor servicio, necesitamos conocer tu ubicación. '
                'Esto nos permite:\n\n'
                '• Mostrar trabajadores cercanos\n'
                '• Calcular distancias precisas\n'
                '• Facilitar la llegada del trabajador\n\n'
                'Tu ubicación solo se usa para mejorar el servicio y nunca se comparte con terceros.',
            icon: Icons.location_on,
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


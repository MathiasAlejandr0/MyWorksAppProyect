import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_logger.dart';

/// Servicio para manejar permisos denegados de manera avanzada
class PermissionDeniedHandler {
  static final PermissionDeniedHandler instance = PermissionDeniedHandler._();
  PermissionDeniedHandler._();

  /// Maneja un permiso denegado con UX mejorada
  Future<void> handleDeniedPermission({
    required BuildContext context,
    required Permission permission,
    required String permissionName,
    String? fallbackMessage,
    VoidCallback? onFallback,
  }) async {
    final status = await permission.status;

    if (status.isGranted) {
      return; // Ya está concedido
    }

    if (status.isPermanentlyDenied) {
      await _showPermanentlyDeniedDialog(
        context: context,
        permissionName: permissionName,
        fallbackMessage: fallbackMessage,
        onFallback: onFallback,
      );
    } else if (status.isDenied) {
      await _showDeniedDialog(
        context: context,
        permissionName: permissionName,
        fallbackMessage: fallbackMessage,
        onFallback: onFallback,
      );
    }
  }

  /// Muestra diálogo para permiso denegado permanentemente
  Future<void> _showPermanentlyDeniedDialog({
    required BuildContext context,
    required String permissionName,
    String? fallbackMessage,
    VoidCallback? onFallback,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Permiso Requerido')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El permiso de $permissionName está deshabilitado permanentemente.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Para usar esta funcionalidad, necesitas habilitarlo manualmente en la configuración de la app.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            if (fallbackMessage != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Alternativa:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                fallbackMessage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          if (onFallback != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onFallback();
              },
              child: const Text('Usar Alternativa'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo para permiso denegado (no permanentemente)
  Future<void> _showDeniedDialog({
    required BuildContext context,
    required String permissionName,
    String? fallbackMessage,
    VoidCallback? onFallback,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso Denegado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('El permiso de $permissionName fue denegado.'),
            const SizedBox(height: 16),
            if (fallbackMessage != null) ...[
              const Text(
                'Alternativa:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(fallbackMessage),
            ],
          ],
        ),
        actions: [
          if (onFallback != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onFallback();
              },
              child: const Text('Usar Alternativa'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Abre la configuración de la app
  Future<void> _openAppSettings() async {
    try {
      await openAppSettings();
      AppLogger.i('Configuración de la app abierta');
    } catch (e) {
      AppLogger.e('Error al abrir configuración de la app', e);
    }
  }

  /// Verifica si un permiso está denegado permanentemente
  Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Obtiene mensaje de fallback según el tipo de permiso
  static String getFallbackMessage(Permission permission) {
    switch (permission) {
      case Permission.location:
        return 'Puedes ingresar la dirección manualmente en el formulario.';
      case Permission.camera:
        return 'Puedes seleccionar una foto desde tu galería.';
      case Permission.photos:
        return 'Puedes continuar sin adjuntar fotos desde la galería.';
      case Permission.storage:
        return 'Algunas funcionalidades pueden estar limitadas.';
      default:
        return 'Puedes continuar sin este permiso, pero algunas funcionalidades estarán limitadas.';
    }
  }
}


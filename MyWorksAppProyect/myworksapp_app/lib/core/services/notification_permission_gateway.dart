import 'package:permission_handler/permission_handler.dart';

import 'notification_opt_in.dart';

/// Permiso real del sistema. Android 13+ muestra POST_NOTIFICATIONS.
/// iOS muestra el diálogo de alertas. Si el usuario lo bloqueó, no vuelve
/// a preguntar: hay que abrir Ajustes.
class NotificationPermissionGateway implements NotificationPermissionClient {
  const NotificationPermissionGateway();

  @override
  Future<NotificationPermissionOutcome> request() async {
    final current = await Permission.notification.status;
    if (current.isGranted || current.isLimited || current.isProvisional) {
      return NotificationPermissionOutcome.granted;
    }
    if (current.isPermanentlyDenied || current.isRestricted) {
      return NotificationPermissionOutcome.permanentlyDenied;
    }
    final next = await Permission.notification.request();
    if (next.isGranted || next.isLimited || next.isProvisional) {
      return NotificationPermissionOutcome.granted;
    }
    if (next.isPermanentlyDenied || next.isRestricted) {
      return NotificationPermissionOutcome.permanentlyDenied;
    }
    return NotificationPermissionOutcome.denied;
  }
}

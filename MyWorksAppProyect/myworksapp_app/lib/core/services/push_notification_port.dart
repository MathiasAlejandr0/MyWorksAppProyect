import 'package:uuid/uuid.dart';

import '../database/models/notification_model.dart';
import 'notification_service.dart';

/// Puerto de notificaciones push (FCM / APNs).
///
/// Placeholder hasta integrar `firebase_messaging`. La implementación local
/// solo cubre init + banners locales sin token de dispositivo real.
abstract class PushNotificationPort {
  Future<void> initialize();
  Future<String?> getDeviceToken();
  Future<void> showLocal({required String title, required String body});
}

/// Implementación local-only: sin FCM.
///
/// Placeholder hasta FCM. Puede delegar a [NotificationService] local si
/// existe, sin romper si el plugin aún no está listo.
class LocalOnlyPushNotifications implements PushNotificationPort {
  LocalOnlyPushNotifications({NotificationService? notificationService})
      : _notificationService =
            notificationService ?? NotificationService.instance;

  final NotificationService _notificationService;

  @override
  Future<void> initialize() async {
    await _notificationService.initialize();
  }

  @override
  Future<String?> getDeviceToken() async {
    // Sin firebase_messaging: no hay token de dispositivo.
    return null;
  }

  @override
  Future<void> showLocal({
    required String title,
    required String body,
  }) async {
    // Solo banner local (showIncomingNotification no reinserta en DB).
    await _notificationService.showIncomingNotification(
      NotificationModel(
        id: const Uuid().v4(),
        userId: 'local',
        type: 'local_push',
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// Activar cuando se agregue firebase_messaging al pubspec.
class UnimplementedFcmPushNotifications implements PushNotificationPort {
  static const _hint =
      'Agrega firebase_messaging y reemplaza pushNotificationProvider.';

  @override
  Future<void> initialize() => throw UnimplementedError(_hint);

  @override
  Future<String?> getDeviceToken() => throw UnimplementedError(_hint);

  @override
  Future<void> showLocal({
    required String title,
    required String body,
  }) =>
      throw UnimplementedError(_hint);
}

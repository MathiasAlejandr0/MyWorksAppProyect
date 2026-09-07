import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_notification_port.dart';

/// Provider del puerto de push. Por defecto [LocalOnlyPushNotifications]
/// (sin FCM real).
///
/// Para activar FCM:
/// - Añadir `firebase_messaging` (y Firebase Core) al `pubspec.yaml`.
/// - Implementar el puerto (o reemplazar [UnimplementedFcmPushNotifications]).
/// - Cambiar este provider para devolver la impl FCM en lugar de local-only.
final pushNotificationProvider = Provider<PushNotificationPort>((ref) {
  return LocalOnlyPushNotifications();
});

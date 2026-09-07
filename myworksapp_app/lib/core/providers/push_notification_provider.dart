import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_notification_port.dart';

/// Provider del puerto de push. Por defecto [LocalOnlyPushNotifications]
/// (sin FCM). Override al integrar firebase_messaging.
final pushNotificationProvider = Provider<PushNotificationPort>((ref) {
  return LocalOnlyPushNotifications();
});

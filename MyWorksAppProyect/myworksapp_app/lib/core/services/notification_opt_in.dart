enum NotificationPermissionOutcome { granted, denied, permanentlyDenied }

/// Pide el permiso del sistema. En Android 13+ es POST_NOTIFICATIONS.
/// En iOS es el permiso de alertas. La prueba usa un doble, no el teléfono.
abstract class NotificationPermissionClient {
  Future<NotificationPermissionOutcome> request();
}

class NotificationOptIn {
  const NotificationOptIn(this.client);

  final NotificationPermissionClient client;

  Future<NotificationPermissionOutcome> enable() => client.request();
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:uuid/uuid.dart';

import '../database/repositories/notification_repository.dart';
import '../database/models/notification_model.dart';
import '../utils/app_logger.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  bool _isInitialized = false;

  NotificationService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Abrir',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      final ok = await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = ok == true;
    } catch (e) {
      _isInitialized = false;
      AppLogger.e('Error inicializando notificaciones', e);
    }
  }

  Future<bool> _bannersAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Manejar cuando se toca una notificación
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required String userId,
    required String type,
    String? relatedId,
  }) async {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      title: title,
      body: body,
      relatedId: relatedId,
      createdAt: DateTime.now(),
    );
    try {
      await _notificationRepository.createNotification(notification);
    } catch (e) {
      AppLogger.e('Error guardando notificación en Supabase', e);
    }

    await _showLocalBanner(
        title: title, body: body, id: notification.id.hashCode);
  }

  /// Avisa a otros usuarios (por ejemplo, a los profesionales de una
  /// categoría) con un solo INSERT. No muestra banner en este equipo: el
  /// aviso es para ellos, no para quien lo envía.
  Future<void> notifyUsers({
    required Iterable<String> userIds,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final now = DateTime.now();
    final notifications = userIds
        .where((id) => id.isNotEmpty)
        .toSet()
        .map(
          (userId) => NotificationModel(
            id: const Uuid().v4(),
            userId: userId,
            type: type,
            title: title,
            body: body,
            relatedId: relatedId,
            createdAt: now,
          ),
        )
        .toList();
    try {
      await _notificationRepository.createNotifications(notifications);
    } catch (e) {
      AppLogger.e('Error guardando notificaciones en Supabase', e);
    }
  }

  /// Muestra banner local para una notificación recibida por Realtime (sin reinsertar).
  Future<void> showIncomingNotification(NotificationModel notification) async {
    await _showLocalBanner(
      title: notification.title,
      body: notification.body,
      id: notification.id.hashCode,
    );
  }

  Future<void> _showLocalBanner({
    required String title,
    required String body,
    required int id,
  }) async {
    if (!_isInitialized) return;
    if (!await _bannersAllowed()) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'myworksapp_channel',
        'My Works App Notifications',
        channelDescription: 'Notificaciones de trabajos y mensajes',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const linuxDetails = LinuxNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
        linux: linuxDetails,
      );

      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      AppLogger.w('No se pudo mostrar notificación local', e);
    }
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String userId,
    required String type,
    String? relatedId,
  }) async {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      title: title,
      body: body,
      relatedId: relatedId,
      createdAt: DateTime.now(),
    );
    try {
      await _notificationRepository.createNotification(notification);
    } catch (e) {
      AppLogger.e('Error guardando notificación programada', e);
    }

    if (!_isInitialized) return;
    if (!await _bannersAllowed()) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'myworksapp_channel',
        'My Works App Notifications',
        channelDescription: 'Notificaciones programadas',
        importance: Importance.high,
        priority: Priority.high,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notifications.zonedSchedule(
        id: notification.id.hashCode,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      AppLogger.w('Error programando notificación local', e);
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    try {
      await _notifications.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    try {
      await _notifications.cancelAll();
    } catch (_) {}
  }
}

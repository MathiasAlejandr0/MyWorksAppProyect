import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../database/repositories/notification_repository.dart';
import '../database/models/notification_model.dart';
import '../utils/platform_support.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NotificationRepository _notificationRepository = NotificationRepository();
  bool _isInitialized = false;

  NotificationService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
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
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = ok == true;

      if (_isInitialized) {
        await _requestPermissions();
      }
    } catch (e) {
      _isInitialized = false;
      print('Error inicializando notificaciones: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
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
      print('Error guardando notificación en Supabase: $e');
    }

    await _showLocalBanner(title: title, body: body, id: notification.id.hashCode);
  }

  Future<void> _showLocalBanner({
    required String title,
    required String body,
    required int id,
  }) async {
    if (!_isInitialized) return;

    // En escritorio el plugin no siempre está disponible; las notificaciones in-app bastan.
    if (AppPlatform.isDesktopNative) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'myworksapp_channel',
        'My Works App Notifications',
        channelDescription: 'Notificaciones de trabajos y mensajes',
        importance: Importance.high,
        priority: Priority.high,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notifications.show(id, title, body, details);
    } catch (e) {
      print('Error mostrando notificación local: $e');
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
      print('Error guardando notificación programada: $e');
    }

    if (!_isInitialized || AppPlatform.isDesktopNative) return;

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
        notification.id.hashCode,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('Error programando notificación local: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    try {
      await _notifications.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    try {
      await _notifications.cancelAll();
    } catch (_) {}
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../database/repositories/notification_repository.dart';
import '../database/models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final NotificationRepository _notificationRepository = NotificationRepository();

  NotificationService._init();

  Future<void> initialize() async {
    try {
      // Inicializar timezone
      tz.initializeTimeZones();

      // Configuración para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuración para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Configuración para macOS
      const macosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: macosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Solicitar permisos
      await _requestPermissions();
    } catch (e) {
      // Si hay error en la inicialización (especialmente en macOS), continuar sin notificaciones
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
    // Puedes navegar a la pantalla correspondiente
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required String userId,
    required String type,
    String? relatedId,
  }) async {
    // Guardar en base de datos
    final notification = NotificationModel(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      title: title,
      body: body,
      relatedId: relatedId,
      createdAt: DateTime.now(),
    );
    await _notificationRepository.createNotification(notification);

    // Mostrar notificación local
    const androidDetails = AndroidNotificationDetails(
      'myworksapp_channel',
      'My Works App Notifications',
      channelDescription: 'Notificaciones de trabajos y mensajes',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notification.id.hashCode,
      title,
      body,
      details,
    );
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String userId,
    required String type,
    String? relatedId,
  }) async {
    // Guardar en base de datos
    final notification = NotificationModel(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      title: title,
      body: body,
      relatedId: relatedId,
      createdAt: DateTime.now(),
    );
    await _notificationRepository.createNotification(notification);

    const androidDetails = AndroidNotificationDetails(
      'myworksapp_channel',
      'My Works App Notifications',
      channelDescription: 'Notificaciones programadas',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
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
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}


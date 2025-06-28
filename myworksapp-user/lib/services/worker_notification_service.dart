import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import '../database/worker_database_helper.dart';
import '../models/notification_model.dart';

class WorkerNotificationService {
  static final WorkerNotificationService _instance =
      WorkerNotificationService._internal();
  factory WorkerNotificationService() => _instance;
  WorkerNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final WorkerDatabaseHelper _databaseHelper = WorkerDatabaseHelper();

  // Inicializar Firebase
  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Solicitar permisos de notificación
  Future<void> requestNotificationPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // print('User granted permission: ${settings.authorizationStatus}');
  }

  // Obtener token FCM
  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      // print('FCM Token: $token');
      return token;
    } catch (e) {
      // print('Error getting FCM token: $e');
      return null;
    }
  }

  // Configurar handlers de notificación
  void setupNotificationHandlers() {
    // Notificación cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // print('Got a message whilst in the foreground!');
      // print('Message data: ${message.data}');

      if (message.notification != null) {
        // print('Message also contained a notification: ${message.notification}');
        _handleForegroundNotification(message);
      }
    });

    // Notificación cuando la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // print('A new onMessageOpenedApp event was published!');
      _handleBackgroundNotification(message);
    });

    // Notificación cuando la app está cerrada
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        // print('App opened from terminated state');
        _handleTerminatedNotification(message);
      }
    });
  }

  // Manejar notificación en primer plano
  void _handleForegroundNotification(RemoteMessage message) {
    // Aquí puedes mostrar una notificación local o actualizar la UI
    // print('Handling foreground notification: ${message.notification?.title}');

    // Guardar notificación en la base de datos local
    _saveNotificationToDatabase(message);
  }

  // Manejar notificación en segundo plano
  void _handleBackgroundNotification(RemoteMessage message) {
    // print('Handling background notification: ${message.notification?.title}');
    // Navegar a la pantalla correspondiente
  }

  // Manejar notificación cuando la app está cerrada
  void _handleTerminatedNotification(RemoteMessage message) {
    // print('Handling terminated notification: ${message.notification?.title}');
    // Navegar a la pantalla correspondiente
  }

  // Guardar notificación en la base de datos local
  Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
    try {
      final notification = WorkerNotification(
        workerId: int.parse(message.data['workerId'] ?? '0'),
        title: message.notification?.title ?? 'Notificación',
        message: message.notification?.body ?? '',
        type: message.data['type'] ?? 'system',
        createdAt: DateTime.now(),
        data: message.data,
      );

      await _databaseHelper.insertNotification(notification);
    } catch (e) {
      // print('Error saving notification to database: $e');
    }
  }

  // Crear notificación local
  Future<void> createLocalNotification({
    required int workerId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = WorkerNotification(
        workerId: workerId,
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        data: data,
      );

      await _databaseHelper.insertNotification(notification);
    } catch (e) {
      // print('Error creating local notification: $e');
    }
  }

  // Obtener notificaciones del trabajador
  Future<List<WorkerNotification>> getWorkerNotifications(int workerId) async {
    try {
      return await _databaseHelper.getNotificationsByWorkerId(workerId);
    } catch (e) {
      // print('Error getting worker notifications: $e');
      return [];
    }
  }

  // Marcar notificación como leída
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _databaseHelper.markNotificationAsRead(notificationId);
    } catch (e) {
      // print('Error marking notification as read: $e');
    }
  }

  // Obtener conteo de notificaciones no leídas
  Future<int> getUnreadNotificationsCount(int workerId) async {
    try {
      return await _databaseHelper.getUnreadNotificationsCount(workerId);
    } catch (e) {
      // print('Error getting unread notifications count: $e');
      return 0;
    }
  }

  // Eliminar notificación
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _databaseHelper.deleteNotification(notificationId);
    } catch (e) {
      // print('Error deleting notification: $e');
    }
  }

  // Suscribirse a un tema (para notificaciones específicas)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      // print('Subscribed to topic: $topic');
    } catch (e) {
      // print('Error subscribing to topic: $e');
    }
  }

  // Desuscribirse de un tema
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      // print('Unsubscribed from topic: $topic');
    } catch (e) {
      // print('Error unsubscribing from topic: $e');
    }
  }

  // Configurar notificaciones para un trabajador específico
  Future<void> setupWorkerNotifications(int workerId) async {
    // Suscribirse al tema del trabajador
    await subscribeToTopic('worker_$workerId');

    // Suscribirse al tema general de trabajadores
    await subscribeToTopic('workers');
  }

  // Limpiar notificaciones del trabajador
  Future<void> clearWorkerNotifications(int workerId) async {
    try {
      final notifications = await getWorkerNotifications(workerId);
      for (var notification in notifications) {
        await deleteNotification(notification.id!);
      }
    } catch (e) {
      // print('Error clearing worker notifications: $e');
    }
  }
}

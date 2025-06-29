import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppCommunicationService {
  static final AppCommunicationService _instance =
      AppCommunicationService._internal();
  factory AppCommunicationService() => _instance;
  AppCommunicationService._internal();

  static const String _requestsKey = 'service_requests';
  static const String _workersKey = 'available_workers';

  // Guardar trabajador disponible para que la app de usuario lo vea
  Future<void> saveWorkerAvailability(Map<String, dynamic> workerData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workersJson = prefs.getString(_workersKey) ?? '[]';
      final workers = List<Map<String, dynamic>>.from(
          json.decode(workersJson).map((x) => Map<String, dynamic>.from(x)));

      // Actualizar o agregar trabajador
      final existingIndex =
          workers.indexWhere((w) => w['id'] == workerData['id']);
      if (existingIndex != -1) {
        workers[existingIndex] = workerData;
      } else {
        workers.add(workerData);
      }

      await prefs.setString(_workersKey, json.encode(workers));
    } catch (e) {
      debugPrint('Error saving worker availability: $e');
    }
  }

  // Obtener trabajadores disponibles desde la app de usuario
  Future<List<Map<String, dynamic>>> getAvailableWorkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workersJson = prefs.getString(_workersKey) ?? '[]';
      final workers = List<Map<String, dynamic>>.from(
          json.decode(workersJson).map((x) => Map<String, dynamic>.from(x)));
      return workers.where((w) => w['isAvailable'] == true).toList();
    } catch (e) {
      debugPrint('Error getting available workers: $e');
      return [];
    }
  }

  // Crear solicitud de servicio
  Future<void> createServiceRequest(Map<String, dynamic> requestData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getString(_requestsKey) ?? '[]';
      final requests = List<Map<String, dynamic>>.from(
          json.decode(requestsJson).map((x) => Map<String, dynamic>.from(x)));

      // Agregar nueva solicitud
      requestData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      requestData['createdAt'] = DateTime.now().toIso8601String();
      requests.add(requestData);

      await prefs.setString(_requestsKey, json.encode(requests));

      // Crear notificación local para el trabajador
      await _createLocalNotification(requestData);
    } catch (e) {
      debugPrint('Error creating service request: $e');
    }
  }

  // Obtener solicitudes de un trabajador
  Future<List<Map<String, dynamic>>> getWorkerRequests(int workerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getString(_requestsKey) ?? '[]';
      final requests = List<Map<String, dynamic>>.from(
          json.decode(requestsJson).map((x) => Map<String, dynamic>.from(x)));
      return requests
          .where((r) => r['professionalId'] == workerId.toString())
          .toList();
    } catch (e) {
      debugPrint('Error getting worker requests: $e');
      return [];
    }
  }

  // Crear notificación local
  Future<void> _createLocalNotification(
      Map<String, dynamic> requestData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsKey = 'notifications_${requestData['professionalId']}';
      final notificationsJson = prefs.getString(notificationsKey) ?? '[]';
      final notifications = List<Map<String, dynamic>>.from(json
          .decode(notificationsJson)
          .map((x) => Map<String, dynamic>.from(x)));

      notifications.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'Nueva solicitud de servicio',
        'message':
            'Tienes una nueva solicitud de ${requestData['serviceName']}',
        'type': 'service_request',
        'data': requestData,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await prefs.setString(notificationsKey, json.encode(notifications));
    } catch (e) {
      debugPrint('Error creating local notification: $e');
    }
  }

  // Obtener notificaciones de un trabajador
  Future<List<Map<String, dynamic>>> getWorkerNotifications(
      int workerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsKey = 'notifications_$workerId';
      final notificationsJson = prefs.getString(notificationsKey) ?? '[]';
      final notifications = List<Map<String, dynamic>>.from(json
          .decode(notificationsJson)
          .map((x) => Map<String, dynamic>.from(x)));
      return notifications;
    } catch (e) {
      debugPrint('Error getting worker notifications: $e');
      return [];
    }
  }

  // Marcar notificación como leída
  Future<void> markNotificationAsRead(
      int workerId, String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsKey = 'notifications_$workerId';
      final notificationsJson = prefs.getString(notificationsKey) ?? '[]';
      final notifications = List<Map<String, dynamic>>.from(json
          .decode(notificationsJson)
          .map((x) => Map<String, dynamic>.from(x)));

      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['isRead'] = true;
        await prefs.setString(notificationsKey, json.encode(notifications));
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Obtener conteo de notificaciones no leídas
  Future<int> getUnreadNotificationsCount(int workerId) async {
    try {
      final notifications = await getWorkerNotifications(workerId);
      return notifications.where((n) => n['isRead'] == false).length;
    } catch (e) {
      debugPrint('Error getting unread notifications count: $e');
      return 0;
    }
  }
}

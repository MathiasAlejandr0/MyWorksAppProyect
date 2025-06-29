import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker.dart';

class WorkerCommunicationService {
  static final WorkerCommunicationService _instance =
      WorkerCommunicationService._internal();
  factory WorkerCommunicationService() => _instance;
  WorkerCommunicationService._internal();

  static const String _availabilityKey = 'worker_availability';
  static const String _requestsKey = 'worker_requests';
  static const String _notificationsKey = 'worker_notifications';

  // Guardar disponibilidad del trabajador para que la app de usuario lo vea
  Future<void> saveWorkerAvailability(Worker worker) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workerData = {
        'id': worker.id,
        'name': worker.name,
        'email': worker.email,
        'phone': worker.phone,
        'profession': worker.profession,
        'isAvailable': worker.isAvailable,
        'hourlyRate': worker.hourlyRate,
        'description': worker.description,
        'address': worker.address,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_availabilityKey, json.encode(workerData));
    } catch (e) {
      debugPrint('Error saving worker availability: $e');
    }
  }

  // Obtener solicitudes del trabajador
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

  // Obtener notificaciones del trabajador
  Future<List<Map<String, dynamic>>> getWorkerNotifications(
      int workerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsKey = '${_notificationsKey}_$workerId';
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
      final notificationsKey = '${_notificationsKey}_$workerId';
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

  // Crear notificación local (simulada)
  Future<void> createLocalNotification({
    required int workerId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsKey = '${_notificationsKey}_$workerId';
      final notificationsJson = prefs.getString(notificationsKey) ?? '[]';
      final notifications = List<Map<String, dynamic>>.from(json
          .decode(notificationsJson)
          .map((x) => Map<String, dynamic>.from(x)));

      notifications.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await prefs.setString(notificationsKey, json.encode(notifications));
    } catch (e) {
      debugPrint('Error creating local notification: $e');
    }
  }
}

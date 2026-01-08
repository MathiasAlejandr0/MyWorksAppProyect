import '../database_helper.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createNotification(NotificationModel notification) async {
    final db = await _dbHelper.database;
    await db.insert('notifications', notification.toMap());
  }

  Future<List<NotificationModel>> getNotificationsByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => NotificationModel.fromMap(map)).toList();
  }

  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notifications',
      where: 'userId = ? AND isRead = 0',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => NotificationModel.fromMap(map)).toList();
  }

  Future<void> markAsRead(String notificationId) async {
    final db = await _dbHelper.database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<void> markAllAsRead(String userId) async {
    final db = await _dbHelper.database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<int> getUnreadCount(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE userId = ? AND isRead = 0',
      [userId],
    );
    return result.first['count'] as int;
  }

  Future<void> deleteNotification(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}


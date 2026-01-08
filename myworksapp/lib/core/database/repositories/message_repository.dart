import '../database_helper.dart';
import '../models/message_model.dart';

class MessageRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createMessage(MessageModel message) async {
    final db = await _dbHelper.database;
    await db.insert('messages', message.toMap());
  }

  Future<List<MessageModel>> getMessagesByJobId(String jobId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'messages',
      where: 'jobId = ?',
      whereArgs: [jobId],
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => MessageModel.fromMap(map)).toList();
  }

  Future<List<MessageModel>> getUnreadMessages(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'messages',
      where: 'receiverId = ? AND isRead = 0',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => MessageModel.fromMap(map)).toList();
  }

  Future<void> markAsRead(String messageId) async {
    final db = await _dbHelper.database;
    await db.update(
      'messages',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> markAllAsRead(String jobId, String userId) async {
    final db = await _dbHelper.database;
    await db.update(
      'messages',
      {'isRead': 1},
      where: 'jobId = ? AND receiverId = ?',
      whereArgs: [jobId, userId],
    );
  }

  Future<int> getUnreadCount(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE receiverId = ? AND isRead = 0',
      [userId],
    );
    return result.first['count'] as int;
  }

  /// Obtiene todos los mensajes de un usuario (como remitente o receptor)
  Future<List<MessageModel>> getMessagesByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'messages',
      where: 'senderId = ? OR receiverId = ?',
      whereArgs: [userId, userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => MessageModel.fromMap(map)).toList();
  }
}


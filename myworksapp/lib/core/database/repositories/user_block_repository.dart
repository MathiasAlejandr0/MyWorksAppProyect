import '../database_helper.dart';
import '../models/user_block_model.dart';

class UserBlockRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createBlock(UserBlockModel block) async {
    final db = await _dbHelper.database;
    try {
      await db.insert('user_blocks', block.toMap());
    } catch (e) {
      // Si ya existe el bloqueo (UNIQUE constraint), ignorar
      // Esto evita errores si se intenta bloquear dos veces
    }
  }

  Future<bool> isBlocked(String blockerId, String blockedUserId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'user_blocks',
      where: 'blockerId = ? AND blockedUserId = ?',
      whereArgs: [blockerId, blockedUserId],
    );
    return maps.isNotEmpty;
  }

  Future<List<String>> getBlockedUserIds(String blockerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'user_blocks',
      where: 'blockerId = ?',
      whereArgs: [blockerId],
    );
    return maps.map((map) => map['blockedUserId'] as String).toList();
  }

  Future<void> removeBlock(String blockerId, String blockedUserId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'user_blocks',
      where: 'blockerId = ? AND blockedUserId = ?',
      whereArgs: [blockerId, blockedUserId],
    );
  }
}


import '../database_helper.dart';
import '../models/password_reset_code_model.dart';
import 'package:uuid/uuid.dart';

class PasswordResetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Crea un código de recuperación
  Future<String> createResetCode({
    required String userId,
    required String email,
    required String code,
  }) async {
    final db = await _dbHelper.database;
    final id = const Uuid().v4();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15)); // Código válido por 15 minutos
    
    final resetCode = PasswordResetCodeModel(
      id: id,
      userId: userId,
      code: code,
      email: email,
      expiresAt: expiresAt,
      isUsed: false,
      createdAt: DateTime.now(),
    );

    await db.insert('password_reset_codes', resetCode.toMap());
    return id;
  }

  /// Valida un código de recuperación
  Future<PasswordResetCodeModel?> validateCode({
    required String email,
    required String code,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'password_reset_codes',
      where: 'email = ? AND code = ? AND isUsed = 0',
      whereArgs: [email.toLowerCase().trim(), code],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final resetCode = PasswordResetCodeModel.fromMap(maps.first);
    
    // Verificar si está expirado
    if (resetCode.isExpired) {
      return null;
    }

    return resetCode;
  }

  /// Marca un código como usado
  Future<void> markCodeAsUsed(String codeId) async {
    final db = await _dbHelper.database;
    await db.update(
      'password_reset_codes',
      {'isUsed': 1},
      where: 'id = ?',
      whereArgs: [codeId],
    );
  }

  /// Elimina códigos expirados (limpieza)
  Future<void> deleteExpiredCodes() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.delete(
      'password_reset_codes',
      where: 'expiresAt < ?',
      whereArgs: [now],
    );
  }

  /// Elimina todos los códigos de un usuario (para invalidar códigos anteriores)
  Future<void> invalidateUserCodes(String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'password_reset_codes',
      where: 'userId = ? AND isUsed = 0',
      whereArgs: [userId],
    );
  }
}


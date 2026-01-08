import '../database_helper.dart';
import '../models/user_consent_model.dart';

/// Repositorio para gestionar consentimientos GDPR
class UserConsentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Crea un nuevo consentimiento
  Future<void> createConsent(UserConsentModel consent) async {
    final db = await _dbHelper.database;
    await db.insert('user_consents', consent.toMap());
  }

  /// Obtiene el consentimiento más reciente de un usuario
  Future<UserConsentModel?> getLatestConsent(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'user_consents',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'acceptedAt DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserConsentModel.fromMap(maps.first);
  }

  /// Verifica si un usuario ha aceptado la versión actual de los términos
  Future<bool> hasAcceptedCurrentVersion(String userId, String currentVersion) async {
    final latest = await getLatestConsent(userId);
    if (latest == null) return false;
    return latest.accepted && latest.consentVersion == currentVersion;
  }

  /// Obtiene todos los consentimientos de un usuario (historial)
  Future<List<UserConsentModel>> getUserConsents(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'user_consents',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'acceptedAt DESC',
    );
    return maps.map((map) => UserConsentModel.fromMap(map)).toList();
  }

  /// Elimina todos los consentimientos de un usuario (GDPR - derecho al olvido)
  Future<void> deleteUserConsents(String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'user_consents',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}


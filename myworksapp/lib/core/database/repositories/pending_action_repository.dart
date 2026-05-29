import '../database_helper.dart';
import '../models/pending_action_model.dart';
import 'package:uuid/uuid.dart';

/// Repositorio para acciones pendientes de sincronización (offline-first)
class PendingActionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Crea una acción pendiente
  Future<String> createPendingAction({
    required String userId,
    required String actionType,
    required String entityType,
    String? entityId,
    required Map<String, dynamic> data,
  }) async {
    final db = await _dbHelper.database;
    final id = const Uuid().v4();
    final now = DateTime.now();

    final pendingAction = PendingActionModel(
      id: id,
      userId: userId,
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      data: _encodeData(data),
      status: 'pending_sync',
      retryCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('pending_actions', pendingAction.toMap());
    return id;
  }

  /// Obtiene todas las acciones pendientes de un usuario
  Future<List<PendingActionModel>> getPendingActions(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'pending_actions',
      where: 'userId = ? AND status IN (?, ?)',
      whereArgs: [userId, 'pending_sync', 'failed'],
      orderBy: 'createdAt ASC',
    );

    return maps.map((map) => PendingActionModel.fromMap(map)).toList();
  }

  /// Actualiza el estado de una acción
  Future<void> updateActionStatus({
    required String actionId,
    required String status,
    String? errorMessage,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'pending_actions',
      {
        'status': status,
        'errorMessage': errorMessage,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [actionId],
    );
  }

  /// Incrementa el contador de reintentos
  Future<void> incrementRetryCount(String actionId) async {
    final db = await _dbHelper.database;
    final action = await getActionById(actionId);
    if (action != null) {
      await db.update(
        'pending_actions',
        {
          'retryCount': action.retryCount + 1,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [actionId],
      );
    }
  }

  /// Establece el contador de reintentos a un valor específico
  Future<void> setRetryCount(String actionId, int newCount) async {
    final db = await _dbHelper.database;
    await db.update(
      'pending_actions',
      {
        'retryCount': newCount,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [actionId],
    );
  }

  /// Actualiza el estado de una acción
  Future<void> updateStatus(String actionId, String status) async {
    final db = await _dbHelper.database;
    await db.update(
      'pending_actions',
      {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [actionId],
    );
  }

  /// Actualiza el mensaje de error
  Future<void> updateErrorMessage(String actionId, String? errorMessage) async {
    final db = await _dbHelper.database;
    await db.update(
      'pending_actions',
      {
        'errorMessage': errorMessage,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [actionId],
    );
  }

  /// Obtiene una acción por ID (alias para compatibilidad)
  Future<PendingActionModel?> getPendingActionById(String actionId) async {
    return await getActionById(actionId);
  }

  /// Obtiene una acción por ID
  Future<PendingActionModel?> getActionById(String actionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'pending_actions',
      where: 'id = ?',
      whereArgs: [actionId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return PendingActionModel.fromMap(maps.first);
  }

  /// Elimina una acción (después de sincronizar exitosamente)
  Future<void> deleteAction(String actionId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'pending_actions',
      where: 'id = ?',
      whereArgs: [actionId],
    );
  }

  /// Elimina acciones antiguas sincronizadas (limpieza)
  Future<void> deleteSyncedActions({int daysOld = 7}) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    await db.delete(
      'pending_actions',
      where: 'status = ? AND updatedAt < ?',
      whereArgs: ['synced', cutoffDate.toIso8601String()],
    );
  }

  /// Codifica datos a JSON string
  String _encodeData(Map<String, dynamic> data) {
    // En producción, usar jsonEncode de dart:convert
    // Por ahora, retornamos un string simple
    return data.toString();
  }

}


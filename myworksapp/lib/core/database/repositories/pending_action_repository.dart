import '../models/pending_action_model.dart';
import '../supabase_db.dart';
import 'package:uuid/uuid.dart';

/// Repositorio para acciones pendientes de sincronización.
class PendingActionRepository {
  static const String _table = 'pending_actions';

  Future<String> createPendingAction({
    required String userId,
    required String actionType,
    required String entityType,
    String? entityId,
    required Map<String, dynamic> data,
  }) async {
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

    await supabase.from(_table).insert(pendingAction.toMap());
    return id;
  }

  Future<List<PendingActionModel>> getPendingActions(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('userId', userId)
        .inFilter('status', ['pending_sync', 'failed'])
        .order('createdAt', ascending: true);
    return rows
        .map<PendingActionModel>((m) => PendingActionModel.fromMap(m))
        .toList();
  }

  Future<void> updateActionStatus({
    required String actionId,
    required String status,
    String? errorMessage,
  }) async {
    await supabase.from(_table).update({
      'status': status,
      'errorMessage': errorMessage,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', actionId);
  }

  Future<void> incrementRetryCount(String actionId) async {
    final action = await getActionById(actionId);
    if (action != null) {
      await supabase.from(_table).update({
        'retryCount': action.retryCount + 1,
        'updatedAt': DateTime.now().toIso8601String(),
      }).eq('id', actionId);
    }
  }

  Future<void> setRetryCount(String actionId, int newCount) async {
    await supabase.from(_table).update({
      'retryCount': newCount,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', actionId);
  }

  Future<void> updateStatus(String actionId, String status) async {
    await supabase.from(_table).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', actionId);
  }

  Future<void> updateErrorMessage(String actionId, String? errorMessage) async {
    await supabase.from(_table).update({
      'errorMessage': errorMessage,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', actionId);
  }

  Future<PendingActionModel?> getPendingActionById(String actionId) async {
    return await getActionById(actionId);
  }

  Future<PendingActionModel?> getActionById(String actionId) async {
    final row =
        await supabase.from(_table).select().eq('id', actionId).maybeSingle();
    if (row == null) return null;
    return PendingActionModel.fromMap(row);
  }

  Future<void> deleteAction(String actionId) async {
    await supabase.from(_table).delete().eq('id', actionId);
  }

  Future<void> deleteSyncedActions({int daysOld = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    await supabase
        .from(_table)
        .delete()
        .eq('status', 'synced')
        .lt('updatedAt', cutoffDate.toIso8601String());
  }

  String _encodeData(Map<String, dynamic> data) {
    return data.toString();
  }
}

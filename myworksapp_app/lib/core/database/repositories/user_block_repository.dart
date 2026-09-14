import '../models/user_block_model.dart';
import '../supabase_db.dart';

class UserBlockRepository {
  static const String _table = 'bloqueos_usuario';

  Future<void> createBlock(UserBlockModel block) async {
    try {
      await supabase.from(_table).insert(block.toMap());
    } catch (e) {
      // Si ya existe el bloqueo (UNIQUE constraint), ignorar.
    }
  }

  Future<bool> isBlocked(String blockerId, String blockedUserId) async {
    final rows = await supabase
        .from(_table)
        .select('id')
        .eq('id_bloqueador', blockerId)
        .eq('id_bloqueado', blockedUserId);
    return rows.isNotEmpty;
  }

  Future<List<String>> getBlockedUserIds(String blockerId) async {
    final rows = await supabase
        .from(_table)
        .select('id_bloqueado')
        .eq('id_bloqueador', blockerId);
    return rows.map<String>((m) => m['id_bloqueado'] as String).toList();
  }

  Future<void> removeBlock(String blockerId, String blockedUserId) async {
    await supabase
        .from(_table)
        .delete()
        .eq('id_bloqueador', blockerId)
        .eq('id_bloqueado', blockedUserId);
  }
}

import '../models/user_block_model.dart';
import '../supabase_db.dart';

class UserBlockRepository {
  static const String _table = 'user_blocks';

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
        .eq('blockerId', blockerId)
        .eq('blockedUserId', blockedUserId);
    return rows.isNotEmpty;
  }

  Future<List<String>> getBlockedUserIds(String blockerId) async {
    final rows = await supabase
        .from(_table)
        .select('blockedUserId')
        .eq('blockerId', blockerId);
    return rows.map<String>((m) => m['blockedUserId'] as String).toList();
  }

  Future<void> removeBlock(String blockerId, String blockedUserId) async {
    await supabase
        .from(_table)
        .delete()
        .eq('blockerId', blockerId)
        .eq('blockedUserId', blockedUserId);
  }
}

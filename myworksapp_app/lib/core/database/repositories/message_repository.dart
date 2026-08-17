import '../models/message_model.dart';
import '../supabase_db.dart';

class MessageRepository {
  static const String _table = 'messages';

  Future<void> createMessage(MessageModel message) async {
    await supabase.from(_table).insert(message.toMap());
  }

  Future<List<MessageModel>> getMessagesByJobId(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('jobId', jobId)
        .order('createdAt', ascending: true);
    return rows.map<MessageModel>((m) => MessageModel.fromMap(m)).toList();
  }

  Future<List<MessageModel>> getUnreadMessages(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('receiverId', userId)
        .eq('isRead', 0)
        .order('createdAt', ascending: false);
    return rows.map<MessageModel>((m) => MessageModel.fromMap(m)).toList();
  }

  Future<void> markAsRead(String messageId) async {
    await supabase.from(_table).update({'isRead': 1}).eq('id', messageId);
  }

  Future<void> markAllAsRead(String jobId, String userId) async {
    await supabase
        .from(_table)
        .update({'isRead': 1})
        .eq('jobId', jobId)
        .eq('receiverId', userId);
  }

  Future<int> getUnreadCount(String userId) async {
    final rows = await supabase
        .from(_table)
        .select('id')
        .eq('receiverId', userId)
        .eq('isRead', 0);
    return rows.length;
  }

  /// Obtiene todos los mensajes de un usuario (como remitente o receptor)
  Future<List<MessageModel>> getMessagesByUserId(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .or('senderId.eq.$userId,receiverId.eq.$userId')
        .order('createdAt', ascending: false);
    return rows.map<MessageModel>((m) => MessageModel.fromMap(m)).toList();
  }
}

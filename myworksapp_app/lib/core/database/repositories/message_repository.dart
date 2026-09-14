import '../models/message_model.dart';
import '../supabase_db.dart';

class MessageRepository {
  static const String _table = 'mensajes';

  Future<void> createMessage(MessageModel message) async {
    await supabase.from(_table).insert(message.toMap());
  }

  Future<List<MessageModel>> getMessagesByJobId(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_trabajo', jobId)
        .order('creado_en', ascending: true);
    return rows.map<MessageModel>((m) => MessageModel.fromMap(m)).toList();
  }

  Future<List<MessageModel>> getUnreadMessages(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_destinatario', userId)
        .eq('leido', 0)
        .order('creado_en', ascending: false);
    return rows.map<MessageModel>((m) => MessageModel.fromMap(m)).toList();
  }

  Future<void> markAsRead(String messageId) async {
    await supabase.from(_table).update({'leido': 1}).eq('id', messageId);
  }

  Future<void> markAllAsRead(String jobId, String userId) async {
    await supabase
        .from(_table)
        .update({'leido': 1})
        .eq('id_trabajo', jobId)
        .eq('id_destinatario', userId);
  }

  Future<int> getUnreadCount(String userId) async {
    final rows = await supabase
        .from(_table)
        .select('id')
        .eq('id_destinatario', userId)
        .eq('leido', 0);
    return rows.length;
  }

  /// Obtiene todos los mensajes de un usuario (como remitente o receptor)
  Future<List<MessageModel>> getMessagesByUserId(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .or('id_remitente.eq.$userId,id_destinatario.eq.$userId')
        .order('creado_en', ascending: false);
    return rows.map<MessageModel>((m) => MessageModel.fromMap(m)).toList();
  }
}

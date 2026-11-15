import '../../../core/database/models/message_model.dart';

/// Último mensaje de un trabajo, para la bandeja de chat.
class ConversationPreview {
  const ConversationPreview({
    required this.jobId,
    required this.preview,
    required this.lastAt,
    required this.unread,
  });

  final String jobId;
  final String preview;
  final DateTime lastAt;
  final int unread;
}

/// Agrupa mensajes por trabajo. El más reciente queda primero.
List<ConversationPreview> groupConversations(
  List<MessageModel> messages,
  String userId,
) {
  final byJob = <String, List<MessageModel>>{};
  for (final message in messages) {
    byJob.putIfAbsent(message.jobId, () => []).add(message);
  }

  final previews = byJob.entries.map((entry) {
    final sorted = [...entry.value]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latest = sorted.first;
    final unread = sorted
        .where((message) => message.receiverId == userId && !message.isRead)
        .length;
    final text = latest.content.trim();
    return ConversationPreview(
      jobId: entry.key,
      preview: text.isEmpty ? 'Mensaje' : text,
      lastAt: latest.createdAt,
      unread: unread,
    );
  }).toList()
    ..sort((a, b) => b.lastAt.compareTo(a.lastAt));

  return previews;
}

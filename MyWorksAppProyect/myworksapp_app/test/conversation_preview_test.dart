import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/message_model.dart';
import 'package:myworksapp/features/chat/domain/conversation_preview.dart';

MessageModel _message({
  required String id,
  required String jobId,
  required String sender,
  required String receiver,
  required String content,
  required DateTime at,
  bool read = false,
}) {
  return MessageModel(
    id: id,
    jobId: jobId,
    senderId: sender,
    receiverId: receiver,
    content: content,
    isRead: read,
    createdAt: at,
  );
}

void main() {
  test('agrupa por trabajo, deja el más reciente primero y cuenta no leídos',
      () {
    const me = 'cliente-1';
    final previews = groupConversations([
      _message(
        id: '1',
        jobId: 'job-a',
        sender: 'trabajador',
        receiver: me,
        content: 'Voy en camino',
        at: DateTime.utc(2026, 11, 1, 10),
      ),
      _message(
        id: '2',
        jobId: 'job-b',
        sender: me,
        receiver: 'otro',
        content: 'Hola',
        at: DateTime.utc(2026, 11, 2, 9),
        read: true,
      ),
      _message(
        id: '3',
        jobId: 'job-a',
        sender: 'trabajador',
        receiver: me,
        content: 'Llegué',
        at: DateTime.utc(2026, 11, 2, 12),
      ),
    ], me);

    expect(previews.map((item) => item.jobId).toList(), ['job-a', 'job-b']);
    expect(previews.first.preview, 'Llegué');
    expect(previews.first.unread, 2);
    expect(previews.last.unread, 0);
  });

  test('un mensaje vacío se muestra como Mensaje', () {
    final previews = groupConversations([
      _message(
        id: '1',
        jobId: 'job-a',
        sender: 'a',
        receiver: 'b',
        content: '   ',
        at: DateTime.utc(2026, 1, 1),
      ),
    ], 'b');

    expect(previews.single.preview, 'Mensaje');
    expect(previews.single.unread, 1);
  });
}

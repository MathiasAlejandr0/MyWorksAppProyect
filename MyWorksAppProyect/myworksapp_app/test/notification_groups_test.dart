import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/notification_model.dart';
import 'package:myworksapp/features/notifications/domain/notification_groups.dart';

NotificationModel _notice({
  required String id,
  required DateTime at,
  String? relatedId,
  bool read = false,
}) {
  return NotificationModel(
    id: id,
    userId: 'u',
    type: 'job_accepted',
    title: 'Aviso $id',
    body: 'cuerpo',
    relatedId: relatedId,
    isRead: read,
    createdAt: at,
  );
}

void main() {
  test('agrupa por trabajo y deja sueltos en Generales', () {
    final folders = groupNotificationsByJob(
      [
        _notice(id: '1', at: DateTime.utc(2026, 11, 19, 15), relatedId: 'job-a'),
        _notice(id: '3', at: DateTime.utc(2026, 11, 19, 14)),
        _notice(
          id: '2',
          at: DateTime.utc(2026, 11, 19, 16),
          relatedId: 'job-a',
          read: true,
        ),
      ],
      jobTitles: {'job-a': 'Fuga en la cocina'},
    );

    expect(folders.first.title, 'Fuga en la cocina');
    expect(folders.first.unreadCount, 1);
    expect(folders.first.items.map((item) => item.id), ['2', '1']);
    expect(folders[1].title, 'Generales');
    expect(folders[1].key, generalNoticesKey);
  });

  test('un trabajo sin nombre se llama Pedido', () {
    final folders = groupNotificationsByJob(
      [
        _notice(id: '1', at: DateTime.utc(2026, 11, 19), relatedId: 'job-z'),
      ],
    );
    expect(folders.single.title, 'Pedido');
  });
}

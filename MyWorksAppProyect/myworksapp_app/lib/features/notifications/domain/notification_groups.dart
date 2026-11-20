import '../../../core/database/models/notification_model.dart';

class NotificationFolder {
  const NotificationFolder({
    required this.key,
    required this.title,
    required this.unreadCount,
    required this.latestAt,
    required this.items,
  });

  final String key;
  final String title;
  final int unreadCount;
  final DateTime latestAt;
  final List<NotificationModel> items;
}

const generalNoticesKey = 'generales';

/// Agrupa avisos por trabajo. El más reciente queda arriba.
List<NotificationFolder> groupNotificationsByJob(
  List<NotificationModel> items, {
  Map<String, String> jobTitles = const {},
}) {
  final buckets = <String, List<NotificationModel>>{};
  for (final item in items) {
    final related = item.relatedId?.trim() ?? '';
    final key = related.isEmpty ? generalNoticesKey : related;
    buckets.putIfAbsent(key, () => []).add(item);
  }

  final folders = <NotificationFolder>[];
  for (final entry in buckets.entries) {
    final sorted = [...entry.value]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final named = jobTitles[entry.key]?.trim();
    folders.add(
      NotificationFolder(
        key: entry.key,
        title: entry.key == generalNoticesKey
            ? 'Generales'
            : (named != null && named.isNotEmpty ? named : 'Pedido'),
        unreadCount: sorted.where((item) => !item.isRead).length,
        latestAt: sorted.first.createdAt,
        items: sorted,
      ),
    );
  }
  folders.sort((a, b) => b.latestAt.compareTo(a.latestAt));
  return folders;
}

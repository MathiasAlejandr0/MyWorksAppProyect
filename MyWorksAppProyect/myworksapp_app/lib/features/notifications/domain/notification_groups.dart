import '../../../core/database/models/notification_model.dart';

class JobNoticeLabel {
  const JobNoticeLabel({required this.title, this.detail});

  /// Nombre del servicio pedido, o la descripción si el servicio no está.
  final String title;

  /// Detalle del pedido, para distinguir dos trabajos del mismo servicio.
  final String? detail;
}

class NotificationFolder {
  const NotificationFolder({
    required this.key,
    required this.title,
    required this.unreadCount,
    required this.latestAt,
    required this.items,
    this.detail,
  });

  final String key;
  final String title;
  final String? detail;
  final int unreadCount;
  final DateTime latestAt;
  final List<NotificationModel> items;
}

const generalNoticesKey = 'generales';

/// Nombre del servicio cuando el embed de `servicios` viene como mapa o lista.
String? serviceNameFromEmbed(Object? embed) {
  if (embed is Map) {
    final name = embed['nombre']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    return null;
  }
  if (embed is List) {
    for (final item in embed) {
      final name = serviceNameFromEmbed(item);
      if (name != null && name.isNotEmpty) return name;
    }
  }
  return null;
}

/// El título de la carpeta es el servicio. La descripción distingue el pedido.
JobNoticeLabel labelForJob({
  String? serviceName,
  String? description,
  String? address,
}) {
  String clean(String? value) => value?.trim() ?? '';
  final service = clean(serviceName);
  final desc = clean(description);
  final addr = clean(address);

  final title = service.isNotEmpty
      ? service
      : (desc.isNotEmpty ? desc : (addr.isNotEmpty ? addr : 'Pedido'));

  String? detail;
  if (service.isNotEmpty && desc.isNotEmpty) {
    detail = desc;
  } else if (service.isNotEmpty && addr.isNotEmpty) {
    detail = addr;
  } else if (service.isEmpty && desc.isNotEmpty && addr.isNotEmpty) {
    detail = addr;
  }
  if (detail == title) detail = null;
  return JobNoticeLabel(title: title, detail: detail);
}

/// Agrupa avisos por trabajo. El pedido con el aviso más reciente queda arriba.
List<NotificationFolder> groupNotificationsByJob(
  List<NotificationModel> items, {
  Map<String, JobNoticeLabel> jobLabels = const {},
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
    final label = jobLabels[entry.key];
    final named = label?.title.trim() ?? '';
    final detail = label?.detail?.trim() ?? '';
    folders.add(
      NotificationFolder(
        key: entry.key,
        title: entry.key == generalNoticesKey
            ? 'Avisos generales'
            : (named.isNotEmpty ? named : 'Pedido'),
        detail: entry.key == generalNoticesKey || detail.isEmpty
            ? null
            : detail,
        unreadCount: sorted.where((item) => !item.isRead).length,
        latestAt: sorted.first.createdAt,
        items: sorted,
      ),
    );
  }
  folders.sort((a, b) => b.latestAt.compareTo(a.latestAt));
  return folders;
}

import '../models/notification_model.dart';
import '../supabase_db.dart';

class NotificationRepository {
  static const String _table = 'notificaciones';

  Future<void> createNotification(NotificationModel notification) async {
    await supabase.from(_table).insert(notification.toMap());
  }

  /// Un solo INSERT para varias notificaciones.
  Future<void> createNotifications(List<NotificationModel> notifications) async {
    if (notifications.isEmpty) return;
    await supabase
        .from(_table)
        .insert(notifications.map((n) => n.toMap()).toList());
  }

  Future<List<NotificationModel>> getNotificationsByUserId(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_usuario', userId)
        .order('creado_en', ascending: false);
    return rows
        .map<NotificationModel>((m) => NotificationModel.fromMap(m))
        .toList();
  }

  /// Solo dice si hay alguna sin leer (no baja las filas).
  Future<bool> hasUnread(String userId) async {
    final row = await supabase
        .from(_table)
        .select('id')
        .eq('id_usuario', userId)
        .eq('leido', 0)
        .limit(1)
        .maybeSingle();
    return row != null;
  }

  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_usuario', userId)
        .eq('leido', 0)
        .order('creado_en', ascending: false);
    return rows
        .map<NotificationModel>((m) => NotificationModel.fromMap(m))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from(_table)
        .update({'leido': 1}).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await supabase.from(_table).update({'leido': 1}).eq('id_usuario', userId);
  }

  Future<int> getUnreadCount(String userId) async {
    final rows = await supabase
        .from(_table)
        .select('id')
        .eq('id_usuario', userId)
        .eq('leido', 0);
    return rows.length;
  }

  Future<void> deleteNotification(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }
}

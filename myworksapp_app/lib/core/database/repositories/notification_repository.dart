import '../models/notification_model.dart';
import '../supabase_db.dart';

class NotificationRepository {
  static const String _table = 'notifications';

  Future<void> createNotification(NotificationModel notification) async {
    await supabase.from(_table).insert(notification.toMap());
  }

  Future<List<NotificationModel>> getNotificationsByUserId(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('userId', userId)
        .order('createdAt', ascending: false);
    return rows
        .map<NotificationModel>((m) => NotificationModel.fromMap(m))
        .toList();
  }

  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('userId', userId)
        .eq('isRead', 0)
        .order('createdAt', ascending: false);
    return rows
        .map<NotificationModel>((m) => NotificationModel.fromMap(m))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from(_table)
        .update({'isRead': 1}).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await supabase.from(_table).update({'isRead': 1}).eq('userId', userId);
  }

  Future<int> getUnreadCount(String userId) async {
    final rows = await supabase
        .from(_table)
        .select('id')
        .eq('userId', userId)
        .eq('isRead', 0);
    return rows.length;
  }

  Future<void> deleteNotification(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }
}

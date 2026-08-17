import 'dart:async' show StreamController, unawaited;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/models/notification_model.dart';
import '../database/supabase_db.dart';
import '../utils/app_logger.dart';
import 'notification_service.dart';

/// Escucha inserciones en `notifications` vía Supabase Realtime
/// y dispara banner local + stream in-app.
class NotificationRealtimeService {
  static final NotificationRealtimeService instance =
      NotificationRealtimeService._();
  NotificationRealtimeService._();

  RealtimeChannel? _channel;
  String? _userId;
  final _incomingController =
      StreamController<NotificationModel>.broadcast();

  Stream<NotificationModel> get onIncoming => _incomingController.stream;

  Future<void> subscribe(String userId) async {
    if (_userId == userId && _channel != null) return;
    await unsubscribe();

    _userId = userId;
    _channel = supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'userId',
            value: userId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isEmpty) return;

            try {
              final notification = NotificationModel.fromMap(
                Map<String, dynamic>.from(record),
              );
              unawaited(
                NotificationService.instance.showIncomingNotification(
                  notification,
                ),
              );
              _incomingController.add(notification);
            } catch (e) {
              AppLogger.e('Error procesando notificación realtime', e);
            }
          },
        )
        .subscribe();

    AppLogger.i('Realtime de notificaciones activo para $userId');
  }

  Future<void> unsubscribe() async {
    if (_channel != null) {
      await supabase.removeChannel(_channel!);
      _channel = null;
    }
    _userId = null;
  }

  void dispose() {
    unawaited(unsubscribe());
    _incomingController.close();
  }
}

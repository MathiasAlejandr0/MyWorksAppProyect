import 'package:uuid/uuid.dart';

import '../models/app_error_log_model.dart';
import '../supabase_db.dart';
import '../../utils/app_logger.dart';

class AppErrorLogRepository {
  static const String _table = 'app_error_logs';

  Future<void> logError({
    required String message,
    String? userId,
    String errorType = 'error',
    String? stackTrace,
    Map<String, dynamic>? metadata,
    String? appVersion,
    String? platform,
  }) async {
    try {
      final entry = AppErrorLogModel(
        id: const Uuid().v4(),
        userId: userId,
        errorType: errorType,
        message: message,
        stackTrace: stackTrace,
        metadata: metadata,
        createdAt: DateTime.now(),
      );
      await supabase.from(_table).insert({
        ...entry.toMap(),
        'appVersion': appVersion,
        'platform': platform,
      });
    } catch (e) {
      AppLogger.d('No se pudo persistir error log: $e');
    }
  }

  Future<List<AppErrorLogModel>> listLogs({
    String? status,
    int limit = 100,
  }) async {
    try {
      var query = supabase.from(_table).select();
      if (status != null) {
        query = query.eq('status', status);
      }
      final rows = await query
          .order('createdAt', ascending: false)
          .limit(limit);
      return rows
          .map<AppErrorLogModel>(
            (m) => AppErrorLogModel.fromMap(Map<String, dynamic>.from(m)),
          )
          .toList();
    } catch (e) {
      AppLogger.e('Error listando app_error_logs', e);
      return [];
    }
  }

  Future<void> updateStatus(String id, String status) async {
    await supabase.from(_table).update({'status': status}).eq('id', id);
  }
}

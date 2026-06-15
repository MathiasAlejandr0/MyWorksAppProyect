import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../database/repositories/app_error_log_repository.dart';
import '../database/supabase_db.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';

/// Persiste errores en Supabase para revisión en el panel admin.
class CrashReportingService {
  static final CrashReportingService instance = CrashReportingService._();
  CrashReportingService._();

  final AppErrorLogRepository _errorLogRepo = AppErrorLogRepository();
  bool _isInitialized = false;
  String? _appVersion;

  Future<void> initialize() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
    } catch (_) {
      _appVersion = null;
    }
    _isInitialized = true;
    AppLogger.i('CrashReportingService: logging remoto activo');
  }

  void recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? additionalData,
  }) {
    if (!_isInitialized) return;

    final message = reason ?? error.toString();
    final metadata = <String, dynamic>{
      if (fatal) 'fatal': true,
      if (additionalData != null) ...additionalData,
      'error': error.toString(),
    };

    _errorLogRepo.logError(
      message: message,
      userId: supabase.auth.currentUser?.id,
      errorType: fatal ? 'fatal' : 'error',
      stackTrace: stackTrace?.toString(),
      metadata: metadata,
      appVersion: _appVersion,
      platform: _platformLabel(),
    );
  }

  void recordAppError(AppError error, {StackTrace? stackTrace}) {
    recordError(
      error,
      stackTrace,
      reason: error.message,
      fatal: error.type == ErrorType.critical,
      additionalData: {
        'errorCode': error.code ?? 'UNKNOWN',
        'errorType': error.type.toString(),
      },
    );
  }

  void setUserId(String userId) {
    AppLogger.d('CrashReporting userId: $userId');
  }

  void setUserInfo({
    String? email,
    String? name,
    String? role,
  }) {}

  void log(String message) {
    AppLogger.d('CrashReporting log: $message');
  }

  void crash() {
    AppLogger.w('crash() solo disponible en debug');
  }

  bool get isInitialized => _isInitialized;

  String _platformLabel() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}

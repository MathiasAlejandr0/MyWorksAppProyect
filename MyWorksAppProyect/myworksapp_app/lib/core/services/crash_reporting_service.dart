import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
  bool _sentryEnabled = false;
  final String _sentryDsn =
      const String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  Future<void> initialize() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
    } catch (_) {
      _appVersion = null;
    }
    _isInitialized = true;
    AppLogger.i('CrashReportingService: logging remoto activo');

    // Sentry es opcional: si no se define DSN, no se inicializa.
    _sentryEnabled = _sentryDsn.isNotEmpty;
    if (_sentryEnabled) {
      try {
        await SentryFlutter.init(
          (options) {
            options.dsn = _sentryDsn;
            // Para no impactar rendimiento en MVP: muestreo conservador.
            options.tracesSampleRate = 0.0;
          },
        );
        AppLogger.i('Sentry inicializado');
      } catch (e) {
        AppLogger.w('Sentry no pudo inicializarse', e);
        _sentryEnabled = false;
      }
    }
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

    // Captura opcional en Sentry (no debe bloquear el flujo).
    if (_sentryEnabled) {
      try {
        // ignore: unawaited_futures
        Sentry.captureException(
          error,
          stackTrace: stackTrace,
          withScope: (scope) {
            // `setExtra` está deprecado: usar contexts para info estructurada.
            scope.setContexts('reason', {'message': message});
          },
        );
      } catch (_) {
        // Nunca fallar por telemetría.
      }
    }
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

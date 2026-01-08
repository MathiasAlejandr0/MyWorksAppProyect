import 'package:logger/logger.dart';
import '../services/crash_reporting_service.dart';
import 'package:flutter/foundation.dart';

/// Logger centralizado para la aplicación
class AppLogger {
  static Logger? _logger;

  static Logger get instance {
    _logger ??= Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: kDebugMode ? Level.debug : Level.warning,
    );
    return _logger!;
  }

  /// Log de debug
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log de info
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log de warning
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log de error
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.e(message, error: error, stackTrace: stackTrace);
    
    // Enviar a Crashlytics si está disponible
    if (error != null && CrashReportingService.instance.isInitialized) {
      CrashReportingService.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    }
  }

  /// Log de error fatal
  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.f(message, error: error, stackTrace: stackTrace);
    
    // Enviar a Crashlytics si está disponible
    if (error != null && CrashReportingService.instance.isInitialized) {
      CrashReportingService.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: true,
      );
    }
  }
}


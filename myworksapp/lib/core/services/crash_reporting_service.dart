// Firebase deshabilitado - descomentar si se necesita en el futuro
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';

/// Servicio de monitoreo de crashes y errores
/// 
/// NOTA: Firebase está deshabilitado por defecto.
/// Este servicio solo loguea localmente.
/// Para habilitar Firebase, agregar las dependencias en pubspec.yaml
/// y descomentar el código de inicialización.
class CrashReportingService {
  static final CrashReportingService instance = CrashReportingService._();
  CrashReportingService._();

  bool _isInitialized = false;

  /// Inicializa el servicio de crash reporting
  /// 
  /// NOTA: Firebase no está habilitado por defecto.
  /// Este servicio está deshabilitado y no hace nada.
  Future<void> initialize() async {
    // Firebase/Crashlytics deshabilitado completamente
    AppLogger.i('CrashReportingService: Firebase deshabilitado, servicio no inicializado');
    _isInitialized = false;
  }

  /// Reporta un error manualmente
  /// 
  /// Útil para errores capturados que no causan crash.
  void recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? additionalData,
  }) {
    // Firebase deshabilitado - solo loguear localmente
    AppLogger.d('Crashlytics deshabilitado, error no reportado: $reason');
  }

  /// Reporta un AppError
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

  /// Establece el ID de usuario para tracking
  void setUserId(String userId) {
    // Firebase deshabilitado
    AppLogger.d('Crashlytics deshabilitado, setUserId ignorado: $userId');
  }

  /// Establece información adicional del usuario
  void setUserInfo({
    String? email,
    String? name,
    String? role,
  }) {
    // Firebase deshabilitado
    AppLogger.d('Crashlytics deshabilitado, setUserInfo ignorado');
  }

  /// Agrega un log personalizado
  void log(String message) {
    // Firebase deshabilitado - solo loguear localmente
    AppLogger.d('Crashlytics log: $message');
  }

  /// Fuerza un crash de prueba (solo en debug)
  void crash() {
    // Firebase deshabilitado
    AppLogger.w('Crashlytics deshabilitado, crash() ignorado');
  }

  /// Verifica si el servicio está inicializado
  bool get isInitialized => _isInitialized;
}

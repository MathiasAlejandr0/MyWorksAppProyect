import '../database/supabase_db.dart';
import '../utils/app_logger.dart';
import 'package:flutter/foundation.dart';

/// Estados de salud de la aplicación
enum AppHealthStatus {
  healthy,
  degraded,
  critical,
}

/// Tipos de fallos críticos detectables
enum CriticalFailureType {
  databaseNotInitialized,
  migrationInterrupted,
  partialCorruption,
  databaseClosed,
  unknown,
}

/// Servicio de salud de la aplicación (conectividad con Supabase).
class AppHealthService {
  static final AppHealthService instance = AppHealthService._();
  AppHealthService._();

  AppHealthStatus _status = AppHealthStatus.healthy;
  CriticalFailureType? _lastFailureType;
  String? _lastFailureMessage;
  bool _isMaintenanceMode = false;

  AppHealthStatus get status => _status;
  CriticalFailureType? get lastFailureType => _lastFailureType;
  String? get lastFailureMessage => _lastFailureMessage;
  bool get isMaintenanceMode => _isMaintenanceMode;

  /// Verifica conectividad con Supabase (lectura mínima al catálogo).
  Future<bool> checkHealth() async {
    try {
      await supabase.from('services').select('id').limit(1);

      _status = AppHealthStatus.healthy;
      _isMaintenanceMode = false;
      _lastFailureType = null;
      _lastFailureMessage = null;

      AppLogger.i('✅ Salud de la app verificada: HEALTHY (Supabase)');
      return true;
    } catch (e) {
      _handleCriticalFailure(
        CriticalFailureType.databaseNotInitialized,
        'No se pudo conectar con Supabase: $e',
      );
      return false;
    }
  }

  void _handleCriticalFailure(CriticalFailureType type, String message) {
    _status = AppHealthStatus.critical;
    _lastFailureType = type;
    _lastFailureMessage = message;
    _isMaintenanceMode = true;

    AppLogger.e('🚨 FALLO CRÍTICO DETECTADO: $type - $message');

    if (kReleaseMode) {
      AppLogger.w('Modo producción: activando modo seguro en lugar de crashear');
    }
  }

  void activateMaintenanceMode({String? reason}) {
    _isMaintenanceMode = true;
    _status = AppHealthStatus.critical;
    _lastFailureMessage = reason ?? 'Modo mantenimiento activado manualmente';
    AppLogger.w('Modo mantenimiento activado: $_lastFailureMessage');
  }

  void deactivateMaintenanceMode() {
    _isMaintenanceMode = false;
    _status = AppHealthStatus.healthy;
    _lastFailureMessage = null;
    _lastFailureType = null;
    AppLogger.i('Modo mantenimiento desactivado');
  }

  /// Reintenta la verificación de conectividad con Supabase.
  Future<bool> attemptRecovery({bool restoreBackup = false}) async {
    try {
      AppLogger.i('🔄 Reintentando conexión con Supabase...');
      final isHealthy = await checkHealth();

      if (isHealthy) {
        AppLogger.i('✅ Recuperación exitosa');
        deactivateMaintenanceMode();
        return true;
      }

      AppLogger.e('❌ Recuperación fallida');
      return false;
    } catch (e) {
      AppLogger.e('Error durante recuperación', e);
      return false;
    }
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'status': _status.toString(),
      'isMaintenanceMode': _isMaintenanceMode,
      'lastFailureType': _lastFailureType?.toString(),
      'lastFailureMessage': _lastFailureMessage,
      'backend': 'supabase',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

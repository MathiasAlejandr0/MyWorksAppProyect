import '../database/database_helper.dart';
import '../utils/app_logger.dart';
import 'backup_restore_service.dart';
import 'package:flutter/foundation.dart';

/// Estados de salud de la aplicación
enum AppHealthStatus {
  healthy, // Todo funcionando correctamente
  degraded, // Problemas menores, app funcional
  critical, // Problemas críticos, modo seguro activado
}

/// Tipos de fallos críticos detectables
enum CriticalFailureType {
  databaseNotInitialized,
  migrationInterrupted,
  partialCorruption,
  databaseClosed,
  unknown,
}

/// Servicio de salud de la aplicación
/// 
/// Responsabilidades:
/// - Detectar fallos críticos (DB no inicializa, migración interrumpida, corrupción)
/// - Activar Modo Seguro cuando sea necesario
/// - Nunca crashear la app en producción
class AppHealthService {
  static final AppHealthService instance = AppHealthService._();
  AppHealthService._();

  AppHealthStatus _status = AppHealthStatus.healthy;
  CriticalFailureType? _lastFailureType;
  String? _lastFailureMessage;
  bool _isMaintenanceMode = false;

  /// Estado actual de salud
  AppHealthStatus get status => _status;
  
  /// Tipo del último fallo detectado
  CriticalFailureType? get lastFailureType => _lastFailureType;
  
  /// Mensaje del último fallo
  String? get lastFailureMessage => _lastFailureMessage;
  
  /// Si está en modo mantenimiento
  bool get isMaintenanceMode => _isMaintenanceMode;

  /// Verifica la salud de la aplicación
  /// 
  /// Retorna true si está saludable, false si hay problemas críticos
  Future<bool> checkHealth() async {
    try {
      // Verificar base de datos
      final dbHelper = DatabaseHelper.instance;
      
      // Verificar si la BD está lista
      if (!await dbHelper.isReady()) {
        // Intentar inicializar (esto es normal durante el primer arranque)
        try {
          await dbHelper.database.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Timeout al inicializar BD');
            },
          );
          // Si se inicializó correctamente, continuar sin error
          AppLogger.d('Base de datos inicializada correctamente');
        } catch (e) {
          // Solo reportar como error crítico si realmente falla
          _handleCriticalFailure(
            CriticalFailureType.databaseNotInitialized,
            'No se pudo inicializar la base de datos: $e',
          );
          return false;
        }
      }

      // Verificar que la BD está abierta y funcional
      try {
        final db = await dbHelper.database;
        await db.rawQuery('SELECT 1');
        
        // Verificar integridad básica (tablas críticas existen)
        final tables = ['users', 'jobs', 'services'];
        for (final table in tables) {
          try {
            await db.rawQuery('SELECT COUNT(*) FROM $table LIMIT 1');
          } catch (e) {
            _handleCriticalFailure(
              CriticalFailureType.partialCorruption,
              'Tabla $table no accesible: $e',
            );
            return false;
          }
        }
      } catch (e) {
        if (e.toString().contains('closed') || e.toString().contains('not open')) {
          _handleCriticalFailure(
            CriticalFailureType.databaseClosed,
            'Base de datos cerrada inesperadamente: $e',
          );
        } else {
          _handleCriticalFailure(
            CriticalFailureType.unknown,
            'Error al verificar base de datos: $e',
          );
        }
        return false;
      }

      // Si llegamos aquí, todo está bien
      _status = AppHealthStatus.healthy;
      _isMaintenanceMode = false;
      _lastFailureType = null;
      _lastFailureMessage = null;
      
      AppLogger.i('✅ Salud de la app verificada: HEALTHY');
      return true;
    } catch (e) {
      // Catch-all para cualquier error inesperado
      _handleCriticalFailure(
        CriticalFailureType.unknown,
        'Error inesperado al verificar salud: $e',
      );
      return false;
    }
  }

  /// Maneja un fallo crítico
  void _handleCriticalFailure(CriticalFailureType type, String message) {
    _status = AppHealthStatus.critical;
    _lastFailureType = type;
    _lastFailureMessage = message;
    _isMaintenanceMode = true;
    
    AppLogger.e('🚨 FALLO CRÍTICO DETECTADO: $type - $message');
    
    // En producción, nunca crashear - solo activar modo seguro
    if (kReleaseMode) {
      AppLogger.w('Modo producción: activando modo seguro en lugar de crashear');
    }
  }

  /// Activa el modo mantenimiento manualmente
  void activateMaintenanceMode({String? reason}) {
    _isMaintenanceMode = true;
    _status = AppHealthStatus.critical;
    _lastFailureMessage = reason ?? 'Modo mantenimiento activado manualmente';
    AppLogger.w('Modo mantenimiento activado: ${_lastFailureMessage}');
  }

  /// Desactiva el modo mantenimiento
  void deactivateMaintenanceMode() {
    _isMaintenanceMode = false;
    _status = AppHealthStatus.healthy;
    _lastFailureMessage = null;
    _lastFailureType = null;
    AppLogger.i('Modo mantenimiento desactivado');
  }

  /// Intenta recuperar de un fallo crítico
  /// 
  /// Opciones:
  /// - Reintentar inicialización
  /// - Restaurar último backup
  Future<bool> attemptRecovery({bool restoreBackup = false}) async {
    try {
      AppLogger.i('🔄 Intentando recuperación...');
      
      if (restoreBackup) {
        AppLogger.i('Restaurando desde último backup...');
        final backupService = BackupRestoreService.instance;
        final backups = await backupService.listBackups();
        if (backups.isNotEmpty) {
          final latestBackup = backups.first;
          await backupService.restoreFromBackup(latestBackup['path'] as String);
          AppLogger.i('Backup restaurado: ${latestBackup['path']}');
        } else {
          AppLogger.w('No hay backups disponibles');
        }
      }

      // Limpiar estado de BD (forzar reinicialización)
      // La BD se reinicializará automáticamente en el próximo acceso

      // Verificar salud nuevamente
      final isHealthy = await checkHealth();
      
      if (isHealthy) {
        AppLogger.i('✅ Recuperación exitosa');
        deactivateMaintenanceMode();
        return true;
      } else {
        AppLogger.e('❌ Recuperación fallida');
        return false;
      }
    } catch (e) {
      AppLogger.e('Error durante recuperación', e);
      return false;
    }
  }

  /// Obtiene información de diagnóstico
  Map<String, dynamic> getDiagnostics() {
    return {
      'status': _status.toString(),
      'isMaintenanceMode': _isMaintenanceMode,
      'lastFailureType': _lastFailureType?.toString(),
      'lastFailureMessage': _lastFailureMessage,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Exception para timeouts
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => 'TimeoutException: $message';
}


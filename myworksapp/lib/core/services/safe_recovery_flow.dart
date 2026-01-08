import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/database_helper.dart';
import '../database/migration_manager.dart';
import '../utils/app_logger.dart';
import 'backup_restore_service.dart';
import 'analytics_service.dart';

/// Estados de recuperación
enum RecoveryState {
  normal, // Estado normal
  sqlcipherError, // Error de SQLCipher
  migrationIncomplete, // Migración incompleta
  databaseCorrupted, // Base de datos corrupta
  readonlyMode, // Modo solo lectura
}

/// Servicio de recuperación segura ante fallas críticas
/// 
/// Maneja:
/// - Error de SQLCipher
/// - Migración incompleta
/// - Corrupción SQLite
/// - Modo solo lectura
class SafeRecoveryFlow {
  static final SafeRecoveryFlow instance = SafeRecoveryFlow._();
  SafeRecoveryFlow._();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final BackupRestoreService _backupService = BackupRestoreService.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  RecoveryState _currentState = RecoveryState.normal;

  RecoveryState get currentState => _currentState;

  /// Detecta y maneja errores críticos
  Future<RecoveryResult> detectAndRecover() async {
    try {
      AppLogger.i('🔍 Detectando problemas críticos...');

      // 1. Verificar SQLCipher
      final sqlcipherCheck = await _checkSqlCipher();
      if (!sqlcipherCheck.success) {
        _currentState = RecoveryState.sqlcipherError;
        return RecoveryResult(
          success: false,
          state: RecoveryState.sqlcipherError,
          message: sqlcipherCheck.message ?? 'Error de SQLCipher',
          canRecover: true,
        );
      }

      // 2. Verificar migraciones
      final migrationCheck = await _checkMigrations();
      if (!migrationCheck.success) {
        _currentState = RecoveryState.migrationIncomplete;
        return RecoveryResult(
          success: false,
          state: RecoveryState.migrationIncomplete,
          message: migrationCheck.message ?? 'Migración incompleta',
          canRecover: true,
        );
      }

      // 3. Verificar integridad de la base de datos
      final integrityCheck = await _checkDatabaseIntegrity();
      if (!integrityCheck.success) {
        _currentState = RecoveryState.databaseCorrupted;
        return RecoveryResult(
          success: false,
          state: RecoveryState.databaseCorrupted,
          message: integrityCheck.message ?? 'Base de datos corrupta',
          canRecover: true,
        );
      }

      // Todo está bien
      _currentState = RecoveryState.normal;
      return RecoveryResult(
        success: true,
        state: RecoveryState.normal,
        message: 'Base de datos en estado normal',
      );
    } catch (e) {
      AppLogger.e('Error en detección de recuperación', e);
      return RecoveryResult(
        success: false,
        state: RecoveryState.databaseCorrupted,
        message: 'Error crítico detectado: ${e.toString()}',
        canRecover: false,
      );
    }
  }

  /// Verifica SQLCipher
  Future<CheckResult> _checkSqlCipher() async {
    try {
      // Intentar abrir la base de datos
      final db = await _dbHelper.database;
      
      // Intentar una consulta simple
      await db.rawQuery('SELECT 1');
      
      return CheckResult(success: true);
    } catch (e) {
      AppLogger.e('Error de SQLCipher detectado', e);
      await _analytics.trackEvent(
        eventName: 'recovery_sqlcipher_error',
        metadata: {'error': e.toString()},
      );
      return CheckResult(
        success: false,
        message: 'Error al acceder a la base de datos encriptada',
      );
    }
  }

  /// Verifica migraciones
  Future<CheckResult> _checkMigrations() async {
    try {
      final db = await _dbHelper.database;
      
      // Verificar que todas las tablas esperadas existen
      final expectedTables = [
        'users',
        'jobs',
        'workers',
        'messages',
        'notifications',
        'ratings',
        'analytics_events',
        'abuse_events',
      ];

      for (final table in expectedTables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [table],
        );
        if (result.isEmpty) {
          return CheckResult(
            success: false,
            message: 'Tabla faltante: $table',
          );
        }
      }

      return CheckResult(success: true);
    } catch (e) {
      AppLogger.e('Error verificando migraciones', e);
      await _analytics.trackEvent(
        eventName: 'recovery_migration_error',
        metadata: {'error': e.toString()},
      );
      return CheckResult(
        success: false,
        message: 'Error verificando migraciones: ${e.toString()}',
      );
    }
  }

  /// Verifica integridad de la base de datos
  Future<CheckResult> _checkDatabaseIntegrity() async {
    try {
      final db = await _dbHelper.database;
      
      // Ejecutar PRAGMA integrity_check
      final result = await db.rawQuery('PRAGMA integrity_check');
      
      if (result.isNotEmpty) {
        final integrity = result.first['integrity_check'] as String?;
        if (integrity != null && integrity.toLowerCase() != 'ok') {
          return CheckResult(
            success: false,
            message: 'Base de datos corrupta: $integrity',
          );
        }
      }

      return CheckResult(success: true);
    } catch (e) {
      AppLogger.e('Error verificando integridad', e);
      await _analytics.trackEvent(
        eventName: 'recovery_integrity_error',
        metadata: {'error': e.toString()},
      );
      return CheckResult(
        success: false,
        message: 'Error verificando integridad: ${e.toString()}',
      );
    }
  }

  /// Intenta recuperar desde backup
  Future<RecoveryResult> recoverFromBackup() async {
    try {
      AppLogger.i('🔄 Intentando recuperar desde backup...');

      // 1. Exportar datos actuales (por si acaso)
      final exportResult = await _exportCurrentData();
      if (!exportResult.success) {
        AppLogger.w('No se pudo exportar datos actuales antes de recuperar');
      }

      // 2. Buscar backup más reciente
      final backupPath = await _findLatestBackup();
      if (backupPath == null) {
        return RecoveryResult(
          success: false,
          state: _currentState,
          message: 'No se encontró backup disponible',
          canRecover: false,
        );
      }

      // 3. Restaurar desde backup
      final restoreResult = await _backupService.restoreFromBackup(backupPath);
      if (!restoreResult) {
        return RecoveryResult(
          success: false,
          state: _currentState,
          message: 'Error al restaurar desde backup',
          canRecover: false,
        );
      }

      // 4. Verificar que la restauración fue exitosa
      final verifyResult = await detectAndRecover();
      if (verifyResult.success) {
        await _analytics.trackEvent(
          eventName: 'recovery_backup_restored',
          metadata: {'backupPath': backupPath},
        );
        return RecoveryResult(
          success: true,
          state: RecoveryState.normal,
          message: 'Recuperación exitosa desde backup',
        );
      }

      return RecoveryResult(
        success: false,
        state: _currentState,
        message: 'La restauración no resolvió el problema',
        canRecover: false,
      );
    } catch (e) {
      AppLogger.e('Error en recuperación desde backup', e);
      await _analytics.trackEvent(
        eventName: 'recovery_backup_failed',
        metadata: {'error': e.toString()},
      );
      return RecoveryResult(
        success: false,
        state: _currentState,
        message: 'Error crítico en recuperación: ${e.toString()}',
        canRecover: false,
      );
    }
  }

  /// Exporta datos actuales antes de recuperar
  Future<CheckResult> _exportCurrentData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final exportPath = path.join(
        appDir.path,
        'myworksapp_export_before_recovery_${DateTime.now().millisecondsSinceEpoch}.json',
      );

      final success = await _backupService.exportData(exportPath);
      if (success) {
        return CheckResult(
          success: true,
          message: 'Datos exportados a: $exportPath',
        );
      }

      return CheckResult(
        success: false,
        message: 'No se pudo exportar datos',
      );
    } catch (e) {
      AppLogger.e('Error exportando datos', e);
      return CheckResult(
        success: false,
        message: 'Error al exportar: ${e.toString()}',
      );
    }
  }

  /// Busca el backup más reciente
  Future<String?> _findLatestBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(appDir.path, 'backups'));

      if (!await backupDir.exists()) {
        return null;
      }

      final backups = backupDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.db'))
          .toList();

      if (backups.isEmpty) {
        return null;
      }

      // Ordenar por fecha de modificación (más reciente primero)
      backups.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return backups.first.path;
    } catch (e) {
      AppLogger.e('Error buscando backup', e);
      return null;
    }
  }

  /// Activa modo solo lectura
  Future<void> enableReadOnlyMode() async {
    _currentState = RecoveryState.readonlyMode;
    await _analytics.trackEvent(
      eventName: 'recovery_readonly_mode',
    );
    AppLogger.w('Modo solo lectura activado');
  }

  /// Desactiva modo solo lectura
  Future<void> disableReadOnlyMode() async {
    if (_currentState == RecoveryState.readonlyMode) {
      _currentState = RecoveryState.normal;
      AppLogger.i('Modo solo lectura desactivado');
    }
  }

  /// Reintenta operación después de recuperación
  Future<bool> retryAfterRecovery() async {
    try {
      final result = await detectAndRecover();
      if (result.success) {
        await _analytics.trackEvent(
          eventName: 'recovery_retry_success',
        );
        return true;
      }

      await _analytics.trackEvent(
        eventName: 'recovery_retry_failed',
        metadata: {'reason': result.message},
      );
      return false;
    } catch (e) {
      AppLogger.e('Error en reintento después de recuperación', e);
      return false;
    }
  }
}

/// Resultado de verificación
class CheckResult {
  final bool success;
  final String? message;

  CheckResult({
    required this.success,
    this.message,
  });
}

/// Resultado de recuperación
class RecoveryResult {
  final bool success;
  final RecoveryState state;
  final String message;
  final bool canRecover;

  RecoveryResult({
    required this.success,
    required this.state,
    required this.message,
    this.canRecover = false,
  });
}


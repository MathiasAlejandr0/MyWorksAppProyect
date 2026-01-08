import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../utils/app_logger.dart';

/// Gestor de migraciones con validación, rollback y backup
class MigrationManager {
  final Database db;
  final String dbPath;
  final List<MigrationStep> steps = [];

  MigrationManager({
    required this.db,
    required this.dbPath,
  });

  /// Ejecuta una migración con validación y rollback
  Future<MigrationResult> executeMigration({
    required int fromVersion,
    required int toVersion,
    required Future<void> Function() migration,
    required Future<bool> Function() validation,
  }) async {
    final step = MigrationStep(
      fromVersion: fromVersion,
      toVersion: toVersion,
      migration: migration,
      validation: validation,
    );

    steps.add(step);
    step.status = MigrationStatus.running;

    AppLogger.i('Iniciando migración de v$fromVersion a v$toVersion');

    try {
      // 1. Crear backup antes de migrar
      final backupPath = await _createBackup();
      AppLogger.i('Backup creado en: $backupPath');

      // 2. Ejecutar migración dentro de transacción
      await db.transaction((txn) async {
        try {
          await migration();
          step.status = MigrationStatus.completed;
        } catch (e) {
          step.status = MigrationStatus.failed;
          step.error = e.toString();
          AppLogger.e('Error en migración v$fromVersion a v$toVersion', e);
          rethrow; // Esto hará rollback automático
        }
      });

      // 3. Validar migración
      final isValid = await validation();
      if (!isValid) {
        AppLogger.w('Validación falló después de migración v$fromVersion a v$toVersion');
        // Restaurar desde backup
        await _restoreFromBackup(backupPath);
        step.status = MigrationStatus.rolledBack;
        return MigrationResult(
          success: false,
          message: 'Validación falló, migración revertida',
          backupPath: backupPath,
        );
      }

      AppLogger.i('Migración v$fromVersion a v$toVersion completada exitosamente');
      return MigrationResult(
        success: true,
        message: 'Migración exitosa',
        backupPath: backupPath,
      );
    } catch (e) {
      // Si hay error, intentar restaurar desde backup
      AppLogger.e('Error crítico en migración, restaurando desde backup', e);
      try {
        final backupPath = steps.last.backupPath;
        if (backupPath != null) {
          await _restoreFromBackup(backupPath);
          step.status = MigrationStatus.rolledBack;
        }
      } catch (restoreError) {
        AppLogger.f('Error al restaurar desde backup', restoreError);
      }

      return MigrationResult(
        success: false,
        message: 'Error en migración: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Crea un backup de la base de datos
  Future<String> _createBackup() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFileName = 'myworksapp_backup_$timestamp.db';
    final dbDir = path.dirname(dbPath);
    final backupPath = path.join(dbDir, backupFileName);

    try {
      final sourceFile = File(dbPath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(backupPath);
        AppLogger.i('Backup creado: $backupPath');
        return backupPath;
      } else {
        AppLogger.w('Base de datos no existe aún, no se puede crear backup');
        return backupPath; // Retornar path aunque no exista
      }
    } catch (e) {
      AppLogger.e('Error al crear backup', e);
      rethrow;
    }
  }

  /// Restaura la base de datos desde un backup
  Future<void> _restoreFromBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
        await backupFile.copy(dbPath);
        AppLogger.i('Base de datos restaurada desde backup: $backupPath');
      } else {
        AppLogger.w('Backup no encontrado: $backupPath');
      }
    } catch (e) {
      AppLogger.e('Error al restaurar desde backup', e);
      rethrow;
    }
  }

  /// Valida que una tabla existe
  Future<bool> validateTableExists(String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      AppLogger.e('Error al validar tabla $tableName', e);
      return false;
    }
  }

  /// Valida que una columna existe en una tabla
  Future<bool> validateColumnExists(String tableName, String columnName) async {
    try {
      final result = await db.rawQuery('PRAGMA table_info($tableName)');
      return result.any((row) => row['name'] == columnName);
    } catch (e) {
      AppLogger.e('Error al validar columna $columnName en $tableName', e);
      return false;
    }
  }

  /// Limpia backups antiguos (más de 7 días)
  Future<void> cleanupOldBackups({int daysOld = 7}) async {
    try {
      final dbDir = path.dirname(dbPath);
      final dir = Directory(dbDir);
      final files = dir.listSync();

      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      for (var file in files) {
        if (file is File && file.path.contains('myworksapp_backup_')) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            AppLogger.i('Backup antiguo eliminado: ${file.path}');
          }
        }
      }
    } catch (e) {
      AppLogger.e('Error al limpiar backups antiguos', e);
    }
  }
}

/// Paso de migración individual
class MigrationStep {
  final int fromVersion;
  final int toVersion;
  final Future<void> Function() migration;
  final Future<bool> Function() validation;
  MigrationStatus status = MigrationStatus.pending;
  String? error;
  String? backupPath;

  MigrationStep({
    required this.fromVersion,
    required this.toVersion,
    required this.migration,
    required this.validation,
  });
}

/// Estado de una migración
enum MigrationStatus {
  pending,
  running,
  completed,
  failed,
  rolledBack,
}

/// Resultado de una migración
class MigrationResult {
  final bool success;
  final String message;
  final String? backupPath;
  final dynamic error;

  MigrationResult({
    required this.success,
    required this.message,
    this.backupPath,
    this.error,
  });
}


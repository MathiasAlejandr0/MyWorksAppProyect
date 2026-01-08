import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';

/// Servicio para backup y restore local de la base de datos
class BackupRestoreService {
  static final BackupRestoreService instance = BackupRestoreService._();
  BackupRestoreService._();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String backupFileName = 'myworksapp_backup.db';
  static const String currentVersion = '6'; // Versión actual de la BD

  /// Exporta datos a JSON (para GDPR y recovery)
  Future<bool> exportData(String exportPath) async {
    try {
      AppLogger.i('Iniciando exportación de datos a JSON...');
      
      // Por ahora, exportar como backup de DB
      // En el futuro, esto puede exportar a JSON estructurado
      final backupPath = await exportBackup();
      if (backupPath == null) {
        return false;
      }
      
      // Copiar backup a la ruta de exportación solicitada
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.copy(exportPath);
        AppLogger.i('Datos exportados exitosamente: $exportPath');
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.e('Error al exportar datos', e);
      return false;
    }
  }

  /// Exporta la base de datos SQLite a un archivo local
  Future<String?> exportBackup() async {
    try {
      AppLogger.i('Iniciando exportación de backup...');

      // 1. Obtener ruta de la base de datos actual
      final dbPath = await _getDatabasePath();
      final sourceFile = File(dbPath);

      if (!await sourceFile.exists()) {
        throw AppError.database('Base de datos no encontrada');
      }

      // 2. Obtener directorio de documentos para guardar backup
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // 3. Crear nombre de archivo con timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${backupDir.path}/backup_$timestamp.db';

      // 4. Copiar archivo
      await sourceFile.copy(backupPath);

      // 5. Guardar metadata del backup
      await _saveBackupMetadata(backupPath, currentVersion);

      AppLogger.i('Backup exportado exitosamente: $backupPath');
      return backupPath;
    } catch (e) {
      AppLogger.e('Error al exportar backup', e);
      return null;
    }
  }

  /// Restaura la base de datos desde un archivo de backup (alias)
  Future<bool> restoreFromBackup(String backupPath) async {
    return await restoreBackup(backupPath);
  }

  /// Restaura la base de datos desde un archivo de backup
  Future<bool> restoreBackup(String backupPath) async {
    try {
      AppLogger.i('Iniciando restauración desde backup: $backupPath');

      // 1. Verificar que el archivo de backup existe
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw AppError.database('Archivo de backup no encontrado');
      }

      // 2. Validar versión del backup
      final backupVersion = await _getBackupVersion(backupPath);
      if (backupVersion == null) {
        throw AppError.database('No se pudo validar la versión del backup');
      }

      // Verificar compatibilidad de versión
      if (!_isVersionCompatible(backupVersion)) {
        throw AppError.database(
          'El backup es de una versión incompatible. Versión del backup: $backupVersion, Versión actual: $currentVersion',
        );
      }

      // 3. Cerrar conexión actual
      await _dbHelper.close();

      // 4. Obtener ruta de la base de datos actual
      final dbPath = await _getDatabasePath();
      final currentDbFile = File(dbPath);

      // 5. Crear backup de la BD actual antes de restaurar
      if (await currentDbFile.exists()) {
        final safetyBackup = '${dbPath}_safety_backup_${DateTime.now().millisecondsSinceEpoch}';
        await currentDbFile.copy(safetyBackup);
        AppLogger.i('Backup de seguridad creado: $safetyBackup');
      }

      // 6. Eliminar BD actual
      if (await currentDbFile.exists()) {
        await currentDbFile.delete();
      }

      // 7. Copiar backup a la ubicación de la BD
      await backupFile.copy(dbPath);

      // 8. Reinicializar conexión
      await _dbHelper.database;

      AppLogger.i('Backup restaurado exitosamente');
      return true;
    } catch (e) {
      AppLogger.e('Error al restaurar backup', e);
      return false;
    }
  }

  /// Obtiene la ruta de la base de datos actual
  Future<String> _getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return '$dbPath/myworksapp.db';
  }

  /// Guarda metadata del backup
  Future<void> _saveBackupMetadata(String backupPath, String version) async {
    try {
      final metadataPath = '$backupPath.meta';
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString('version:$version\ntimestamp:${DateTime.now().toIso8601String()}');
    } catch (e) {
      AppLogger.w('No se pudo guardar metadata del backup', e);
    }
  }

  /// Obtiene la versión del backup
  Future<String?> _getBackupVersion(String backupPath) async {
    try {
      final metadataPath = '$backupPath.meta';
      final metadataFile = File(metadataPath);
      
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final lines = content.split('\n');
        for (final line in lines) {
          if (line.startsWith('version:')) {
            return line.substring(8);
          }
        }
      }

      // Si no hay metadata, asumir versión antigua (compatible con v1-v5)
      return '5'; // Versión por defecto para backups sin metadata
    } catch (e) {
      AppLogger.w('Error al leer versión del backup', e);
      return null;
    }
  }

  /// Verifica si la versión del backup es compatible
  bool _isVersionCompatible(String backupVersion) {
    // Permitir restaurar backups de versiones anteriores o iguales
    final backupVersionNum = int.tryParse(backupVersion) ?? 0;
    final currentVersionNum = int.tryParse(currentVersion) ?? 0;
    
    // Permitir restaurar si la versión del backup es <= a la actual
    // Las migraciones se ejecutarán automáticamente
    return backupVersionNum <= currentVersionNum;
  }

  /// Lista todos los backups disponibles
  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      
      if (!await backupDir.exists()) {
        return [];
      }

      final files = backupDir.listSync();
      final backups = <Map<String, dynamic>>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.db') && !file.path.endsWith('.meta')) {
          final stat = await file.stat();
          final version = await _getBackupVersion(file.path);
          
          backups.add({
            'path': file.path,
            'size': stat.size,
            'modified': stat.modified,
            'version': version ?? 'desconocida',
          });
        }
      }

      // Ordenar por fecha de modificación (más recientes primero)
      backups.sort((a, b) => (b['modified'] as DateTime).compareTo(a['modified'] as DateTime));

      return backups;
    } catch (e) {
      AppLogger.e('Error al listar backups', e);
      return [];
    }
  }

  /// Elimina un backup
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.delete();
        
        // Eliminar metadata si existe
        final metadataFile = File('$backupPath.meta');
        if (await metadataFile.exists()) {
          await metadataFile.delete();
        }
        
        AppLogger.i('Backup eliminado: $backupPath');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('Error al eliminar backup', e);
      return false;
    }
  }
}


import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../utils/app_logger.dart';

/// Servicio para control de versiones de la app
class AppVersionService {
  static final AppVersionService instance = AppVersionService._();
  AppVersionService._();

  static const String _prefKeyLastShownVersion = 'last_shown_version';
  static const String _currentVersion = '1.0.0'; // Debe coincidir con pubspec.yaml

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Obtiene un valor de app_meta
  Future<String?> getAppMeta(String key) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'app_meta',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (maps.isEmpty) return null;
      return maps.first['value'] as String?;
    } catch (e) {
      AppLogger.e('Error al obtener app_meta', e);
      return null;
    }
  }

  /// Establece un valor de app_meta
  Future<void> setAppMeta(String key, String value) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'app_meta',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.i('App meta actualizado: $key = $value');
    } catch (e) {
      AppLogger.e('Error al establecer app_meta', e);
    }
  }

  /// Obtiene la versión de la app
  Future<String> getAppVersion() async {
    final version = await getAppMeta('app_version');
    return version ?? _currentVersion;
  }

  /// Obtiene la fecha del primer lanzamiento
  Future<DateTime?> getFirstLaunchDate() async {
    final dateStr = await getAppMeta('first_launch_date');
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      AppLogger.e('Error al parsear fecha de primer lanzamiento', e);
      return null;
    }
  }

  /// Obtiene la última versión de migración
  Future<String?> getLastMigrationVersion() async {
    return await getAppMeta('last_migration_version');
  }

  /// Verifica si es la primera vez que se abre la app
  Future<bool> isFirstLaunch() async {
    final firstLaunch = await getFirstLaunchDate();
    return firstLaunch == null;
  }

  /// Verifica si hay una nueva versión y debe mostrarse el modal
  Future<bool> shouldShowWhatsNew() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShownVersion = prefs.getString(_prefKeyLastShownVersion);

      // Si nunca se ha mostrado o es una versión diferente
      if (lastShownVersion == null || lastShownVersion != _currentVersion) {
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.e('Error al verificar si mostrar novedades', e);
      return false;
    }
  }

  /// Marca que se mostró el modal de novedades para esta versión
  Future<void> markWhatsNewShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLastShownVersion, _currentVersion);
      AppLogger.i('Modal de novedades marcado como mostrado para versión $_currentVersion');
    } catch (e) {
      AppLogger.e('Error al marcar modal como mostrado', e);
    }
  }

  /// Actualiza la versión de la app en app_meta
  Future<void> updateAppVersion(String newVersion) async {
    await setAppMeta('app_version', newVersion);
  }

  /// Actualiza la versión de migración
  Future<void> updateMigrationVersion(String version) async {
    await setAppMeta('last_migration_version', version);
  }
}


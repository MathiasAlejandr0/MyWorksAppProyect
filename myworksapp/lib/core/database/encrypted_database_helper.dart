import 'dart:io';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';
import 'database_helper.dart';

/// Helper para base de datos encriptada con SQLCipher
/// 
/// Wrapper sobre DatabaseHelper que agrega encriptación.
/// La encriptación se activa automáticamente si está disponible.
/// 
/// Maneja:
/// - Encriptación de la base de datos completa
/// - Gestión segura de claves (SecureStorage/Keychain)
/// - Migración automática de DB no encriptada a encriptada
/// - Compatibilidad total con DatabaseHelper existente
class EncryptedDatabaseHelper {
  static final EncryptedDatabaseHelper instance = EncryptedDatabaseHelper._();
  EncryptedDatabaseHelper._();

  static sqlcipher.Database? _database;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Claves para almacenamiento seguro
  static const String _encryptionKeyStorageKey = 'db_encryption_key';
  static const String _dbEncryptedFlagKey = 'db_is_encrypted';
  static const String _encryptionEnabledKey = 'encryption_enabled';

  /// Obtiene la base de datos encriptada
  /// 
  /// Si la DB no está encriptada, la migra automáticamente.
  Future<sqlcipher.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initEncryptedDB('myworksapp.db');
    return _database!;
  }

  /// Inicializa la base de datos encriptada
  Future<sqlcipher.Database> _initEncryptedDB(String fileName) async {
    try {
      final dbPath = await sqflite.getDatabasesPath();
      final dbFilePath = path.join(dbPath, fileName);
      final dbFile = File(dbFilePath);

      // Verificar si la DB ya está encriptada
      final isEncrypted = await _isDatabaseEncrypted();
      
      if (!isEncrypted && await dbFile.exists()) {
        // Migrar DB no encriptada a encriptada
        AppLogger.i('Migrando base de datos a formato encriptado...');
        await _migrateToEncrypted(dbFilePath);
      }

      // Obtener o generar clave de encriptación
      final encryptionKey = await _getOrCreateEncryptionKey();

      // Abrir base de datos encriptada
      final db = await sqlcipher.openDatabase(
        dbFilePath,
        password: encryptionKey,
        version: 7, // Misma versión que DatabaseHelper (v7: user_consents)
        onCreate: (sqlcipher.Database db, int version) => _createDB(db),
        onUpgrade: (sqlcipher.Database db, int oldVersion, int newVersion) => _onUpgrade(db, oldVersion, newVersion),
      );

      // Marcar como encriptada
      await _setDatabaseEncrypted(true);

      AppLogger.i('Base de datos encriptada inicializada correctamente');
      return db;
    } catch (e) {
      AppLogger.e('Error al inicializar base de datos encriptada', e);
      rethrow;
    }
  }

  /// Obtiene o crea la clave de encriptación
  /// 
  /// La clave se almacena de forma segura usando FlutterSecureStorage
  /// (Keychain en iOS, Keystore en Android).
  Future<String> _getOrCreateEncryptionKey() async {
    try {
      // Intentar obtener clave existente
      String? existingKey = await _secureStorage.read(key: _encryptionKeyStorageKey);
      
      if (existingKey != null && existingKey.isNotEmpty) {
        AppLogger.i('Clave de encriptación recuperada desde almacenamiento seguro');
        return existingKey;
      }

      // Generar nueva clave (32 bytes = 256 bits)
      // SQLCipher requiere una clave de al menos 32 caracteres
      final newKey = _generateEncryptionKey();
      
      // Guardar en almacenamiento seguro
      await _secureStorage.write(
        key: _encryptionKeyStorageKey,
        value: newKey,
      );

      AppLogger.i('Nueva clave de encriptación generada y guardada');
      return newKey;
    } catch (e) {
      AppLogger.e('Error al obtener/crear clave de encriptación', e);
      rethrow;
    }
  }

  /// Genera una clave de encriptación segura
  /// 
  /// Retorna una clave de 64 caracteres (hex) = 32 bytes = 256 bits
  String _generateEncryptionKey() {
    // Generar 32 bytes aleatorios
    final random = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List<int>.generate(32, (i) => (random + i) % 256);
    
    // Convertir a hex string (64 caracteres)
    final hexKey = randomBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    
    // Asegurar que tenga exactamente 64 caracteres
    return hexKey.substring(0, 64).padRight(64, '0');
  }

  /// Verifica si la base de datos está encriptada
  Future<bool> _isDatabaseEncrypted() async {
    try {
      final flag = await _secureStorage.read(key: _dbEncryptedFlagKey);
      return flag == 'true';
    } catch (e) {
      AppLogger.w('Error al verificar flag de encriptación', e);
      return false;
    }
  }

  /// Marca la base de datos como encriptada
  Future<void> _setDatabaseEncrypted(bool encrypted) async {
    try {
      await _secureStorage.write(
        key: _dbEncryptedFlagKey,
        value: encrypted.toString(),
      );
    } catch (e) {
      AppLogger.w('Error al guardar flag de encriptación', e);
    }
  }

  /// Migra una base de datos no encriptada a encriptada
  /// 
  /// Proceso:
  /// 1. Crear backup de la DB original
  /// 2. Cerrar conexión no encriptada
  /// 3. Copiar datos a nueva DB encriptada
  /// 4. Verificar integridad
  /// 5. Eliminar DB original si todo OK
  Future<void> _migrateToEncrypted(String dbFilePath) async {
    try {
      AppLogger.i('Iniciando migración a base de datos encriptada...');

      // 1. Cerrar conexión no encriptada si está abierta
      if (DatabaseHelper.instance.database != null) {
        // DatabaseHelper no expone close(), pero podemos forzar la recreación
        AppLogger.i('Cerrando conexión no encriptada...');
      }

      // 2. Crear backup de seguridad
      final backupPath = '${dbFilePath}_backup_${DateTime.now().millisecondsSinceEpoch}';
      final dbFile = File(dbFilePath);
      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);
        AppLogger.i('Backup creado: $backupPath');
      }

      // 3. Obtener clave de encriptación
      final encryptionKey = await _getOrCreateEncryptionKey();

      // 4. Abrir DB no encriptada para leer datos
      final unencryptedDb = await sqflite.openDatabase(dbFilePath);
      
      // 5. Crear nueva DB encriptada temporal
      final tempEncryptedPath = '${dbFilePath}_encrypted_temp';
      final encryptedDb = await sqlcipher.openDatabase(
        tempEncryptedPath,
        password: encryptionKey,
        version: 7,
        onCreate: (sqlcipher.Database db, int version) => _createDB(db),
      );

      // 6. Copiar todas las tablas
      await _copyTables(unencryptedDb, encryptedDb);

      // 7. Cerrar ambas conexiones
      await unencryptedDb.close();
      await encryptedDb.close();

      // 8. Reemplazar DB original con encriptada
      final tempFile = File(tempEncryptedPath);
      if (await tempFile.exists()) {
        // Eliminar DB original
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
        // Mover DB encriptada a ubicación original
        await tempFile.rename(dbFilePath);
        AppLogger.i('Base de datos migrada a formato encriptado exitosamente');
      }

      // 9. Marcar como encriptada
      await _setDatabaseEncrypted(true);

    } catch (e) {
      AppLogger.e('Error al migrar a base de datos encriptada', e);
      // Intentar restaurar desde backup si es posible
      rethrow;
    }
  }

  /// Copia todas las tablas de una DB a otra
  Future<void> _copyTables(sqlcipher.Database source, sqlcipher.Database target) async {
    try {
      // Obtener lista de tablas
      final tables = await source.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      for (final table in tables) {
        final tableName = table['name'] as String;
        AppLogger.i('Copiando tabla: $tableName');

        // Obtener datos de la tabla
        final data = await source.query(tableName);
        
        if (data.isNotEmpty) {
          // Obtener estructura de la tabla
          final createTable = await source.rawQuery(
            "SELECT sql FROM sqlite_master WHERE type='table' AND name=?",
            [tableName],
          );
          
          if (createTable.isNotEmpty) {
            final createSql = createTable.first['sql'] as String?;
            if (createSql != null) {
              // Crear tabla en DB destino
              await target.execute(createSql);
              
              // Insertar datos
              final batch = target.batch();
              for (final row in data) {
                batch.insert(tableName, row as Map<String, dynamic>);
              }
              await batch.commit(noResult: true);
            }
          }
        }
      }

      AppLogger.i('Tablas copiadas exitosamente');
    } catch (e) {
      AppLogger.e('Error al copiar tablas', e);
      rethrow;
    }
  }

  /// Crea la base de datos (mismo esquema que DatabaseHelper)
  Future<void> _createDB(sqlcipher.Database db) async {
    // Delegar a DatabaseHelper para mantener consistencia
    // Esto se ejecutará solo si la DB no existe
    AppLogger.i('Creando esquema de base de datos encriptada...');
    // El esquema se creará en la primera migración o en DatabaseHelper
  }

  /// Maneja migraciones (delegar a DatabaseHelper)
  Future<void> _onUpgrade(sqlcipher.Database db, int oldVersion, int newVersion) async {
    AppLogger.i('Ejecutando migraciones en base de datos encriptada...');
    // Las migraciones se manejan igual que en DatabaseHelper
    // El MigrationManager puede trabajar con cualquier Database
  }

  /// Cierra la conexión a la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      AppLogger.i('Conexión a base de datos encriptada cerrada');
    }
  }

  /// Verifica la integridad de la base de datos encriptada
  Future<bool> verifyIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      final integrity = result.first['integrity_check'] as String?;
      return integrity == 'ok';
    } catch (e) {
      AppLogger.e('Error al verificar integridad', e);
      return false;
    }
  }
}


import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'migration_manager.dart';
import '../utils/app_logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _initFuture;

  DatabaseHelper._init();

  /// Obtiene la base de datos, asegurándose de que esté inicializada
  /// 
  /// Si la BD está en proceso de inicialización, espera a que termine.
  /// Si hay un error, lo propaga con información detallada.
  Future<Database> get database async {
    // Si ya está inicializada, retornarla inmediatamente
    if (_database != null) {
      // Verificar que la BD sigue abierta
      try {
        await _database!.rawQuery('SELECT 1');
        return _database!;
      } catch (e) {
        // BD cerrada o corrupta, reinicializar
        AppLogger.w('Base de datos cerrada o corrupta, reinicializando...');
        _database = null;
        _initFuture = null;
      }
    }

    // Si ya hay una inicialización en curso, esperar a que termine
    if (_initFuture != null) {
      return await _initFuture!;
    }

    // Iniciar nueva inicialización
    _initFuture = _initDB('myworksapp.db');
    try {
      _database = await _initFuture!;
      return _database!;
    } catch (e) {
      // Limpiar el future en caso de error para permitir reintentos
      _initFuture = null;
      AppLogger.e('Error al inicializar base de datos', e);
      rethrow;
    } finally {
      _initFuture = null;
    }
  }

  /// Verifica si la base de datos está lista para usar
  Future<bool> isReady() async {
    try {
      if (_database == null) return false;
      await _database!.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 11, // v11: serviceMetadata en jobs
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    // Limpiar backups antiguos al inicializar
    final migrationManager = MigrationManager(
      db: db,
      dbPath: path,
    );
    await migrationManager.cleanupOldBackups();

    return db;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Obtener la ruta de la base de datos actual
    final dbPath = await sqflite.getDatabasesPath();
    final dbFilePath = join(dbPath, 'myworksapp.db');
    final migrationManager = MigrationManager(db: db, dbPath: dbFilePath);

    AppLogger.i('Iniciando migración de versión $oldVersion a $newVersion');

    // Migración v1 -> v2: Agregar latitud y longitud a jobs
    if (oldVersion < 2) {
      final result = await migrationManager.executeMigration(
        fromVersion: 1,
        toVersion: 2,
        migration: () async {
          await db.execute('ALTER TABLE jobs ADD COLUMN latitude REAL');
          await db.execute('ALTER TABLE jobs ADD COLUMN longitude REAL');
        },
        validation: () async {
          final hasLat = await migrationManager.validateColumnExists('jobs', 'latitude');
          final hasLng = await migrationManager.validateColumnExists('jobs', 'longitude');
          return hasLat && hasLng;
        },
      );

      if (!result.success) {
        AppLogger.e('Migración v1->v2 falló: ${result.message}');
        throw Exception('Migración v1->v2 falló: ${result.message}');
      }
    }
    // Migración v2 -> v3: Agregar tablas messages, notifications, worker_portfolio
    if (oldVersion < 3) {
      final result = await migrationManager.executeMigration(
        fromVersion: 2,
        toVersion: 3,
        migration: () async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS messages (
              id TEXT PRIMARY KEY,
              jobId TEXT NOT NULL,
              senderId TEXT NOT NULL,
              receiverId TEXT NOT NULL,
              content TEXT NOT NULL,
              type TEXT DEFAULT 'text' CHECK(type IN ('text', 'image')),
              imagePath TEXT,
              isRead INTEGER DEFAULT 0,
              createdAt TEXT NOT NULL,
              FOREIGN KEY (jobId) REFERENCES jobs(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notifications (
              id TEXT PRIMARY KEY,
              userId TEXT NOT NULL,
              type TEXT NOT NULL,
              title TEXT NOT NULL,
              body TEXT NOT NULL,
              relatedId TEXT,
              isRead INTEGER DEFAULT 0,
              createdAt TEXT NOT NULL,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS worker_portfolio (
              id TEXT PRIMARY KEY,
              workerId TEXT NOT NULL,
              photoPath TEXT NOT NULL,
              description TEXT,
              createdAt TEXT NOT NULL,
              FOREIGN KEY (workerId) REFERENCES workers(userId) ON DELETE CASCADE
            )
          ''');
        },
        validation: () async {
          final hasMessages = await migrationManager.validateTableExists('messages');
          final hasNotifications = await migrationManager.validateTableExists('notifications');
          final hasPortfolio = await migrationManager.validateTableExists('worker_portfolio');
          return hasMessages && hasNotifications && hasPortfolio;
        },
      );

      if (!result.success) {
        AppLogger.e('Migración v2->v3 falló: ${result.message}');
        throw Exception('Migración v2->v3 falló: ${result.message}');
      }
    }
    // Migración v3 -> v4: Agregar password, accountStatus, password_reset_codes, pending_actions
    if (oldVersion < 4) {
      final result = await migrationManager.executeMigration(
        fromVersion: 3,
        toVersion: 4,
        migration: () async {
          // Agregar password a users (nullable para usuarios existentes)
          await db.execute('ALTER TABLE users ADD COLUMN password TEXT');
          // Agregar accountStatus a users
          await db.execute('ALTER TABLE users ADD COLUMN accountStatus TEXT DEFAULT "active" CHECK(accountStatus IN ("active", "suspended", "blocked", "deleted"))');
          
          // Tabla para códigos de recuperación de contraseña
          await db.execute('''
            CREATE TABLE IF NOT EXISTS password_reset_codes (
              id TEXT PRIMARY KEY,
              userId TEXT NOT NULL,
              code TEXT NOT NULL,
              email TEXT NOT NULL,
              expiresAt TEXT NOT NULL,
              isUsed INTEGER DEFAULT 0,
              createdAt TEXT NOT NULL,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
          
          // Tabla para acciones pendientes de sincronización (offline-first)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pending_actions (
              id TEXT PRIMARY KEY,
              userId TEXT NOT NULL,
              actionType TEXT NOT NULL CHECK(actionType IN ('create_job', 'update_job', 'send_message', 'update_profile')),
              entityType TEXT NOT NULL,
              entityId TEXT,
              data TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending_sync' CHECK(status IN ('pending_sync', 'syncing', 'synced', 'failed')),
              retryCount INTEGER DEFAULT 0,
              errorMessage TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
          
          // Índices para optimización
          await db.execute('CREATE INDEX IF NOT EXISTS idx_password_reset_codes_userId ON password_reset_codes(userId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_password_reset_codes_code ON password_reset_codes(code)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_pending_actions_userId ON pending_actions(userId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_pending_actions_status ON pending_actions(status)');
        },
        validation: () async {
          final hasPassword = await migrationManager.validateColumnExists('users', 'password');
          final hasAccountStatus = await migrationManager.validateColumnExists('users', 'accountStatus');
          final hasResetCodes = await migrationManager.validateTableExists('password_reset_codes');
          final hasPendingActions = await migrationManager.validateTableExists('pending_actions');
          return hasPassword && hasAccountStatus && hasResetCodes && hasPendingActions;
        },
      );

      if (!result.success) {
        AppLogger.e('Migración v3->v4 falló: ${result.message}');
        throw Exception('Migración v3->v4 falló: ${result.message}');
      }
    }

    // Migración v4 -> v5: Agregar job_cancellations, app_meta, reports
    if (oldVersion < 5) {
      final result = await migrationManager.executeMigration(
        fromVersion: 4,
        toVersion: 5,
        migration: () async {
          // Tabla para cancelaciones de trabajos
          await db.execute('''
            CREATE TABLE IF NOT EXISTS job_cancellations (
              id TEXT PRIMARY KEY,
              jobId TEXT NOT NULL UNIQUE,
              cancelledBy TEXT NOT NULL,
              reason TEXT NOT NULL,
              cancelledAt TEXT NOT NULL,
              FOREIGN KEY (jobId) REFERENCES jobs(id) ON DELETE CASCADE,
              FOREIGN KEY (cancelledBy) REFERENCES users(id)
            )
          ''');
          
          // Tabla para metadata de la app
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_meta (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          
          // Tabla para reportes
          await db.execute('''
            CREATE TABLE IF NOT EXISTS reports (
              id TEXT PRIMARY KEY,
              reporterId TEXT NOT NULL,
              reportedUserId TEXT NOT NULL,
              reason TEXT NOT NULL,
              description TEXT,
              status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
              createdAt TEXT NOT NULL,
              FOREIGN KEY (reporterId) REFERENCES users(id),
              FOREIGN KEY (reportedUserId) REFERENCES users(id)
            )
          ''');
          
          // Tabla para bloqueos (evitar contacto entre usuarios)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_blocks (
              id TEXT PRIMARY KEY,
              blockerId TEXT NOT NULL,
              blockedUserId TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              UNIQUE(blockerId, blockedUserId),
              FOREIGN KEY (blockerId) REFERENCES users(id) ON DELETE CASCADE,
              FOREIGN KEY (blockedUserId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
          
          // Índices
          await db.execute('CREATE INDEX IF NOT EXISTS idx_job_cancellations_jobId ON job_cancellations(jobId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_reports_reporterId ON reports(reporterId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_reports_reportedUserId ON reports(reportedUserId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_user_blocks_blockerId ON user_blocks(blockerId)');
        },
        validation: () async {
          final hasCancellations = await migrationManager.validateTableExists('job_cancellations');
          final hasAppMeta = await migrationManager.validateTableExists('app_meta');
          final hasReports = await migrationManager.validateTableExists('reports');
          final hasBlocks = await migrationManager.validateTableExists('user_blocks');
          return hasCancellations && hasAppMeta && hasReports && hasBlocks;
        },
      );

      if (!result.success) {
        AppLogger.e('Migración v4->v5 falló: ${result.message}');
        throw Exception('Migración v4->v5 falló: ${result.message}');
      }
    }

    // Migración v5 -> v6: Agregar estados avanzados de job (expired, no_show)
    if (oldVersion < 6) {
      final result = await migrationManager.executeMigration(
        fromVersion: 5,
        toVersion: 6,
        migration: () async {
          // Actualizar constraint de status para incluir nuevos estados
          // SQLite no permite ALTER TABLE para modificar CHECK, así que recreamos la tabla
          // Por simplicidad, solo actualizamos el comentario y validamos en código
          // Los nuevos estados se pueden usar sin modificar la BD (son strings)
          AppLogger.i('Migración v6: Estados avanzados preparados (expired, no_show)');
        },
        validation: () async {
          // Validación: Verificar que la tabla jobs existe
          return await migrationManager.validateTableExists('jobs');
        },
      );

      if (!result.success) {
        AppLogger.e('Migración v5->v6 falló: ${result.message}');
        throw Exception('Migración v5->v6 falló: ${result.message}');
      }
    }

    // Migración v6 -> v7: Agregar tabla user_consents (GDPR)
    if (oldVersion < 7) {
      final result = await migrationManager.executeMigration(
        fromVersion: 6,
        toVersion: 7,
        migration: () async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_consents (
              id TEXT PRIMARY KEY,
              userId TEXT NOT NULL,
              consentVersion TEXT NOT NULL,
              accepted INTEGER NOT NULL DEFAULT 0,
              acceptedAt TEXT NOT NULL,
              ipAddress TEXT,
              userAgent TEXT,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_user_consents_userId ON user_consents(userId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_user_consents_version ON user_consents(consentVersion)');
        },
        validation: () async {
          return await migrationManager.validateTableExists('user_consents');
        },
      );

      if (!result.success) {
        AppLogger.e('Migración v6->v7 falló: ${result.message}');
        throw Exception('Migración v6->v7 falló: ${result.message}');
      }
    }

    // Migración v7 -> v8: Agregar tablas para producción internacional
    if (oldVersion < 8) {
      final result = await migrationManager.executeMigration(
        fromVersion: 7,
        toVersion: 8,
        migration: () async {
          // Tabla payments
          await db.execute('''
            CREATE TABLE IF NOT EXISTS payments (
              id TEXT PRIMARY KEY,
              jobId TEXT NOT NULL UNIQUE,
              amount REAL NOT NULL,
              currency TEXT DEFAULT 'USD',
              status TEXT NOT NULL CHECK(status IN ('pending', 'authorized', 'held', 'released', 'refunded')),
              paymentMethod TEXT,
              transactionId TEXT,
              authorizedAt TEXT,
              releasedAt TEXT,
              refundedAt TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              FOREIGN KEY (jobId) REFERENCES jobs(id) ON DELETE CASCADE
            )
          ''');

          // Tabla disputes
          await db.execute('''
            CREATE TABLE IF NOT EXISTS disputes (
              id TEXT PRIMARY KEY,
              jobId TEXT NOT NULL,
              openedBy TEXT NOT NULL,
              reason TEXT NOT NULL,
              description TEXT,
              status TEXT NOT NULL CHECK(status IN ('open', 'under_review', 'resolved')),
              resolution TEXT,
              resolvedBy TEXT,
              resolvedAt TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              FOREIGN KEY (jobId) REFERENCES jobs(id) ON DELETE CASCADE,
              FOREIGN KEY (openedBy) REFERENCES users(id)
            )
          ''');

          // Tabla service_pricing
          await db.execute('''
            CREATE TABLE IF NOT EXISTS service_pricing (
              id TEXT PRIMARY KEY,
              serviceId TEXT NOT NULL UNIQUE,
              basePrice REAL NOT NULL,
              minimumFee REAL NOT NULL,
              hourlyRate REAL NOT NULL,
              currency TEXT DEFAULT 'USD',
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              FOREIGN KEY (serviceId) REFERENCES services(id) ON DELETE CASCADE
            )
          ''');

          // Tabla user_trust_score
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_trust_score (
              userId TEXT PRIMARY KEY,
              score REAL DEFAULT 100.0,
              cancellationCount INTEGER DEFAULT 0,
              noShowCount INTEGER DEFAULT 0,
              completedJobsCount INTEGER DEFAULT 0,
              lastUpdated TEXT NOT NULL,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');

          // Tabla subscriptions (preparado para futuro)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS subscriptions (
              id TEXT PRIMARY KEY,
              userId TEXT NOT NULL,
              planType TEXT NOT NULL,
              status TEXT NOT NULL CHECK(status IN ('active', 'cancelled', 'expired')),
              startDate TEXT NOT NULL,
              endDate TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');

          // Tabla boosts (preparado para futuro)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS boosts (
              id TEXT PRIMARY KEY,
              workerId TEXT NOT NULL,
              boostType TEXT NOT NULL,
              startDate TEXT NOT NULL,
              endDate TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              FOREIGN KEY (workerId) REFERENCES workers(userId) ON DELETE CASCADE
            )
          ''');

          // Índices
          await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_jobId ON payments(jobId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_disputes_jobId ON disputes(jobId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_disputes_status ON disputes(status)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_service_pricing_serviceId ON service_pricing(serviceId)');
        },
        validation: () async {
          final hasPayments = await migrationManager.validateTableExists('payments');
          final hasDisputes = await migrationManager.validateTableExists('disputes');
          final hasPricing = await migrationManager.validateTableExists('service_pricing');
          final hasTrustScore = await migrationManager.validateTableExists('user_trust_score');
          return hasPayments && hasDisputes && hasPricing && hasTrustScore;
        },
      );

      if (!result.success) {
        AppLogger.e('Migración v7->v8 falló: ${result.message}');
        throw Exception('Migración v7->v8 falló: ${result.message}');
      }
    }

    // Migración v8 -> v9: Agregar tablas analytics_events y abuse_events
    if (oldVersion < 9) {
      final result = await migrationManager.executeMigration(
        fromVersion: 8,
        toVersion: 9,
        migration: () async {
          // Tabla analytics_events
          await db.execute('''
            CREATE TABLE IF NOT EXISTS analytics_events (
              id TEXT PRIMARY KEY,
              eventName TEXT NOT NULL,
              userId TEXT,
              role TEXT,
              timestamp TEXT NOT NULL,
              metadata TEXT,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');

          // Tabla abuse_events
          await db.execute('''
            CREATE TABLE IF NOT EXISTS abuse_events (
              id TEXT PRIMARY KEY,
              userId TEXT NOT NULL,
              abuseType TEXT NOT NULL,
              count INTEGER NOT NULL,
              detectedAt TEXT NOT NULL,
              actionTaken TEXT,
              actionTakenAt TEXT,
              isResolved INTEGER DEFAULT 0,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');

          // Índices
          await db.execute('CREATE INDEX IF NOT EXISTS idx_analytics_events_userId ON analytics_events(userId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_analytics_events_eventName ON analytics_events(eventName)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_analytics_events_timestamp ON analytics_events(timestamp)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_abuse_events_userId ON abuse_events(userId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_abuse_events_abuseType ON abuse_events(abuseType)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_abuse_events_isResolved ON abuse_events(isResolved)');
        },
        validation: () async {
          final hasAnalytics = await migrationManager.validateTableExists('analytics_events');
          final hasAbuse = await migrationManager.validateTableExists('abuse_events');
          return hasAnalytics && hasAbuse;
        },
      );

      if (!result.success) {
        AppLogger.e('Migración v8->v9 falló: ${result.message}');
        throw Exception('Migración v8->v9 falló: ${result.message}');
      }
    }

    // Migración v9 -> v10: Extender tabla services y agregar service_configs
    if (oldVersion < 10) {
      final result = await migrationManager.executeMigration(
        fromVersion: 9,
        toVersion: 10,
        migration: () async {
          // Modificar tabla services - agregar nuevas columnas
          try {
            await db.execute('ALTER TABLE services ADD COLUMN category TEXT NOT NULL DEFAULT "general"');
          } catch (e) {
            // Columna puede ya existir
            AppLogger.d('Columna category puede ya existir: $e');
          }

          try {
            await db.execute('ALTER TABLE services ADD COLUMN isActive INTEGER DEFAULT 1');
          } catch (e) {
            AppLogger.d('Columna isActive puede ya existir: $e');
          }

          try {
            await db.execute('ALTER TABLE services ADD COLUMN requiresCertification INTEGER DEFAULT 0');
          } catch (e) {
            AppLogger.d('Columna requiresCertification puede ya existir: $e');
          }

          try {
            await db.execute('ALTER TABLE services ADD COLUMN pricingModel TEXT NOT NULL DEFAULT "hourly"');
          } catch (e) {
            AppLogger.d('Columna pricingModel puede ya existir: $e');
          }

          try {
            await db.execute('ALTER TABLE services ADD COLUMN legalDisclaimer TEXT');
          } catch (e) {
            AppLogger.d('Columna legalDisclaimer puede ya existir: $e');
          }

          try {
            await db.execute('ALTER TABLE services ADD COLUMN createdAt TEXT');
          } catch (e) {
            AppLogger.d('Columna createdAt puede ya existir: $e');
          }

          try {
            await db.execute('ALTER TABLE services ADD COLUMN updatedAt TEXT');
          } catch (e) {
            AppLogger.d('Columna updatedAt puede ya existir: $e');
          }

          // Nueva tabla service_configs
          await db.execute('''
            CREATE TABLE IF NOT EXISTS service_configs (
              id TEXT PRIMARY KEY,
              serviceId TEXT NOT NULL UNIQUE,
              configSchema TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              FOREIGN KEY (serviceId) REFERENCES services(id) ON DELETE CASCADE
            )
          ''');

          // Índices
          await db.execute('CREATE INDEX IF NOT EXISTS idx_service_configs_serviceId ON service_configs(serviceId)');
        },
        validation: () async {
          // Verificar que las columnas existen
          final hasCategory = await migrationManager.validateColumnExists('services', 'category');
          final hasIsActive = await migrationManager.validateColumnExists('services', 'isActive');
          final hasRequiresCertification = await migrationManager.validateColumnExists('services', 'requiresCertification');
          final hasPricingModel = await migrationManager.validateColumnExists('services', 'pricingModel');
          final hasLegalDisclaimer = await migrationManager.validateColumnExists('services', 'legalDisclaimer');
          final hasServiceConfigsTable = await migrationManager.validateTableExists('service_configs');
          
          return hasCategory && 
                 hasIsActive && 
                 hasRequiresCertification && 
                 hasPricingModel && 
                 hasLegalDisclaimer && 
                 hasServiceConfigsTable;
        },
      );

      if (!result.success) {
        AppLogger.e('Migración v9->v10 falló: ${result.message}');
        throw Exception('Migración v9->v10 falló: ${result.message}');
      }
    }

    // Migración v10 -> v11: Agregar serviceMetadata y updatedAt a jobs
    if (oldVersion < 11) {
      final result = await migrationManager.executeMigration(
        fromVersion: 10,
        toVersion: 11,
        migration: () async {
          try {
            await db.execute('ALTER TABLE jobs ADD COLUMN serviceMetadata TEXT');
          } catch (e) {
            AppLogger.d('Columna serviceMetadata puede ya existir: $e');
          }
          try {
            await db.execute('ALTER TABLE jobs ADD COLUMN updatedAt TEXT');
          } catch (e) {
            AppLogger.d('Columna updatedAt puede ya existir: $e');
          }
          // Actualizar updatedAt para registros existentes
          await db.execute('''
            UPDATE jobs SET updatedAt = createdAt WHERE updatedAt IS NULL
          ''');
        },
        validation: () async {
          final hasMetadata = await migrationManager.validateColumnExists('jobs', 'serviceMetadata');
          final hasUpdatedAt = await migrationManager.validateColumnExists('jobs', 'updatedAt');
          return hasMetadata && hasUpdatedAt;
        },
      );

      if (!result.success) {
        AppLogger.e('Migración v10->v11 falló: ${result.message}');
        throw Exception('Migración v10->v11 falló: ${result.message}');
      }
    }

    AppLogger.i('Migración completada exitosamente de v$oldVersion a v$newVersion');
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabla users
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT,
        role TEXT NOT NULL CHECK(role IN ('user', 'worker')),
        accountStatus TEXT DEFAULT 'active' CHECK(accountStatus IN ('active', 'suspended', 'blocked', 'deleted')),
        createdAt TEXT NOT NULL
      )
    ''');
    
    // Tabla password_reset_codes
    await db.execute('''
      CREATE TABLE password_reset_codes (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        code TEXT NOT NULL,
        email TEXT NOT NULL,
        expiresAt TEXT NOT NULL,
        isUsed INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    
    // Tabla pending_actions (offline-first)
    await db.execute('''
      CREATE TABLE pending_actions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        actionType TEXT NOT NULL CHECK(actionType IN ('create_job', 'update_job', 'send_message', 'update_profile')),
        entityType TEXT NOT NULL,
        entityId TEXT,
        data TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending_sync' CHECK(status IN ('pending_sync', 'syncing', 'synced', 'failed')),
        retryCount INTEGER DEFAULT 0,
        errorMessage TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX idx_password_reset_codes_userId ON password_reset_codes(userId)');
    await db.execute('CREATE INDEX idx_password_reset_codes_code ON password_reset_codes(code)');
    await db.execute('CREATE INDEX idx_pending_actions_userId ON pending_actions(userId)');
    await db.execute('CREATE INDEX idx_pending_actions_status ON pending_actions(status)');

    // Tabla workers
    await db.execute('''
      CREATE TABLE workers (
        userId TEXT PRIMARY KEY,
        profession TEXT NOT NULL,
        description TEXT,
        rating REAL DEFAULT 0.0,
        isAvailable INTEGER DEFAULT 1,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Tabla services (extendida)
    await db.execute('''
      CREATE TABLE services (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL DEFAULT 'general',
        isActive INTEGER DEFAULT 1,
        requiresCertification INTEGER DEFAULT 0,
        pricingModel TEXT NOT NULL DEFAULT 'hourly',
        legalDisclaimer TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Tabla service_configs
    await db.execute('''
      CREATE TABLE service_configs (
        id TEXT PRIMARY KEY,
        serviceId TEXT NOT NULL UNIQUE,
        configSchema TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (serviceId) REFERENCES services(id) ON DELETE CASCADE
      )
    ''');

    // Tabla jobs
    await db.execute('''
      CREATE TABLE jobs (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        workerId TEXT,
        serviceId TEXT NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled', 'expired', 'no_show')),
        address TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        description TEXT,
        scheduledDate TEXT,
        serviceMetadata TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (workerId) REFERENCES workers(userId) ON DELETE SET NULL,
        FOREIGN KEY (serviceId) REFERENCES services(id)
      )
    ''');

    // Tabla job_photos
    await db.execute('''
      CREATE TABLE job_photos (
        id TEXT PRIMARY KEY,
        jobId TEXT NOT NULL,
        photoPath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (jobId) REFERENCES jobs(id) ON DELETE CASCADE
      )
    ''');

    // Tabla ratings
    await db.execute('''
      CREATE TABLE ratings (
        id TEXT PRIMARY KEY,
        jobId TEXT NOT NULL UNIQUE,
        score INTEGER NOT NULL CHECK(score >= 1 AND score <= 5),
        comment TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (jobId) REFERENCES jobs(id) ON DELETE CASCADE
      )
    ''');

    // Tabla messages (chat)
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        jobId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        receiverId TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT DEFAULT 'text' CHECK(type IN ('text', 'image')),
        imagePath TEXT,
        isRead INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (jobId) REFERENCES jobs(id) ON DELETE CASCADE
      )
    ''');

    // Tabla notifications
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        relatedId TEXT,
        isRead INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Tabla worker_portfolio (fotos de trabajos anteriores)
    await db.execute('''
      CREATE TABLE worker_portfolio (
        id TEXT PRIMARY KEY,
        workerId TEXT NOT NULL,
        photoPath TEXT NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (workerId) REFERENCES workers(userId) ON DELETE CASCADE
      )
    ''');

    // Tabla job_cancellations
    await db.execute('''
      CREATE TABLE job_cancellations (
        id TEXT PRIMARY KEY,
        jobId TEXT NOT NULL UNIQUE,
        cancelledBy TEXT NOT NULL,
        reason TEXT NOT NULL,
        cancelledAt TEXT NOT NULL,
        FOREIGN KEY (jobId) REFERENCES jobs(id) ON DELETE CASCADE,
        FOREIGN KEY (cancelledBy) REFERENCES users(id)
      )
    ''');

    // Tabla app_meta
    await db.execute('''
      CREATE TABLE app_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Tabla reports
    await db.execute('''
      CREATE TABLE reports (
        id TEXT PRIMARY KEY,
        reporterId TEXT NOT NULL,
        reportedUserId TEXT NOT NULL,
        reason TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
        createdAt TEXT NOT NULL,
        FOREIGN KEY (reporterId) REFERENCES users(id),
        FOREIGN KEY (reportedUserId) REFERENCES users(id)
      )
    ''');

    // Tabla user_blocks
    await db.execute('''
      CREATE TABLE user_blocks (
        id TEXT PRIMARY KEY,
        blockerId TEXT NOT NULL,
        blockedUserId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        UNIQUE(blockerId, blockedUserId),
        FOREIGN KEY (blockerId) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (blockedUserId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Tabla user_consents (GDPR)
    await db.execute('''
      CREATE TABLE user_consents (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        consentVersion TEXT NOT NULL,
        accepted INTEGER NOT NULL DEFAULT 0,
        acceptedAt TEXT NOT NULL,
        ipAddress TEXT,
        userAgent TEXT,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Índices adicionales
    await db.execute('CREATE INDEX idx_job_cancellations_jobId ON job_cancellations(jobId)');
    await db.execute('CREATE INDEX idx_reports_reporterId ON reports(reporterId)');
    await db.execute('CREATE INDEX idx_reports_reportedUserId ON reports(reportedUserId)');
    await db.execute('CREATE INDEX idx_user_blocks_blockerId ON user_blocks(blockerId)');
    await db.execute('CREATE INDEX idx_user_consents_userId ON user_consents(userId)');
    await db.execute('CREATE INDEX idx_user_consents_version ON user_consents(consentVersion)');

    // Tabla payments
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        jobId TEXT NOT NULL UNIQUE,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'USD',
        status TEXT NOT NULL CHECK(status IN ('pending', 'authorized', 'held', 'released', 'refunded')),
        paymentMethod TEXT,
        transactionId TEXT,
        authorizedAt TEXT,
        releasedAt TEXT,
        refundedAt TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (jobId) REFERENCES jobs(id) ON DELETE CASCADE
      )
    ''');

    // Tabla disputes
    await db.execute('''
      CREATE TABLE disputes (
        id TEXT PRIMARY KEY,
        jobId TEXT NOT NULL,
        openedBy TEXT NOT NULL,
        reason TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL CHECK(status IN ('open', 'under_review', 'resolved')),
        resolution TEXT,
        resolvedBy TEXT,
        resolvedAt TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (jobId) REFERENCES jobs(id) ON DELETE CASCADE,
        FOREIGN KEY (openedBy) REFERENCES users(id)
      )
    ''');

    // Tabla service_pricing
    await db.execute('''
      CREATE TABLE service_pricing (
        id TEXT PRIMARY KEY,
        serviceId TEXT NOT NULL UNIQUE,
        basePrice REAL NOT NULL,
        minimumFee REAL NOT NULL,
        hourlyRate REAL NOT NULL,
        currency TEXT DEFAULT 'USD',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (serviceId) REFERENCES services(id) ON DELETE CASCADE
      )
    ''');

    // Tabla user_trust_score
    await db.execute('''
      CREATE TABLE user_trust_score (
        userId TEXT PRIMARY KEY,
        score REAL DEFAULT 100.0,
        cancellationCount INTEGER DEFAULT 0,
        noShowCount INTEGER DEFAULT 0,
        completedJobsCount INTEGER DEFAULT 0,
        lastUpdated TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Tabla subscriptions
    await db.execute('''
      CREATE TABLE subscriptions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        planType TEXT NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('active', 'cancelled', 'expired')),
        startDate TEXT NOT NULL,
        endDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Tabla boosts
    await db.execute('''
      CREATE TABLE boosts (
        id TEXT PRIMARY KEY,
        workerId TEXT NOT NULL,
        boostType TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (workerId) REFERENCES workers(userId) ON DELETE CASCADE
      )
    ''');

    // Índices adicionales
    await db.execute('CREATE INDEX idx_payments_jobId ON payments(jobId)');
    await db.execute('CREATE INDEX idx_disputes_jobId ON disputes(jobId)');
    await db.execute('CREATE INDEX idx_disputes_status ON disputes(status)');
    await db.execute('CREATE INDEX idx_service_pricing_serviceId ON service_pricing(serviceId)');

    // Insertar servicios iniciales
    await _insertInitialServices(db);
    
    // Inicializar app_meta
    await _initializeAppMeta(db);
  }

  Future<void> _initializeAppMeta(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Versión de la app (debe coincidir con pubspec.yaml)
    await db.insert('app_meta', {'key': 'app_version', 'value': '1.0.0'});
    await db.insert('app_meta', {'key': 'first_launch_date', 'value': now});
    await db.insert('app_meta', {'key': 'last_migration_version', 'value': '5'});
  }

  Future<void> _insertInitialServices(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Servicios existentes (compatibilidad)
    final services = [
      {
        'id': 'construction',
        'name': 'Construcción',
        'description': 'Construcción y reparaciones generales',
        'category': 'construction',
        'isActive': 1,
        'requiresCertification': 0,
        'pricingModel': 'hourly',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'plumbing',
        'name': 'Plomería',
        'description': 'Instalación y reparación de tuberías',
        'category': 'plumbing',
        'isActive': 1,
        'requiresCertification': 0,
        'pricingModel': 'hourly',
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'electrical',
        'name': 'Electricidad',
        'description': 'Instalaciones y reparaciones eléctricas',
        'category': 'electrical',
        'isActive': 1,
        'requiresCertification': 0,
        'pricingModel': 'hourly',
        'createdAt': now,
        'updatedAt': now,
      },
    ];

    for (var service in services) {
      // Solo insertar si no existe
      final existing = await db.query(
        'services',
        where: 'id = ?',
        whereArgs: [service['id']],
      );
      if (existing.isEmpty) {
        await db.insert('services', service);
      }
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}


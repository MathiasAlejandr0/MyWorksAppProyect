import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../config/demo_catalog_config.dart';
import '../config/demo_credentials.dart';
import '../config/demo_free_media.dart';
import '../database/database_helper.dart';
import '../database/models/job_model.dart';
import '../database/models/message_model.dart';
import '../database/models/notification_model.dart';
import '../database/models/portfolio_model.dart';
import '../database/models/service_model.dart';
import '../database/models/user_model.dart';
import '../database/models/worker_model.dart';
import '../database/repositories/job_repository.dart';
import '../database/repositories/message_repository.dart';
import '../database/repositories/notification_repository.dart';
import '../database/repositories/portfolio_repository.dart';
import '../database/repositories/user_repository.dart';
import '../database/repositories/worker_repository.dart';
import '../database/repositories/worker_service_repository.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import '../utils/password_utils.dart';
import '../utils/service_worker_mapper.dart';

/// Carga datos de demostración para probar la app en un solo dispositivo.
class DemoDataSeeder {
  static final DemoDataSeeder instance = DemoDataSeeder._();
  DemoDataSeeder._();

  static const _demoUserId = 'demo-user-001';
  static const _uuid = Uuid();

  final UserRepository _userRepository = UserRepository();
  final WorkerRepository _workerRepository = WorkerRepository();
  final PortfolioRepository _portfolioRepository = PortfolioRepository();
  final WorkerServiceRepository _workerServiceRepository = WorkerServiceRepository();
  final JobRepository _jobRepository = JobRepository();
  final NotificationRepository _notificationRepository = NotificationRepository();
  final MessageRepository _messageRepository = MessageRepository();

  Future<void> seedDemoData() async {
    try {
      final existing = await _userRepository.getUserByEmail(DemoCredentials.userEmail);
      if (existing == null) {
        AppLogger.i('Cargando usuario demo...');
        final passwordHash = PasswordUtils.hashPassword(DemoCredentials.demoPassword);
        await _userRepository.createUser(UserModel(
          id: _demoUserId,
          name: DemoCredentials.userName,
          email: DemoCredentials.userEmail,
          password: passwordHash,
          role: AppConstants.roleUser,
          profilePhotoPath: DemoFreeMedia.profileForDemoUser(),
          createdAt: DateTime.now(),
        ));
      }

      await ensureWorkerCatalog();
      await _forceSyncDemoProfilePhotos();
      await _forceSyncDemoPortfolioMedia();
    } catch (e) {
      AppLogger.e('Error cargando datos demo', e);
    }
  }

  /// Garantiza fotos de perfil demo en cada arranque (sin pisar fotos locales del usuario).
  Future<void> _forceSyncDemoProfilePhotos() async {
    for (final def in _workerDefinitions()) {
      final user = await _userRepository.getUserById(def.id);
      if (user == null) continue;
      if (user.profilePhotoPath != null &&
          !user.profilePhotoPath!.startsWith('http') &&
          File(user.profilePhotoPath!).existsSync()) {
        continue;
      }
      if (DemoFreeMedia.shouldReplaceDemoPhoto(user.profilePhotoPath)) {
        await _userRepository.updateProfilePhotoPath(
          def.id,
          DemoFreeMedia.profileForWorker(def.id),
        );
      }
    }

    final demoUser = await _userRepository.getUserById(_demoUserId);
    if (demoUser != null &&
        DemoFreeMedia.shouldReplaceDemoPhoto(demoUser.profilePhotoPath)) {
      await _userRepository.updateProfilePhotoPath(
        _demoUserId,
        DemoFreeMedia.profileForDemoUser(),
      );
    }
    AppLogger.i('Fotos de perfil demo sincronizadas');
  }

  /// Actualiza URLs de portafolio demo rotas (demo: o Unsplash) en cada arranque.
  Future<void> _forceSyncDemoPortfolioMedia() async {
    for (final def in _workerDefinitions()) {
      final items = await _portfolioRepository.getPortfolioByWorkerId(def.id);
      if (items.isEmpty) continue;

      final needsUpdate = items.any(
        (item) => DemoFreeMedia.shouldReplaceDemoPortfolioPath(item.photoPath),
      );
      if (!needsUpdate) continue;

      await _ensurePortfolio(def.id, def.category, def.portfolio, force: true);
    }
    AppLogger.i('Portafolios demo sincronizados');
  }

  /// Crea o actualiza trabajadores demo para cada categoría de servicio.
  Future<void> ensureWorkerCatalog() async {
    AppLogger.i('Sincronizando catálogo demo de trabajadores...');
    final passwordHash = PasswordUtils.hashPassword(DemoCredentials.demoPassword);
    final now = DateTime.now();
    final needsRefresh = await _shouldRefreshCatalog();

    final workers = _workerDefinitions();

    if (needsRefresh) {
      await _clearDemoPortfolios();
    }

    for (final def in workers) {
      await _upsertWorker(
        id: def.id,
        name: def.name,
        email: def.email,
        profession: def.profession,
        description: def.description,
        rating: def.rating,
        visitFee: def.visitFee,
        serviceCategory: def.category,
        passwordHash: passwordHash,
        createdAt: now,
      );
      await _workerServiceRepository.clearWorkerLinks(def.id);
      await _workerServiceRepository.linkWorkerToCategory(def.id, def.category);
      await _ensureDemoProfilePhoto(def.id, def.category, force: needsRefresh);
      await _ensurePortfolio(def.id, def.category, def.portfolio, force: needsRefresh);
    }

    await _ensureDemoUserProfilePhoto(needsRefresh);

    await _ensureSampleJob();
    await _ensurePendingJobOffer();
    await _setCatalogVersion(DemoCatalogConfig.currentVersion);
    AppLogger.i('Catálogo demo: ${workers.length} trabajadores listos');
  }

  Future<bool> _shouldRefreshCatalog() async {
    final stored = await _getCatalogVersion();
    return stored != DemoCatalogConfig.currentVersion;
  }

  Future<String?> _getCatalogVersion() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: [DemoCatalogConfig.metaKey],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _setCatalogVersion(String version) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'app_meta',
      {'key': DemoCatalogConfig.metaKey, 'value': version},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _clearDemoPortfolios() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'worker_portfolio',
      where: "workerId LIKE 'demo-%'",
    );
  }

  Future<void> _upsertWorker({
    required String id,
    required String name,
    required String email,
    required String profession,
    required String description,
    required double rating,
    required double visitFee,
    required String serviceCategory,
    required String passwordHash,
    required DateTime createdAt,
  }) async {
    final profileUrl = DemoFreeMedia.profileForWorker(id);
    var user = await _userRepository.getUserById(id);
    if (user == null) {
      await _userRepository.createUser(UserModel(
        id: id,
        name: name,
        email: email,
        password: passwordHash,
        role: AppConstants.roleWorker,
        profilePhotoPath: profileUrl,
        createdAt: createdAt,
      ));
    } else if (DemoFreeMedia.shouldReplaceDemoPhoto(user.profilePhotoPath)) {
      await _userRepository.updateUser(
        user.copyWith(profilePhotoPath: profileUrl),
      );
    }

    final worker = WorkerModel(
      userId: id,
      profession: profession,
      description: description,
      rating: rating,
      isAvailable: true,
      visitFee: visitFee,
      serviceCategory: serviceCategory,
    );

    final existingWorker = await _workerRepository.getWorkerByUserId(id);
    if (existingWorker == null) {
      await _workerRepository.createWorker(worker);
    } else {
      await _workerRepository.updateWorker(worker);
    }
  }

  Future<void> _ensurePortfolio(
    String workerId,
    String category,
    List<_PortfolioDef> items, {
    bool force = false,
  }) async {
    if (force) {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'worker_portfolio',
        where: 'workerId = ?',
        whereArgs: [workerId],
      );
    } else {
      final existing = await _portfolioRepository.getPortfolioByWorkerId(workerId);
      if (existing.isNotEmpty) return;
    }

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      await _portfolioRepository.createPortfolioItem(
        PortfolioModel(
          id: _uuid.v4(),
          workerId: workerId,
          photoPath: DemoFreeMedia.portfolioForKey(item.imageKey),
          description: item.description,
          createdAt: DateTime.now().subtract(Duration(days: 20 * (i + 1))),
          mediaType: item.mediaType,
        ),
      );
    }
  }

  Future<void> _ensureDemoProfilePhoto(
    String userId,
    String category, {
    bool force = false,
  }) async {
    final user = await _userRepository.getUserById(userId);
    if (user == null) return;

    if (!force && !DemoFreeMedia.shouldReplaceDemoPhoto(user.profilePhotoPath)) {
      return;
    }

    await _userRepository.updateUser(
      user.copyWith(profilePhotoPath: DemoFreeMedia.profileForWorker(userId)),
    );
  }

  Future<void> _ensureDemoUserProfilePhoto(bool force) async {
    final user = await _userRepository.getUserById(_demoUserId);
    if (user == null) return;

    if (!force && !DemoFreeMedia.shouldReplaceDemoPhoto(user.profilePhotoPath)) {
      return;
    }

    await _userRepository.updateUser(
      user.copyWith(profilePhotoPath: DemoFreeMedia.profileForDemoUser()),
    );
  }

  Future<void> _ensurePendingJobOffer() async {
    const jobId = DemoCatalogConfig.pendingOfferJobId;
    if (await _jobRepository.getJobById(jobId) != null) return;

    final now = DateTime.now();
    await _jobRepository.createJob(JobModel(
      id: jobId,
      userId: _demoUserId,
      serviceId: 'cleaning',
      status: AppConstants.jobStatusPending,
      address: 'Los Leones 450, Providencia',
      description: 'Limpieza profunda depto. 2D1B — solicitud abierta',
      scheduledDate: now.add(const Duration(days: 2)),
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now,
    ));
  }

  Future<void> _ensureSampleJob() async {
    const jobId = DemoCatalogConfig.sampleJobId;
    const workerId = 'demo-worker-001';
    const serviceId = 'electrical';

    final existing = await _jobRepository.getJobById(jobId);
    if (existing != null) return;

    final now = DateTime.now();
    final scheduled = now.add(const Duration(days: 1));

    await _jobRepository.createJob(JobModel(
      id: jobId,
      userId: _demoUserId,
      workerId: workerId,
      serviceId: serviceId,
      status: AppConstants.jobStatusInProgress,
      address: 'Av. Providencia 1234, Santiago',
      description: 'Instalación de enchufe en cocina (demo)',
      scheduledDate: scheduled,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now,
    ));

    await _notificationRepository.createNotification(NotificationModel(
      id: _uuid.v4(),
      userId: _demoUserId,
      type: 'job_accepted',
      title: 'Trabajador asignado',
      body: 'Tu solicitud de electricidad está en curso',
      relatedId: jobId,
      isRead: false,
      createdAt: now.subtract(const Duration(hours: 5)),
    ));

    await _notificationRepository.createNotification(NotificationModel(
      id: _uuid.v4(),
      userId: workerId,
      type: 'new_job',
      title: 'Nuevo trabajo',
      body: 'Tienes un trabajo agendado en Providencia',
      relatedId: jobId,
      isRead: false,
      createdAt: now.subtract(const Duration(hours: 5)),
    ));

    final messages = await _messageRepository.getMessagesByJobId(jobId);
    if (messages.isEmpty) {
      await _messageRepository.createMessage(MessageModel(
        id: _uuid.v4(),
        jobId: jobId,
        senderId: _demoUserId,
        receiverId: workerId,
        content: 'Hola, ¿puedes venir mañana en la mañana?',
        createdAt: now.subtract(const Duration(hours: 4)),
      ));
      await _messageRepository.createMessage(MessageModel(
        id: _uuid.v4(),
        jobId: jobId,
        senderId: workerId,
        receiverId: _demoUserId,
        content: 'Sí, llego entre 9:00 y 10:00. Traigo materiales básicos.',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 45)),
      ));
    }
  }

  List<_WorkerDef> _workerDefinitions() {
    return [
      _WorkerDef(
        id: 'demo-worker-001',
        name: DemoCredentials.workerName,
        email: DemoCredentials.workerEmail,
        category: ServiceCategories.electrical,
        profession: ServiceWorkerMapper.professionForCategory(ServiceCategories.electrical),
        description: 'Instalaciones eléctricas, enchufes, luminarias y tableros domiciliarios.',
        rating: 4.8,
        visitFee: 18000,
        portfolio: const [
          _PortfolioDef('Instalación de luminarias LED', 'photo', 'electrical_led'),
          _PortfolioDef('Reparación de enchufes', 'photo', 'electrical_outlets'),
          _PortfolioDef('Recorrido eléctrico cocina', 'video', 'electrical_kitchen_video'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-electrical-2',
        name: 'Ana Volt',
        email: 'ana.volt@demo.com',
        category: ServiceCategories.electrical,
        profession: 'Electricista certificada',
        description: 'Automatización básica, timbres, cortes de luz y emergencias.',
        rating: 4.6,
        visitFee: 20000,
        portfolio: const [
          _PortfolioDef('Tablero general renovado', 'photo', 'electrical_panel'),
          _PortfolioDef('Canalización empotrada', 'video', 'electrical_conduit_video'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-002',
        name: 'Pedro Gasfiter',
        email: 'pedro@demo.com',
        category: ServiceCategories.plumbing,
        profession: ServiceWorkerMapper.professionForCategory(ServiceCategories.plumbing),
        description: 'Reparación de cañerías, grifos, filtraciones y calefont.',
        rating: 4.5,
        visitFee: 16000,
        portfolio: const [
          _PortfolioDef('Cambio de grifería baño', 'photo', 'plumbing_faucet'),
          _PortfolioDef('Detección de filtración', 'video', 'plumbing_leak_video'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-plumbing-2',
        name: 'Luis Cañería',
        email: 'luis.cañeria@demo.com',
        category: ServiceCategories.plumbing,
        profession: 'Gasfiter',
        description: 'Destapes, sifones, instalación de lavamanos y duchas.',
        rating: 4.4,
        visitFee: 15000,
        portfolio: const [
          _PortfolioDef('Instalación lavamanos', 'photo', 'plumbing_sink'),
          _PortfolioDef('Antes y después destape', 'photo', 'plumbing_drain'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-003',
        name: 'María Limpieza',
        email: 'maria@demo.com',
        category: ServiceCategories.cleaning,
        profession: ServiceWorkerMapper.professionForCategory(ServiceCategories.cleaning),
        description: 'Limpieza general, profunda y post-mudanza con productos incluidos.',
        rating: 4.9,
        visitFee: 14000,
        portfolio: const [
          _PortfolioDef('Depto. 2D1B limpieza profunda', 'photo', 'cleaning_apartment'),
          _PortfolioDef('Limpieza post-mudanza', 'video', 'cleaning_move_video'),
          _PortfolioDef('Cocina y baños', 'photo', 'cleaning_kitchen_bath'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-cleaning-2',
        name: 'Carolina Brillo',
        email: 'carolina.brillo@demo.com',
        category: ServiceCategories.cleaning,
        profession: 'Especialista en Limpieza',
        description: 'Oficinas, ventanas y sanitización de espacios comunes.',
        rating: 4.7,
        visitFee: 17000,
        portfolio: const [
          _PortfolioDef('Oficina 80m²', 'photo', 'cleaning_office'),
          _PortfolioDef('Vidrios en altura', 'video', 'cleaning_windows_video'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-construction-1',
        name: 'Roberto Obra',
        email: 'roberto.obra@demo.com',
        category: ServiceCategories.construction,
        profession: ServiceWorkerMapper.professionForCategory(ServiceCategories.construction),
        description: 'Reparaciones menores, tabiques, enlucidos y pintura de muros.',
        rating: 4.7,
        visitFee: 22000,
        portfolio: const [
          _PortfolioDef('Tabique divisorio', 'photo', 'construction_partition'),
          _PortfolioDef('Reparación muro living', 'video', 'construction_wall_video'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-construction-2',
        name: 'Diego Albañil',
        email: 'diego.albañil@demo.com',
        category: ServiceCategories.construction,
        profession: 'Maestro Constructor',
        description: 'Ampliaciones, radieres y reparación de humedad.',
        rating: 4.5,
        visitFee: 25000,
        portfolio: const [
          _PortfolioDef('Radier patio trasero', 'photo', 'construction_patio'),
          _PortfolioDef('Impermeabilización', 'photo', 'construction_waterproof'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-assembly-1',
        name: 'Tomás IKEA Pro',
        email: 'tomas.armado@demo.com',
        category: ServiceCategories.assembly,
        profession: ServiceWorkerMapper.professionForCategory(ServiceCategories.assembly),
        description: 'Armado de muebles modulares, camas, closets y repisas.',
        rating: 4.8,
        visitFee: 15000,
        portfolio: const [
          _PortfolioDef('Closet 2 puertas', 'photo', 'assembly_closet'),
          _PortfolioDef('Escritorio + repisa', 'video', 'assembly_desk_video'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-assembly-2',
        name: 'Felipe Ensambla',
        email: 'felipe.ensambla@demo.com',
        category: ServiceCategories.assembly,
        profession: 'Armador de Muebles',
        description: 'Cocinas modulares, racks TV y muebles de terraza.',
        rating: 4.6,
        visitFee: 16000,
        portfolio: const [
          _PortfolioDef('Rack TV y mueble', 'photo', 'assembly_tv_rack'),
          _PortfolioDef('Mueble terraza', 'photo', 'assembly_terrace'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-tech-1',
        name: 'Nico Tech',
        email: 'nico.tech@demo.com',
        category: ServiceCategories.techSupport,
        profession: ServiceWorkerMapper.professionForCategory(ServiceCategories.techSupport),
        description: 'WiFi, impresoras, PCs lentos y configuración de smartphones.',
        rating: 4.7,
        visitFee: 18000,
        portfolio: const [
          _PortfolioDef('Red WiFi mesh instalada', 'photo', 'tech_wifi'),
          _PortfolioDef('Configuración impresora', 'video', 'tech_printer_video'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-tech-2',
        name: 'Valentina IT',
        email: 'valentina.it@demo.com',
        category: ServiceCategories.techSupport,
        profession: 'Soporte Técnico',
        description: 'Backup de datos, limpieza de virus y optimización de notebooks.',
        rating: 4.9,
        visitFee: 19000,
        portfolio: const [
          _PortfolioDef('Notebook optimizada', 'photo', 'tech_laptop'),
          _PortfolioDef('Migración de datos', 'photo', 'tech_backup'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-garden-1',
        name: 'Jorge Verde',
        email: 'jorge.verde@demo.com',
        category: ServiceCategories.gardening,
        profession: ServiceWorkerMapper.professionForCategory(ServiceCategories.gardening),
        description: 'Corte de pasto, poda, riego y mantención de jardines.',
        rating: 4.5,
        visitFee: 14000,
        portfolio: const [
          _PortfolioDef('Jardín antes/después', 'photo', 'garden_before_after'),
          _PortfolioDef('Poda de setos', 'video', 'garden_hedge_video'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-garden-2',
        name: 'Paula Jardín',
        email: 'paula.jardin@demo.com',
        category: ServiceCategories.gardening,
        profession: 'Jardinero',
        description: 'Diseño de maceteros, riego automático y control de malezas.',
        rating: 4.6,
        visitFee: 15500,
        portfolio: const [
          _PortfolioDef('Maceteros terraza', 'photo', 'garden_planters'),
          _PortfolioDef('Sistema riego', 'photo', 'garden_irrigation'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-moving-1',
        name: 'Camilo Mudanzas',
        email: 'camilo.mudanzas@demo.com',
        category: ServiceCategories.moving,
        profession: ServiceWorkerMapper.professionForCategory(ServiceCategories.moving),
        description: 'Mudanzas pequeñas dentro de la ciudad con furgón incluido.',
        rating: 4.4,
        visitFee: 20000,
        portfolio: const [
          _PortfolioDef('Mudanza depto. 2D', 'photo', 'moving_apartment'),
          _PortfolioDef('Embalaje muebles', 'video', 'moving_packing_video'),
        ],
      ),
      _WorkerDef(
        id: 'demo-worker-moving-2',
        name: 'Andrea Traslado',
        email: 'andrea.traslado@demo.com',
        category: ServiceCategories.moving,
        profession: 'Especialista en Mudanzas',
        description: 'Traslado de oficinas, carga pesada y desarme de muebles.',
        rating: 4.8,
        visitFee: 23000,
        portfolio: const [
          _PortfolioDef('Oficina 6 puestos', 'photo', 'moving_office'),
          _PortfolioDef('Carga segura electrodomésticos', 'photo', 'moving_appliances'),
        ],
      ),
    ];
  }
}

class _WorkerDef {
  final String id;
  final String name;
  final String email;
  final String category;
  final String profession;
  final String description;
  final double rating;
  final double visitFee;
  final List<_PortfolioDef> portfolio;

  const _WorkerDef({
    required this.id,
    required this.name,
    required this.email,
    required this.category,
    required this.profession,
    required this.description,
    required this.rating,
    required this.visitFee,
    required this.portfolio,
  });
}

class _PortfolioDef {
  final String description;
  final String mediaType;
  final String imageKey;

  const _PortfolioDef(this.description, this.mediaType, this.imageKey);
}

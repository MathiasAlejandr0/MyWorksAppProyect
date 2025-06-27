import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'myworksapp.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        profileImage TEXT,
        addresses TEXT,
        isProfessional INTEGER DEFAULT 0,
        professionalId TEXT,
        createdAt TEXT NOT NULL,
        lastLogin TEXT,
        isVerified INTEGER DEFAULT 0,
        fcmToken TEXT
      )
    ''');

    // Tabla de servicios
    await db.execute('''
      CREATE TABLE services (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        basePrice REAL DEFAULT 0.0,
        categories TEXT
      )
    ''');

    // Tabla de profesionales
    await db.execute('''
      CREATE TABLE professionals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        profileImage TEXT NOT NULL,
        bio TEXT NOT NULL,
        services TEXT NOT NULL,
        rating REAL DEFAULT 0.0,
        totalReviews INTEGER DEFAULT 0,
        completedJobs INTEGER DEFAULT 0,
        yearsExperience INTEGER DEFAULT 0,
        isVerified INTEGER DEFAULT 0,
        isAvailable INTEGER DEFAULT 1,
        location TEXT DEFAULT '',
        certifications TEXT,
        servicePrices TEXT
      )
    ''');

    // Tabla de portafolios
    await db.execute('''
      CREATE TABLE portfolio_items (
        id TEXT PRIMARY KEY,
        professionalId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        images TEXT NOT NULL,
        completedDate TEXT NOT NULL,
        serviceType TEXT NOT NULL,
        cost REAL DEFAULT 0.0,
        clientFeedback TEXT DEFAULT '',
        FOREIGN KEY (professionalId) REFERENCES professionals (id)
      )
    ''');

    // Tabla de evaluaciones
    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        professionalId TEXT NOT NULL,
        clientId TEXT NOT NULL,
        clientName TEXT NOT NULL,
        rating REAL NOT NULL,
        comment TEXT NOT NULL,
        reviewDate TEXT NOT NULL,
        serviceType TEXT NOT NULL,
        isVerified INTEGER DEFAULT 0,
        FOREIGN KEY (professionalId) REFERENCES professionals (id)
      )
    ''');

    // Tabla de solicitudes de servicio
    await db.execute('''
      CREATE TABLE service_requests (
        id TEXT PRIMARY KEY,
        clientId TEXT NOT NULL,
        professionalId TEXT NOT NULL,
        serviceId TEXT NOT NULL,
        address TEXT NOT NULL,
        description TEXT NOT NULL,
        requestedDate TEXT NOT NULL,
        scheduledDate TEXT,
        status TEXT DEFAULT 'pending',
        estimatedCost REAL,
        finalCost REAL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (clientId) REFERENCES users (id),
        FOREIGN KEY (professionalId) REFERENCES professionals (id),
        FOREIGN KEY (serviceId) REFERENCES services (id)
      )
    ''');

    // Tabla de notificaciones
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT,
        isRead INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Insertar datos iniciales
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // Insertar servicios
    for (Service service in services) {
      await db.insert('services', {
        'id': service.id,
        'name': service.name,
        'description': service.description,
        'imageUrl': service.imageUrl,
        'icon': service.icon.codePoint.toString(),
        'color': service.color.toARGB32(),
        'basePrice': service.basePrice,
        'categories': service.categories.join(','),
      });
    }

    // Insertar profesionales
    for (Professional professional in professionals) {
      await db.insert('professionals', {
        'id': professional.id,
        'name': professional.name,
        'email': professional.email,
        'phone': professional.phone,
        'profileImage': professional.profileImage,
        'bio': professional.bio,
        'services': professional.services.join(','),
        'rating': professional.rating,
        'totalReviews': professional.totalReviews,
        'completedJobs': professional.completedJobs,
        'yearsExperience': professional.yearsExperience,
        'isVerified': professional.isVerified ? 1 : 0,
        'isAvailable': professional.isAvailable ? 1 : 0,
        'location': professional.location,
        'certifications': professional.certifications.join(','),
        'servicePrices': professional.servicePrices.entries
            .map((e) => '${e.key}:${e.value}')
            .join(','),
      });
    }

    // Insertar portafolios
    for (PortfolioItem item in portfolioItems) {
      await db.insert('portfolio_items', {
        'id': item.id,
        'professionalId': item.professionalId,
        'title': item.title,
        'description': item.description,
        'images': item.images.join(','),
        'completedDate': item.completedDate.toIso8601String(),
        'serviceType': item.serviceType,
        'cost': item.cost,
        'clientFeedback': item.clientFeedback,
      });
    }

    // Insertar evaluaciones
    for (Review review in reviews) {
      await db.insert('reviews', {
        'id': review.id,
        'professionalId': review.professionalId,
        'clientId': review.clientId,
        'clientName': review.clientName,
        'rating': review.rating,
        'comment': review.comment,
        'reviewDate': review.reviewDate.toIso8601String(),
        'serviceType': review.serviceType,
        'isVerified': review.isVerified ? 1 : 0,
      });
    }
  }

  // Métodos para usuarios
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'profileImage': user.profileImage,
      'addresses': user.addresses.join(','),
      'isProfessional': user.isProfessional ? 1 : 0,
      'professionalId': user.professionalId,
      'createdAt': user.createdAt.toIso8601String(),
      'lastLogin': user.lastLogin?.toIso8601String(),
      'isVerified': user.isVerified ? 1 : 0,
      'fcmToken': user.fcmToken,
    });
  }

  Future<User?> getUser(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return User(
      id: maps[0]['id'],
      name: maps[0]['name'],
      email: maps[0]['email'],
      phone: maps[0]['phone'],
      profileImage: maps[0]['profileImage'],
      addresses: maps[0]['addresses']?.split(',') ?? [],
      isProfessional: maps[0]['isProfessional'] == 1,
      professionalId: maps[0]['professionalId'],
      createdAt: DateTime.parse(maps[0]['createdAt']),
      lastLogin: maps[0]['lastLogin'] != null
          ? DateTime.parse(maps[0]['lastLogin'])
          : null,
      isVerified: maps[0]['isVerified'] == 1,
      fcmToken: maps[0]['fcmToken'],
    );
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isEmpty) return null;

    return User(
      id: maps[0]['id'],
      name: maps[0]['name'],
      email: maps[0]['email'],
      phone: maps[0]['phone'],
      profileImage: maps[0]['profileImage'],
      addresses: maps[0]['addresses']?.split(',') ?? [],
      isProfessional: maps[0]['isProfessional'] == 1,
      professionalId: maps[0]['professionalId'],
      createdAt: DateTime.parse(maps[0]['createdAt']),
      lastLogin: maps[0]['lastLogin'] != null
          ? DateTime.parse(maps[0]['lastLogin'])
          : null,
      isVerified: maps[0]['isVerified'] == 1,
      fcmToken: maps[0]['fcmToken'],
    );
  }

  // Métodos para profesionales
  Future<List<Professional>> getProfessionalsByService(String serviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'professionals',
      where: 'services LIKE ?',
      whereArgs: ['%$serviceId%'],
    );

    return List.generate(maps.length, (i) {
      final services = maps[i]['services'].split(',');
      final servicePrices = <String, double>{};
      if (maps[i]['servicePrices'] != null) {
        for (String price in maps[i]['servicePrices'].split(',')) {
          final parts = price.split(':');
          if (parts.length == 2) {
            servicePrices[parts[0]] = double.parse(parts[1]);
          }
        }
      }

      return Professional(
        id: maps[i]['id'],
        name: maps[i]['name'],
        email: maps[i]['email'],
        phone: maps[i]['phone'],
        profileImage: maps[i]['profileImage'],
        bio: maps[i]['bio'],
        services: services,
        rating: maps[i]['rating'],
        totalReviews: maps[i]['totalReviews'],
        completedJobs: maps[i]['completedJobs'],
        yearsExperience: maps[i]['yearsExperience'],
        isVerified: maps[i]['isVerified'] == 1,
        isAvailable: maps[i]['isAvailable'] == 1,
        location: maps[i]['location'],
        certifications: maps[i]['certifications']?.split(',') ?? [],
        servicePrices: servicePrices,
      );
    });
  }

  Future<Professional?> getProfessional(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'professionals',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final services = maps[0]['services'].split(',');
    final servicePrices = <String, double>{};
    if (maps[0]['servicePrices'] != null) {
      for (String price in maps[0]['servicePrices'].split(',')) {
        final parts = price.split(':');
        if (parts.length == 2) {
          servicePrices[parts[0]] = double.parse(parts[1]);
        }
      }
    }

    return Professional(
      id: maps[0]['id'],
      name: maps[0]['name'],
      email: maps[0]['email'],
      phone: maps[0]['phone'],
      profileImage: maps[0]['profileImage'],
      bio: maps[0]['bio'],
      services: services,
      rating: maps[0]['rating'],
      totalReviews: maps[0]['totalReviews'],
      completedJobs: maps[0]['completedJobs'],
      yearsExperience: maps[0]['yearsExperience'],
      isVerified: maps[0]['isVerified'] == 1,
      isAvailable: maps[0]['isAvailable'] == 1,
      location: maps[0]['location'],
      certifications: maps[0]['certifications']?.split(',') ?? [],
      servicePrices: servicePrices,
    );
  }

  // Métodos para portafolios
  Future<List<PortfolioItem>> getPortfolioByProfessional(
    String professionalId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'portfolio_items',
      where: 'professionalId = ?',
      whereArgs: [professionalId],
      orderBy: 'completedDate DESC',
    );

    return List.generate(maps.length, (i) {
      return PortfolioItem(
        id: maps[i]['id'],
        professionalId: maps[i]['professionalId'],
        title: maps[i]['title'],
        description: maps[i]['description'],
        images: maps[i]['images'].split(','),
        completedDate: DateTime.parse(maps[i]['completedDate']),
        serviceType: maps[i]['serviceType'],
        cost: maps[i]['cost'],
        clientFeedback: maps[i]['clientFeedback'],
      );
    });
  }

  // Métodos para evaluaciones
  Future<List<Review>> getReviewsByProfessional(String professionalId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reviews',
      where: 'professionalId = ?',
      whereArgs: [professionalId],
      orderBy: 'reviewDate DESC',
    );

    return List.generate(maps.length, (i) {
      return Review(
        id: maps[i]['id'],
        professionalId: maps[i]['professionalId'],
        clientId: maps[i]['clientId'],
        clientName: maps[i]['clientName'],
        rating: maps[i]['rating'],
        comment: maps[i]['comment'],
        reviewDate: DateTime.parse(maps[i]['reviewDate']),
        serviceType: maps[i]['serviceType'],
        isVerified: maps[i]['isVerified'] == 1,
      );
    });
  }

  // Métodos para solicitudes de servicio
  Future<int> insertServiceRequest(ServiceRequest request) async {
    final db = await database;
    return await db.insert('service_requests', {
      'id': request.id,
      'clientId': request.clientId,
      'professionalId': request.professionalId,
      'serviceId': request.service.id,
      'address': request.address,
      'description': request.description,
      'requestedDate': request.requestedDate.toIso8601String(),
      'scheduledDate': request.scheduledDate?.toIso8601String(),
      'status': request.status,
      'estimatedCost': request.estimatedCost,
      'finalCost': request.finalCost,
      'notes': request.notes,
      'createdAt': request.createdAt.toIso8601String(),
      'updatedAt': request.updatedAt?.toIso8601String(),
    });
  }

  Future<List<ServiceRequest>> getServiceRequestsByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'service_requests',
      where: 'clientId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    List<ServiceRequest> requests = [];
    for (var map in maps) {
      final service = services.firstWhere((s) => s.id == map['serviceId']);
      requests.add(
        ServiceRequest(
          id: map['id'],
          clientId: map['clientId'],
          professionalId: map['professionalId'],
          service: service,
          address: map['address'],
          description: map['description'],
          requestedDate: DateTime.parse(map['requestedDate']),
          scheduledDate: map['scheduledDate'] != null
              ? DateTime.parse(map['scheduledDate'])
              : null,
          status: map['status'],
          estimatedCost: map['estimatedCost'],
          finalCost: map['finalCost'],
          notes: map['notes'],
          createdAt: DateTime.parse(map['createdAt']),
          updatedAt: map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'])
              : null,
        ),
      );
    }
    return requests;
  }

  // Métodos para notificaciones
  Future<int> insertNotification(Notification notification) async {
    final db = await database;
    return await db.insert('notifications', {
      'id': notification.id,
      'userId': notification.userId,
      'title': notification.title,
      'message': notification.message,
      'type': notification.type,
      'data': notification.data?.toString(),
      'isRead': notification.isRead ? 1 : 0,
      'createdAt': notification.createdAt.toIso8601String(),
    });
  }

  Future<List<Notification>> getNotificationsByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Notification(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        title: maps[i]['title'],
        message: maps[i]['message'],
        type: maps[i]['type'],
        data: (maps[i]['data'] as Map?)?.cast<String, dynamic>(),
        isRead: maps[i]['isRead'] == 1,
        createdAt: DateTime.parse(maps[i]['createdAt']),
      );
    });
  }

  Future<int> markNotificationAsRead(String notificationId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // Método para cerrar la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

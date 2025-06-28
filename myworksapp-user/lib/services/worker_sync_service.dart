import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class WorkerSyncService {
  static final WorkerSyncService _instance = WorkerSyncService._internal();
  factory WorkerSyncService() => _instance;
  WorkerSyncService._internal();

  // Ruta de la base de datos de trabajadores
  String? _workerDbPath;

  // Inicializar el servicio
  Future<void> initialize() async {
    try {
      // Obtener la ruta de la base de datos de trabajadores
      final databasesPath = await getDatabasesPath();
      _workerDbPath = join(databasesPath, 'worker_database.db');

      // print('Worker database path: \\$_workerDbPath');
    } catch (e) {
      // print('Error initializing worker sync service: \\${e}');
    }
  }

  // Verificar si existe la base de datos de trabajadores
  Future<bool> workerDatabaseExists() async {
    if (_workerDbPath == null) await initialize();

    try {
      final file = File(_workerDbPath!);
      return await file.exists();
    } catch (e) {
      // print('Error checking worker database: \\${e}');
      return false;
    }
  }

  // Obtener todos los trabajadores disponibles
  Future<List<Professional>> getAvailableWorkers() async {
    if (!await workerDatabaseExists()) {
      // print('Worker database does not exist');
      return [];
    }

    try {
      final database = await openDatabase(_workerDbPath!);

      final List<Map<String, dynamic>> maps = await database.query(
        'workers',
        where: 'isAvailable = ?',
        whereArgs: [1],
      );

      await database.close();

      return maps.map((map) => _convertWorkerToProfessional(map)).toList();
    } catch (e) {
      // print('Error getting available workers: \\${e}');
      return [];
    }
  }

  // Obtener trabajadores por profesión
  Future<List<Professional>> getWorkersByProfession(String profession) async {
    if (!await workerDatabaseExists()) {
      return [];
    }

    try {
      final database = await openDatabase(_workerDbPath!);

      final List<Map<String, dynamic>> maps = await database.query(
        'workers',
        where: 'profession = ? AND isAvailable = ?',
        whereArgs: [profession, 1],
      );

      await database.close();

      return maps.map((map) => _convertWorkerToProfessional(map)).toList();
    } catch (e) {
      // print('Error getting workers by profession: \\${e}');
      return [];
    }
  }

  // Obtener un trabajador específico por ID
  Future<Professional?> getWorkerById(int id) async {
    if (!await workerDatabaseExists()) {
      return null;
    }

    try {
      final database = await openDatabase(_workerDbPath!);

      final List<Map<String, dynamic>> maps = await database.query(
        'workers',
        where: 'id = ?',
        whereArgs: [id],
      );

      await database.close();

      if (maps.isNotEmpty) {
        return _convertWorkerToProfessional(maps.first);
      }
      return null;
    } catch (e) {
      // print('Error getting worker by id: \\${e}');
      return null;
    }
  }

  // Obtener reseñas de un trabajador
  Future<List<Review>> getWorkerReviews(int workerId) async {
    if (!await workerDatabaseExists()) {
      return [];
    }

    try {
      final database = await openDatabase(_workerDbPath!);

      final List<Map<String, dynamic>> maps = await database.query(
        'reviews',
        where: 'workerId = ?',
        whereArgs: [workerId],
        orderBy: 'createdAt DESC',
      );

      await database.close();

      return maps.map((map) => _convertWorkerReviewToReview(map)).toList();
    } catch (e) {
      // print('Error getting worker reviews: \\${e}');
      return [];
    }
  }

  // Convertir datos de trabajador a modelo Professional
  Professional _convertWorkerToProfessional(Map<String, dynamic> workerMap) {
    // Mapear profesión a servicios
    List<String> services = [];
    switch (workerMap['profession']) {
      case 'Plomero':
        services = ['plomeria'];
        break;
      case 'Electricista':
        services = ['electricidad'];
        break;
      case 'Albañil':
        services = ['construccion'];
        break;
      case 'Jardinero':
        services = ['jardineria'];
        break;
      case 'Cerrajero':
        services = ['cerrajeria'];
        break;
      case 'Pintor':
        services = ['pintura'];
        break;
      case 'Carpintero':
        services = ['carpinteria'];
        break;
      case 'Técnico':
        services = ['tecnico'];
        break;
      case 'Limpieza':
        services = ['limpieza'];
        break;
      default:
        services = ['otros'];
    }

    // Crear mapa de precios por servicio
    Map<String, double> servicePrices = {};
    if (workerMap['hourlyRate'] != null) {
      for (String service in services) {
        servicePrices[service] = workerMap['hourlyRate'].toDouble();
      }
    }

    // Obtener certificaciones
    List<String> certifications = [];
    if (workerMap['certificates'] != null) {
      certifications = workerMap['certificates']
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return Professional(
      id: workerMap['id'].toString(),
      name: workerMap['name'],
      email: workerMap['email'],
      phone: workerMap['phone'],
      profileImage: workerMap['profileImage'] ?? '',
      bio: workerMap['description'] ?? '',
      services: services,
      rating: workerMap['rating']?.toDouble() ?? 0.0,
      totalReviews: workerMap['totalReviews'] ?? 0,
      completedJobs: 0, // No disponible en worker database
      yearsExperience: 0, // No disponible en worker database
      isVerified: workerMap['title'] != null, // Verificado si tiene título
      isAvailable: workerMap['isAvailable'] == 1,
      location: workerMap['address'] ?? '',
      certifications: certifications,
      servicePrices: servicePrices,
    );
  }

  // Convertir reseña de trabajador a modelo Review
  Review _convertWorkerReviewToReview(Map<String, dynamic> reviewMap) {
    return Review(
      id: reviewMap['id'].toString(),
      professionalId: reviewMap['workerId'].toString(),
      clientId: 'unknown', // No disponible en worker database
      clientName: reviewMap['clientName'],
      rating: reviewMap['rating'].toDouble(),
      comment: reviewMap['comment'],
      reviewDate: DateTime.parse(reviewMap['createdAt']),
      serviceType: 'general', // No específico en worker database
      isVerified: false,
    );
  }

  // Obtener estadísticas de trabajadores
  Future<Map<String, dynamic>> getWorkerStats() async {
    if (!await workerDatabaseExists()) {
      return {
        'totalWorkers': 0,
        'availableWorkers': 0,
        'professions': {},
      };
    }

    try {
      final database = await openDatabase(_workerDbPath!);

      // Total de trabajadores
      final totalResult =
          await database.rawQuery('SELECT COUNT(*) as count FROM workers');
      final totalWorkers = totalResult.first['count'] as int;

      // Trabajadores disponibles
      final availableResult = await database.rawQuery(
          'SELECT COUNT(*) as count FROM workers WHERE isAvailable = 1');
      final availableWorkers = availableResult.first['count'] as int;

      // Trabajadores por profesión
      final professionResult = await database.rawQuery(
          'SELECT profession, COUNT(*) as count FROM workers WHERE isAvailable = 1 GROUP BY profession');

      final Map<String, int> professions = {};
      for (var row in professionResult) {
        professions[row['profession'] as String] = row['count'] as int;
      }

      await database.close();

      return {
        'totalWorkers': totalWorkers,
        'availableWorkers': availableWorkers,
        'professions': professions,
      };
    } catch (e) {
      // print('Error getting worker stats: \\${e}');
      return {
        'totalWorkers': 0,
        'availableWorkers': 0,
        'professions': {},
      };
    }
  }

  // Verificar si hay trabajadores disponibles
  Future<bool> hasAvailableWorkers() async {
    if (!await workerDatabaseExists()) {
      return false;
    }

    try {
      final database = await openDatabase(_workerDbPath!);

      final result = await database.rawQuery(
          'SELECT COUNT(*) as count FROM workers WHERE isAvailable = 1');

      await database.close();

      return (result.first['count'] as int) > 0;
    } catch (e) {
      // print('Error checking available workers: \\${e}');
      return false;
    }
  }

  // Obtener trabajadores destacados (con mejor calificación)
  Future<List<Professional>> getFeaturedWorkers({int limit = 5}) async {
    if (!await workerDatabaseExists()) {
      return [];
    }

    try {
      final database = await openDatabase(_workerDbPath!);

      final List<Map<String, dynamic>> maps = await database.query(
        'workers',
        where: 'isAvailable = ? AND rating IS NOT NULL',
        whereArgs: [1],
        orderBy: 'rating DESC',
        limit: limit,
      );

      await database.close();

      return maps.map((map) => _convertWorkerToProfessional(map)).toList();
    } catch (e) {
      // print('Error getting featured workers: \\${e}');
      return [];
    }
  }
}

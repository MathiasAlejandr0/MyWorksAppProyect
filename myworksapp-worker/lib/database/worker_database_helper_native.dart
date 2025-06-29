import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/worker.dart';
import '../models/portfolio_item.dart';
import '../models/request.dart';

class WorkerDatabaseHelper {
  static final WorkerDatabaseHelper _instance =
      WorkerDatabaseHelper._internal();
  factory WorkerDatabaseHelper() => _instance;
  WorkerDatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'worker_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE workers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            phone TEXT,
            password TEXT,
            profession TEXT,
            description TEXT,
            address TEXT,
            hourlyRate REAL,
            profileImage TEXT,
            workImages TEXT,
            certificates TEXT,
            createdAt TEXT,
            isAvailable INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE portfolio (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workerId INTEGER,
            imagePath TEXT,
            description TEXT,
            createdAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workerId INTEGER,
            userName TEXT,
            userContact TEXT,
            service TEXT,
            description TEXT,
            requestedAt TEXT,
            status TEXT
          )
        ''');
      },
    );
  }

  // Trabajadores
  Future<int> insertWorker(Worker worker) async {
    final db = await database;
    return await db.insert('workers', worker.toMap());
  }

  Future<Worker?> getWorkerByEmail(String email) async {
    final db = await database;
    final maps =
        await db.query('workers', where: 'email = ?', whereArgs: [email]);
    if (maps.isNotEmpty) {
      return Worker.fromMap(maps.first);
    }
    return null;
  }

  Future<Worker?> getWorkerById(int id) async {
    final db = await database;
    final maps = await db.query('workers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Worker.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateWorker(Worker worker) async {
    final db = await database;
    return await db.update('workers', worker.toMap(),
        where: 'id = ?', whereArgs: [worker.id]);
  }

  Future<int> updateWorkerAvailability(int workerId, bool isAvailable) async {
    final db = await database;
    return await db.update('workers', {'isAvailable': isAvailable ? 1 : 0},
        where: 'id = ?', whereArgs: [workerId]);
  }

  // Portafolio
  Future<int> insertPortfolioItem(PortfolioItem item) async {
    final db = await database;
    return await db.insert('portfolio', item.toMap());
  }

  Future<List<PortfolioItem>> getPortfolioByWorker(int workerId) async {
    final db = await database;
    final maps = await db.query('portfolio',
        where: 'workerId = ?',
        whereArgs: [workerId],
        orderBy: 'createdAt DESC');
    return maps.map((m) => PortfolioItem.fromMap(m)).toList();
  }

  Future<int> deletePortfolioItem(int id) async {
    final db = await database;
    return await db.delete('portfolio', where: 'id = ?', whereArgs: [id]);
  }

  // Solicitudes
  Future<int> insertRequest(Request request) async {
    final db = await database;
    return await db.insert('requests', request.toMap());
  }

  Future<List<Request>> getRequestsByWorker(int workerId) async {
    final db = await database;
    final maps = await db.query('requests',
        where: 'workerId = ?',
        whereArgs: [workerId],
        orderBy: 'requestedAt DESC');
    return maps.map((m) => Request.fromMap(m)).toList();
  }

  Future<int> updateRequestStatus(int requestId, String status) async {
    final db = await database;
    return await db.update('requests', {'status': status},
        where: 'id = ?', whereArgs: [requestId]);
  }

  // Método para insertar datos de prueba
  Future<void> insertTestData() async {
    final db = await database;
    // Verificar si ya existen datos
    final workers = await db.query('workers');
    if (workers.isNotEmpty) return; // Ya hay datos
    // Insertar trabajador de prueba
    final testWorker = Worker(
      name: 'Juan Pérez',
      email: 'juan@test.com',
      phone: '123456789',
      password: '123456',
      profession: 'Plomero',
      description:
          'Plomero profesional con 5 años de experiencia en instalaciones y reparaciones.',
      address: 'Calle Principal 123, Ciudad',
      hourlyRate: 25.0,
      createdAt: DateTime.now(),
      isAvailable: true,
    );
    final workerId = await insertWorker(testWorker);
    // Insertar algunos elementos de portafolio de prueba
    final portfolioItems = [
      PortfolioItem(
        workerId: workerId,
        imagePath: 'assets/images/placeholder.txt',
        description: 'Instalación de tuberías en cocina',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      PortfolioItem(
        workerId: workerId,
        imagePath: 'assets/images/placeholder.txt',
        description: 'Reparación de fuga en baño',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
    for (final item in portfolioItems) {
      await insertPortfolioItem(item);
    }
    // Insertar algunas solicitudes de prueba
    final requests = [
      Request(
        workerId: workerId,
        userName: 'María García',
        userContact: 'maria@email.com',
        service: 'Reparación de fuga',
        description:
            'Tengo una fuga en la tubería del baño que necesita reparación urgente.',
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'pendiente',
      ),
      Request(
        workerId: workerId,
        userName: 'Carlos López',
        userContact: 'carlos@email.com',
        service: 'Instalación de grifo',
        description: 'Necesito instalar un nuevo grifo en la cocina.',
        requestedAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'aceptada',
      ),
    ];
    for (final request in requests) {
      await insertRequest(request);
    }
  }
}

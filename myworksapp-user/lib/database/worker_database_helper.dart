import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/worker.dart';
import '../models/review.dart';
import '../models/notification_model.dart';

class WorkerDatabaseHelper {
  static final WorkerDatabaseHelper _instance =
      WorkerDatabaseHelper._internal();
  static Database? _database;

  factory WorkerDatabaseHelper() => _instance;

  WorkerDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'worker_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de trabajadores
    await db.execute('''
      CREATE TABLE workers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        profession TEXT NOT NULL,
        title TEXT,
        titleInstitution TEXT,
        titleYear INTEGER,
        description TEXT,
        address TEXT,
        hourlyRate REAL,
        isAvailable INTEGER DEFAULT 0,
        rating REAL,
        totalReviews INTEGER DEFAULT 0,
        profileImage TEXT,
        workImages TEXT,
        certificates TEXT,
        createdAt TEXT NOT NULL,
        lastActive TEXT
      )
    ''');

    // Tabla de reseñas
    await db.execute('''
      CREATE TABLE reviews(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workerId INTEGER NOT NULL,
        clientName TEXT NOT NULL,
        rating REAL NOT NULL,
        comment TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (workerId) REFERENCES workers (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de notificaciones
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workerId INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        data TEXT,
        FOREIGN KEY (workerId) REFERENCES workers (id) ON DELETE CASCADE
      )
    ''');
  }

  // CRUD para trabajadores
  Future<int> insertWorker(Worker worker) async {
    final db = await database;
    return await db.insert('workers', worker.toMap());
  }

  Future<List<Worker>> getAllWorkers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('workers');
    return List.generate(maps.length, (i) => Worker.fromMap(maps[i]));
  }

  Future<Worker?> getWorkerById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Worker.fromMap(maps.first);
    }
    return null;
  }

  Future<Worker?> getWorkerByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workers',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return Worker.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Worker>> getAvailableWorkers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workers',
      where: 'isAvailable = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Worker.fromMap(maps[i]));
  }

  Future<List<Worker>> getWorkersByProfession(String profession) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workers',
      where: 'profession = ? AND isAvailable = ?',
      whereArgs: [profession, 1],
    );
    return List.generate(maps.length, (i) => Worker.fromMap(maps[i]));
  }

  Future<int> updateWorker(Worker worker) async {
    final db = await database;
    return await db.update(
      'workers',
      worker.toMap(),
      where: 'id = ?',
      whereArgs: [worker.id],
    );
  }

  Future<int> updateWorkerAvailability(int workerId, bool isAvailable) async {
    final db = await database;
    return await db.update(
      'workers',
      {
        'isAvailable': isAvailable ? 1 : 0,
        'lastActive': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }

  Future<int> deleteWorker(int id) async {
    final db = await database;
    return await db.delete(
      'workers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD para reseñas
  Future<int> insertReview(Review review) async {
    final db = await database;
    return await db.insert('reviews', review.toMap());
  }

  Future<List<Review>> getReviewsByWorkerId(int workerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reviews',
      where: 'workerId = ?',
      whereArgs: [workerId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Review.fromMap(maps[i]));
  }

  Future<double> getAverageRating(int workerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT AVG(rating) as avgRating FROM reviews WHERE workerId = ?',
      [workerId],
    );
    return maps.first['avgRating'] ?? 0.0;
  }

  Future<int> getTotalReviews(int workerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reviews WHERE workerId = ?',
      [workerId],
    );
    return maps.first['count'] ?? 0;
  }

  // CRUD para notificaciones
  Future<int> insertNotification(WorkerNotification notification) async {
    final db = await database;
    return await db.insert('notifications', notification.toMap());
  }

  Future<List<WorkerNotification>> getNotificationsByWorkerId(
      int workerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'workerId = ?',
      whereArgs: [workerId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(
        maps.length, (i) => WorkerNotification.fromMap(maps[i]));
  }

  Future<int> markNotificationAsRead(int notificationId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<int> getUnreadNotificationsCount(int workerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE workerId = ? AND isRead = 0',
      [workerId],
    );
    return maps.first['count'] ?? 0;
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos de utilidad
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

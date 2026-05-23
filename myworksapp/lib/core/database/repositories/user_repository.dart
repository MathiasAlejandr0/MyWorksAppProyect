import '../database_helper.dart';
import '../models/user_model.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> createUser(UserModel user) async {
    final db = await _dbHelper.database;
    await db.insert('users', user.toMap());
    return user.id;
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<void> updateUser(UserModel user) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> updateProfilePhotoPath(String userId, String? photoPath) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'profilePhotoPath': photoPath},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Actualiza solo la contraseña de un usuario
  Future<void> updatePassword(String userId, String passwordHash) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'password': passwordHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Actualiza el estado de cuenta de un usuario
  Future<void> updateAccountStatus(String userId, String status) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'accountStatus': status},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteUser(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await _dbHelper.database;
    final maps = await db.query('users');
    return maps.map((map) => UserModel.fromMap(map)).toList();
  }
}


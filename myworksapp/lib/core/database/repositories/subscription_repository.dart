import '../database_helper.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createSubscription(SubscriptionModel subscription) async {
    final db = await _dbHelper.database;
    await db.insert('subscriptions', subscription.toMap());
  }

  Future<SubscriptionModel?> getSubscriptionById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SubscriptionModel.fromMap(maps.first);
  }

  Future<SubscriptionModel?> getActiveSubscription(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'subscriptions',
      where: 'userId = ? AND status = ?',
      whereArgs: [userId, 'active'],
      orderBy: 'startDate DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SubscriptionModel.fromMap(maps.first);
  }

  Future<List<SubscriptionModel>> getActiveSubscriptions() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'subscriptions',
      where: 'status = ?',
      whereArgs: ['active'],
    );
    return maps.map((map) => SubscriptionModel.fromMap(map)).toList();
  }

  Future<void> updateSubscription(SubscriptionModel subscription) async {
    final db = await _dbHelper.database;
    await db.update(
      'subscriptions',
      subscription.toMap(),
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
  }
}


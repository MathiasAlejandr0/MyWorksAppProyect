import '../database_helper.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<ServiceModel>> getAllServices() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'services',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => ServiceModel.fromMap(map)).toList();
  }

  Future<List<ServiceModel>> getServicesByCategory(String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'services',
      where: 'category = ? AND isActive = ?',
      whereArgs: [category, 1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => ServiceModel.fromMap(map)).toList();
  }

  Future<ServiceModel?> getServiceById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'services',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ServiceModel.fromMap(maps.first);
  }

  Future<void> createService(ServiceModel service) async {
    final db = await _dbHelper.database;
    await db.insert('services', service.toMap());
  }

  Future<void> updateService(ServiceModel service) async {
    final db = await _dbHelper.database;
    await db.update(
      'services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  /// Obtiene solo servicios principales (uno por categoría)
  /// Útil para mostrar en el home sin duplicados
  Future<List<ServiceModel>> getMainServices() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'services',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'category ASC, name ASC',
    );
    
    final allServices = maps.map((map) => ServiceModel.fromMap(map)).toList();
    
    // Agrupar por categoría y tomar solo el primero de cada categoría
    final Map<String, ServiceModel> mainServices = {};
    for (final service in allServices) {
      if (!mainServices.containsKey(service.category)) {
        mainServices[service.category] = service;
      }
    }
    
    // Ordenar por nombre para mejor UX
    final result = mainServices.values.toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    
    return result;
  }
}

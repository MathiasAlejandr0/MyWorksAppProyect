/// Interfaz base para repositorios
/// 
/// Preparado para migración a backend.
/// Todos los repositorios deberían implementar estas interfaces.
abstract class IRepository<T> {
  /// Crea una entidad
  Future<T> create(T entity);

  /// Obtiene una entidad por ID
  Future<T?> getById(String id);

  /// Actualiza una entidad
  Future<void> update(T entity);

  /// Elimina una entidad
  Future<void> delete(String id);
}

/// Interfaz para repositorios con sincronización
abstract class ISyncableRepository<T> extends IRepository<T> {
  /// Sincroniza con el servidor
  Future<void> sync();

  /// Obtiene entidades pendientes de sincronizar
  Future<List<T>> getPendingSync();

  /// Marca una entidad como sincronizada
  Future<void> markAsSynced(String id);
}


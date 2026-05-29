import '../database/repositories/worker_repository.dart';
import '../database/models/worker_model.dart';
import '../utils/app_logger.dart';

// Importar funciones matemáticas
import 'dart:math' as math;

/// Opciones de ordenamiento
enum WorkerSortOption {
  distance,
  rating,
  availability,
  name,
}

/// Filtros de búsqueda
class WorkerSearchFilters {
  final String? serviceId;
  final double? minRating;
  final bool? isAvailable;
  final String? profession;

  WorkerSearchFilters({
    this.serviceId,
    this.minRating,
    this.isAvailable,
    this.profession,
  });
}

/// Servicio para búsqueda, filtros y ordenamiento de trabajadores
class WorkerSearchService {
  final WorkerRepository _workerRepository = WorkerRepository();

  /// Busca y filtra trabajadores
  Future<List<WorkerModel>> searchWorkers({
    String? query,
    WorkerSearchFilters? filters,
    WorkerSortOption sortBy = WorkerSortOption.rating,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      // 1. Obtener todos los trabajadores disponibles
      List<WorkerModel> workers;
      if (filters?.isAvailable == true) {
        workers = await _workerRepository.getAllAvailableWorkers();
      } else {
        // Obtener todos (luego filtrar)
        workers = await _getAllWorkers();
      }

      // 2. Aplicar filtros
      if (filters != null) {
        workers = _applyFilters(workers, filters);
      }

      // 3. Aplicar búsqueda por texto (nombre, profesión)
      if (query != null && query.isNotEmpty) {
        workers = _applyTextSearch(workers, query);
      }

      // 4. Calcular distancias si se proporcionan coordenadas
      if (userLatitude != null && userLongitude != null) {
        workers = _calculateDistances(workers, userLatitude, userLongitude);
      }

      // 5. Ordenar
      workers = _sortWorkers(workers, sortBy);

      return workers;
    } catch (e) {
      AppLogger.e('Error en búsqueda de trabajadores', e);
      return [];
    }
  }

  /// Obtiene todos los trabajadores (método auxiliar)
  Future<List<WorkerModel>> _getAllWorkers() async {
    // Necesitaríamos un método en el repositorio para obtener todos
    // Por ahora, obtener disponibles y no disponibles por separado
    final available = await _workerRepository.getAllAvailableWorkers();
    // Para obtener no disponibles, necesitaríamos otro método
    // Por simplicidad, retornamos solo disponibles
    return available;
  }

  /// Aplica filtros a la lista de trabajadores
  List<WorkerModel> _applyFilters(List<WorkerModel> workers, WorkerSearchFilters filters) {
    return workers.where((worker) {
      // Filtro por rating mínimo
      if (filters.minRating != null && worker.rating < filters.minRating!) {
        return false;
      }

      // Filtro por disponibilidad
      if (filters.isAvailable != null && worker.isAvailable != filters.isAvailable) {
        return false;
      }

      // Filtro por profesión
      if (filters.profession != null && worker.profession != filters.profession) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Aplica búsqueda por texto
  List<WorkerModel> _applyTextSearch(List<WorkerModel> workers, String query) {
    final queryLower = query.toLowerCase();
    return workers.where((worker) {
      return worker.profession.toLowerCase().contains(queryLower) ||
          (worker.description?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  /// Calcula distancias usando fórmula de Haversine
  List<WorkerModel> _calculateDistances(
    List<WorkerModel> workers,
    double userLat,
    double userLng,
  ) {
    // Nota: Necesitaríamos tener latitud/longitud en WorkerModel
    // Por ahora, retornamos sin modificar
    // En producción, esto requeriría agregar campos de ubicación al modelo
    return workers;
  }

  /// Ordena trabajadores según la opción seleccionada
  List<WorkerModel> _sortWorkers(List<WorkerModel> workers, WorkerSortOption sortBy) {
    switch (sortBy) {
      case WorkerSortOption.rating:
        workers.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case WorkerSortOption.availability:
        workers.sort((a, b) {
          if (a.isAvailable && !b.isAvailable) return -1;
          if (!a.isAvailable && b.isAvailable) return 1;
          return 0;
        });
        break;
      case WorkerSortOption.distance:
        // Ordenar por distancia (requiere que se haya calculado)
        // Por ahora, mantener orden original
        break;
      case WorkerSortOption.name:
        // Ordenar por nombre (requiere acceso al UserModel)
        // Por ahora, mantener orden original
        break;
    }
    return workers;
  }

  /// Calcula distancia entre dos puntos usando fórmula de Haversine
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Radio de la Tierra en km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;

    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}


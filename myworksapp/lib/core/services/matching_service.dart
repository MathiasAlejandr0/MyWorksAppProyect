import 'dart:math' as math;
import '../database/repositories/worker_repository.dart';
import '../database/repositories/job_repository.dart';
import '../database/repositories/user_repository.dart';
import '../database/models/worker_model.dart';
import '../database/models/job_model.dart';
import '../database/models/user_model.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';

/// Resultado de matching con score y metadata
class MatchResult {
  final WorkerModel worker;
  final UserModel user;
  final double score;
  final double? distanceKm;
  final int? cancellationCount;
  final DateTime? lastActivity;
  final String? reason; // Por qué fue seleccionado

  MatchResult({
    required this.worker,
    required this.user,
    required this.score,
    this.distanceKm,
    this.cancellationCount,
    this.lastActivity,
    this.reason,
  });
}

/// Estrategias de matching
enum MatchingStrategy {
  automatic, // Modo rápido - selección automática
  manual, // Modo manual - usuario elige
}

/// Servicio de matching inteligente híbrido
/// 
/// Proporciona dos modos:
/// - Automático: Selecciona los mejores trabajadores automáticamente
/// - Manual: Permite al usuario filtrar y elegir
/// 
/// Preparado para migrar lógica a backend futuro.
class MatchingService {
  static final MatchingService instance = MatchingService._();
  MatchingService._();

  final WorkerRepository _workerRepository = WorkerRepository();
  final JobRepository _jobRepository = JobRepository();
  final UserRepository _userRepository = UserRepository();

  // Pesos para cálculo de score (configurables)
  static const double _weightRating = 0.35;
  static const double _weightAvailability = 0.20;
  static const double _weightCancellations = 0.15;
  static const double _weightActivity = 0.05;

  /// Matching automático - Selecciona los mejores trabajadores
  /// 
  /// Retorna los 3-5 mejores trabajadores ordenados por score.
  /// El usuario solo confirma.
  Future<List<MatchResult>> automaticMatching({
    required String jobId,
    required String serviceId,
    required double userLatitude,
    required double userLongitude,
    int maxResults = 5,
  }) async {
    try {
      AppLogger.i('Iniciando matching automático para job: $jobId');

      // 1. Obtener job
      final job = await _jobRepository.getJobById(jobId);
      if (job == null) {
        AppLogger.e('Job no encontrado: $jobId');
        return [];
      }

      // 2. Obtener profesión del servicio
      final profession = await _getProfessionFromService(serviceId);

      // 3. Obtener trabajadores disponibles de esa profesión
      final workers = await _workerRepository.getWorkersByProfession(profession);
      if (workers.isEmpty) {
        AppLogger.w('No hay trabajadores disponibles para: $profession');
        return [];
      }

      // 4. Calcular scores para cada trabajador
      final matches = <MatchResult>[];
      for (final worker in workers) {
        final match = await _calculateMatchScore(
          worker: worker,
          job: job,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        );
        if (match != null) {
          matches.add(match);
        }
      }

      // 5. Ordenar por score descendente
      matches.sort((a, b) => b.score.compareTo(a.score));

      // 6. Retornar top N
      final results = matches.take(maxResults).toList();
      AppLogger.i('Matching automático completado: ${results.length} trabajadores seleccionados');
      return results;
    } catch (e) {
      AppLogger.e('Error en matching automático', e);
      return [];
    }
  }

  /// Matching manual - Retorna todos los trabajadores con scores
  /// 
  /// Permite al usuario filtrar, ordenar y elegir conscientemente.
  Future<List<MatchResult>> manualMatching({
    required String jobId,
    required String serviceId,
    required double userLatitude,
    required double userLongitude,
    double? minRating,
    double? maxDistanceKm,
    bool? onlyAvailable,
  }) async {
    try {
      AppLogger.i('Iniciando matching manual para job: $jobId');

      // 1. Obtener job
      final job = await _jobRepository.getJobById(jobId);
      if (job == null) {
        AppLogger.e('Job no encontrado: $jobId');
        return [];
      }

      // 2. Obtener profesión del servicio
      final profession = await _getProfessionFromService(serviceId);

      // 3. Obtener trabajadores (con filtros)
      List<WorkerModel> workers;
      if (onlyAvailable == true) {
        workers = await _workerRepository.getWorkersByProfession(profession);
      } else {
        // Obtener todos (incluyendo no disponibles)
        workers = await _getAllWorkersByProfession(profession);
      }

      // 4. Aplicar filtros
      if (minRating != null) {
        workers = workers.where((w) => w.rating >= minRating).toList();
      }

      // 5. Calcular scores
      final matches = <MatchResult>[];
      for (final worker in workers) {
        final match = await _calculateMatchScore(
          worker: worker,
          job: job,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        );

        if (match == null) continue;

        // Aplicar filtro de distancia
        if (maxDistanceKm != null && match.distanceKm != null) {
          if (match.distanceKm! > maxDistanceKm) continue;
        }

        matches.add(match);
      }

      // 6. Ordenar por score descendente
      matches.sort((a, b) => b.score.compareTo(a.score));

      AppLogger.i('Matching manual completado: ${matches.length} trabajadores');
      return matches;
    } catch (e) {
      AppLogger.e('Error en matching manual', e);
      return [];
    }
  }

  /// Calcula el score de matching para un trabajador
  Future<MatchResult?> _calculateMatchScore({
    required WorkerModel worker,
    required JobModel job,
    required double userLatitude,
    required double userLongitude,
  }) async {
    try {
      // 1. Obtener datos del usuario trabajador
      final user = await _userRepository.getUserById(worker.userId);
      if (user == null) return null;

      // 2. Calcular distancia (si tenemos coordenadas del trabajador)
      // Nota: Por ahora, asumimos que no tenemos coordenadas del trabajador
      // En producción, esto requeriría agregar lat/lng al WorkerModel
      double? distanceKm;
      // TODO: Calcular distancia real cuando tengamos coordenadas del trabajador

      // 3. Obtener cancelaciones previas (solo del trabajador, no del usuario)
      final cancellationCount = await _getCancellationCount(worker.userId);

      // 4. Obtener última actividad
      final lastActivity = await _getLastActivity(worker.userId);

      // 5. Calcular score
      double score = 0.0;

      // Score por rating (0-5 estrellas → 0-1)
      final ratingScore = (worker.rating / 5.0) * _weightRating;
      score += ratingScore;

      // Score por disponibilidad
      if (worker.isAvailable) {
        score += _weightAvailability;
      }

      // Score por distancia (menor distancia = mayor score)
      // Por ahora, no penalizamos por distancia
      // TODO: Implementar cuando tengamos coordenadas

      // Score por cancelaciones (menos cancelaciones = mayor score)
      final cancellationPenalty = math.min(cancellationCount * 0.1, 1.0);
      score += _weightCancellations * (1.0 - cancellationPenalty);

      // Score por última actividad (más reciente = mayor score)
      if (lastActivity != null) {
        final daysSinceActivity = DateTime.now().difference(lastActivity).inDays;
        final activityScore = math.max(0, 1.0 - (daysSinceActivity / 30.0));
        score += _weightActivity * activityScore;
      }

      // Normalizar score a 0-1
      score = math.min(1.0, math.max(0.0, score));

      // Generar razón de selección
      final reason = _generateReason(worker, cancellationCount, lastActivity);

      return MatchResult(
        worker: worker,
        user: user,
        score: score,
        distanceKm: distanceKm,
        cancellationCount: cancellationCount,
        lastActivity: lastActivity,
        reason: reason,
      );
    } catch (e) {
      AppLogger.e('Error calculando score para worker: ${worker.userId}', e);
      return null;
    }
  }

  /// Obtiene el número de cancelaciones de un trabajador
  Future<int> _getCancellationCount(String workerId) async {
    try {
      // Obtener trabajos cancelados por este trabajador
      final jobs = await _jobRepository.getWorkerJobs(workerId);
      return jobs.where((j) => j.status == AppConstants.jobStatusCancelled).length;
    } catch (e) {
      AppLogger.e('Error obteniendo cancelaciones', e);
      return 0;
    }
  }

  /// Obtiene la última actividad de un trabajador
  Future<DateTime?> _getLastActivity(String workerId) async {
    try {
      // Obtener el trabajo más reciente del trabajador
      final jobs = await _jobRepository.getWorkerJobs(workerId);
      if (jobs.isEmpty) return null;

      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs.first.createdAt;
    } catch (e) {
      AppLogger.e('Error obteniendo última actividad', e);
      return null;
    }
  }

  /// Genera una razón de selección legible
  String _generateReason(WorkerModel worker, int cancellationCount, DateTime? lastActivity) {
    final reasons = <String>[];

    if (worker.rating >= 4.5) {
      reasons.add('Excelente calificación');
    } else if (worker.rating >= 4.0) {
      reasons.add('Buena calificación');
    }

    if (cancellationCount == 0) {
      reasons.add('Sin cancelaciones');
    }

    if (lastActivity != null) {
      final daysSince = DateTime.now().difference(lastActivity).inDays;
      if (daysSince <= 7) {
        reasons.add('Activo recientemente');
      }
    }

    if (worker.isAvailable) {
      reasons.add('Disponible ahora');
    }

    return reasons.isEmpty ? 'Trabajador disponible' : reasons.join(', ');
  }

  /// Obtiene la profesión desde el servicio
  Future<String> _getProfessionFromService(String serviceId) async {
    // Por ahora, mapeo simple
    // En producción, esto debería venir de la tabla services
    final serviceMap = {
      'plumber': 'Plomero',
      'electrician': 'Electricista',
      'carpenter': 'Carpintero',
      'painter': 'Pintor',
      'cleaner': 'Limpieza',
    };

    // Si no está en el mapa, usar el serviceId como profesión
    return serviceMap[serviceId.toLowerCase()] ?? serviceId;
  }

  /// Obtiene todos los trabajadores de una profesión (disponibles y no disponibles)
  Future<List<WorkerModel>> _getAllWorkersByProfession(String profession) async {
    // Por ahora, solo retornamos disponibles
    // En producción, necesitaríamos un método en el repositorio
    return await _workerRepository.getWorkersByProfession(profession);
  }

  /// Calcula distancia usando fórmula de Haversine
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


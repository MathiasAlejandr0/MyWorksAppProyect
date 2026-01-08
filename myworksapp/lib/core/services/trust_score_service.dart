import '../database/repositories/job_repository.dart';
import '../database/repositories/user_repository.dart';
import '../database/models/job_model.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';

/// Modelo para trust score del usuario
class UserTrustScore {
  final String userId;
  final double score; // 0-100
  final int cancellationCount;
  final int noShowCount;
  final int completedJobsCount;
  final DateTime lastUpdated;

  UserTrustScore({
    required this.userId,
    required this.score,
    required this.cancellationCount,
    required this.noShowCount,
    required this.completedJobsCount,
    required this.lastUpdated,
  });
}

/// Servicio de trust score y límites de seguridad
/// 
/// Maneja:
/// - Cálculo de trust score
/// - Límites de cancelaciones
/// - Penalizaciones por no-show
/// - Soft-ban automático
class TrustScoreService {
  static final TrustScoreService instance = TrustScoreService._();
  TrustScoreService._();

  final JobRepository _jobRepository = JobRepository();
  final UserRepository _userRepository = UserRepository();

  // Límites configurables
  static const int maxCancellationsPerMonth = 3;
  static const int maxNoShowsPerMonth = 2;
  static const double softBanThreshold = 30.0; // Score mínimo para no estar baneado

  // Penalizaciones
  static const double cancellationPenalty = 10.0;
  static const double noShowPenalty = 20.0;
  static const double completedJobBonus = 2.0;

  /// Calcula el trust score de un usuario
  Future<UserTrustScore> calculateTrustScore(String userId) async {
    try {
      // 1. Obtener todos los trabajos del usuario
      final jobs = await _jobRepository.getJobsByUserId(userId);
      final workerJobs = await _jobRepository.getJobsByWorkerId(userId);
      final allJobs = [...jobs, ...workerJobs];

      // 2. Contar eventos
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);

      int cancellationCount = 0;
      int noShowCount = 0;
      int completedCount = 0;

      for (final job in allJobs) {
        if (job.createdAt.isBefore(thisMonth)) continue;

        if (job.status == AppConstants.jobStatusCancelled) {
          cancellationCount++;
        } else if (job.status == AppConstants.jobStatusNoShow) {
          noShowCount++;
        } else if (job.status == AppConstants.jobStatusCompleted) {
          completedCount++;
        }
      }

      // 3. Calcular score inicial (100)
      double score = 100.0;

      // 4. Aplicar penalizaciones
      score -= cancellationCount * cancellationPenalty;
      score -= noShowCount * noShowPenalty;

      // 5. Aplicar bonificaciones
      score += completedCount * completedJobBonus;

      // 6. Normalizar a 0-100
      score = score.clamp(0.0, 100.0);

      return UserTrustScore(
        userId: userId,
        score: score,
        cancellationCount: cancellationCount,
        noShowCount: noShowCount,
        completedJobsCount: completedCount,
        lastUpdated: now,
      );
    } catch (e) {
      AppLogger.e('Error calculando trust score', e);
      // Retornar score por defecto en caso de error
      return UserTrustScore(
        userId: userId,
        score: 100.0,
        cancellationCount: 0,
        noShowCount: 0,
        completedJobsCount: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Verifica si un usuario puede cancelar más trabajos
  Future<bool> canCancelJob(String userId) async {
    try {
      final trustScore = await calculateTrustScore(userId);
      return trustScore.cancellationCount < maxCancellationsPerMonth;
    } catch (e) {
      AppLogger.e('Error verificando límite de cancelaciones', e);
      return true; // Por defecto, permitir
    }
  }

  /// Verifica si un usuario está en soft-ban
  Future<bool> isSoftBanned(String userId) async {
    try {
      final trustScore = await calculateTrustScore(userId);
      return trustScore.score < softBanThreshold;
    } catch (e) {
      AppLogger.e('Error verificando soft-ban', e);
      return false;
    }
  }

  /// Registra una cancelación y actualiza el score
  Future<void> recordCancellation(String userId) async {
    try {
      // El score se recalcula automáticamente en calculateTrustScore
      AppLogger.i('Cancelación registrada para usuario: $userId');
      
      // Verificar si debe ser soft-baneado
      final isBanned = await isSoftBanned(userId);
      if (isBanned) {
        AppLogger.w('Usuario $userId está en soft-ban por bajo trust score');
        // TODO: Actualizar accountStatus a 'suspended' si es necesario
      }
    } catch (e) {
      AppLogger.e('Error registrando cancelación', e);
    }
  }

  /// Registra un no-show y actualiza el score
  Future<void> recordNoShow(String userId) async {
    try {
      AppLogger.i('No-show registrado para usuario: $userId');
      
      // Verificar si debe ser soft-baneado
      final isBanned = await isSoftBanned(userId);
      if (isBanned) {
        AppLogger.w('Usuario $userId está en soft-ban por bajo trust score');
      }
    } catch (e) {
      AppLogger.e('Error registrando no-show', e);
    }
  }

  /// Registra un trabajo completado (bonificación)
  Future<void> recordCompletedJob(String userId) async {
    try {
      AppLogger.i('Trabajo completado registrado para usuario: $userId');
    } catch (e) {
      AppLogger.e('Error registrando trabajo completado', e);
    }
  }

  /// Obtiene el mensaje de advertencia si está cerca del límite
  Future<String?> getWarningMessage(String userId) async {
    try {
      final trustScore = await calculateTrustScore(userId);
      
      if (trustScore.cancellationCount >= maxCancellationsPerMonth - 1) {
        return 'Has alcanzado el límite de cancelaciones este mes. Cancelar otro trabajo puede resultar en suspensión.';
      }
      
      if (trustScore.noShowCount >= maxNoShowsPerMonth - 1) {
        return 'Has alcanzado el límite de no-shows este mes. Otro no-show puede resultar en suspensión.';
      }
      
      if (trustScore.score < 50.0) {
        return 'Tu score de confianza está bajo. Completa trabajos para mejorarlo.';
      }
      
      return null;
    } catch (e) {
      AppLogger.e('Error obteniendo mensaje de advertencia', e);
      return null;
    }
  }
}


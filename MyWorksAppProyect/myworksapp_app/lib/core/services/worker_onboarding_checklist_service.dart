import '../database/repositories/user_repository.dart';
import '../database/repositories/worker_repository.dart';
import '../database/repositories/portfolio_repository.dart';
import '../utils/app_logger.dart';

/// Checklist de onboarding para trabajadores.
///
/// Requisitos para aparecer en búsquedas y recibir trabajos:
/// - Foto de perfil
/// - Descripción profesional (mín. 150 caracteres)
/// - Al menos 1 foto en portafolio
/// - Categoría de servicio configurada
/// - Zona de trabajo definida
/// - Tarifas configuradas
class WorkerOnboardingChecklistService {
  static final WorkerOnboardingChecklistService instance =
      WorkerOnboardingChecklistService._();
  WorkerOnboardingChecklistService._();

  final UserRepository _userRepository = UserRepository();
  final WorkerRepository _workerRepository = WorkerRepository();
  final PortfolioRepository _portfolioRepository = PortfolioRepository();

  static const int minDescriptionLength = 150;
  static const int minPortfolioPhotos = 1;
  static const int totalItems = 6;

  Future<WorkerOnboardingStatus> checkStatus(String workerId) async {
    try {
      final user = await _userRepository.getUserById(workerId);
      if (user == null) {
        return WorkerOnboardingStatus(
          isComplete: false,
          completionPercentage: 0,
          missingItems: ['Usuario no encontrado'],
        );
      }

      final worker = await _workerRepository.getWorkerByUserId(workerId);
      if (worker == null) {
        return WorkerOnboardingStatus(
          isComplete: false,
          completionPercentage: 0,
          missingItems: ['Perfil de trabajador no creado'],
        );
      }

      final portfolio =
          await _portfolioRepository.getPortfolioByWorkerId(workerId);

      final missingItems = <String>[];
      var completedItems = 0;

      // 1. Foto de perfil
      final hasPhoto = user.profilePhotoPath != null &&
          user.profilePhotoPath!.trim().isNotEmpty;
      if (!hasPhoto) {
        missingItems.add('Foto de perfil');
      } else {
        completedItems++;
      }

      // 2. Descripción profesional
      if (worker.description == null ||
          worker.description!.trim().length < minDescriptionLength) {
        missingItems.add(
          'Descripción profesional (mín. $minDescriptionLength caracteres)',
        );
      } else {
        completedItems++;
      }

      // 3. Portafolio
      if (portfolio.length < minPortfolioPhotos) {
        missingItems.add('Al menos $minPortfolioPhotos foto en portafolio');
      } else {
        completedItems++;
      }

      // 4. Servicio / categoría
      if (worker.serviceCategory.isEmpty ||
          worker.serviceCategory == 'general') {
        missingItems.add('Servicio seleccionado');
      } else {
        completedItems++;
      }

      // 5. Zona de trabajo
      if (worker.workZone == null || worker.workZone!.trim().length < 3) {
        missingItems.add('Zona de trabajo definida');
      } else {
        completedItems++;
      }

      // 6. Tarifas configuradas
      if (!worker.pricingConfigured) {
        missingItems.add('Tarifas y precios configurados');
      } else {
        completedItems++;
      }

      final completionPercentage =
          (completedItems / totalItems * 100).round();

      return WorkerOnboardingStatus(
        isComplete: missingItems.isEmpty,
        completionPercentage: completionPercentage,
        missingItems: missingItems,
        completedItems: completedItems,
        totalItems: totalItems,
      );
    } catch (e) {
      AppLogger.e('Error al verificar checklist de onboarding', e);
      return WorkerOnboardingStatus(
        isComplete: false,
        completionPercentage: 0,
        missingItems: ['Error al verificar requisitos'],
      );
    }
  }

  Future<bool> canReceiveJobs(String workerId) async {
    final status = await checkStatus(workerId);
    return status.isComplete;
  }

  Future<bool> isListedInSearch(String workerId) async {
    final worker = await _workerRepository.getWorkerByUserId(workerId);
    if (worker == null || !worker.pricingConfigured || !worker.isAvailable) {
      return false;
    }
    return canReceiveJobs(workerId);
  }

  Future<String?> getNextPendingStep(String workerId) async {
    final status = await checkStatus(workerId);
    if (status.missingItems.isNotEmpty) {
      return status.missingItems.first;
    }
    return null;
  }
}

class WorkerOnboardingStatus {
  final bool isComplete;
  final int completionPercentage;
  final List<String> missingItems;
  final int? completedItems;
  final int? totalItems;

  WorkerOnboardingStatus({
    required this.isComplete,
    required this.completionPercentage,
    required this.missingItems,
    this.completedItems,
    this.totalItems,
  });

  Map<String, dynamic> toMap() {
    return {
      'isComplete': isComplete,
      'completionPercentage': completionPercentage,
      'missingItems': missingItems,
      'completedItems': completedItems,
      'totalItems': totalItems,
    };
  }
}

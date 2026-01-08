import '../database/repositories/user_repository.dart';
import '../database/repositories/worker_repository.dart';
import '../database/repositories/portfolio_repository.dart';
import '../database/repositories/service_repository.dart';
import '../utils/app_logger.dart';

/// Checklist de onboarding para trabajadores
/// 
/// Requisitos mínimos para que un trabajador esté activo y reciba trabajos:
/// - Foto de perfil
/// - Descripción profesional (mín. 150 caracteres)
/// - Al menos 1 foto en portafolio
/// - Servicio seleccionado
/// - Zona de trabajo definida
class WorkerOnboardingChecklistService {
  static final WorkerOnboardingChecklistService instance = 
      WorkerOnboardingChecklistService._();
  WorkerOnboardingChecklistService._();

  final UserRepository _userRepository = UserRepository();
  final WorkerRepository _workerRepository = WorkerRepository();
  final PortfolioRepository _portfolioRepository = PortfolioRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();

  /// Requisitos del checklist
  static const int minDescriptionLength = 150;
  static const int minPortfolioPhotos = 1;

  /// Verifica si un trabajador cumple con todos los requisitos
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

      final portfolio = await _portfolioRepository.getPortfolioByWorkerId(workerId);
      
      final missingItems = <String>[];
      int completedItems = 0;
      const totalItems = 5;

      // 1. Foto de perfil
      // TODO: Implementar cuando UserModel tenga profilePhoto
      // Por ahora, asumimos que no es requerido para MVP
      completedItems++;

      // 2. Descripción profesional (mín. 150 caracteres)
      if (worker.description == null || 
          worker.description!.trim().length < minDescriptionLength) {
        missingItems.add(
          'Descripción profesional (mín. $minDescriptionLength caracteres)',
        );
      } else {
        completedItems++;
      }

      // 3. Al menos 1 foto en portafolio
      if (portfolio.length < minPortfolioPhotos) {
        missingItems.add('Al menos $minPortfolioPhotos foto en portafolio');
      } else {
        completedItems++;
      }

      // 4. Servicio seleccionado (profession debe estar en servicios activos)
      if (worker.profession.isEmpty) {
        missingItems.add('Servicio seleccionado');
      } else {
        // Verificar que el servicio existe y está activo
        final services = await _serviceRepository.getAllServices();
        final serviceExists = services.any(
          (s) => s.name.toLowerCase() == worker.profession.toLowerCase() ||
                 s.category.toLowerCase() == worker.profession.toLowerCase(),
        );
        
        if (!serviceExists) {
          missingItems.add('Servicio válido seleccionado');
        } else {
          completedItems++;
        }
      }

      // 5. Zona de trabajo definida
      // Por ahora, asumimos que si el trabajador está registrado, tiene zona
      // En el futuro, esto puede requerir una tabla de zonas de trabajo
      completedItems++; // TODO: Implementar verificación real de zona

      final completionPercentage = (completedItems / totalItems * 100).round();
      final isComplete = missingItems.isEmpty;

      return WorkerOnboardingStatus(
        isComplete: isComplete,
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

  /// Verifica si un trabajador puede recibir trabajos
  Future<bool> canReceiveJobs(String workerId) async {
    final status = await checkStatus(workerId);
    return status.isComplete;
  }

  /// Obtiene el siguiente paso pendiente para completar el onboarding
  Future<String?> getNextPendingStep(String workerId) async {
    final status = await checkStatus(workerId);
    if (status.missingItems.isNotEmpty) {
      return status.missingItems.first;
    }
    return null;
  }
}

/// Estado del onboarding de un trabajador
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


import 'package:uuid/uuid.dart';
import '../database/repositories/boost_repository.dart';
import '../database/models/boost_model.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';

/// Tipos de boost
enum BoostType {
  visibility, // Aumenta visibilidad en búsquedas
  priority, // Prioridad en matching automático
  featured, // Aparece en destacados
}

/// Servicio de boosts (preparado para futuro)
/// 
/// NO implementa cobro real todavía.
/// Solo prepara la arquitectura para:
/// - Boost de visibilidad
/// - Boost de prioridad
/// - Boost destacado
class BoostService {
  static final BoostService instance = BoostService._();
  BoostService._();

  final BoostRepository _boostRepository = BoostRepository();

  /// Crea un boost (MOCK)
  Future<BoostModel> createBoost({
    required String workerId,
    required BoostType boostType,
    required int durationDays,
  }) async {
    try {
      AppLogger.i('Creando boost (MOCK) para trabajador: $workerId');

      final now = DateTime.now();
      final endDate = now.add(Duration(days: durationDays));

      final boost = BoostModel(
        id: const Uuid().v4(),
        workerId: workerId,
        boostType: boostType.name,
        startDate: now,
        endDate: endDate,
        createdAt: now,
      );

      await _boostRepository.createBoost(boost);

      AppLogger.i('Boost creado (MOCK): ${boost.id}');
      return boost;
    } catch (e) {
      AppLogger.e('Error creando boost', e);
      throw AppError.database('Error al crear boost: ${e.toString()}');
    }
  }

  /// Verifica si un trabajador tiene boost activo
  Future<bool> hasActiveBoost(String workerId, BoostType? boostType) async {
    try {
      final boosts = await _boostRepository.getActiveBoosts(workerId);
      if (boostType == null) {
        return boosts.isNotEmpty;
      }
      return boosts.any((b) => b.boostType == boostType.name);
    } catch (e) {
      AppLogger.e('Error verificando boost', e);
      return false;
    }
  }

  /// Obtiene todos los boosts activos de un trabajador
  Future<List<BoostModel>> getActiveBoosts(String workerId) async {
    try {
      return await _boostRepository.getActiveBoosts(workerId);
    } catch (e) {
      AppLogger.e('Error obteniendo boosts', e);
      return [];
    }
  }

  /// Limpia boosts expirados
  Future<void> cleanExpiredBoosts() async {
    try {
      final allBoosts = await _boostRepository.getAllBoosts();
      final now = DateTime.now();

      for (final boost in allBoosts) {
        if (boost.endDate.isBefore(now)) {
          await _boostRepository.deleteBoost(boost.id);
          AppLogger.i('Boost expirado eliminado: ${boost.id}');
        }
      }
    } catch (e) {
      AppLogger.e('Error limpiando boosts expirados', e);
    }
  }
}


import 'package:uuid/uuid.dart';
import '../database/repositories/subscription_repository.dart';
import '../database/models/subscription_model.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';

/// Tipos de planes de suscripción
enum SubscriptionPlan {
  free,
  basic,
  premium,
  enterprise,
}

/// Servicio de suscripciones (preparado para futuro)
/// 
/// NO implementa cobro real todavía.
/// Solo prepara la arquitectura para:
/// - Gestión de suscripciones
/// - Verificación de estado
/// - Renovaciones
class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();
  SubscriptionService._();

  final SubscriptionRepository _subscriptionRepository = SubscriptionRepository();

  /// Crea una suscripción (MOCK)
  Future<SubscriptionModel> createSubscription({
    required String userId,
    required SubscriptionPlan plan,
    int? durationDays, // Duración en días (null = indefinido)
  }) async {
    try {
      AppLogger.i('Creando suscripción (MOCK) para usuario: $userId');

      final now = DateTime.now();
      final endDate = durationDays != null
          ? now.add(Duration(days: durationDays))
          : null;

      final subscription = SubscriptionModel(
        id: const Uuid().v4(),
        userId: userId,
        planType: plan.name,
        status: 'active',
        startDate: now,
        endDate: endDate,
        createdAt: now,
        updatedAt: now,
      );

      await _subscriptionRepository.createSubscription(subscription);

      AppLogger.i('Suscripción creada (MOCK): ${subscription.id}');
      return subscription;
    } catch (e) {
      AppLogger.e('Error creando suscripción', e);
      throw AppError.database('Error al crear suscripción: ${e.toString()}');
    }
  }

  /// Verifica si un usuario tiene suscripción activa
  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final subscription = await _subscriptionRepository.getActiveSubscription(userId);
      return subscription != null;
    } catch (e) {
      AppLogger.e('Error verificando suscripción', e);
      return false;
    }
  }

  /// Obtiene la suscripción activa de un usuario
  Future<SubscriptionModel?> getActiveSubscription(String userId) async {
    try {
      return await _subscriptionRepository.getActiveSubscription(userId);
    } catch (e) {
      AppLogger.e('Error obteniendo suscripción', e);
      return null;
    }
  }

  /// Cancela una suscripción
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final subscription = await _subscriptionRepository.getSubscriptionById(subscriptionId);
      if (subscription == null) {
        throw AppError.notFound('Suscripción no encontrada');
      }

      final updated = subscription.copyWith(
        status: 'cancelled',
        updatedAt: DateTime.now(),
      );

      await _subscriptionRepository.updateSubscription(updated);

      AppLogger.i('Suscripción cancelada: $subscriptionId');
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error cancelando suscripción', e);
      throw AppError.database('Error al cancelar suscripción: ${e.toString()}');
    }
  }

  /// Verifica si una suscripción está expirada
  Future<void> checkExpiredSubscriptions() async {
    try {
      final subscriptions = await _subscriptionRepository.getActiveSubscriptions();
      final now = DateTime.now();

      for (final subscription in subscriptions) {
        if (subscription.endDate != null && subscription.endDate!.isBefore(now)) {
          final updated = subscription.copyWith(
            status: 'expired',
            updatedAt: now,
          );
          await _subscriptionRepository.updateSubscription(updated);
          AppLogger.i('Suscripción expirada: ${subscription.id}');
        }
      }
    } catch (e) {
      AppLogger.e('Error verificando suscripciones expiradas', e);
    }
  }
}


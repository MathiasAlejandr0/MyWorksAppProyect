import '../database/repositories/pending_action_repository.dart';
import '../database/models/pending_action_model.dart';
import '../utils/app_logger.dart';

/// Servicio para manejar reintentos controlados de pending_actions
class PendingActionRetryService {
  final PendingActionRepository _repository = PendingActionRepository();
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  /// Intenta sincronizar una acción pendiente
  Future<bool> retryAction(String actionId) async {
    try {
      final action = await _repository.getPendingActionById(actionId);
      if (action == null) {
        AppLogger.w('Acción pendiente no encontrada: $actionId');
        return false;
      }

      // Verificar si ya se alcanzó el máximo de reintentos
      if (action.retryCount >= maxRetries) {
        AppLogger.w('Máximo de reintentos alcanzado para acción: $actionId');
        await _markAsFailed(action, 'Máximo de reintentos alcanzado');
        return false;
      }

      // Marcar como syncing
      await _repository.updateStatus(actionId, 'syncing');

      // Intentar sincronizar (aquí iría la lógica de sincronización con backend)
      final success = await _attemptSync(action);

      if (success) {
        // Marcar como synced
        await _repository.updateStatus(actionId, 'synced');
        AppLogger.i('Acción sincronizada exitosamente: $actionId');
        return true;
      } else {
        // Incrementar contador de reintentos
        final newRetryCount = action.retryCount + 1;
        await _repository.setRetryCount(actionId, newRetryCount);

        if (newRetryCount >= maxRetries) {
          await _markAsFailed(action, 'Error después de $maxRetries intentos');
        } else {
          // Volver a pending_sync para reintento automático
          await _repository.updateStatus(actionId, 'pending_sync');
          AppLogger.i('Reintento programado para acción: $actionId (intento ${newRetryCount + 1}/$maxRetries)');
        }

        return false;
      }
    } catch (e) {
      AppLogger.e('Error al reintentar acción: $actionId', e);
      return false;
    }
  }

  /// Intenta sincronizar todas las acciones pendientes
  Future<void> retryAllPendingActions(String userId) async {
    try {
      final pendingActions = await _repository.getPendingActions(userId);
      final toRetry = pendingActions.where((a) => 
        a.status == 'pending_sync' && a.retryCount < maxRetries
      ).toList();

      AppLogger.i('Reintentando ${toRetry.length} acciones pendientes para usuario: $userId');

      for (final action in toRetry) {
        await retryAction(action.id);
        // Delay entre reintentos para no saturar
        await Future.delayed(retryDelay);
      }
    } catch (e) {
      AppLogger.e('Error al reintentar todas las acciones pendientes', e);
    }
  }

  /// Marca una acción como fallida
  Future<void> _markAsFailed(PendingActionModel action, String errorMessage) async {
    await _repository.updateStatus(action.id, 'failed');
    await _repository.updateErrorMessage(action.id, errorMessage);
    AppLogger.w('Acción marcada como fallida: ${action.id} - $errorMessage');
    
    // Aquí se podría notificar al usuario
    // await NotificationService.instance.showNotification(...)
  }

  /// Intenta sincronizar una acción (lógica de sincronización)
  /// En producción, esto se conectaría con el backend
  Future<bool> _attemptSync(PendingActionModel action) async {
    try {
      // Simular intento de sincronización
      // En producción, aquí se haría la llamada al backend
      
      AppLogger.i('Intentando sincronizar acción: ${action.id} (${action.actionType})');
      
      // Simular intento de sincronización
      // En producción, esto sería una llamada HTTP real
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Por ahora, simulamos que siempre falla (para testing de reintentos)
      // En producción, esto dependería de la respuesta del backend
      // TODO: Implementar sincronización real con backend
      return false; // Cambiar a true cuando se implemente backend
    } catch (e) {
      AppLogger.e('Error en intento de sincronización', e);
      return false;
    }
  }

  /// Obtiene acciones fallidas que pueden reintentarse manualmente
  Future<List<PendingActionModel>> getFailedActions(String userId) async {
    try {
      final allActions = await _repository.getPendingActions(userId);
      return allActions.where((a) => a.status == 'failed').toList();
    } catch (e) {
      AppLogger.e('Error al obtener acciones fallidas', e);
      return [];
    }
  }

  /// Reintenta manualmente una acción fallida
  Future<bool> retryFailedAction(String actionId) async {
    try {
      final action = await _repository.getPendingActionById(actionId);
      if (action == null || action.status != 'failed') {
        return false;
      }

      // Resetear contador de reintentos para reintento manual
      await _repository.setRetryCount(actionId, 0);
      await _repository.updateErrorMessage(actionId, null);
      
      // Intentar sincronizar
      return await retryAction(actionId);
    } catch (e) {
      AppLogger.e('Error al reintentar acción fallida manualmente', e);
      return false;
    }
  }
}


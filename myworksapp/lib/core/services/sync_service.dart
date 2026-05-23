import '../database/repositories/pending_action_repository.dart';
import '../database/models/pending_action_model.dart';
import '../utils/app_logger.dart';
import 'dart:convert';

/// Servicio de sincronización local (modo demo offline-first).
///
/// En esta versión de demostración las acciones se procesan localmente.
/// La arquitectura de pending_actions queda lista para conectar un backend.
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final PendingActionRepository _pendingActionRepository = PendingActionRepository();

  // Configuración
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  /// Sincroniza todas las acciones pendientes
  Future<void> syncAll({String? userId}) async {
    try {
      AppLogger.i('Iniciando sincronización de acciones pendientes...');

      final pendingActions = userId != null
          ? await _pendingActionRepository.getPendingActions(userId)
          : await _getAllPendingActions();

      if (pendingActions.isEmpty) {
        AppLogger.i('No hay acciones pendientes para sincronizar');
        return;
      }

      int synced = 0;
      int failed = 0;

      for (final action in pendingActions) {
        try {
          final success = await _syncAction(action);
          if (success) {
            synced++;
            await _pendingActionRepository.updateStatus(action.id, 'synced');
            await _pendingActionRepository.deleteAction(action.id);
          } else {
            failed++;
            await _handleSyncFailure(action);
          }
        } catch (e) {
          AppLogger.e('Error sincronizando acción ${action.id}', e);
          failed++;
          await _handleSyncFailure(action);
        }
      }

      AppLogger.i('Sincronización completada: $synced exitosas, $failed fallidas');
    } catch (e) {
      AppLogger.e('Error en sincronización general', e);
    }
  }

  /// Sincroniza una acción individual
  Future<bool> _syncAction(PendingActionModel action) async {
    try {
      // Marcar como sincronizando
      await _pendingActionRepository.updateStatus(action.id, 'syncing');

      // Modo demo: la acción ya quedó persistida en SQLite localmente.
      AppLogger.i('Acción procesada localmente: ${action.actionType} - ${action.entityId}');
      return true;
    } catch (e) {
      AppLogger.e('Error sincronizando acción', e);
      return false;
    }
  }

  /// Maneja fallo de sincronización
  Future<void> _handleSyncFailure(PendingActionModel action) async {
    final newRetryCount = action.retryCount + 1;

    if (newRetryCount >= maxRetries) {
      // Marcar como fallido permanentemente
      await _pendingActionRepository.updateActionStatus(
        actionId: action.id,
        status: 'failed',
        errorMessage: 'Máximo de reintentos alcanzado',
      );
      AppLogger.w('Acción ${action.id} marcada como fallida permanentemente');
    } else {
      // Reintentar más tarde
      await _pendingActionRepository.setRetryCount(action.id, newRetryCount);
      await _pendingActionRepository.updateStatus(action.id, 'pending_sync');
      AppLogger.i('Acción ${action.id} programada para reintento (intento $newRetryCount/$maxRetries)');
    }
  }

  /// Sincroniza una acción específica manualmente
  Future<bool> syncAction(String actionId) async {
    try {
      final action = await _pendingActionRepository.getActionById(actionId);
      if (action == null) {
        AppLogger.e('Acción no encontrada: $actionId');
        return false;
      }

      return await _syncAction(action);
    } catch (e) {
      AppLogger.e('Error sincronizando acción específica', e);
      return false;
    }
  }

  /// Obtiene todas las acciones pendientes (helper)
  Future<List<PendingActionModel>> _getAllPendingActions() async {
    // Por ahora, retornamos lista vacía
    // En producción, necesitaríamos un método en el repositorio
    return [];
  }

  /// Obtiene estadísticas de sincronización
  Future<SyncStats> getStats({String? userId}) async {
    try {
      final allActions = userId != null
          ? await _pendingActionRepository.getPendingActions(userId)
          : await _getAllPendingActions();

      return SyncStats(
        total: allActions.length,
        pending: allActions.where((a) => a.status == 'pending_sync').length,
        syncing: allActions.where((a) => a.status == 'syncing').length,
        synced: allActions.where((a) => a.status == 'synced').length,
        failed: allActions.where((a) => a.status == 'failed').length,
      );
    } catch (e) {
      AppLogger.e('Error obteniendo estadísticas de sync', e);
      return SyncStats(total: 0, pending: 0, syncing: 0, synced: 0, failed: 0);
    }
  }
}

/// Estadísticas de sincronización
class SyncStats {
  final int total;
  final int pending;
  final int syncing;
  final int synced;
  final int failed;

  SyncStats({
    required this.total,
    required this.pending,
    required this.syncing,
    required this.synced,
    required this.failed,
  });

  double get successRate {
    if (total == 0) return 0.0;
    return synced / total;
  }
}


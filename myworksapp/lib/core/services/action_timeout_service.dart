import 'dart:async';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';
import '../utils/error_handler.dart';

/// Exception para timeouts
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => message;
}

/// Servicio para manejar timeouts y rollback de acciones críticas
class ActionTimeoutService {
  static final ActionTimeoutService instance = ActionTimeoutService._();
  ActionTimeoutService._();

  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration criticalTimeout = Duration(seconds: 10);

  /// Ejecuta una acción crítica con timeout y rollback
  Future<T> executeWithTimeout<T>({
    required Future<T> Function() action,
    required Future<void> Function() rollback,
    Duration? timeout,
    String? actionName,
  }) async {
    final timeoutDuration = timeout ?? defaultTimeout;
    final name = actionName ?? 'acción crítica';

    try {
      AppLogger.i('Ejecutando $name con timeout de ${timeoutDuration.inSeconds}s');

      // Ejecutar acción con timeout
      final result = await action().timeout(
        timeoutDuration,
        onTimeout: () {
          AppLogger.w('Timeout en $name después de ${timeoutDuration.inSeconds}s');
          throw AppError.critical(
            'La operación tardó demasiado. Por favor intenta nuevamente.',
            TimeoutException('Timeout en $name', timeoutDuration),
          );
        },
      );

      AppLogger.i('$name completada exitosamente');
      return result;
    } catch (e) {
      AppLogger.e('Error en $name, ejecutando rollback', e);

      // Ejecutar rollback
      try {
        await rollback();
        AppLogger.i('Rollback de $name ejecutado exitosamente');
      } catch (rollbackError) {
        AppLogger.f('Error crítico en rollback de $name', rollbackError);
        // Si el rollback falla, es un error crítico
        throw AppError.critical(
          'Error crítico. Por favor contacta con soporte.',
          rollbackError,
        );
      }

      // Re-lanzar el error original para que el UI pueda manejarlo
      if (e is AppError) {
        rethrow;
      } else {
        throw ErrorHandler.handle(e);
      }
    }
  }

  /// Ejecuta acción con timeout sin rollback (para acciones no críticas)
  Future<T> executeWithTimeoutOnly<T>({
    required Future<T> Function() action,
    Duration? timeout,
    String? actionName,
  }) async {
    final timeoutDuration = timeout ?? defaultTimeout;
    final name = actionName ?? 'acción';

    try {
      return await action().timeout(
        timeoutDuration,
        onTimeout: () {
          AppLogger.w('Timeout en $name');
          throw AppError.network(
            'La operación tardó demasiado. Por favor intenta nuevamente.',
            TimeoutException('Timeout en $name', timeoutDuration),
          );
        },
      );
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      throw ErrorHandler.handle(e);
    }
  }
}

/// Helper para crear rollbacks específicos
class RollbackHelper {
  /// Crea un rollback para actualizar estado de job
  static Future<void> Function() jobStatusRollback({
    required String jobId,
    required String originalStatus,
    required Future<void> Function(String, String) updateStatus,
  }) {
    return () async {
      AppLogger.i('Rollback: Restaurando job $jobId a estado $originalStatus');
      await updateStatus(jobId, originalStatus);
    };
  }

  /// Crea un rollback para eliminar mensaje
  static Future<void> Function() messageRollback({
    required String messageId,
    required Future<void> Function(String) deleteMessage,
  }) {
    return () async {
      AppLogger.i('Rollback: Eliminando mensaje $messageId');
      await deleteMessage(messageId);
    };
  }

  /// Crea un rollback para actualizar disponibilidad
  static Future<void> Function() availabilityRollback({
    required String workerId,
    required bool originalAvailability,
    required Future<void> Function(String, bool) updateAvailability,
  }) {
    return () async {
      AppLogger.i('Rollback: Restaurando disponibilidad de $workerId a $originalAvailability');
      await updateAvailability(workerId, originalAvailability);
    };
  }
}


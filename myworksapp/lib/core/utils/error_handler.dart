import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_error.dart';
import 'app_logger.dart';

/// Manejo centralizado de errores
class ErrorHandler {
  /// Maneja errores y retorna AppError
  static AppError handle(dynamic error) {
    AppLogger.e('Error capturado', error);

    // Si ya es un AppError, retornarlo
    if (error is AppError) {
      return error;
    }

    // Si es String, crear AppError genérico
    if (error is String) {
      return AppError(message: error);
    }

    // Mensajes amigables para errores comunes
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return AppError.network('Error de conexión. Verifica tu internet e intenta nuevamente', error);
    }

    if (errorString.contains('timeout')) {
      return AppError.network('La operación tardó demasiado. Intenta nuevamente', error);
    }

    if (errorString.contains('permission') || errorString.contains('denied')) {
      return AppError.permission('Permiso denegado. Verifica los permisos de la app');
    }

    if (errorString.contains('not found')) {
      return AppError.recoverable('No se encontró el recurso solicitado');
    }

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return AppError.authentication('Sesión expirada. Por favor inicia sesión nuevamente');
    }

    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return AppError.permission('No tienes permisos para realizar esta acción');
    }

    if (errorString.contains('database') || errorString.contains('sqlite')) {
      return AppError.database('Error en la base de datos. Intenta nuevamente', error);
    }

    // Error genérico
    return AppError(message: 'Ocurrió un error inesperado. Por favor intenta nuevamente', originalError: error);
  }

  /// Obtiene mensaje amigable del error
  static String getErrorMessage(dynamic error) {
    final appError = handle(error);
    return appError.message;
  }

  /// Muestra un SnackBar con el error
  static void showError(BuildContext context, dynamic error) {
    final appError = handle(error);
    final backgroundColor = _getErrorColor(appError.type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appError.message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: appError.type == ErrorType.critical 
            ? const Duration(seconds: 5) 
            : const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Muestra un diálogo de error
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    dynamic error,
  ) async {
    final appError = handle(error);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(appError.message),
        actions: [
          if (appError.type == ErrorType.recoverable)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de error crítico con opción de acción
  static Future<bool?> showCriticalErrorDialog(
    BuildContext context,
    String title,
    dynamic error, {
    String? actionLabel,
  }) async {
    final appError = handle(error);
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(appError.message),
        actions: [
          if (actionLabel != null)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(actionLabel),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Obtiene el color según el tipo de error
  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.critical:
        return Colors.red.shade900;
      case ErrorType.authentication:
        return Colors.orange.shade700;
      case ErrorType.permission:
        return Colors.amber.shade700;
      case ErrorType.network:
        return AppColors.brandOrange;
      case ErrorType.validation:
        return Colors.orange.shade600;
      case ErrorType.database:
        return Colors.red.shade700;
      case ErrorType.recoverable:
        return AppColors.brandOrangeDark;
      default:
        return Colors.red;
    }
  }
}


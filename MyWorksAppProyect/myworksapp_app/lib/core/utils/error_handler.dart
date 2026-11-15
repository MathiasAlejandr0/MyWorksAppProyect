import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;
import 'package:myworksapp/utils/content_filter.dart';

import '../theme/app_colors.dart';
import '../exceptions/auth_exceptions.dart';
import '../services/crash_reporting_service.dart';
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

    if (errorString.contains('mensaje bloqueado') ||
        errorString.contains('no se permite compartir') ||
        errorString.contains('este tipo de mensaje no está permitido') ||
        errorString.contains('este tipo de contenido no esta permitido')) {
      return AppError.validation(ContentFilter.blockedMessage);
    }
    if (errorString.contains('ya esta reservado') ||
        errorString.contains('ya está reservado') ||
        errorString.contains('duplicate key')) {
      return AppError.validation(
        'Ese horario ya está reservado con este profesional. Elige otra hora.',
      );
    }
    if (errorString.contains('no esta publicada') ||
        errorString.contains('no está publicada') ||
        errorString.contains('ya no esta disponible') ||
        errorString.contains('elige un horario publicado')) {
      return AppError.validation(
        'Esa hora no está publicada por el profesional. Elige un horario de su agenda.',
      );
    }
    if (errorString.contains('demasiados pedidos esperando pago')) {
      return AppError.validation(
        'Tienes pedidos sin pagar en curso. Completa o espera a que venza uno para reservar otra hora.',
      );
    }

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

    if (errorString.contains('database') ||
        errorString.contains('postgres') ||
        errorString.contains('supabase')) {
      return AppError.database('Error al guardar datos. Intenta nuevamente', error);
    }

    // Error genérico
    return AppError(message: 'Ocurrió un error inesperado. Por favor intenta nuevamente', originalError: error);
  }

  /// Texto para mostrar al usuario. Nunca devuelve el detalle técnico
  /// (nombres de funciones, códigos PGRST, SQL): eso va al log y a Sentry.
  ///
  /// Sí muestra los mensajes de negocio que escribimos en Postgres con
  /// `RAISE EXCEPTION` (SQLSTATE P0001), por ejemplo «El trabajo queda a
  /// más de 30 km del profesional».
  static String userMessage(
    Object error, {
    String fallback = 'Algo salió mal. Intenta de nuevo en un momento.',
    StackTrace? stackTrace,
  }) {
    final text = userMessageFor(error, fallback: fallback);
    if (error is! AppError && error is! AppAuthException) {
      AppLogger.e('Error mostrado como mensaje amigable', error, stackTrace);
      CrashReportingService.instance.recordError(error, stackTrace);
    }
    return text;
  }

  /// Versión pura de [userMessage] (sin log), para tests.
  static String userMessageFor(
    Object error, {
    String fallback = 'Algo salió mal. Intenta de nuevo en un momento.',
  }) {
    if (error is AppError) return error.message;
    if (error is AppAuthException) return error.userMessage;
    if (error is PostgrestException) {
      final message = error.message.trim();
      if (error.code == 'P0001' && _looksLikeUserText(message)) return message;
      final mapped = handle(error);
      if (mapped.type == ErrorType.validation ||
          mapped.type == ErrorType.network ||
          mapped.type == ErrorType.authentication) {
        return mapped.message;
      }
      return fallback;
    }
    if (error is AuthException) {
      return 'No pudimos validar tu sesión. Vuelve a iniciar sesión.';
    }
    final mapped = handle(error);
    if (mapped.type == ErrorType.unknown || mapped.type == ErrorType.database) {
      return fallback;
    }
    return mapped.message;
  }

  /// Un mensaje de RAISE EXCEPTION escrito para personas: corto y sin
  /// pistas de SQL o de PostgREST.
  static bool _looksLikeUserText(String message) {
    if (message.isEmpty || message.length > 200) return false;
    final lower = message.toLowerCase();
    const technical = [
      'pgrst',
      'sqlstate',
      'violates',
      'relation ',
      'column ',
      'function ',
      'syntax',
      'null value',
      'permission denied',
      'jwt',
      'operator does not',
      'public.',
      '()',
    ];
    return !technical.any(lower.contains);
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


/// Clase para errores de la aplicación
class AppError implements Exception {
  final String message;
  final String? code;
  final ErrorType type;
  final dynamic originalError;

  AppError({
    required this.message,
    this.code,
    this.type = ErrorType.unknown,
    this.originalError,
  });

  @override
  String toString() => message;

  /// Crea un error de red
  factory AppError.network(String message, [dynamic originalError]) {
    return AppError(
      message: message,
      code: 'NETWORK_ERROR',
      type: ErrorType.network,
      originalError: originalError,
    );
  }

  /// Crea un error de validación
  factory AppError.validation(String message) {
    return AppError(
      message: message,
      code: 'VALIDATION_ERROR',
      type: ErrorType.validation,
    );
  }

  /// Crea un error de autenticación
  factory AppError.authentication(String message) {
    return AppError(
      message: message,
      code: 'AUTH_ERROR',
      type: ErrorType.authentication,
    );
  }

  /// Crea un error de permisos
  factory AppError.permission(String message) {
    return AppError(
      message: message,
      code: 'PERMISSION_ERROR',
      type: ErrorType.permission,
    );
  }

  /// Crea un error de base de datos
  factory AppError.database(String message, [dynamic originalError]) {
    return AppError(
      message: message,
      code: 'DATABASE_ERROR',
      type: ErrorType.database,
      originalError: originalError,
    );
  }

  /// Crea un error crítico
  factory AppError.critical(String message, [dynamic originalError]) {
    return AppError(
      message: message,
      code: 'CRITICAL_ERROR',
      type: ErrorType.critical,
      originalError: originalError,
    );
  }

  /// Crea un error recuperable
  factory AppError.recoverable(String message) {
    return AppError(
      message: message,
      code: 'RECOVERABLE_ERROR',
      type: ErrorType.recoverable,
    );
  }

  /// Crea un error de recurso no encontrado
  factory AppError.notFound(String message) {
    return AppError(
      message: message,
      code: 'NOT_FOUND',
      type: ErrorType.unknown,
    );
  }
}

/// Tipos de errores
enum ErrorType {
  unknown,
  network,
  validation,
  authentication,
  permission,
  database,
  critical,
  recoverable,
}


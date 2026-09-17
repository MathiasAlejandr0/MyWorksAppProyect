/// Excepciones de autenticación con mensajes listos para mostrar al usuario.
sealed class AppAuthException implements Exception {
  const AppAuthException(this.userMessage, {this.cause});

  /// Mensaje claro, en español, para SnackBars / diálogos.
  final String userMessage;

  /// Error original (Supabase, red, etc.) para logs.
  final Object? cause;

  @override
  String toString() => userMessage;
}

final class InvalidCredentialsException extends AppAuthException {
  const InvalidCredentialsException([Object? cause])
      : super(
          'Correo o contraseña incorrectos. Verifica tus datos e intenta de nuevo.',
          cause: cause,
        );
}

final class AuthNetworkException extends AppAuthException {
  const AuthNetworkException([Object? cause])
      : super(
          'No pudimos conectar con el servidor. Revisa tu conexión a internet e intenta nuevamente.',
          cause: cause,
        );
}

final class EmailAlreadyRegisteredException extends AppAuthException {
  const EmailAlreadyRegisteredException([Object? cause])
      : super(
          'Este correo ya tiene una cuenta. Inicia sesión o recupera tu contraseña.',
          cause: cause,
        );
}

final class EmailConfirmationRequiredException extends AppAuthException {
  const EmailConfirmationRequiredException([Object? cause])
      : super(
          'Cuenta creada. Revisa tu correo para confirmarla antes de iniciar sesión.',
          cause: cause,
        );
}

final class AccountInactiveException extends AppAuthException {
  const AccountInactiveException._(super.userMessage, {super.cause});

  factory AccountInactiveException.blocked([Object? cause]) =>
      AccountInactiveException._(
        'Tu cuenta está bloqueada. Contacta con soporte.',
        cause: cause,
      );

  factory AccountInactiveException.suspended([Object? cause]) =>
      AccountInactiveException._(
        'Tu cuenta está suspendida. Contacta con soporte.',
        cause: cause,
      );
}

final class RegistrationFailedException extends AppAuthException {
  const RegistrationFailedException([Object? cause])
      : super(
          'No se pudo crear la cuenta. Intenta de nuevo en unos minutos.',
          cause: cause,
        );
}

final class SessionExpiredException extends AppAuthException {
  const SessionExpiredException([Object? cause])
      : super(
          'Tu sesión expiró. Inicia sesión nuevamente.',
          cause: cause,
        );
}

final class AuthUnexpectedException extends AppAuthException {
  const AuthUnexpectedException([
    super.userMessage =
        'Ocurrió un error inesperado al autenticarte. Intenta nuevamente.',
    Object? cause,
  ]) : super(cause: cause);
}

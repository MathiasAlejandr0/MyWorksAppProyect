import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../utils/app_error.dart';

/// Decide si un error es algo que el usuario ya ve explicado en pantalla
/// (regla de negocio, sin conexión, sesión) y por tanto no es un fallo de
/// código que deba llenar `registros_error_app` ni Sentry.
///
/// Lo que sí se sigue reportando: funciones que no existen (42883, PGRST202),
/// montos que no coinciden entre app y servidor, nulos, excepciones de
/// plataforma y cualquier otro error inesperado.
bool isExpectedUserError(Object? error) {
  if (error == null) return false;

  if (error is AppError) {
    return error.type == ErrorType.validation ||
        error.type == ErrorType.network ||
        error.type == ErrorType.authentication ||
        error.type == ErrorType.permission;
  }

  // RAISE EXCEPTION escrito a propósito en Postgres: «ya hay un acuerdo
  // pendiente», «esa hora ya no esta disponible», «el trabajo ya esta cerrado».
  if (error is PostgrestException && error.code == 'P0001') return true;

  final text = error.toString().toLowerCase();
  const network = [
    'socketexception',
    'clientexception',
    'failed host lookup',
    'failed to fetch',
    'connection closed',
    'connection reset',
    'connection refused',
    'connection abort',
    'connection timed out',
    'network is unreachable',
    'timeoutexception',
  ];
  return network.any(text.contains);
}

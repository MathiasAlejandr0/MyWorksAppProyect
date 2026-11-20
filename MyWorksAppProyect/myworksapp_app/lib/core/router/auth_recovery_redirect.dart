import '../utils/constants.dart';

/// Mientras la sesión viene del enlace de recuperación, la app pide la clave nueva.
/// Devuelve null si ya estamos en esa pantalla o no hay recuperación.
String? authRecoveryRedirect({
  required bool recovering,
  required String location,
}) {
  if (!recovering) return null;
  if (location == AppConstants.routeResetPassword) return null;
  return AppConstants.routeResetPassword;
}

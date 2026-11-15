import '../domain/user_role.dart';
import 'constants.dart';

/// Roles permitidos en registro público (nunca admin).
///
/// Conserva el contrato de string (códigos BD) para no romper llamadas
/// existentes; internamente delega en [UserRole].
String sanitizeRegistrationRole(String? role) {
  return UserRole.sanitizeForRegistration(UserRole.fromDb(role)).dbValue;
}

UserRole sanitizeRegistrationUserRole(UserRole? role) {
  return UserRole.sanitizeForRegistration(role);
}

/// Ruta de inicio según el rol autenticado.
String homeRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.administrador:
      return AppConstants.routeAdminDashboard;
    case UserRole.especialista:
      return AppConstants.routeWorkerHome;
    case UserRole.cliente:
      return AppConstants.routeUserHome;
  }
}

/// Ruta de perfil según el rol autenticado.
String profileRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.especialista:
      return AppConstants.routeWorkerProfile;
    case UserRole.administrador:
    case UserRole.cliente:
      return AppConstants.routeUserProfile;
  }
}

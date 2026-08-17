import 'constants.dart';

/// Roles permitidos en registro público (nunca admin).
String sanitizeRegistrationRole(String? role) {
  if (role == AppConstants.roleWorker) {
    return AppConstants.roleWorker;
  }
  return AppConstants.roleUser;
}

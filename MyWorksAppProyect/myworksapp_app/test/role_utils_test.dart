import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/user_role.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/core/utils/role_utils.dart';

void main() {
  group('UserRole', () {
    test('dbValue coincide con los códigos de BD', () {
      expect(UserRole.cliente.dbValue, AppConstants.roleUser);
      expect(UserRole.especialista.dbValue, AppConstants.roleWorker);
      expect(UserRole.administrador.dbValue, AppConstants.roleAdmin);
    });

    test('fromDb acepta códigos BD, inglés y alias de negocio', () {
      expect(UserRole.fromDb('usuario'), UserRole.cliente);
      expect(UserRole.fromDb('cliente'), UserRole.cliente);
      expect(UserRole.fromDb('client'), UserRole.cliente);
      expect(UserRole.fromDb('trabajador'), UserRole.especialista);
      expect(UserRole.fromDb('especialista'), UserRole.especialista);
      expect(UserRole.fromDb('worker'), UserRole.especialista);
      expect(UserRole.fromDb('administrador'), UserRole.administrador);
      expect(UserRole.fromDb('admin'), UserRole.administrador);
    });

    test('fromDb desconoce → cliente', () {
      expect(UserRole.fromDb(null), UserRole.cliente);
      expect(UserRole.fromDb('superuser'), UserRole.cliente);
    });

    test('sanitizeForRegistration nunca permite administrador', () {
      expect(
        UserRole.sanitizeForRegistration(UserRole.administrador),
        UserRole.cliente,
      );
      expect(
        UserRole.sanitizeForRegistration(UserRole.especialista),
        UserRole.especialista,
      );
    });

    test('etiquetas de UI', () {
      expect(UserRole.cliente.label, 'Cliente');
      expect(UserRole.especialista.label, 'Especialista');
    });
  });

  group('sanitizeRegistrationRole', () {
    test('permite user y worker', () {
      expect(sanitizeRegistrationRole(AppConstants.roleUser), AppConstants.roleUser);
      expect(sanitizeRegistrationRole(AppConstants.roleWorker), AppConstants.roleWorker);
    });

    test('acepta alias cliente/especialista', () {
      expect(sanitizeRegistrationRole('cliente'), AppConstants.roleUser);
      expect(sanitizeRegistrationRole('especialista'), AppConstants.roleWorker);
    });

    test('nunca devuelve admin', () {
      expect(sanitizeRegistrationRole(AppConstants.roleAdmin), AppConstants.roleUser);
      expect(sanitizeRegistrationRole('admin'), AppConstants.roleUser);
    });

    test('null o desconocido → user', () {
      expect(sanitizeRegistrationRole(null), AppConstants.roleUser);
      expect(sanitizeRegistrationRole('superuser'), AppConstants.roleUser);
    });
  });

  group('homeRouteForRole', () {
    test('redirige al dashboard del rol', () {
      expect(homeRouteForRole(UserRole.cliente), AppConstants.routeUserHome);
      expect(homeRouteForRole(UserRole.especialista), AppConstants.routeWorkerHome);
      expect(homeRouteForRole(UserRole.administrador), AppConstants.routeAdminDashboard);
    });
  });
}

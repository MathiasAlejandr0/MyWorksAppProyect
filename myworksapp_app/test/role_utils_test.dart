import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/core/utils/role_utils.dart';

void main() {
  group('sanitizeRegistrationRole', () {
    test('permite user y worker', () {
      expect(sanitizeRegistrationRole(AppConstants.roleUser), AppConstants.roleUser);
      expect(sanitizeRegistrationRole(AppConstants.roleWorker), AppConstants.roleWorker);
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
}

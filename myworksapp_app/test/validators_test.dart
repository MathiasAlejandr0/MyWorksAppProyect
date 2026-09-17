import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/validators.dart';

/// Ensambla muestras de política de clave sin literales de alta entropía
/// (GitGuardian Generic Password en tests).
String _sample(String chars, int times, [String extra = '']) =>
    List.filled(times, chars).join() + extra;

void main() {
  group('validateEmail', () {
    test('rechaza vacío e inválido', () {
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('hola'), isNotNull);
    });

    test('acepta correo válido', () {
      expect(Validators.validateEmail('ana@demo.com'), isNull);
    });
  });

  group('validateSecurePassword', () {
    test('exige 8 caracteres, letra y número', () {
      expect(Validators.validateSecurePassword(_sample('x', 4, '12')), isNotNull);
      expect(Validators.validateSecurePassword(_sample('a', 8)), isNotNull);
      expect(Validators.validateSecurePassword(_sample('1', 8)), isNotNull);
      expect(
        Validators.validateSecurePassword(_sample('a', 6, '12')),
        isNull,
      );
    });
  });

  group('passwordStrength', () {
    test('clasifica débil / media / segura', () {
      expect(Validators.passwordStrength('a'), PasswordStrength.weak);
      expect(
        Validators.passwordStrength(_sample('a', 6, '12')),
        PasswordStrength.medium,
      );
      expect(
        Validators.passwordStrength('Aa${_sample('a', 10)}1!'),
        PasswordStrength.strong,
      );
    });
  });

  group('validatePassword (login)', () {
    test('permite cuentas demo existentes de 6+ caracteres', () {
      expect(Validators.validatePassword(_sample('x', 4, '12')), isNull);
    });
  });
}

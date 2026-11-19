import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/user_model.dart';

void main() {
  test('un perfil con correo nulo y fecha rara igual se puede abrir', () {
    final user = UserModel.fromMap({
      'id': '11111111-1111-4111-8111-000000000001',
      'nombre': 'Ana',
      'correo': null,
      'rol': 'usuario',
      'estado_cuenta': 'activo',
      'creado_en': '2026-11-19 16:40:12',
    });

    expect(user.email, isEmpty);
    expect(user.name, 'Ana');
    expect(user.role, 'usuario');
    expect(user.isActive, isTrue);
    expect(user.createdAt.year, 2026);
  });

  test('nombre o rol que no son texto usan un valor seguro', () {
    final user = UserModel.fromMap({
      'id': '11111111-1111-4111-8111-000000000002',
      'nombre': 12,
      'rol': null,
      'creado_en': null,
    });

    expect(user.name, 'Usuario');
    expect(user.userRole.isCliente, isTrue);
    expect(user.accountStatus, 'activo');
  });
}

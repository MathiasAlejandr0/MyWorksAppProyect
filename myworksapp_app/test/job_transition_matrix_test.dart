import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/job_transition_matrix.dart';

void main() {
  group('targetsFromRpc', () {
    test('lee el array que devuelve Postgres', () {
      expect(
        targetsFromRpc(['aceptado', 'cancelado']),
        ['aceptado', 'cancelado'],
      );
    });

    test('una respuesta vacía no inventa destinos', () {
      expect(targetsFromRpc(null), isEmpty);
      expect(targetsFromRpc('aceptado'), isEmpty);
    });
  });
}

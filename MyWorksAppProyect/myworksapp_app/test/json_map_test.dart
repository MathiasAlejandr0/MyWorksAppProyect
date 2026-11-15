import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/utils/json_map.dart';

void main() {
  group('decodeJsonMap', () {
    test('lee un Map directo', () {
      expect(decodeJsonMap({'a': 1}), {'a': 1});
    });

    test('lee un JSON en texto', () {
      expect(decodeJsonMap('{"a": 1}'), {'a': 1});
    });

    test('vacío o inválido queda null', () {
      expect(decodeJsonMap(null), isNull);
      expect(decodeJsonMap(''), isNull);
      expect(decodeJsonMap('no-json'), isNull);
    });
  });

  test('JobModel.fromMap lee metadatos como objeto o como texto', () {
    final now = DateTime.utc(2026, 1, 1).toIso8601String();
    final asMap = JobModel.fromMap({
      'id': 'j1',
      'id_usuario': 'u1',
      'id_servicio': 's1',
      'estado': 'esperando_pago',
      'direccion': 'Calle 1',
      'metadatos_servicio': {'quoted_total_clp': 12000},
      'creado_en': now,
      'actualizado_en': now,
    });
    expect(asMap.serviceMetadata?['quoted_total_clp'], 12000);

    final asText = JobModel.fromMap({
      'id': 'j2',
      'id_usuario': 'u1',
      'id_servicio': 's1',
      'estado': 'esperando_pago',
      'direccion': 'Calle 1',
      'metadatos_servicio': '{"quoted_total_clp":15000}',
      'creado_en': now,
      'actualizado_en': now,
    });
    expect(asText.serviceMetadata?['quoted_total_clp'], 15000);
  });
}

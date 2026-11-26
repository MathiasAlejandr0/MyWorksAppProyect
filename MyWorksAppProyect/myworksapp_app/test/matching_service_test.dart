// MatchingService con un catálogo de profesionales sembrado: matching
// automático y manual con filtros de nota, distancia y disponibilidad.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/matching_service.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';

const _job = '00000000-0000-4000-8000-0000000000aa';

Map<String, dynamic> _pro(int i, {double nota = 4.5, bool disponible = true}) =>
    {
      ...sampleWorkerModel,
      'id': '00000000-0000-4000-8000-00000000d00$i',
      'id_usuario': '00000000-0000-4000-8000-00000000e00$i',
      'profesion': 'Plomero',
      'calificacion': nota,
      'disponible': disponible ? 1 : 0,
      'latitud_base': -41.4693 + i * 0.01,
      'longitud_base': -72.9424,
      'ultima_actividad': DateTime.now().toUtc().toIso8601String(),
    };

Future<void> _b({bool sinPros = false, bool falla = false}) async {
  final b = await setUpFakeSupabase(signedIn: true);
  b.defaultRows = [universalRow];
  b.tableDefaults = tableRows;
  b.rowOverrides = {'estado': 'pendiente'};
  final pros = sinPros
      ? <Map<String, dynamic>>[]
      : [_pro(1), _pro(2, nota: 3.0, disponible: false), _pro(3, nota: 5.0)];
  b.defaultRpc = (_) => pros;
  b.seed('trabajadores', pros);
  b.rpc('perfiles_publicos_por_ids', [
    for (final p in pros)
      {
        ...sampleUserModel,
        'id': p['id_usuario'],
        'ultimo_acceso': DateTime.now().toUtc().toIso8601String(),
      },
  ]);
  b.rpc('stats_profesionales', <Object>[]);
  if (falla) b.failAll = true;
}

final _m = MatchingService.instance;

void main() {
  test('matching automático', () async {
    for (final caso in ['ok', 'sin', 'falla']) {
      await _b(sinPros: caso == 'sin', falla: caso == 'falla');
      for (final servicio in ['plumber', 'cleaner', 'Plomero']) {
        final r = await _m.automaticMatching(
          jobId: _job,
          serviceId: servicio,
          userLatitude: -41.4693,
          userLongitude: -72.9424,
          maxResults: 2,
        );
        expect(r.length, lessThanOrEqualTo(2));
      }
    }
  });

  test('matching manual con filtros', () async {
    for (final caso in ['ok', 'sin', 'falla']) {
      await _b(sinPros: caso == 'sin', falla: caso == 'falla');
      for (final soloDisp in [true, false, null]) {
        await _m.manualMatching(
          jobId: _job,
          serviceId: 'plumber',
          userLatitude: -41.4693,
          userLongitude: -72.9424,
          minRating: soloDisp == null ? null : 4.0,
          maxDistanceKm: soloDisp == true ? 1.5 : null,
          onlyAvailable: soloDisp,
        );
      }
    }
  });
}

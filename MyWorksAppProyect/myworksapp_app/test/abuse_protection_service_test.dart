// AbuseProtectionService con trabajos sembrados: límite diario de trabajos,
// rechazos consecutivos y cancelaciones del día, más el caso de error.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/abuse_protection_service.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';

const _u = '00000000-0000-4000-8000-0000000000b1';

Future<FakeBackend> _trabajos(int n, {String estado = 'cancelado'}) async {
  final b = await setUpFakeSupabase(signedIn: true);
  final hoy = DateTime.now().toUtc().toIso8601String();
  b.seed('trabajos', [
    for (var i = 0; i < n; i++)
      {
        ...sampleJobModel,
        'id':
            '00000000-0000-4000-8000-00000000c${i.toString().padLeft(3, '0')}',
        'id_usuario': _u,
        'id_trabajador': _u,
        'estado': estado,
        'creado_en': hoy,
      },
  ]);
  return b;
}

final _s = AbuseProtectionService.instance;

void main() {
  test('crear trabajos: permitido, sobre el límite y con error', () async {
    await _trabajos(0);
    expect((await _s.canCreateJob(_u)).allowed, isTrue);
    await _trabajos(AbuseProtectionService.maxJobsPerDay + 1);
    expect((await _s.canCreateJob(_u)).allowed, isFalse);
    // Segunda vez: el evento quedó en la caché del servicio.
    await _trabajos(0);
    await _s.canCreateJob(_u);
    final b = await _trabajos(0);
    b.failing.add('trabajos');
    expect((await _s.canCreateJob(_u)).allowed, isTrue);
  });

  test('rechazos consecutivos y cancelaciones del día', () async {
    await _trabajos(AbuseProtectionService.maxConsecutiveRejections + 1);
    expect((await _s.canRejectJob(_u)).allowed, isFalse);
    expect((await _s.canCancelJob(_u)).allowed, isFalse);
    await _trabajos(2, estado: 'completado');
    expect((await _s.canRejectJob(_u)).allowed, isTrue);
    expect((await _s.canCancelJob(_u)).allowed, isTrue);
    final b = await _trabajos(0);
    b.failAll = true;
    expect((await _s.canRejectJob(_u)).allowed, isTrue);
    expect((await _s.canCancelJob(_u)).allowed, isTrue);
  });
}

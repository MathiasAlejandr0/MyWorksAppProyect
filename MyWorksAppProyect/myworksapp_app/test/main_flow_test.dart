// Flujo principal contra el backend falso (sin producción ni pasarelas reales):
// crear trabajo -> aceptar -> iniciar con PIN -> completar -> pago en garantía
// (autorizar, retener y liberar con Edge Functions simuladas) -> calificación.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/rating_model.dart';
import 'package:myworksapp/core/database/repositories/rating_repository.dart';
import 'package:myworksapp/core/database/repositories/service_repository.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/services/job_service.dart';
import 'package:myworksapp/core/services/payment_service.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';

const _servicio = '00000000-0000-4000-8000-0000000000aa';
const _profesional = '00000000-0000-4000-8000-0000000000b1';

void main() {
  test('crear, aceptar, completar, pagar y calificar', () async {
    ServiceRepository.clearCache();
    final b = await setUpFakeSupabase(signedIn: true);
    b.seed('perfiles', [
      {
        ...universalRow,
        ...sampleUserModel,
        'id': fakeUserId,
        'rol': 'usuario',
        'estado_cuenta': 'activo',
      },
    ]);
    b.seed('servicios', [
      {
        ...universalRow,
        ...sampleServiceModel,
        'id': _servicio,
        'categoria': 'limpieza',
        'activo': 1,
        'requiere_certificacion': 0,
      },
    ]);
    b.seed('trabajadores', [
      {
        ...universalRow,
        ...sampleWorkerModel,
        'id_usuario': _profesional,
        'id': _profesional,
      },
    ]);
    b.seed('trabajos', []);
    b.seed('pagos', []);
    b.seed('calificaciones', []);
    b.rpc('transiciones_trabajo_posibles',
        ['aceptado', 'en_curso', 'completado', 'cancelado']);
    b.defaultRpc = (_) => null;
    // El RPC real asigna al profesional y deja el trabajo aceptado.
    b.rpcs['asignar_trabajador_trabajo'] = (req) {
      final p = req.json as Map;
      for (final t in b.tables['trabajos']!) {
        if (t['id'] == p['p_trabajo_id']) {
          t['id_trabajador'] = p['p_trabajador_id'];
          t['estado'] = 'aceptado';
        }
      }
      return null;
    };
    b.rpc('intentar_pin_inicio', {'ok': true});
    b.rpcs['transicionar_trabajo'] = (req) {
      final p = req.json as Map;
      for (final t in b.tables['trabajos']!) {
        if (t['id'] == p['p_trabajo_id']) t['estado'] = p['p_nuevo_estado'];
      }
      return null;
    };

    // 1. El cliente crea el trabajo.
    final job = await JobService.instance.createJob(
      userId: fakeUserId,
      serviceId: _servicio,
      description: 'Limpieza profunda del living',
      address: 'Calle 1, Puerto Montt',
      latitude: -41.47,
      longitude: -72.94,
      scheduledDate: DateTime.utc(2026, 12, 1, 15),
      serviceMetadata: {'variant': 'basica'},
    );
    expect(job, isNotNull);
    expect(b.tables['trabajos']!.length, 1);
    final id = b.tables['trabajos']!.first['id'] as String;
    expect(b.tables['trabajos']!.first['estado'], 'pendiente');

    // 2. El profesional acepta.
    expect(
        await JobService.instance.acceptJob(jobId: id, workerId: _profesional),
        isTrue);
    expect(b.tables['trabajos']!.first['estado'], 'aceptado');
    expect(b.tables['trabajos']!.first['id_trabajador'], _profesional);

    // 3. Inicia con PIN y completa.
    await JobService.instance.updateJobStatus(
        jobId: id, newStatus: 'en_curso', userId: _profesional, pin: '1234');
    expect(b.tables['trabajos']!.first['estado'], 'en_curso');
    await JobService.instance
        .updateJobStatus(jobId: id, newStatus: 'completado', userId: _profesional);
    expect(b.tables['trabajos']!.first['estado'], 'completado');

    // 4. Pago en garantía simulado: el pago ya está autorizado (lo deja así la
    // Edge Function de Webpay, no el cliente) y se libera al completar.
    b.seed('pagos', [
      {
        ...samplePaymentModel,
        'id': 'pago-1',
        'id_trabajo': id,
        'tipo_pago': PricingConstants.paymentTypePrimary,
        'estado': PricingConstants.paymentAuthorized,
      },
    ]);
    final pagos = PaymentService.instance;
    expect((await pagos.getPrimaryPayment(id))?.status,
        PricingConstants.paymentAuthorized);
    b.functions['webpay-release'] = (_) => {
          'payment': {
            ...samplePaymentModel,
            'id': 'pago-1',
            'id_trabajo': id,
            'estado': PricingConstants.paymentReleased,
          },
        };
    final liberado = await pagos.releasePayment('pago-1', transferRef: 'TRF-1');
    expect(liberado.status, PricingConstants.paymentReleased);

    // 5. El cliente califica.
    final repo = RatingRepository();
    await repo.createRating(RatingModel.fromMap({
      ...sampleRatingModel,
      'id': 'cal-1',
      'id_trabajo': id,
      'direccion': 'cliente_a_trabajador',
      'puntaje': 5,
    }));
    final cal = await repo.getRatingByJobId(id);
    expect(cal, isNotNull);
    expect(cal!.score, 5);
  });
}

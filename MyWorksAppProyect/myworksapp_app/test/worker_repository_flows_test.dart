// WorkerRepository contra el backend falso: alta con precios, servicios propios
// y categoría; ficha con datos inesperados; nota y trabajos sin la RPC;
// nota de verificación propia; disponibilidad de cuentas demo.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/worker_model.dart';
import 'package:myworksapp/core/database/repositories/worker_repository.dart';
import 'package:myworksapp/core/domain/worker_custom_service.dart';
import 'package:myworksapp/core/domain/worker_service_options_catalog.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';

void main() {
  late FakeBackend b;
  final repo = WorkerRepository();

  setUp(() async {
    b = await setUpFakeSupabase(signedIn: true);
  });

  test('alta con precios, servicios propios y categoría', () async {
    final worker = WorkerModel.fromMap({
      ...sampleWorkerModel,
      'id_usuario': fakeUserId,
      'categoria_servicio': 'plomeria',
    }).copyWith(
      pricingTiers: {'visita': 15000, 'hora': 20000},
      customServices: [
        const WorkerCustomService(
            id: 's1',
            title: 'Pintura',
            subtitle: 'Muros',
            priceClp: 5000,
            unit: WorkerPriceUnit.perSqm),
        const WorkerCustomService(
            id: 's2', title: 'Armado', subtitle: 'Muebles', priceClp: 12000),
      ],
    );
    await repo.createWorker(worker);
    final paths = b.requests.map((r) => '${r.method} ${r.url.path}').toList();
    expect(paths, contains('POST /rest/v1/trabajador_precios'));
    expect(paths, contains('POST /rest/v1/trabajador_servicios_extra'));
    expect(paths, contains('POST /rest/v1/trabajador_servicios'));
  });

  test('ficha con un dato inesperado', () async {
    b.seed('trabajadores', [
      {...sampleWorkerModel, 'id_usuario': 'w-raro', 'calificacion': 'mucho'},
    ]);
    final w = await repo.getWorkerByUserId('w-raro');
    expect(w?.profession, 'Profesional');

    b.seed('trabajadores', [
      {...sampleWorkerModel, 'calificacion': 'mucho'}..remove('id_usuario'),
    ]);
    expect(() => repo.getWorkerByUserId('w-sin-id'), throwsA(anything));
  });

  test('nota y trabajos calculados en el cliente', () async {
    b.rpcErrors['stats_profesional'] = 'no existe';
    b.seed('trabajos', [
      for (var i = 0; i < 3; i++)
        {'id': 'j$i', 'id_trabajador': 'w-1', 'estado': 'completado'},
    ]);
    b.seed('calificaciones', [
      for (var i = 0; i < 3; i++)
        {
          'id': 'c$i',
          'id_trabajo': 'j$i',
          'id_usuario': 'u$i',
          'id_calificado': 'w-1',
          'direccion': 'cliente_a_trabajador',
          'puntaje': 3 + i,
          'comentario': null,
          'creado_en': '2026-05-0${i + 1}T10:00:00Z',
        },
    ]);
    final stats = await repo.getPublicStats('w-1');
    expect(stats.averageRating, isNotNull);
  });

  test('nota de verificación propia sin el documento', () async {
    b.seed('trabajadores', [
      {
        ...sampleWorkerModel,
        'id_usuario': fakeUserId,
        'estado_verificacion': 'rechazado',
      },
    ]);
    b.rpc('mi_ficha_propia', [
      {'nota_verificacion': 'Foto borrosa\nDocumento: carnet.pdf'},
    ]);
    final v = await repo.fetchVerification(fakeUserId);
    expect(v?.note, 'Foto borrosa');
  });

  test('cuenta demo sin trabajos vuelve a estar disponible', () async {
    b.seed('trabajos', []);
    b.seed('trabajadores', [
      {...sampleWorkerModel, 'id_usuario': 'w-demo', 'disponible': false},
    ]);
    await repo.syncAvailabilityWithJobs('w-demo',
        email: 'pro@demo.myworksapp.cl');
    await repo.syncAvailabilityWithJobs('w-demo', email: 'otro@gmail.com');
  });
}

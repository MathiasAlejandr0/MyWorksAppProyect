// PricingGuardService: rango desde trabajos completados (≥5), rango por nombre
// o categoría del servicio y alertas de precio muy bajo, muy alto, alto y bajo.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/pricing_guard_service.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';

void main() {
  late FakeBackend b;
  final svc = PricingGuardService.instance;

  setUp(() async {
    b = await setUpFakeSupabase(signedIn: true);
    b.seed('servicios', [
      {
        ...sampleServiceModel,
        'id': 'svc-limp',
        'nombre': 'Limpieza hogar',
        'categoria': 'limpieza'
      },
      {
        ...sampleServiceModel,
        'id': 'svc-raro',
        'nombre': 'Otra cosa',
        'categoria': 'otra'
      },
    ]);
    b.seed('trabajos', [
      for (var i = 0; i < 6; i++)
        {
          ...sampleJobModel,
          'id': 'hist-$i',
          'id_servicio': 'svc-hist',
          'estado': 'completado',
          'instantanea_precio': {'total_clp': 40000 + i * 2000},
          'metadatos_servicio': <String, dynamic>{},
        },
    ]);
  });

  test('rango histórico y alertas', () async {
    expect(await svc.checkPrice(serviceId: 'svc-hist', price: 45000), isNull);
    expect((await svc.checkPrice(serviceId: 'svc-hist', price: 5000))?.type,
        PricingAlertType.tooLow);
    expect((await svc.checkPrice(serviceId: 'svc-hist', price: 200000))?.type,
        PricingAlertType.tooHigh);
  });

  test('rango por nombre: alto y bajo', () async {
    expect((await svc.checkPrice(serviceId: 'svc-limp', price: 45000))?.type,
        PricingAlertType.high);
    expect((await svc.checkPrice(serviceId: 'svc-limp', price: 9000))?.type,
        PricingAlertType.low);
  });

  test('servicio sin rango conocido y error de lectura', () async {
    await svc.checkPrice(serviceId: 'svc-raro', price: 50000);
    b.failing.add('trabajos');
    await svc.checkPrice(serviceId: 'svc-raro', price: 50000);
  });
}

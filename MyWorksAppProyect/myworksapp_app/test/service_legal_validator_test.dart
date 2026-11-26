// ServiceLegalValidator con servicios sembrados en el backend falso: cada
// categoría, servicio inactivo o con certificación, y restricciones por tipo.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/service_model.dart';
import 'package:myworksapp/core/services/service_legal_validator.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';

const _id = '00000000-0000-4000-8000-0000000000s1';
final _v = ServiceLegalValidator.instance;

Future<void> _servicio({
  String? categoria,
  int activo = 1,
  int cert = 0,
  String? aviso,
  bool falla = false,
}) async {
  final b = await setUpFakeSupabase(signedIn: true);
  if (falla) b.failing.add('servicios');
  b.seed('servicios', [
    if (categoria != null)
      {
        ...sampleServiceModel,
        'id': _id,
        'categoria': categoria,
        'activo': activo,
        'requiere_certificacion': cert,
        'aviso_legal': aviso,
      },
  ]);
}

const _categorias = [
  ServiceCategories.cleaning,
  ServiceCategories.assembly,
  ServiceCategories.techSupport,
  ServiceCategories.gardening,
  ServiceCategories.moving,
  ServiceCategories.construction,
  ServiceCategories.plumbing,
  ServiceCategories.electrical,
  'otra',
];

void main() {
  test('validateService por categoría y estado', () async {
    await _servicio();
    expect((await _v.validateService(_id)).valid, isFalse);
    await _servicio(categoria: 'limpieza', cert: 1);
    expect((await _v.validateService(_id)).valid, isFalse);
    await _servicio(categoria: 'limpieza', activo: 0);
    expect((await _v.validateService(_id)).valid, isFalse);
    await _servicio(categoria: 'limpieza', falla: true);
    expect((await _v.validateService(_id)).valid, isFalse);
    for (final c in _categorias) {
      await _servicio(categoria: c);
      final r = await _v.validateService(_id);
      expect(r.valid, c != 'otra');
    }
  });

  test('validateServiceRestrictions por tipo de servicio', () async {
    await _servicio();
    expect(
      (await _v.validateServiceRestrictions(serviceId: _id)).valid,
      isFalse,
    );
    final casos = {
      ServiceCategories.techSupport: [
        {'problem': 'Instalación eléctrica completa'},
        {'problem': 'formatear notebook'},
      ],
      ServiceCategories.gardening: [
        {'task': 'Tala de pino'},
        {'task': 'Árbol grande'},
        {'task': 'cortar pasto'},
      ],
      ServiceCategories.moving: [
        {'volume': 'Carga comercial'},
        {'volume': 'internacional'},
        {'volume': 'departamento'},
      ],
      ServiceCategories.cleaning: [
        {'cleaningType': 'Sanitización clínica'},
        {'cleaningType': 'hospitalaria'},
        {'cleaningType': 'casa'},
      ],
      ServiceCategories.assembly: [<String, dynamic>{}],
    };
    for (final e in casos.entries) {
      for (final data in e.value) {
        await _servicio(categoria: e.key);
        await _v.validateServiceRestrictions(serviceId: _id, serviceData: data);
      }
      await _servicio(categoria: e.key);
      await _v.validateServiceRestrictions(serviceId: _id);
    }
    await _servicio(categoria: 'limpieza', falla: true);
    expect(
      (await _v.validateServiceRestrictions(serviceId: _id)).valid,
      isTrue,
    );
  });

  test('textos de confirmación y descargo', () async {
    for (final c in _categorias) {
      await _servicio(
        categoria: c,
        aviso: c == 'limpieza' ? 'Nota propia' : null,
      );
      final t = await _v.buildConfirmationText(serviceId: _id, serviceName: 'X');
      expect(t, contains('"X"'));
    }
    await _servicio();
    await _v.buildConfirmationText(serviceId: _id, serviceName: 'X');
    await _servicio(categoria: 'limpieza', falla: true);
    await _v.buildConfirmationText(serviceId: _id, serviceName: 'X');
    expect(ServiceLegalValidator.platformDisclaimer, isNotEmpty);
    expect(ServiceLegalValidator.formatClp(1234567), contains('1'));
    expect(ServiceLegalValidator.paymentNotice(), isNotEmpty);
    expect(ServiceLegalValidator.paymentNotice(chargeAmountClp: 25000), isNotEmpty);
    await _servicio(categoria: 'limpieza', aviso: 'Aviso del servicio');
    await _v.getServiceDisclaimer(_id);
    await _servicio(categoria: 'limpieza');
    await _v.getServiceDisclaimer(_id);
    await _servicio(categoria: 'limpieza', falla: true);
    await _v.getServiceDisclaimer(_id);
  });
}

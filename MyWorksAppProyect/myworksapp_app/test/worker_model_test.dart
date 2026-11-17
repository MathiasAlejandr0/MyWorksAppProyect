import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/config/demo_credentials.dart';
import 'package:myworksapp/core/database/models/worker_model.dart';
import 'package:myworksapp/core/domain/worker_login_item.dart';
import 'package:myworksapp/core/domain/worker_service_options_catalog.dart';

void main() {
  Map<String, dynamic> baseRow() => {
        'id_usuario': '11111111-1111-4111-8111-000000000206',
        'profesion': 'Gasfíter',
        'calificacion': 4.2,
        'tarifa_visita': 34000,
        'categoria_servicio': 'gasfiteria',
      };

  test('fromMap ignora horarios_disponibles (columna ya no existe)', () {
    final worker = WorkerModel.fromMap({
      ...baseRow(),
      'horarios_disponibles': [
        {'dia': 1, 'hora': '09:00'},
      ],
    });
    expect(worker.availableHours, isEmpty);
  });

  test('fromMap lee las horas publicadas cuando vienen en la fila', () {
    final worker = WorkerModel.fromMap({
      ...baseRow(),
      'horas_publicadas': [
        {'dia': 1, 'hora': '09:00'},
        {'dia': 1, 'hora': '11:00'},
      ],
    });
    expect(worker.availableHours.map((slot) => slot.time), ['09:00', '11:00']);
  });

  test('fromMap arma precios, servicios propios y categoría desde las tablas hijas',
      () {
    final worker = WorkerModel.fromMap({
      'id_usuario': '11111111-1111-4111-8111-000000000206',
      'profesion': 'Gasfíter',
      'trabajador_precios': [
        {'codigo': 'service_basic', 'monto_clp': 30000},
        {'codigo': 'service_premium', 'monto_clp': 80000},
      ],
      'trabajador_servicios_extra': [
        {
          'id': 'custom_1',
          'titulo': 'Revisión de calefont',
          'subtitulo': 'Incluye prueba de gas',
          'monto_clp': 25000,
          'unidad': 'por_m2',
        },
      ],
      'trabajador_servicios': [
        {'categoria_servicio': 'plomeria'},
        {'categoria_servicio': 'gasfiteria'},
      ],
    });
    expect(worker.pricingTiers, {'service_basic': 30000, 'service_premium': 80000});
    expect(worker.customServices.single.title, 'Revisión de calefont');
    expect(worker.customServices.single.priceClp, 25000);
    expect(worker.customServices.single.unit, WorkerPriceUnit.perSqm);
    expect(worker.serviceCategory, 'gasfiteria');
  });

  test('toMap ya no escribe precios, servicios ni categoría en trabajadores', () {
    final map = WorkerModel.fromMap(baseRow()).toMap();
    for (final key in [
      'categoria_servicio',
      'niveles_precio',
      'servicios_personalizados',
      'id_region',
    ]) {
      expect(map.containsKey(key), isFalse, reason: key);
    }
  });

  test('fromCatalogMap asume disponible y precio configurado', () {
    final worker = WorkerModel.fromCatalogMap({
      ...baseRow(),
      'es_elite': false,
      'trabajos_completados': 5,
      'score_listado': 74.4,
      'radio_urbano_km': 5,
      'tarifa_fuera_radio_clp': 0,
    });
    expect(worker.isAvailable, isTrue);
    expect(worker.pricingConfigured, isTrue);
    expect(worker.completedJobs, 5);
    expect(worker.listingScore, 74.4);
  });

  test('el fallback de login demo prioriza gasfitería y no queda vacío', () {
    final sorted = sortWorkerLoginItems(DemoCredentials.loginWorkers);
    expect(sorted, isNotEmpty);
    expect(sorted.first.serviceCategory, 'gasfiteria');
    expect(
      sorted.any((item) => item.email == DemoCredentials.workerEmail),
      isTrue,
    );
  });
}

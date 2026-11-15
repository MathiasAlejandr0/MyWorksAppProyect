import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/config/demo_credentials.dart';
import 'package:myworksapp/core/database/models/worker_model.dart';
import 'package:myworksapp/core/domain/worker_login_item.dart';

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

  test('fromMap lee horarios de trabajador_horarios', () {
    final worker = WorkerModel.fromMap({
      ...baseRow(),
      'horarios': [
        {'dia': 1, 'hora': '09:00'},
        {'dia': 1, 'hora': '11:00'},
      ],
    });
    expect(worker.availableHours.map((slot) => slot.time), ['09:00', '11:00']);
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

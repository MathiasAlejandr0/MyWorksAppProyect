import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/service_model.dart';
import 'package:myworksapp/core/database/models/worker_model.dart';
import 'package:myworksapp/core/domain/worker_service_options_catalog.dart';
import 'package:myworksapp/features/user/presentation/widgets/worker_service_option_picker.dart';

WorkerModel _plumber({
  List<Map<String, dynamic>> prices = const [],
  List<Map<String, dynamic>> extras = const [],
  num visitFee = 32000,
}) =>
    WorkerModel.fromMap({
      'id_usuario': '11111111-1111-4111-8111-000000000301',
      'profesion': 'Gasfíter',
      'tarifa_visita': visitFee,
      'categoria_servicio': ServiceCategories.plumbing,
      'trabajador_precios': prices,
      'trabajador_servicios_extra': extras,
    });

void main() {
  group('opciones que ve el cliente', () {
    test('sin filas en trabajador_precios ofrece solo la visita con su tarifa', () {
      final worker = _plumber();
      final options = WorkerServiceOptionsCatalog.clientOptionsFor(worker);
      expect(options.map((o) => o.id), [WorkerServiceOptionsCatalog.visitOptionId]);
      expect(
        WorkerServiceOptionsCatalog.totalPriceForWorker(worker: worker, option: options.single),
        32000,
      );
    });

    test('no muestra precios por defecto del catálogo que el profesional no publicó', () {
      final worker = _plumber(prices: [
        {'codigo': 'plumbing_install', 'monto_clp': 50000},
      ]);
      final options = WorkerServiceOptionsCatalog.clientOptionsFor(worker);
      expect(options.map((o) => o.id), ['plumbing_install']);
      expect(
        WorkerServiceOptionsCatalog.priceForWorker(worker: worker, option: options.single),
        50000,
      );
    });

    test('con servicios extra publicados no agrega la visita', () {
      final worker = _plumber(extras: [
        {'id': 'x1', 'titulo': 'Destape', 'subtitulo': '', 'monto_clp': 30000, 'unidad': 'fijo'},
      ]);
      expect(WorkerServiceOptionsCatalog.clientOptionsFor(worker), isEmpty);
      expect(WorkerServiceOptionsCatalog.customOptionsFor(worker).single.id, 'x1');
    });

    test('la visita se encuentra por su código para retomar el pedido', () {
      final worker = _plumber();
      expect(
        WorkerServiceOptionsCatalog.findOptionForWorker(worker, 'visita')?.title,
        'Visita del profesional',
      );
    });
  });

  testWidgets('el formulario muestra la visita y no «Arreglo menor \$28.000»', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WorkerServiceOptionPicker(
              worker: _plumber(),
              category: ServiceCategories.plumbing,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Visita del profesional'), findsOneWidget);
    expect(find.text('\$32.000'), findsOneWidget);
    expect(find.text('Arreglo menor'), findsNothing);
  });
}

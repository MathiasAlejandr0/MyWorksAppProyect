import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/worker_model.dart';
import 'package:myworksapp/core/domain/catalog_order.dart';
import 'package:myworksapp/core/services/worker_reputation_service.dart';

/// Mismos casos que `shared/src/catalogOrder.test.ts`: la app y la web deben
/// dar el mismo orden que la RPC `listar_profesionales_catalogo`.
Map<String, dynamic> _fixture() {
  final file = File('../shared/fixtures/catalog_order_cases.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

double? _num(Object? value) => value == null ? null : (value as num).toDouble();

void main() {
  final cases = (_fixture()['cases'] as List).cast<Map<String, dynamic>>();

  group('orden único del catálogo (cercanía, nota, precio)', () {
    for (final testCase in cases) {
      test(testCase['name'] as String, () {
        final origin = testCase['origin'] as Map<String, dynamic>?;
        final items = [
          for (final raw in (testCase['workers'] as List).cast<Map<String, dynamic>>())
            CatalogOrderItem(
              id: raw['id'] as String,
              rating: _num(raw['rating']),
              price: _num(raw['price']),
              latitude: _num(raw['latitude']),
              longitude: _num(raw['longitude']),
            ),
        ];
        sortCatalog(
          items,
          (item) => item,
          originLatitude: _num(origin?['latitude']),
          originLongitude: _num(origin?['longitude']),
        );
        expect(items.map((item) => item.id).toList(), testCase['expected']);
      });
    }

    test('el listado de la app (WorkerReputationService) usa el mismo orden', () {
      final testCase = cases.first;
      final origin = testCase['origin'] as Map<String, dynamic>;
      final workers = [
        for (final raw in (testCase['workers'] as List).cast<Map<String, dynamic>>().reversed)
          WorkerModel(
            userId: raw['id'] as String,
            profession: 'Gasfíter',
            rating: _num(raw['rating'])!,
            visitFee: _num(raw['price']) ?? 0,
            baseLatitude: _num(raw['latitude']),
            baseLongitude: _num(raw['longitude']),
          ),
      ];
      WorkerReputationService.instance.sortForListing(
        workers,
        clientLatitude: _num(origin['latitude']),
        clientLongitude: _num(origin['longitude']),
      );
      expect(workers.map((w) => w.userId).toList(), testCase['expected']);
    });

    test('redondea como Postgres, también con coordenadas negativas', () {
      expect(roundCoord2(-41.235), -41.24);
      expect(roundCoord2(-72.9396), -72.94);
      expect(roundCoord2(41.235), 41.24);
    });

    test('precio y nota como vista opcional desempatan con el orden único', () {
      final list = ['b', 'a', 'c'];
      final price = {'a': 1000, 'b': 1000, 'c': 500};
      stableSortBy(list, (x, y) => price[x]!.compareTo(price[y]!));
      expect(list, ['c', 'b', 'a']);
    });
  });
}

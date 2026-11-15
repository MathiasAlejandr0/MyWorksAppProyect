import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/map/app_map_tiles.dart';

void main() {
  setUp(MapTileCache.debugReset);

  test('el mapa usa OpenFreeMap Positron y el crédito pedido', () {
    expect(
      AppMapTiles.styleUrl,
      'https://tiles.openfreemap.org/styles/positron',
    );
    expect(
      AppMapTiles.attribution,
      'OpenFreeMap © OpenMapTiles © OpenStreetMap contributors',
    );
  });

  test('la clave ignora el servidor y deja z/x/y', () {
    expect(
      MapTileCache.keyOf(
        'https://tile.openstreetmap.org/13/2516/5486.png',
      ),
      '13/2516/5486.png',
    );
    expect(
      MapTileCache.osmUrlFor(
        'https://tiles.example/raster/13/2516/5486.png',
      ),
      'https://tile.openstreetmap.org/13/2516/5486.png',
    );
  });

  test('la caché devuelve los mismos bytes y olvida la baldosa más vieja', () {
    final first = Uint8List.fromList([1]);
    final second = Uint8List.fromList([2]);
    MapTileCache.put('https://cdn.example/13/1/1.png', first);
    MapTileCache.put('https://cdn.example/13/1/2.png', second);

    expect(MapTileCache.get('https://other.example/13/1/1.png'), same(first));
    expect(MapTileCache.served, 2);

    for (var i = 0; i < MapTileCache.maxEntries; i++) {
      MapTileCache.put(
        'https://cdn.example/14/2/$i.png',
        Uint8List.fromList([i]),
      );
    }
    expect(MapTileCache.get('https://cdn.example/13/1/2.png'), isNull);
  });
}

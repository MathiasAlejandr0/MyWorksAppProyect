import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/user_location_service.dart';
import 'package:myworksapp/core/utils/chile_comunas.dart';

void main() {
  group('ChileComunas', () {
    test('Alerce no es ciudad de catálogo; el más cercano es Puerto Montt', () {
      expect(ChileComunas.isServiceCity('Alerce'), isFalse);
      expect(
        ChileComunas.catalogCity(
          'Alerce',
          latitude: -41.43,
          longitude: -72.85,
        ),
        'Puerto Montt',
      );
    });

    test('Santiago a secas cae a una comuna de la RM', () {
      expect(ChileComunas.isServiceCity('Santiago'), isFalse);
      expect(
        ChileComunas.catalogCity(
          'Santiago',
          region: 'Región Metropolitana',
          latitude: -33.45,
          longitude: -70.66,
        ),
        'Santiago Centro',
      );
    });

    test('Puerto Varas se conserva', () {
      expect(
        ChileComunas.catalogCity(
          'Puerto Varas',
          latitude: -41.3195,
          longitude: -72.9854,
        ),
        'Puerto Varas',
      );
    });
  });

  group('UserLocationService.resolvePoint', () {
    test('un tap en Chamiza no mueve el pin a Puerto Montt', () {
      const lat = -41.48;
      const lng = -72.82;
      final point = UserLocationService.resolvePoint(
        latitude: lat,
        longitude: lng,
        city: 'Chamiza',
      );
      expect(point.latitude, lat);
      expect(point.longitude, lng);
      expect(point.city, 'Puerto Montt');
    });

    test('GPS del emulador fuera de Chile sí vuelve a la demo', () {
      final point = UserLocationService.resolvePoint(
        latitude: 37.422,
        longitude: -122.084,
        city: 'Mountain View',
        remapOutsideChile: true,
      );
      expect(point.city, 'Puerto Montt');
      expect(point.latitude, UserLocationService.demoFallbackLatitude);
      expect(point.longitude, UserLocationService.demoFallbackLongitude);
    });

    test('un tap fuera de Chile sin remap conserva el punto', () {
      final point = UserLocationService.resolvePoint(
        latitude: 37.422,
        longitude: -122.084,
        city: 'Mountain View',
      );
      expect(point.latitude, 37.422);
      expect(point.longitude, -122.084);
    });
  });
}

// LocationUtils con geocodificación falsa: lugar encontrado, sin resultados y
// con error (Nominatim queda sin red en los tests y cae al texto por defecto).
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/core/utils/location_utils.dart';

import 'support/fake_geocoding.dart';
import 'support/fake_supabase.dart';

void main() {
  setUp(() async {
    await setUpFakeSupabase();
  });

  for (final modo in GeoModo.values) {
    test('direcciones con geocodificación $modo', () async {
      geoModo = modo;
      final aprox = await LocationUtils.getApproximateAddress(-41.47, -72.94);
      expect(aprox, isNotEmpty);
      expect(
        await LocationUtils.resolveExactAddress(
          address: 'Ubicación GPS: -41.4693, -72.9424',
          latitude: -41.4693,
          longitude: -72.9424,
        ),
        isNotEmpty,
      );
      expect(
        await LocationUtils.resolveExactAddress(address: ''),
        'Dirección no disponible',
      );
      expect(
        await LocationUtils.resolveExactAddress(
            address: 'Calle 1, Puerto Montt'),
        'Calle 1, Puerto Montt',
      );
      for (final status in [AppConstants.jobStatusPending, 'aceptado']) {
        await LocationUtils.getLocationTextForJob(
          address: '-41.4693, -72.9424',
          status: status,
          latitude: -41.4693,
          longitude: -72.9424,
        );
      }
    });
  }

  test('isCoordinateLikeAddress', () {
    expect(LocationUtils.isCoordinateLikeAddress('-41.4693, -72.9424'), isTrue);
    expect(LocationUtils.isCoordinateLikeAddress('Ubicación: -41.4, -72.9'),
        isTrue);
    expect(LocationUtils.isCoordinateLikeAddress('Calle 1'), isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/distance_match.dart';
import 'package:myworksapp/core/domain/transport_surcharge.dart';
import 'package:myworksapp/core/services/user_location_service.dart';
import 'package:myworksapp/core/utils/comuna_utils.dart';

void main() {
  const puertoMonttLat = UserLocationService.demoFallbackLatitude;
  const puertoMonttLng = UserLocationService.demoFallbackLongitude;
  const santiagoLat = -33.4489;
  const santiagoLng = -70.6693;

  test('una dirección sin ciudad queda en Puerto Montt, no en Santiago', () {
    expect(inferComunaKey('Calle Urmeneta 320'), 'puerto_montt');
    expect(inferComunaKey('Pelluco, Los Lagos'), 'puerto_montt');
    expect(inferComunaKey('Av. Providencia 1234, Santiago'), 'providencia');
    expect(inferComunaKey('Santiago Centro'), 'santiago');
  });

  test('el radio de traslado desde Puerto Montt excluye Santiago', () {
    final toSantiago = haversineKm(
      puertoMonttLat,
      puertoMonttLng,
      santiagoLat,
      santiagoLng,
    );
    expect(toSantiago, greaterThan(kMaxTravelWithSurchargeKm));
    expect(withinTravelRange(toSantiago), isFalse);

    final costanera = haversineKm(
      puertoMonttLat,
      puertoMonttLng,
      -41.4682,
      -72.9424,
    );
    expect(costanera, lessThan(kNearbyServiceRadiusKm));
    expect(withinTravelRange(costanera), isTrue);
  });
}

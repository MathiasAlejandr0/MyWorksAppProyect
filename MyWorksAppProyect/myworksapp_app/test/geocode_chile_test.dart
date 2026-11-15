import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/geocode_chile.dart';

void main() {
  test('Photon prefiere el hit de Chile', () {
    final site = geocodedSiteFromPhoton(
      {
        'features': [
          {
            'geometry': {
              'coordinates': [13.4, 52.5],
            },
            'properties': {
              'name': 'Berlin',
              'country': 'Germany',
              'countrycode': 'de',
            },
          },
          {
            'geometry': {
              'coordinates': [-72.94, -41.47],
            },
            'properties': {
              'name': 'Puerto Montt',
              'city': 'Puerto Montt',
              'state': 'Los Lagos',
              'country': 'Chile',
              'countrycode': 'cl',
            },
          },
        ],
      },
      'Puerto Montt, Chile',
    );
    expect(site, isNotNull);
    expect(site!.latitude, closeTo(-41.47, 0.01));
    expect(site.longitude, closeTo(-72.94, 0.01));
    expect(site.city, 'Puerto Montt');
    expect(site.region, 'Los Lagos');
  });

  test('Nominatim toma el primer resultado de Chile', () {
    final site = geocodedSiteFromNominatim(
      [
        {
          'lat': '-41.3195',
          'lon': '-72.9854',
          'display_name': 'Puerto Varas, Los Lagos, Chile',
          'address': {
            'city': 'Puerto Varas',
            'state': 'Los Lagos',
          },
        },
      ],
      'Puerto Varas',
    );
    expect(site?.city, 'Puerto Varas');
    expect(site?.latitude, closeTo(-41.3195, 0.0001));
  });
}

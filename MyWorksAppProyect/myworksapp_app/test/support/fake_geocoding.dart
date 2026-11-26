// Geocodificación falsa (geocoding 5): sin plataforma real en los tests,
// `Geocoding(...)` fallaría siempre. Devuelve un lugar de Puerto Montt o, si
// se pide, una lista vacía o un error, para recorrer cada rama.
import 'dart:ui' show Locale;

import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';

enum GeoModo { lugar, parcial, vacio, error }

GeoModo geoModo = GeoModo.lugar;

const fakePlacemark = Placemark(
  name: 'Avenida Diego Portales 1234',
  street: 'Avenida Diego Portales 1234',
  isoCountryCode: 'CL',
  country: 'Chile',
  postalCode: '5480000',
  administrativeArea: 'Los Lagos',
  subAdministrativeArea: 'Llanquihue',
  locality: 'Puerto Montt',
  subLocality: 'Centro',
  thoroughfare: 'Avenida Diego Portales',
  subThoroughfare: '1234',
);

/// Lugar con solo calle y provincia (sin comuna ni número).
const _parcial = Placemark(
  street: 'Camino a Chinquihue, km 3',
  subAdministrativeArea: 'Llanquihue',
);

class _FakeGeocoding extends Geocoding {
  _FakeGeocoding(super.params) : super.implementation();

  Future<List<T>> _r<T>(T valor) async {
    switch (geoModo) {
      case GeoModo.lugar:
        return [valor];
      case GeoModo.parcial:
        return [if (valor is Placemark) _parcial as T else valor];
      case GeoModo.vacio:
        return [];
      case GeoModo.error:
        throw Exception('geocodificación no disponible');
    }
  }

  @override
  Future<List<Location>> locationFromAddress(String address,
          {Locale? locale}) =>
      _r(const Location(latitude: -41.4693, longitude: -72.9424));

  @override
  Future<bool> isPresent() async => true;

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    Locale? locale,
  }) =>
      _r(fakePlacemark);

  @override
  Future<List<Placemark>> placemarkFromAddress(String address,
          {Locale? locale}) =>
      _r(fakePlacemark);
}

class _FakeFactory extends GeocodingPlatformFactory {
  @override
  Geocoding createGeocoding(GeocodingCreationParams params) =>
      _FakeGeocoding(params);
}

/// Instala la geocodificación falsa (idempotente).
void installFakeGeocoding() {
  if (GeocodingPlatformFactory.instance is! _FakeFactory) {
    GeocodingPlatformFactory.instance = _FakeFactory();
  }
}

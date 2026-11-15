import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_location_context.dart';
import '../utils/app_logger.dart';
import '../utils/chile_comunas.dart';
import '../utils/platform_support.dart';
import 'geocode_chile.dart';

class UserLocationService {
  static final UserLocationService instance = UserLocationService._();
  UserLocationService._();

  static const _keyLat = 'user_location_lat';
  static const _keyLng = 'user_location_lng';
  static const _keyCity = 'user_location_city';
  static const _keyRegion = 'user_location_region';
  static const _demoFallbackCity = 'Puerto Montt';
  static const _demoFallbackRegion = 'Los Lagos';
  static const _demoFallbackLat = -41.4717;
  static const _demoFallbackLng = -72.9366;

  /// Ubicación de la demo cuando no hay GPS (Puerto Montt).
  static const demoFallbackLabel = 'Puerto Montt, Los Lagos';
  static const demoFallbackLatitude = _demoFallbackLat;
  static const demoFallbackLongitude = _demoFallbackLng;

  /// Máximo que esperamos al GPS antes de usar la última posición conocida.
  static const gpsTimeout = Duration(seconds: 6);
  static const _quickTimeout = Duration(seconds: 3);
  static const _geocodeTimeout = Duration(seconds: 5);

  /// Posición actual con límite de tiempo: GPS → última conocida → null.
  /// Nunca lanza ni espera más de [timeout] + unos segundos.
  Future<Position?> currentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeout = gpsTimeout,
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      ).timeout(timeout + const Duration(seconds: 1));
    } catch (e) {
      AppLogger.w('GPS sin respuesta, usando última posición conocida', e);
    }
    try {
      return await Geolocator.getLastKnownPosition().timeout(_quickTimeout);
    } catch (e) {
      AppLogger.w('Sin última posición conocida', e);
      return null;
    }
  }

  /// Obtiene ubicación: caché → GPS → caché guardada previamente.
  Future<UserLocationContext?> resolve() async {
    final cached = await getCached();
    if (cached != null) return cached;

    final current = await getCurrent();
    if (current != null) {
      await persist(current);
      return current;
    }

    const fallback = UserLocationContext(
      city: _demoFallbackCity,
      region: _demoFallbackRegion,
      latitude: _demoFallbackLat,
      longitude: _demoFallbackLng,
    );
    await persist(fallback);
    return fallback;
  }

  Future<UserLocationContext?> getCached() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_keyCity);
    final lat = prefs.getDouble(_keyLat);
    final lng = prefs.getDouble(_keyLng);
    if (city == null || city.isEmpty || lat == null || lng == null) {
      return null;
    }
    final resolved = resolvePoint(
      latitude: lat,
      longitude: lng,
      city: city,
      region: prefs.getString(_keyRegion),
      remapOutsideChile: true,
    );
    if (resolved.city != city ||
        resolved.latitude != lat ||
        resolved.longitude != lng) {
      await persist(resolved);
    }
    return resolved;
  }

  Future<void> persist(UserLocationContext location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCity, location.city);
    if (location.region != null) {
      await prefs.setString(_keyRegion, location.region!);
    }
    if (location.latitude != null) {
      await prefs.setDouble(_keyLat, location.latitude!);
    }
    if (location.longitude != null) {
      await prefs.setDouble(_keyLng, location.longitude!);
    }
  }

  Future<UserLocationContext?> getCurrent() async {
    try {
      if (!AppPlatform.isDesktopNative) {
        final enabled = await Geolocator.isLocationServiceEnabled()
            .timeout(_quickTimeout, onTimeout: () => false);
        if (!enabled) return null;
      }

      var permission = await Geolocator.checkPermission()
          .timeout(_quickTimeout, onTimeout: () => LocationPermission.denied);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await currentPosition(
        accuracy: AppPlatform.isDesktopNative
            ? LocationAccuracy.low
            : LocationAccuracy.medium,
      );
      if (position == null) return null;

      return await fromCoordinates(
        position.latitude,
        position.longitude,
        remapOutsideChile: true,
      );
    } catch (e) {
      AppLogger.w('No se pudo obtener ubicación del usuario', e);
      return null;
    }
  }

  /// GPS / tap / dirección → contexto. Si el punto está en Chile, **no** se
  /// pisan las coordenadas (Alerce/Chamiza siguen en el mapa). El GPS fuera de
  /// Chile (emulador) sí puede volver a la demo.
  Future<UserLocationContext> fromCoordinates(
    double latitude,
    double longitude, {
    bool remapOutsideChile = false,
  }) async {
    String? city;
    String? region;

    final fromPlugin = await _fromGeocodingPlugin(latitude, longitude);
    if (fromPlugin != null) {
      city = fromPlugin.city;
      region = fromPlugin.region;
    } else {
      final fromOsm = await reverseGeocodeChile(latitude, longitude);
      if (fromOsm != null) {
        city = fromOsm.city;
        region = fromOsm.region;
      } else {
        final inferred = _inferCityFromCoordinates(latitude, longitude);
        city = inferred?.$1;
        region = inferred?.$2;
      }
    }

    final resolved = resolvePoint(
      latitude: latitude,
      longitude: longitude,
      city: city,
      region: region,
      remapOutsideChile: remapOutsideChile,
    );
    await persist(resolved);
    return resolved;
  }

  /// Punto del trabajo: conserva lat/lng en Chile; solo el GPS extranjero
  /// vuelve a Puerto Montt. La ciudad de catálogo se infiere aparte.
  @visibleForTesting
  static UserLocationContext resolvePoint({
    required double latitude,
    required double longitude,
    String? city,
    String? region,
    bool remapOutsideChile = false,
  }) {
    if (remapOutsideChile && !ChileComunas.inChile(latitude, longitude)) {
      AppLogger.w('GPS fuera de Chile: usando $_demoFallbackCity');
      return const UserLocationContext(
        city: _demoFallbackCity,
        region: _demoFallbackRegion,
        latitude: _demoFallbackLat,
        longitude: _demoFallbackLng,
      );
    }

    final catalog = ChileComunas.catalogCity(
      city ?? '',
      region: region,
      latitude: latitude,
      longitude: longitude,
    );
    return UserLocationContext(
      city: catalog,
      region: region ?? ChileComunas.regionOf(catalog),
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Dirección escrita (calle, barrio o ciudad) → GPS, igual que en la web.
  Future<UserLocationContext?> fromAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return null;

    try {
      final site = await geocodeChileAddress(trimmed);
      if (site != null) {
        final resolved = resolvePoint(
          latitude: site.latitude,
          longitude: site.longitude,
          city: site.city,
          region: site.region,
        );
        await persist(resolved);
        return resolved;
      }
    } catch (e) {
      AppLogger.w('Photon/Nominatim no geocodificó la dirección', e);
    }

    try {
      final needle =
          trimmed.toLowerCase().contains('chile') ? trimmed : '$trimmed, Chile';
      final hits = await Geocoding(locale: const Locale('es'))
          .locationFromAddress(needle)
          .timeout(_geocodeTimeout);
      if (hits.isEmpty) return null;
      return await fromCoordinates(hits.first.latitude, hits.first.longitude);
    } catch (e) {
      AppLogger.w('No se geocodificó la dirección', e);
      return null;
    }
  }

  Future<UserLocationContext?> setManualCity(String city, {String? region}) async {
    final center = ChileComunas.cityCenter(city);
    double? latitude = center?.$1;
    double? longitude = center?.$2;
    var resolvedRegion = region ?? ChileComunas.regionOf(city);

    if (latitude == null || longitude == null) {
      final geo = await fromAddress(city);
      latitude = geo?.latitude;
      longitude = geo?.longitude;
      resolvedRegion ??= geo?.region;
    }

    final ctx = UserLocationContext(
      city: city,
      region: resolvedRegion,
      latitude: latitude ?? _demoFallbackLat,
      longitude: longitude ?? _demoFallbackLng,
    );
    await persist(ctx);
    return ctx;
  }

  Future<UserLocationContext?> _fromGeocodingPlugin(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await Geocoding(locale: const Locale('es'))
          .placemarkFromCoordinates(latitude, longitude)
          .timeout(_geocodeTimeout);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final city = _extractCity(place);
      if (city == null || city.isEmpty) return null;

      return UserLocationContext(
        city: city,
        region: place.administrativeArea,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      AppLogger.w('Geocoding plugin no disponible', e);
      return null;
    }
  }

  (String, String?)? _inferCityFromCoordinates(double lat, double lon) {
    if (!ChileComunas.inChile(lat, lon)) return null;
    final city = ChileComunas.nearestServiceCity(lat, lon);
    return (city, ChileComunas.regionOf(city));
  }

  String? _extractCity(Placemark place) {
    if (place.locality != null && place.locality!.trim().isNotEmpty) {
      return place.locality!.trim();
    }
    if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.trim().isNotEmpty) {
      return place.subAdministrativeArea!.trim();
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.trim().isNotEmpty) {
      return place.administrativeArea!.trim();
    }
    return null;
  }
}

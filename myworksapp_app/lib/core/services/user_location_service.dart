import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_location_context.dart';
import '../utils/app_logger.dart';
import '../utils/chile_comunas.dart';
import '../utils/platform_support.dart';

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

    // Sin GPS ni caché: ciudad de la demo (misma que en debug).
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
    return _ensureServiceArea(
      UserLocationContext(
        city: city,
        region: prefs.getString(_keyRegion),
        latitude: lat,
        longitude: lng,
      ),
    );
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

      return await fromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      AppLogger.w('No se pudo obtener ubicación del usuario', e);
      return null;
    }
  }

  Future<UserLocationContext?> fromCoordinates(
    double latitude,
    double longitude,
  ) async {
    final fromPlugin = await _fromGeocodingPlugin(latitude, longitude);
    if (fromPlugin != null) return _ensureServiceArea(fromPlugin);

    final fromOsm = await _fromOpenStreetMap(latitude, longitude);
    if (fromOsm != null) return _ensureServiceArea(fromOsm);

    final inferred = _inferCityFromCoordinates(latitude, longitude);
    if (inferred != null) {
      return _ensureServiceArea(
        UserLocationContext(
          city: inferred.$1,
          region: inferred.$2,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }

    return null;
  }

  /// GPS fuera de Chile (p. ej. emulador en Mountain View) → demo en Puerto Montt.
  Future<UserLocationContext?> _ensureServiceArea(UserLocationContext? ctx) async {
    if (ctx == null) return null;
    if (ChileComunas.isServiceCity(ctx.city)) {
      await persist(ctx);
      return ctx;
    }

    AppLogger.w('Ciudad fuera de cobertura: ${ctx.city}');

    // Debug y release: GPS fuera de cobertura (p. ej. emulador en
    // Mountain View) usa la ciudad de la demo.
    const fallback = UserLocationContext(
      city: _demoFallbackCity,
      region: _demoFallbackRegion,
      latitude: _demoFallbackLat,
      longitude: _demoFallbackLng,
    );
    await persist(fallback);
    AppLogger.i('Fuera de cobertura: usando $_demoFallbackCity');
    return fallback;
  }

  Future<UserLocationContext?> setManualCity(String city, {String? region}) async {
    final cached = await getCached();
    final ctx = UserLocationContext(
      city: city,
      region: region,
      latitude: cached?.latitude,
      longitude: cached?.longitude,
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

  Future<UserLocationContext?> _fromOpenStreetMap(
    double latitude,
    double longitude,
  ) async {
    final client = HttpClient()..connectionTimeout = _geocodeTimeout;
    try {
      return await _fetchOpenStreetMap(client, latitude, longitude)
          .timeout(_geocodeTimeout + _quickTimeout);
    } catch (e) {
      AppLogger.w('Reverse geocoding OSM falló', e);
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<UserLocationContext?> _fetchOpenStreetMap(
    HttpClient client,
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$latitude&lon=$longitude&format=json&accept-language=es',
    );
    final request = await client.getUrl(uri);
    request.headers.set('User-Agent', 'MyWorksApp/1.0 (demo university project)');
    final response = await request.close();
    if (response.statusCode != 200) return null;

    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return null;

    final city = _firstNonEmpty(address, [
      'city',
      'town',
      'municipality',
      'village',
      'county',
    ]);
    if (city == null) return null;

    final region = _firstNonEmpty(address, ['state', 'region']);

    return UserLocationContext(
      city: city,
      region: region,
      latitude: latitude,
      longitude: longitude,
    );
  }

  String? _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  (String, String?)? _inferCityFromCoordinates(double lat, double lon) {
    if (lat >= -41.65 && lat <= -41.25 && lon >= -73.25 && lon <= -72.65) {
      return ('Puerto Montt', 'Los Lagos');
    }
    if (lat >= -33.65 && lat <= -33.05 && lon >= -71.05 && lon <= -70.35) {
      return ('Santiago', 'Región Metropolitana');
    }
    return null;
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

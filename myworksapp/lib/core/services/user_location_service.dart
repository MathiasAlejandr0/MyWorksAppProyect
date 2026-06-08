import 'dart:convert';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_location_context.dart';
import '../utils/app_logger.dart';
import '../utils/platform_support.dart';

class UserLocationService {
  static final UserLocationService instance = UserLocationService._();
  UserLocationService._();

  static const _keyLat = 'user_location_lat';
  static const _keyLng = 'user_location_lng';
  static const _keyCity = 'user_location_city';
  static const _keyRegion = 'user_location_region';

  /// Obtiene ubicación: caché → GPS → caché guardada previamente.
  Future<UserLocationContext?> resolve() async {
    final cached = await getCached();
    if (cached != null) return cached;

    final current = await getCurrent();
    if (current != null) {
      await persist(current);
      return current;
    }

    return null;
  }

  Future<UserLocationContext?> getCached() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_keyCity);
    final lat = prefs.getDouble(_keyLat);
    final lng = prefs.getDouble(_keyLng);
    if (city == null || city.isEmpty || lat == null || lng == null) {
      return null;
    }
    return UserLocationContext(
      city: city,
      region: prefs.getString(_keyRegion),
      latitude: lat,
      longitude: lng,
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
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: AppPlatform.isDesktopNative
              ? LocationAccuracy.low
              : LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 20),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) return null;

      final ctx = await fromCoordinates(position.latitude, position.longitude);
      if (ctx != null) await persist(ctx);
      return ctx;
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
    if (fromPlugin != null) return fromPlugin;

    final fromOsm = await _fromOpenStreetMap(latitude, longitude);
    if (fromOsm != null) return fromOsm;

    final inferred = _inferCityFromCoordinates(latitude, longitude);
    if (inferred != null) {
      return UserLocationContext(
        city: inferred.$1,
        region: inferred.$2,
        latitude: latitude,
        longitude: longitude,
      );
    }

    return null;
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
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: 'es',
      );
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
    final client = HttpClient();
    try {
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
    } catch (e) {
      AppLogger.w('Reverse geocoding OSM falló', e);
      return null;
    } finally {
      client.close();
    }
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

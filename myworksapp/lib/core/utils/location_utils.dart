import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:geocoding/geocoding.dart';

class LocationUtils {
  static final RegExp _coordinatePairPattern = RegExp(
    r'^-?\d+\.?\d*\s*,\s*-?\d+\.?\d*$',
  );

  /// Genera una ubicación aproximada agregando un offset aleatorio
  /// para proteger la privacidad del usuario.
  static Future<String> getApproximateAddress(
    double latitude,
    double longitude,
  ) async {
    final random = Random();
    final distanceInMeters = 200 + random.nextDouble() * 300;
    final bearing = random.nextDouble() * 360;

    final approximateLat = _offsetLatitude(latitude, distanceInMeters, bearing);
    final approximateLon =
        _offsetLongitude(latitude, longitude, distanceInMeters, bearing);

    try {
      final placemarks = await placemarkFromCoordinates(
        approximateLat,
        approximateLon,
        localeIdentifier: 'es',
      );

      if (placemarks.isNotEmpty) {
        return _formatApproximateAddress(placemarks.first);
      }

      return 'Zona aproximada';
    } catch (_) {
      return 'Ubicación aproximada';
    }
  }

  /// Indica si el texto guardado es una coordenada y no una dirección postal.
  static bool isCoordinateLikeAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return true;

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('ubicación:') || lower.startsWith('ubicacion:')) {
      return true;
    }
    if (lower.startsWith('ubicación gps:') || lower.startsWith('ubicacion gps:')) {
      return true;
    }

    final withoutLabel = trimmed
        .replaceFirst(RegExp(r'^ubicaci[oó]n(\s*gps)?\s*:\s*', caseSensitive: false), '')
        .trim();

    return _coordinatePairPattern.hasMatch(withoutLabel);
  }

  /// Dirección exacta con calle y número para trabajos aceptados.
  static Future<String> resolveExactAddress({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    final stored = address.trim();
    if (stored.isNotEmpty && !isCoordinateLikeAddress(stored)) {
      return stored;
    }

    if (latitude != null && longitude != null) {
      final fromCoords = await _reverseGeocodeExact(latitude, longitude);
      if (fromCoords != null && fromCoords.isNotEmpty) {
        return fromCoords;
      }
    }

    return stored.isNotEmpty ? stored : 'Dirección no disponible';
  }

  /// Obtiene el texto de ubicación según el estado del trabajo.
  static Future<String> getLocationTextForJob({
    required String address,
    required String status,
    double? latitude,
    double? longitude,
  }) async {
    if (status == 'pending' && latitude != null && longitude != null) {
      try {
        return await getApproximateAddress(latitude, longitude);
      } catch (_) {
        return 'Zona aproximada';
      }
    }

    return resolveExactAddress(
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static Future<String?> _reverseGeocodeExact(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: 'es',
      );
      if (placemarks.isNotEmpty) {
        final formatted = _formatExactAddress(placemarks.first);
        if (formatted.isNotEmpty) return formatted;
      }
    } catch (_) {
      // Fallback OSM (útil en escritorio).
    }

    return _reverseGeocodeFromOpenStreetMap(latitude, longitude);
  }

  static Future<String?> _reverseGeocodeFromOpenStreetMap(
    double latitude,
    double longitude,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$latitude&lon=$longitude&format=json&addressdetails=1&accept-language=es',
      );
      final request = await client.getUrl(uri);
      request.headers.set(
        'User-Agent',
        'MyWorksApp/1.0 (university demo project)',
      );
      final response = await request.close();
      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      return _formatOsmAddress(address);
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static String _formatExactAddress(Placemark place) {
    final parts = <String>[];

    if (place.street != null && place.street!.isNotEmpty) {
      final number = place.subThoroughfare?.trim();
      if (number != null && number.isNotEmpty) {
        parts.add('${place.street!} $number');
      } else {
        parts.add(place.street!);
      }
    } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      final number = place.subThoroughfare?.trim();
      if (number != null && number.isNotEmpty) {
        parts.add('${place.thoroughfare!} $number');
      } else {
        parts.add(place.thoroughfare!);
      }
    } else if (place.subThoroughfare != null &&
        place.subThoroughfare!.isNotEmpty) {
      parts.add('Nº ${place.subThoroughfare!}');
    }

    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    } else if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    }

    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    return parts.join(', ');
  }

  static String _formatOsmAddress(Map<String, dynamic> address) {
    final parts = <String>[];

    final road = _firstNonEmpty(address, ['road', 'pedestrian', 'footway']);
    final houseNumber = _firstNonEmpty(address, ['house_number']);
    if (road != null) {
      parts.add(houseNumber != null ? '$road $houseNumber' : road);
    } else if (houseNumber != null) {
      parts.add('Nº $houseNumber');
    }

    final city = _firstNonEmpty(address, [
      'city',
      'town',
      'municipality',
      'village',
      'county',
    ]);
    if (city != null) parts.add(city);

    final region = _firstNonEmpty(address, ['state', 'region']);
    if (region != null) parts.add(region);

    return parts.join(', ');
  }

  static String? _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static double _offsetLatitude(double lat, double distanceMeters, double bearing) {
    const earthRadius = 6371000.0;
    final latRad = lat * pi / 180;
    final bearingRad = bearing * pi / 180;

    final newLat = asin(
      sin(latRad) * cos(distanceMeters / earthRadius) +
          cos(latRad) * sin(distanceMeters / earthRadius) * cos(bearingRad),
    );

    return newLat * 180 / pi;
  }

  static double _offsetLongitude(
    double lat,
    double lon,
    double distanceMeters,
    double bearing,
  ) {
    const earthRadius = 6371000.0;
    final latRad = lat * pi / 180;
    final lonRad = lon * pi / 180;
    final bearingRad = bearing * pi / 180;

    final newLat = _offsetLatitude(lat, distanceMeters, bearing);
    final newLatRad = newLat * pi / 180;

    final newLon = lonRad +
        atan2(
          sin(bearingRad) * sin(distanceMeters / earthRadius) * cos(latRad),
          cos(distanceMeters / earthRadius) - sin(latRad) * sin(newLatRad),
        );

    return newLon * 180 / pi;
  }

  static String _formatApproximateAddress(Placemark place) {
    final parts = <String>[];

    if (place.street != null && place.street!.isNotEmpty) {
      final street = place.street!.replaceAll(RegExp(r'\d+'), '').trim();
      if (street.isNotEmpty) {
        parts.add(street);
      }
    }

    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    } else if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    }

    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    if (parts.isNotEmpty) {
      return '${parts.join(', ')} (ubicación aproximada)';
    }

    return 'Ubicación aproximada';
  }
}

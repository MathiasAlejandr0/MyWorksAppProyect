import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';

import '../services/geocode_chile.dart';
import 'constants.dart';

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
      final placemarks = await Geocoding(locale: const Locale('es'))
          .placemarkFromCoordinates(approximateLat, approximateLon);

      if (placemarks.isNotEmpty) {
        return _formatApproximateAddress(placemarks.first);
      }
    } catch (_) {
      // En web el plugin suele fallar; Nominatim cubre ese caso.
    }
    final osm = await reverseGeocodeChile(approximateLat, approximateLon);
    if (osm != null) {
      final city = osm.city ?? osm.label;
      if (city.trim().isNotEmpty) {
        return '$city (ubicación aproximada)';
      }
    }
    return 'Ubicación aproximada';
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
    if (status == AppConstants.jobStatusPending &&
        latitude != null &&
        longitude != null) {
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
      final placemarks = await Geocoding(locale: const Locale('es'))
          .placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final formatted = _formatExactAddress(placemarks.first);
        if (formatted.isNotEmpty) return formatted;
      }
    } catch (_) {
      // Fallback OSM (útil en escritorio).
    }

    final osm = await reverseGeocodeChile(latitude, longitude);
    return osm?.label;
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

    // `street` en Android trae la línea completa; se usa thoroughfare o solo
    // el primer segmento para no duplicar comuna/región.
    final rawStreet = (place.thoroughfare?.trim().isNotEmpty ?? false)
        ? place.thoroughfare!
        : (place.street ?? '').split(',').first;
    if (rawStreet.trim().isNotEmpty) {
      final street = rawStreet
          .replaceAll(RegExp(r'[\d#-]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
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

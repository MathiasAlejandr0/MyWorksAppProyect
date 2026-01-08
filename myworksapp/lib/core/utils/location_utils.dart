import 'dart:math';
import 'package:geocoding/geocoding.dart';

class LocationUtils {
  /// Genera una ubicación aproximada agregando un offset aleatorio
  /// para proteger la privacidad del usuario
  /// 
  /// Offset máximo: aproximadamente 200-500 metros
  static Future<String> getApproximateAddress(
    double latitude,
    double longitude,
  ) async {
    // Generar offset aleatorio entre 200-500 metros
    final random = Random();
    final distanceInMeters = 200 + random.nextDouble() * 300; // 200-500 metros
    final bearing = random.nextDouble() * 360; // Dirección aleatoria
    
    // Calcular nueva posición aproximada
    final approximateLat = _offsetLatitude(latitude, distanceInMeters, bearing);
    final approximateLon = _offsetLongitude(latitude, longitude, distanceInMeters, bearing);
    
    try {
      // Obtener dirección de la ubicación aproximada
      List<Placemark> placemarks = await placemarkFromCoordinates(
        approximateLat,
        approximateLon,
        localeIdentifier: 'es',
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        return _formatApproximateAddress(place);
      }
      
      // Si no se puede obtener, devolver área general
      return 'Zona aproximada';
    } catch (e) {
      // Si falla, devolver mensaje genérico
      return 'Ubicación aproximada';
    }
  }
  
  /// Calcula el offset de latitud
  static double _offsetLatitude(double lat, double distanceMeters, double bearing) {
    const earthRadius = 6371000.0; // Radio de la Tierra en metros
    final latRad = lat * pi / 180;
    final bearingRad = bearing * pi / 180;
    
    final newLat = asin(
      sin(latRad) * cos(distanceMeters / earthRadius) +
      cos(latRad) * sin(distanceMeters / earthRadius) * cos(bearingRad),
    );
    
    return newLat * 180 / pi;
  }
  
  /// Calcula el offset de longitud
  static double _offsetLongitude(
    double lat,
    double lon,
    double distanceMeters,
    double bearing,
  ) {
    const earthRadius = 6371000.0; // Radio de la Tierra en metros
    final latRad = lat * pi / 180;
    final lonRad = lon * pi / 180;
    final bearingRad = bearing * pi / 180;
    
    final newLat = _offsetLatitude(lat, distanceMeters, bearing);
    final newLatRad = newLat * pi / 180;
    
    final newLon = lonRad + atan2(
      sin(bearingRad) * sin(distanceMeters / earthRadius) * cos(latRad),
      cos(distanceMeters / earthRadius) - sin(latRad) * sin(newLatRad),
    );
    
    return newLon * 180 / pi;
  }
  
  /// Formatea la dirección aproximada (sin número de casa)
  static String _formatApproximateAddress(Placemark place) {
    final parts = <String>[];
    
    // Solo incluir calle sin número
    if (place.street != null && place.street!.isNotEmpty) {
      // Remover números de la calle si existen
      final street = place.street!.replaceAll(RegExp(r'\d+'), '').trim();
      if (street.isNotEmpty) {
        parts.add(street);
      }
    }
    
    // Localidad/Comuna
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    }
    
    // Región
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    
    if (parts.isNotEmpty) {
      return '${parts.join(', ')} (ubicación aproximada)';
    }
    
    return 'Ubicación aproximada';
  }
  
  /// Obtiene el texto de ubicación según el estado del trabajo
  /// - Pendiente: muestra ubicación aproximada
  /// - Aceptado/En progreso/Completado: muestra ubicación exacta
  static Future<String> getLocationTextForJob({
    required String address,
    required String status,
    double? latitude,
    double? longitude,
  }) async {
    // Si el trabajo está pendiente y tenemos coordenadas, mostrar aproximada
    if (status == 'pending' && latitude != null && longitude != null) {
      try {
        final approximateAddress = await getApproximateAddress(latitude, longitude);
        return approximateAddress;
      } catch (e) {
        // Si falla, mostrar dirección genérica
        return 'Zona aproximada';
      }
    }
    
    // Para trabajos aceptados o en progreso, mostrar dirección exacta
    return address;
  }
}


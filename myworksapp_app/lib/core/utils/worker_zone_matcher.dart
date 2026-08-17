import '../domain/user_location_context.dart';
import 'chile_comunas.dart';

/// Determina si la zona de trabajo de un profesional cubre la ubicación del cliente.
/// Solo ciudad exacta o cobertura regional explícita en la misma región.
class WorkerZoneMatcher {
  WorkerZoneMatcher._();

  static bool serves({
    required String? workZone,
    required UserLocationContext userLocation,
  }) {
    if (workZone == null || workZone.trim().isEmpty) return false;

    final zone = _normalize(workZone);
    final city = _normalize(userLocation.city);
    final region = userLocation.region != null
        ? _normalize(userLocation.region!)
        : '';

    if (zone.contains('(todas)')) {
      final zoneRegion = zone.replaceAll('(todas)', '').trim();
      return region.isNotEmpty && _sameRegion(zoneRegion, region);
    }

    if (zone == city) return true;

    if (ChileComunas.isMetropolitanComuna(workZone)) {
      return ChileComunas.isMetropolitanRegion(region) && zone == city;
    }

    return false;
  }

  static bool _sameRegion(String zoneRegion, String userRegion) {
    if (zoneRegion.isEmpty || userRegion.isEmpty) return false;

    const pairs = [
      ('region metropolitana', 'metropolitana'),
      ('region metropolitana', 'santiago'),
      ('los lagos', 'los lagos'),
      ('de los lagos', 'los lagos'),
    ];

    for (final pair in pairs) {
      final zoneHit = zoneRegion.contains(pair.$1) || zoneRegion.contains(pair.$2);
      final userHit = userRegion.contains(pair.$1) || userRegion.contains(pair.$2);
      if (zoneHit && userHit) return true;
    }

    return zoneRegion == userRegion;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }
}

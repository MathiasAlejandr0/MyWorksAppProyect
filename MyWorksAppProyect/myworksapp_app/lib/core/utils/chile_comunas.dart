/// Zonas de trabajo en Chile para registro y filtrado local.
class ChileComunas {
  ChileComunas._();

  static const List<String> metropolitan = [
    'Santiago Centro',
    'Providencia',
    'Las Condes',
    'Ñuñoa',
    'Maipú',
    'La Florida',
    'Puente Alto',
    'San Bernardo',
    'Peñalolén',
    'La Reina',
    'Vitacura',
    'Lo Barnechea',
    'Quilicura',
    'Estación Central',
    'Independencia',
    'Recoleta',
    'Huechuraba',
    'Macul',
    'La Cisterna',
    'El Bosque',
    'Región Metropolitana (todas)',
  ];

  static const List<String> losLagos = [
    'Puerto Montt',
    'Puerto Varas',
    'Osorno',
    'Castro',
    'Ancud',
    'Los Lagos (todas)',
  ];

  static const List<String> otherCities = [
    'Valparaíso',
    'Viña del Mar',
    'Concepción',
    'Temuco',
    'La Serena',
    'Antofagasta',
    'Iquique',
    'Rancagua',
    'Talca',
    'Chillán',
  ];

  /// Centros aproximados para el pin al elegir ciudad a mano.
  static const Map<String, (double, double)> cityCenters = {
    'Puerto Montt': (-41.4717, -72.9366),
    'Puerto Varas': (-41.3195, -72.9854),
    'Osorno': (-40.5739, -73.1356),
    'Castro': (-42.4823, -73.7642),
    'Ancud': (-41.8682, -73.8275),
    'Santiago Centro': (-33.4372, -70.6506),
    'Providencia': (-33.4313, -70.6099),
    'Las Condes': (-33.4084, -70.5670),
    'Ñuñoa': (-33.4545, -70.6010),
    'Maipú': (-33.5108, -70.7575),
    'La Florida': (-33.5227, -70.5956),
    'Puente Alto': (-33.6117, -70.5758),
    'San Bernardo': (-33.5923, -70.6996),
    'Peñalolén': (-33.4900, -70.5480),
    'La Reina': (-33.4443, -70.5317),
    'Vitacura': (-33.3906, -70.5724),
    'Lo Barnechea': (-33.3513, -70.5164),
    'Quilicura': (-33.3615, -70.7290),
    'Estación Central': (-33.4569, -70.6987),
    'Independencia': (-33.4150, -70.6650),
    'Recoleta': (-33.4060, -70.6400),
    'Huechuraba': (-33.3680, -70.6370),
    'Macul': (-33.4850, -70.5990),
    'La Cisterna': (-33.5280, -70.6640),
    'El Bosque': (-33.5630, -70.6760),
    'Valparaíso': (-33.0472, -71.6127),
    'Viña del Mar': (-33.0246, -71.5518),
    'Concepción': (-36.8201, -73.0444),
    'Temuco': (-38.7359, -72.5904),
    'La Serena': (-29.9027, -71.2520),
    'Antofagasta': (-23.6509, -70.3975),
    'Iquique': (-20.2307, -70.1357),
    'Rancagua': (-34.1708, -70.7444),
    'Talca': (-35.4264, -71.6554),
    'Chillán': (-36.6067, -72.1034),
  };

  static List<String> get allZones => [
        ...losLagos,
        ...metropolitan,
        ...otherCities,
      ];

  static bool isMetropolitanComuna(String zone) {
    final normalized = _norm(zone);
    return metropolitan.any(
      (c) => _norm(c) == normalized && !c.contains('(todas)'),
    );
  }

  static bool isMetropolitanRegion(String? region) {
    if (region == null) return false;
    final r = _norm(region);
    return r.contains('metropolitana') || r.contains('santiago');
  }

  /// Ciudades donde la app opera (excluye coberturas regionales "(todas)").
  static bool isServiceCity(String city) {
    final normalized = _norm(city);
    return allZones
        .where((zone) => !zone.contains('(todas)'))
        .any((zone) => _norm(zone) == normalized);
  }

  static bool inChile(double latitude, double longitude) {
    return latitude >= -56.0 &&
        latitude <= -17.0 &&
        longitude >= -76.5 &&
        longitude <= -66.0;
  }

  static (double, double)? cityCenter(String city) {
    final normalized = _norm(city);
    for (final entry in cityCenters.entries) {
      if (_norm(entry.key) == normalized) return entry.value;
    }
    return null;
  }

  static String? regionOf(String city) {
    final normalized = _norm(city);
    if (losLagos.any((zone) => _norm(zone) == normalized && !zone.contains('(todas)'))) {
      return 'Los Lagos';
    }
    if (metropolitan.any((zone) => _norm(zone) == normalized && !zone.contains('(todas)'))) {
      return 'Región Metropolitana';
    }
    return null;
  }

  static String nearestServiceCity(double latitude, double longitude) {
    var bestName = 'Puerto Montt';
    var best = double.infinity;
    for (final entry in cityCenters.entries) {
      final dLat = entry.value.$1 - latitude;
      final dLng = entry.value.$2 - longitude;
      final distance = dLat * dLat + dLng * dLng;
      if (distance < best) {
        best = distance;
        bestName = entry.key;
      }
    }
    return bestName;
  }

  /// Ciudad de catálogo para filtrar profesionales. No mueve el pin.
  static String catalogCity(
    String city, {
    String? region,
    double? latitude,
    double? longitude,
  }) {
    if (isServiceCity(city)) return city;
    if (latitude != null &&
        longitude != null &&
        inChile(latitude, longitude)) {
      return nearestServiceCity(latitude, longitude);
    }
    if (isMetropolitanRegion(region)) return 'Santiago Centro';
    if (region != null && _norm(region).contains('lagos')) {
      return 'Puerto Montt';
    }
    return city.trim().isEmpty ? 'Puerto Montt' : city;
  }

  static String _norm(String value) {
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

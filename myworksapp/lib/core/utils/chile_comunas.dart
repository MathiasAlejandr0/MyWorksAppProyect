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

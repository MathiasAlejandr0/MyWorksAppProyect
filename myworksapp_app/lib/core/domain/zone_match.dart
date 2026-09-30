/// 1.0 si la zona declarada del profesional aparece en la dirección del trabajo.
///
/// No inventa kilómetros: sin coordenadas del profesional no hay distancia real.
double zoneMatchScore(String? workZone, String? address) {
  final zone = workZone?.trim().toLowerCase() ?? '';
  final place = address?.trim().toLowerCase() ?? '';
  if (zone.length < 3 || place.isEmpty) return 0;
  return place.contains(zone) ? 1 : 0;
}

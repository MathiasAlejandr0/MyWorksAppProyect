import 'dart:math' as math;

/// Distancia en kilómetros. Misma fórmula que `shared/src/geo/distance.ts`.
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earth = 6371.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

class DistanceMatch {
  const DistanceMatch({
    required this.distanceKm,
    required this.score,
    required this.outsideRadius,
  });

  final double distanceKm;
  /// 1 junto a la base, 0 en el borde del radio.
  final double score;
  final bool outsideRadius;
}

/// Null si el profesional no tiene base. Fuera del radio queda marcado para excluirlo.
DistanceMatch? matchByDistance({
  double? workerLat,
  double? workerLng,
  required double jobLat,
  required double jobLng,
  double radiusKm = 15,
}) {
  if (workerLat == null || workerLng == null) return null;
  final radius = radiusKm <= 0 ? 15.0 : radiusKm;
  final km = haversineKm(workerLat, workerLng, jobLat, jobLng);
  if (km > radius) {
    return DistanceMatch(distanceKm: km, score: 0, outsideRadius: true);
  }
  final score = (1 - (km / radius)).clamp(0.0, 1.0);
  return DistanceMatch(distanceKm: km, score: score, outsideRadius: false);
}

int? estimateEtaMinutes(double distanceKm, {double speedKmh = 28}) {
  if (distanceKm.isNaN || distanceKm < 0 || speedKmh <= 0) return null;
  if (distanceKm < 0.05) return 1;
  return math.max(1, (distanceKm / speedKmh * 60).round());
}

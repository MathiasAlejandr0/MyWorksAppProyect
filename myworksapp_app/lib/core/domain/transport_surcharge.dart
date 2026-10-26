import 'distance_match.dart';

/// Radio cercano realista: unos 10–15 min en auto, sin extra de traslado.
const double kNearbyServiceRadiusKm = 7;

/// Más lejos que esto no se ofrece el viaje, ni con recargo.
const double kMaxTravelWithSurchargeKm = 30;

const int kTransportClpPerExtraKm = 1200;
const int kTransportMinSurchargeClp = 3000;
const int kTransportMaxSurchargeClp = 18000;

class TransportSurcharge {
  const TransportSurcharge({
    required this.distanceKm,
    required this.radiusKm,
    required this.extraKm,
    required this.extraClp,
    required this.insideRadar,
  });

  final double? distanceKm;
  final double radiusKm;
  final double extraKm;
  final int extraClp;
  final bool? insideRadar;
}

double resolveServiceRadiusKm(double? radiusKm) {
  if (radiusKm == null || radiusKm <= 0 || radiusKm.isNaN) {
    return kNearbyServiceRadiusKm;
  }
  return radiusKm;
}

bool withinTravelRange(double? distanceKm) {
  if (distanceKm == null || distanceKm.isNaN) return true;
  return distanceKm <= kMaxTravelWithSurchargeKm;
}

/// Recargo solo por los km fuera del radar. Cero si el trabajo queda cerca.
TransportSurcharge transportSurcharge({
  double? workerLat,
  double? workerLng,
  double? jobLat,
  double? jobLng,
  double? radiusKm,
}) {
  final radius = resolveServiceRadiusKm(radiusKm);
  if (workerLat == null ||
      workerLng == null ||
      jobLat == null ||
      jobLng == null) {
    return TransportSurcharge(
      distanceKm: null,
      radiusKm: radius,
      extraKm: 0,
      extraClp: 0,
      insideRadar: null,
    );
  }

  final distanceKm = haversineKm(workerLat, workerLng, jobLat, jobLng);
  final extraKm = (distanceKm - radius).clamp(0.0, double.infinity);
  if (extraKm <= 0) {
    return TransportSurcharge(
      distanceKm: distanceKm,
      radiusKm: radius,
      extraKm: 0,
      extraClp: 0,
      insideRadar: true,
    );
  }

  final raw = (extraKm * kTransportClpPerExtraKm).round();
  final extraClp = raw.clamp(
    kTransportMinSurchargeClp,
    kTransportMaxSurchargeClp,
  );
  return TransportSurcharge(
    distanceKm: distanceKm,
    radiusKm: radius,
    extraKm: extraKm,
    extraClp: extraClp,
    insideRadar: false,
  );
}

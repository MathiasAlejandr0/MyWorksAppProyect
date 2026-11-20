import 'dart:math' as math;

import 'clp_rounding.dart';

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
    this.catalogBaseIsApproximate = false,
  });

  final double? distanceKm;
  final double radiusKm;
  final double extraKm;
  final int extraClp;
  final bool? insideRadar;

  /// La base vino del catálogo (2 decimales, ~1 km). [extraClp] no es cobrable.
  final bool catalogBaseIsApproximate;
}

/// Haversine con `asin`, la misma expresión que `km_entre_puntos` en Postgres.
double haversineKmForCharge(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earth = 6371.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final clamped = a.clamp(0.0, 1.0);
  return earth * 2 * math.asin(math.sqrt(clamped));
}

/// Texto del radio gratis. Piso a 1 decimal: no promete una zona más grande
/// que la que usa el cobro.
String formatServiceRadiusKm(double? radiusKm) {
  final radius = resolveServiceRadiusKm(radiusKm);
  final milli = (radius * 1000).round();
  final tenths = milli ~/ 100;
  final whole = tenths ~/ 10;
  final fraction = tenths % 10;
  if (fraction == 0) return '$whole';
  return '$whole,$fraction';
}

/// El pin del catálogo puede mentir ~1 km. Se oculta solo si queda holgadamente
/// más lejos que el tope de 30 km.
const double kCatalogPinHideBeyondKm = 31.5;

bool catalogPinTooFar(double? distanceKm) {
  if (distanceKm == null || distanceKm.isNaN) return false;
  return distanceKm > kCatalogPinHideBeyondKm;
}

double resolveServiceRadiusKm(double? radiusKm) {
  if (radiusKm == null || radiusKm <= 0 || radiusKm.isNaN) {
    return kNearbyServiceRadiusKm;
  }
  return radiusKm;
}

bool withinTravelRange(double? distanceKm) {
  if (distanceKm == null || distanceKm.isNaN) return true;
  return quantizeChargeKm(distanceKm) <= kMaxTravelWithSurchargeKm;
}

/// Recargo solo por los km fuera del radar. Cero si el trabajo queda cerca.
///
/// [catalogBaseIsApproximate] es la base publicada a 2 decimales. Con esa
/// coordenada no se calcula un peso cobrable: el servidor usa la base real.
TransportSurcharge transportSurcharge({
  double? workerLat,
  double? workerLng,
  double? jobLat,
  double? jobLng,
  double? radiusKm,
  bool catalogBaseIsApproximate = false,
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
      catalogBaseIsApproximate: catalogBaseIsApproximate,
    );
  }

  final distanceKm = quantizeChargeKm(
    haversineKmForCharge(workerLat, workerLng, jobLat, jobLng),
  );
  if (catalogBaseIsApproximate) {
    return TransportSurcharge(
      distanceKm: distanceKm,
      radiusKm: radius,
      extraKm: 0,
      extraClp: 0,
      insideRadar: null,
      catalogBaseIsApproximate: true,
    );
  }

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

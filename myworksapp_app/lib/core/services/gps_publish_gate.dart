import '../domain/distance_match.dart';

const liveGpsStatuses = {'en_camino', 'en_curso'};

bool publishesLiveGps(String? status) =>
    status != null && liveGpsStatuses.contains(status);

/// Ahorra batería: no manda un punto si no pasó el tiempo ni se movió lo suficiente.
class GpsPublishGate {
  GpsPublishGate({
    this.minInterval = const Duration(seconds: 20),
    this.minMeters = 40,
  });

  final Duration minInterval;
  final double minMeters;
  DateTime? lastAt;
  double? lastLat;
  double? lastLng;

  bool shouldPublish({
    required DateTime now,
    required double latitude,
    required double longitude,
  }) {
    if (lastAt == null || lastLat == null || lastLng == null) {
      _remember(now, latitude, longitude);
      return true;
    }
    final elapsed = now.difference(lastAt!);
    final moved = haversineKm(lastLat!, lastLng!, latitude, longitude) * 1000;
    if (elapsed >= minInterval || moved >= minMeters) {
      _remember(now, latitude, longitude);
      return true;
    }
    return false;
  }

  void _remember(DateTime now, double latitude, double longitude) {
    lastAt = now;
    lastLat = latitude;
    lastLng = longitude;
  }
}

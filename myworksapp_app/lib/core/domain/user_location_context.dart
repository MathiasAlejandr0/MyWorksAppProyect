/// Ubicación del cliente para filtrar trabajadores por ciudad/región.
class UserLocationContext {
  final String city;
  final String? region;
  final double? latitude;
  final double? longitude;

  const UserLocationContext({
    required this.city,
    this.region,
    this.latitude,
    this.longitude,
  });

  String get displayLabel {
    if (region != null && region!.isNotEmpty) {
      return '$city, $region';
    }
    return city;
  }
}

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Reloj de Chile continental. La agenda y la disponibilidad usan este huso,
/// no el del teléfono.
class SantiagoTime {
  SantiagoTime._();

  static const String locationName = 'America/Santiago';
  static bool _ready = false;

  static void ensureInitialized() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  static tz.Location get location {
    ensureInitialized();
    return tz.getLocation(locationName);
  }

  /// Instantáneo absoluto expresado en la hora civil de Santiago.
  static DateTime wall(DateTime instant) {
    final zoned = tz.TZDateTime.from(instant.toUtc(), location);
    return DateTime(
      zoned.year,
      zoned.month,
      zoned.day,
      zoned.hour,
      zoned.minute,
      zoned.second,
    );
  }

  static DateTime day(DateTime instant) {
    final local = wall(instant);
    return DateTime(local.year, local.month, local.day);
  }
}

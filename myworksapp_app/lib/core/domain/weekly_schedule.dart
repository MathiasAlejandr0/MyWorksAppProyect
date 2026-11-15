import '../utils/santiago_time.dart';

/// Un día de la semana ISO (1 = lunes … 7 = domingo) con un rango horario.
class DayWindow {
  const DayWindow({
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    this.enabled = true,
  });

  final int weekday;
  final int startMinute;
  final int endMinute;
  final bool enabled;

  bool containsMinute(int minute) =>
      enabled &&
      startMinute < endMinute &&
      minute >= startMinute &&
      minute < endMinute;

  DayWindow copyWith({
    int? weekday,
    int? startMinute,
    int? endMinute,
    bool? enabled,
  }) {
    return DayWindow(
      weekday: weekday ?? this.weekday,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Horario semanal del profesional. Si [enabled] es falso, o no hay días,
/// no restringe búsquedas ni reservas: se respeta solo el interruptor
/// «disponible» que ya existía.
class WeeklySchedule {
  const WeeklySchedule({required this.enabled, this.days = const []});

  final bool enabled;
  final List<DayWindow> days;

  bool get restricts => enabled && days.isNotEmpty;

  DayWindow? windowFor(int weekday) {
    for (final day in days) {
      if (day.weekday == weekday) return day;
    }
    return null;
  }

  static WeeklySchedule weekdaysNineToSix() {
    final days = <DayWindow>[
      for (var day = 1; day <= 5; day++)
        DayWindow(
          weekday: day,
          startMinute: 9 * 60,
          endMinute: 18 * 60,
        ),
      for (var day = 6; day <= 7; day++)
        DayWindow(
          weekday: day,
          startMinute: 9 * 60,
          endMinute: 13 * 60,
          enabled: false,
        ),
    ];
    return WeeklySchedule(enabled: true, days: days);
  }
}

/// «Disponible ahora»: el interruptor manual y, si hay horario activo, la
/// hora civil de Santiago.
bool countsAsAvailableNow({
  required bool manuallyAvailable,
  WeeklySchedule? schedule,
  required DateTime instant,
}) {
  if (!manuallyAvailable) return false;
  if (schedule == null || !schedule.restricts) return true;
  final wall = SantiagoTime.wall(instant);
  final window = schedule.windowFor(wall.weekday);
  if (window == null) return false;
  return window.containsMinute(wall.hour * 60 + wall.minute);
}

/// Null si la fecha civil se puede reservar. El día se lee de año/mes/día,
/// sin convertir por la zona del teléfono.
String? scheduleBlocksCivilDay(WeeklySchedule? schedule, DateTime civil) {
  if (schedule == null || !schedule.restricts) return null;
  final weekday = DateTime(civil.year, civil.month, civil.day).weekday;
  final window = schedule.windowFor(weekday);
  if (window == null || !window.enabled) {
    return 'Este profesional no atiende ese día';
  }
  return null;
}

/// Si el horario está activo, la reserva queda a la hora de inicio de ese día.
DateTime applyScheduleStart(WeeklySchedule? schedule, DateTime civil) {
  if (schedule == null || !schedule.restricts) return civil;
  final date = DateTime(civil.year, civil.month, civil.day);
  final window = schedule.windowFor(date.weekday);
  if (window == null || !window.enabled) return civil;
  return DateTime(
    date.year,
    date.month,
    date.day,
    window.startMinute ~/ 60,
    window.startMinute % 60,
  );
}

String formatMinute(int minute) {
  final hour = (minute ~/ 60).toString().padLeft(2, '0');
  final mins = (minute % 60).toString().padLeft(2, '0');
  return '$hour:$mins';
}

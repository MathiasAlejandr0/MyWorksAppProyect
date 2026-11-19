import 'dart:math' as math;

import '../utils/santiago_time.dart';
import 'worker_hours.dart';

/// Tramo continuo dentro de un día, en minutos desde medianoche.
class TimeRange {
  const TimeRange({required this.startMinute, required this.endMinute});

  final int startMinute;
  final int endMinute;

  bool get isValid => startMinute < endMinute;

  bool containsMinute(int minute) =>
      isValid && minute >= startMinute && minute < endMinute;

  TimeRange copyWith({int? startMinute, int? endMinute}) {
    return TimeRange(
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
    );
  }
}

/// Un día de la semana ISO (1 = lunes … 7 = domingo) con una o más ventanas.
class DayWindow {
  const DayWindow({
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    this.enabled = true,
    this.ranges = const [],
  });

  final int weekday;
  final int startMinute;
  final int endMinute;
  final bool enabled;

  /// Vacío cuando el día tiene una sola ventana: [startMinute] y [endMinute].
  final List<TimeRange> ranges;

  List<TimeRange> get windows {
    if (ranges.isNotEmpty) return List<TimeRange>.unmodifiable(ranges);
    return [TimeRange(startMinute: startMinute, endMinute: endMinute)];
  }

  bool containsMinute(int minute) =>
      enabled && windows.any((window) => window.containsMinute(minute));

  DayWindow copyWith({
    int? weekday,
    int? startMinute,
    int? endMinute,
    bool? enabled,
    List<TimeRange>? ranges,
  }) {
    final nextRanges = ranges ?? this.ranges;
    final envelopeStart = nextRanges.isEmpty
        ? null
        : nextRanges.map((range) => range.startMinute).reduce(math.min);
    final envelopeEnd = nextRanges.isEmpty
        ? null
        : nextRanges.map((range) => range.endMinute).reduce(math.max);
    return DayWindow(
      weekday: weekday ?? this.weekday,
      startMinute: startMinute ?? envelopeStart ?? this.startMinute,
      endMinute: endMinute ?? envelopeEnd ?? this.endMinute,
      enabled: enabled ?? this.enabled,
      ranges: nextRanges,
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

/// Paso con el que una ventana se ofrece al cliente. El fin es exclusivo:
/// 09:00–13:00 publica 09:00, 10:00, 11:00 y 12:00.
const scheduleSlotStepMinutes = 60;

const weekdayNamesEs = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

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
  final start = window.windows
      .map((range) => range.startMinute)
      .reduce((a, b) => a < b ? a : b);
  return DateTime(
    date.year,
    date.month,
    date.day,
    start ~/ 60,
    start % 60,
  );
}

String formatMinute(int minute) {
  final hour = (minute ~/ 60).toString().padLeft(2, '0');
  final mins = (minute % 60).toString().padLeft(2, '0');
  return '$hour:$mins';
}

int parseClockMinute(Object? raw) {
  final text = raw?.toString() ?? '00:00';
  final parts = text.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return 0;
  return hour * 60 + minute;
}

String? overlappingWindowsMessage(List<DayWindow> days) {
  for (final day in days) {
    if (!day.enabled) continue;
    final name = day.weekday >= 1 && day.weekday <= 7
        ? weekdayNamesEs[day.weekday - 1]
        : 'Día ${day.weekday}';
    final sorted = [...day.windows]
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    for (final window in sorted) {
      if (!window.isValid) {
        return '$name: la hora de fin debe ser posterior al inicio';
      }
    }
    for (var i = 1; i < sorted.length; i++) {
      final previous = sorted[i - 1];
      final current = sorted[i];
      if (current.startMinute < previous.endMinute) {
        return '$name: las ventanas ${formatMinute(previous.startMinute)}–${formatMinute(previous.endMinute)} '
            'y ${formatMinute(current.startMinute)}–${formatMinute(current.endMinute)} se solapan';
      }
    }
  }
  return null;
}

/// Horas publicadas `{dia, hora}` que lee la reserva del cliente.
List<Map<String, dynamic>> publishedHourSlots(List<DayWindow> days) {
  final seen = <String>{};
  final slots = <Map<String, dynamic>>[];
  for (final day in days) {
    if (!day.enabled || day.weekday < 1 || day.weekday > 7) continue;
    for (final window in day.windows) {
      if (!window.isValid) continue;
      var emitted = false;
      for (var minute = window.startMinute;
          minute + scheduleSlotStepMinutes <= window.endMinute;
          minute += scheduleSlotStepMinutes) {
        final label = formatMinute(minute);
        if (seen.add('${day.weekday}|$label')) {
          slots.add({'dia': day.weekday, 'hora': label});
        }
        emitted = true;
      }
      if (!emitted) {
        final label = formatMinute(window.startMinute);
        if (seen.add('${day.weekday}|$label')) {
          slots.add({'dia': day.weekday, 'hora': label});
        }
      }
    }
  }
  slots.sort((a, b) {
    final byDay = (a['dia'] as int).compareTo(b['dia'] as int);
    return byDay != 0
        ? byDay
        : (a['hora'] as String).compareTo(b['hora'] as String);
  });
  return slots;
}

List<TimeRange> rangesFromHourLabels(Iterable<String> labels) {
  final minutes = <int>{};
  for (final label in labels) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(label.trim());
    if (match == null) continue;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null ||
        minute == null ||
        hour > 23 ||
        minute > 59) {
      continue;
    }
    minutes.add(hour * 60 + minute);
  }
  if (minutes.isEmpty) return const [];
  final sorted = minutes.toList()..sort();
  final ranges = <TimeRange>[];
  var start = sorted.first;
  var previous = sorted.first;
  for (final minute in sorted.skip(1)) {
    if (minute - previous != scheduleSlotStepMinutes) {
      ranges.add(
        TimeRange(
          startMinute: start,
          endMinute: previous + scheduleSlotStepMinutes,
        ),
      );
      start = minute;
    }
    previous = minute;
  }
  ranges.add(
    TimeRange(
      startMinute: start,
      endMinute: previous + scheduleSlotStepMinutes,
    ),
  );
  return ranges;
}

/// Arma los días desde filas de `trabajador_horarios`. Si el día está activo
/// y el JSON `horarios` trae bloques, las ventanas salen de esos bloques.
List<DayWindow> daysFromScheduleRows(List<dynamic> rows) {
  final maps = <Map<String, dynamic>>[];
  var best = const <WorkerHourSlot>[];
  for (final raw in rows) {
    if (raw is! Map) continue;
    final map = Map<String, dynamic>.from(raw);
    maps.add(map);
    final parsed = parseWorkerHours(map['horarios']);
    if (parsed.length > best.length) best = parsed;
  }

  final labels = <int, List<String>>{};
  for (final slot in best) {
    labels.putIfAbsent(slot.weekday, () => []).add(slot.time);
  }

  final byDay = <int, DayWindow>{};
  for (final map in maps) {
    final weekday = (map['dia_semana'] as num?)?.toInt();
    if (weekday == null || weekday < 1 || weekday > 7) continue;
    byDay[weekday] = _dayFromColumnsAndSlots(
      weekday: weekday,
      enabled: map['activo'] != false,
      startMinute: parseClockMinute(map['hora_inicio']),
      endMinute: parseClockMinute(map['hora_fin']),
      labels: labels[weekday] ?? const [],
    );
  }

  for (final entry in labels.entries) {
    if (byDay.containsKey(entry.key) || entry.key < 1 || entry.key > 7) {
      continue;
    }
    final ranges = rangesFromHourLabels(entry.value);
    if (ranges.isEmpty) continue;
    byDay[entry.key] = DayWindow(
      weekday: entry.key,
      startMinute: ranges.map((range) => range.startMinute).reduce(math.min),
      endMinute: ranges.map((range) => range.endMinute).reduce(math.max),
      ranges: ranges.length > 1 ? ranges : const [],
    );
  }

  final days = byDay.values.toList()
    ..sort((a, b) => a.weekday.compareTo(b.weekday));
  return days;
}

DayWindow _dayFromColumnsAndSlots({
  required int weekday,
  required bool enabled,
  required int startMinute,
  required int endMinute,
  required List<String> labels,
}) {
  final fromSlots = rangesFromHourLabels(labels);
  if (enabled && fromSlots.isNotEmpty) {
    return DayWindow(
      weekday: weekday,
      startMinute: fromSlots.map((range) => range.startMinute).reduce(math.min),
      endMinute: fromSlots.map((range) => range.endMinute).reduce(math.max),
      ranges: fromSlots.length > 1 ? fromSlots : const [],
    );
  }
  return DayWindow(
    weekday: weekday,
    startMinute: startMinute,
    endMinute: endMinute,
    enabled: enabled,
  );
}

/// Deja una sola ocurrencia de cada instante y descarta horas fuera de las
/// ventanas cuando el horario semanal está activo.
List<DateTime> slotsInsideSchedule(
  List<DateTime> slots,
  WeeklySchedule? schedule,
) {
  final unique = <String>{};
  final filtered = <DateTime>[];
  for (final slot in slots) {
    if (schedule != null && schedule.restricts) {
      final wall = SantiagoTime.wall(slot);
      final window = schedule.windowFor(wall.weekday);
      if (window == null ||
          !window.containsMinute(wall.hour * 60 + wall.minute)) {
        continue;
      }
    }
    final key = slot.toUtc().toIso8601String().substring(0, 16);
    if (!unique.add(key)) continue;
    filtered.add(slot);
  }
  filtered.sort();
  return filtered;
}

/// Columnas del índice único `(id_usuario, dia_semana)`.
const scheduleUpsertConflict = 'id_usuario,dia_semana';

/// Filas para upsert. No incluye la fila legada sin `dia_semana`.
/// `hora_inicio` y `hora_fin` cubren el día; los bloques viven en `horarios`.
List<Map<String, dynamic>> scheduleDayRows({
  required String userId,
  required List<DayWindow> days,
  required DateTime updatedAt,
}) {
  final stamp = updatedAt.toUtc().toIso8601String();
  return [
    for (final day in days)
      {
        'id_usuario': userId,
        'dia_semana': day.weekday,
        'hora_inicio': formatMinute(_envelopeStart(day)),
        'hora_fin': formatMinute(_envelopeEnd(day)),
        'activo': day.enabled,
        'actualizado_en': stamp,
      },
  ];
}

int _envelopeStart(DayWindow day) {
  final windows = day.windows.where((window) => window.isValid).toList();
  if (windows.isEmpty) return day.startMinute;
  return windows.map((window) => window.startMinute).reduce(math.min);
}

int _envelopeEnd(DayWindow day) {
  final windows = day.windows.where((window) => window.isValid).toList();
  if (windows.isEmpty) return day.endMinute;
  return windows.map((window) => window.endMinute).reduce(math.max);
}

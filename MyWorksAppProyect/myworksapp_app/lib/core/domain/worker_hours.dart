class WorkerHourSlot {
  const WorkerHourSlot({required this.weekday, required this.time});

  /// ISO-8601: 1 lunes … 7 domingo.
  final int weekday;
  final String time;

  Map<String, dynamic> toJson() => {'dia': weekday, 'hora': time};

  static const weekdayLabels = {
    1: 'Lun',
    2: 'Mar',
    3: 'Mié',
    4: 'Jue',
    5: 'Vie',
    6: 'Sáb',
    7: 'Dom',
  };

  static const duplicateMessage =
      'Esa hora ya está en tu agenda para ese día. Elige otra distinta.';

  static const slotTakenMessage =
      'Ese horario ya está reservado con este profesional. Elige otra hora.';

  static const slotUnpublishedMessage =
      'Esa hora no está publicada por el profesional. Elige un horario de su agenda.';

  static const tooManyPendingPaymentsMessage =
      'Tienes pedidos sin pagar en curso. Completa o espera a que venza uno para reservar otra hora.';
}

String? normalizeHourLabel(String raw) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.trim());
  if (match == null) return null;
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

List<WorkerHourSlot> uniqueWorkerHours(Iterable<WorkerHourSlot> slots) {
  final seen = <String>{};
  final unique = <WorkerHourSlot>[];
  for (final slot in slots) {
    final time = normalizeHourLabel(slot.time);
    if (time == null || slot.weekday < 1 || slot.weekday > 7) continue;
    final key = '${slot.weekday}|$time';
    if (!seen.add(key)) continue;
    unique.add(WorkerHourSlot(weekday: slot.weekday, time: time));
  }
  unique.sort((a, b) {
    final byDay = a.weekday.compareTo(b.weekday);
    return byDay != 0 ? byDay : a.time.compareTo(b.time);
  });
  return unique;
}

List<WorkerHourSlot> parseWorkerHours(dynamic raw) {
  if (raw is! List) return const [];
  final slots = <WorkerHourSlot>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final dia = item['dia'];
    final hora = item['hora'];
    final weekday = dia is num ? dia.toInt() : int.tryParse('$dia');
    if (weekday == null || hora is! String) continue;
    slots.add(WorkerHourSlot(weekday: weekday, time: hora));
  }
  return uniqueWorkerHours(slots);
}

String? addWorkerHourError(List<WorkerHourSlot> slots, WorkerHourSlot next) {
  final time = normalizeHourLabel(next.time);
  if (time == null || next.weekday < 1 || next.weekday > 7) {
    return 'Indica un día y una hora válidos.';
  }
  if (slots.any((item) => item.weekday == next.weekday && item.time == time)) {
    return WorkerHourSlot.duplicateMessage;
  }
  return null;
}

List<DateTime> slotsOnDate(List<DateTime> freeSlots, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return freeSlots.where((slot) {
    final local = slot.toLocal();
    return local.year == day.year &&
        local.month == day.month &&
        local.day == day.day;
  }).toList()
    ..sort();
}

/// Horas de [date] que todavía no empezaron. Una hora ya pasada no se ofrece.
List<DateTime> openSlotsOnDate(
  List<DateTime> freeSlots,
  DateTime date, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  return slotsOnDate(freeSlots, date)
      .where((slot) => slot.toLocal().isAfter(clock))
      .toList();
}

DateTime? matchingFreeSlot({
  required List<DateTime> freeSlots,
  required DateTime date,
  required int hour,
  required int minute,
}) {
  for (final slot in slotsOnDate(freeSlots, date)) {
    final local = slot.toLocal();
    if (local.hour == hour && local.minute == minute) return slot;
  }
  return null;
}

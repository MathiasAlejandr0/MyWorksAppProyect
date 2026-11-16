import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/booking_schedule.dart';
import 'package:myworksapp/core/domain/worker_hours.dart';
import 'package:myworksapp/core/utils/santiago_time.dart';

void main() {
  setUpAll(SantiagoTime.ensureInitialized);

  test('el calendario acepta hoy aunque la hora actual ya avanzó', () {
    // 18:40 en Santiago (UTC-3 en noviembre).
    final now = DateTime.utc(2026, 11, 10, 21, 40);
    final bounds = BookingSchedule.pickerBounds(
      selected: DateTime(2026, 11, 9, 23, 59),
      now: now,
      horizonDays: 90,
    );
    expect(bounds.initial.isBefore(bounds.first), isFalse);
    expect(bounds.initial.isAfter(bounds.last), isFalse);
    expect(bounds.first, DateTime(2026, 11, 10));
    expect(bounds.initial, DateTime(2026, 11, 10));
    expect(bounds.last, DateTime(2027, 2, 8));
  });

  test('«hoy» es el día de Santiago aunque el teléfono ya esté en mañana', () {
    // 22:30 del 10-nov en Santiago = 01:30 UTC del 11-nov.
    final now = DateTime.utc(2026, 11, 11, 1, 30);
    final bounds = BookingSchedule.pickerBounds(now: now, horizonDays: 90);
    expect(bounds.first, DateTime(2026, 11, 10));
    expect(bounds.initial, DateTime(2026, 11, 10));
  });

  test('una hora ya pasada no se ofrece y una libre futura sí', () {
    // Los horarios libres llegan del servidor como instantes absolutos:
    // 09:00 y 19:00 del 10-nov en Santiago.
    final morning = DateTime.utc(2026, 11, 10, 12);
    final evening = DateTime.utc(2026, 11, 10, 22);
    final now = DateTime.utc(2026, 11, 10, 18); // 15:00 en Santiago
    final day = DateTime(2026, 11, 10);
    final open = openSlotsOnDate([morning, evening], day, now: now);
    expect(open, [evening]);
    expect(
      matchingFreeSlot(freeSlots: open, date: day, hour: 9, minute: 0),
      isNull,
    );
    expect(
      matchingFreeSlot(freeSlots: open, date: day, hour: 19, minute: 0),
      evening,
    );
  });
}

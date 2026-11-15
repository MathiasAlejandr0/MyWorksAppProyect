import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/booking_schedule.dart';
import 'package:myworksapp/core/domain/worker_hours.dart';

void main() {
  test('el calendario acepta hoy aunque la hora actual ya avanzó', () {
    final now = DateTime(2026, 11, 10, 18, 40);
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

  test('una hora ya pasada no se ofrece y una libre futura sí', () {
    final morning = DateTime(2026, 11, 10, 9);
    final evening = DateTime(2026, 11, 10, 19);
    final now = DateTime(2026, 11, 10, 15);
    final open = openSlotsOnDate([morning, evening], now, now: now);
    expect(open, [evening]);
    expect(
      matchingFreeSlot(freeSlots: open, date: now, hour: 9, minute: 0),
      isNull,
    );
    expect(
      matchingFreeSlot(freeSlots: open, date: now, hour: 19, minute: 0),
      evening,
    );
  });
}

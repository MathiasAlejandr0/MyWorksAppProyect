import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/worker_hours.dart';

void main() {
  group('uniqueWorkerHours', () {
    test('no duplica el mismo día y la misma hora', () {
      final unique = uniqueWorkerHours(const [
        WorkerHourSlot(weekday: 1, time: '9:00'),
        WorkerHourSlot(weekday: 1, time: '09:00'),
        WorkerHourSlot(weekday: 1, time: '14:00'),
      ]);
      expect(unique.map((slot) => slot.time), ['09:00', '14:00']);
    });
  });

  test('addWorkerHourError avisa si la hora ya existe', () {
    const current = [WorkerHourSlot(weekday: 5, time: '18:00')];
    expect(
      addWorkerHourError(current, const WorkerHourSlot(weekday: 5, time: '18:00')),
      WorkerHourSlot.duplicateMessage,
    );
    expect(
      addWorkerHourError(current, const WorkerHourSlot(weekday: 5, time: '09:00')),
      isNull,
    );
  });

  test('slotsOnDate usa el día de Santiago y no mezcla días', () {
    // 23:30 del 12-nov en Santiago = 02:30 UTC del 13-nov.
    final slot = DateTime.utc(2026, 11, 13, 2, 30);
    expect(slotsOnDate([slot], DateTime(2026, 11, 12)), hasLength(1));
    expect(slotsOnDate([slot], DateTime(2026, 11, 13)), isEmpty);
  });
}

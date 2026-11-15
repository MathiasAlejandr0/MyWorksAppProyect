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

  test('slotsOnDate usa la fecha local y no mezcla días', () {
    final slot = DateTime.now().toUtc().add(const Duration(days: 2));
    final local = slot.toLocal();
    final otherDay = local.add(const Duration(days: 1));
    expect(slotsOnDate([slot], local), hasLength(1));
    expect(slotsOnDate([slot], otherDay), isEmpty);
  });
}

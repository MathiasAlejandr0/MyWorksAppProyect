import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/weekly_schedule.dart';
import 'package:myworksapp/core/utils/santiago_time.dart';

void main() {
  setUpAll(SantiagoTime.ensureInitialized);

  test('disponible ahora exige el rango si el horario está activo', () {
    final schedule = WeeklySchedule.weekdaysNineToSix();
    final open = DateTime.utc(2026, 11, 16, 15, 0);
    final closed = DateTime.utc(2026, 11, 16, 1, 0);
    expect(
      countsAsAvailableNow(
        manuallyAvailable: true,
        schedule: schedule,
        instant: open,
      ),
      isTrue,
    );
    expect(
      countsAsAvailableNow(
        manuallyAvailable: true,
        schedule: schedule,
        instant: closed,
      ),
      isFalse,
    );
    expect(
      countsAsAvailableNow(
        manuallyAvailable: false,
        schedule: schedule,
        instant: open,
      ),
      isFalse,
    );
  });

  test('sin horario activo no restringe el día', () {
    const schedule = WeeklySchedule(enabled: false);
    expect(scheduleBlocksCivilDay(schedule, DateTime(2026, 11, 15)), isNull);
    expect(
      countsAsAvailableNow(
        manuallyAvailable: true,
        schedule: schedule,
        instant: DateTime.utc(2026, 11, 15, 3),
      ),
      isTrue,
    );
  });

  test('un domingo apagado no se puede reservar', () {
    final schedule = WeeklySchedule.weekdaysNineToSix();
    final sunday = DateTime(2026, 11, 15);
    expect(sunday.weekday, DateTime.sunday);
    expect(scheduleBlocksCivilDay(schedule, sunday), contains('no atiende'));
  });
}

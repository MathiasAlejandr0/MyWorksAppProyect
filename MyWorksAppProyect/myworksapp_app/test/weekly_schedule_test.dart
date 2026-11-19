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

  test('dos ventanas publican horas sin el hueco del mediodía', () {
    const day = DayWindow(
      weekday: 1,
      startMinute: 9 * 60,
      endMinute: 18 * 60,
      ranges: [
        TimeRange(startMinute: 9 * 60, endMinute: 13 * 60),
        TimeRange(startMinute: 15 * 60, endMinute: 18 * 60),
      ],
    );
    final slots = publishedHourSlots([day]);
    expect(
      slots.map((slot) => slot['hora']),
      ['09:00', '10:00', '11:00', '12:00', '15:00', '16:00', '17:00'],
    );
    expect(day.containsMinute(12 * 60), isTrue);
    expect(day.containsMinute(14 * 60), isFalse);
    expect(day.containsMinute(16 * 60), isTrue);
    expect(overlappingWindowsMessage([day]), isNull);
  });

  test('rechaza ventanas que se pisan', () {
    const day = DayWindow(
      weekday: 2,
      startMinute: 9 * 60,
      endMinute: 16 * 60,
      ranges: [
        TimeRange(startMinute: 9 * 60, endMinute: 13 * 60),
        TimeRange(startMinute: 12 * 60, endMinute: 16 * 60),
      ],
    );
    expect(overlappingWindowsMessage([day]), contains('se solapan'));
  });

  test('al recargar, los bloques vuelven a ser dos ventanas', () {
    final days = daysFromScheduleRows([
      {
        'dia_semana': 1,
        'hora_inicio': '09:00:00',
        'hora_fin': '18:00:00',
        'activo': true,
        'horarios': [
          {'dia': 1, 'hora': '09:00'},
          {'dia': 1, 'hora': '10:00'},
          {'dia': 1, 'hora': '11:00'},
          {'dia': 1, 'hora': '12:00'},
          {'dia': 1, 'hora': '15:00'},
          {'dia': 1, 'hora': '16:00'},
          {'dia': 1, 'hora': '17:00'},
        ],
      },
      {
        'dia_semana': 7,
        'hora_inicio': '09:00',
        'hora_fin': '13:00',
        'activo': false,
        'horarios': [
          {'dia': 1, 'hora': '09:00'},
        ],
      },
    ]);
    final monday = days.firstWhere((day) => day.weekday == 1);
    final sunday = days.firstWhere((day) => day.weekday == 7);
    expect(monday.windows.map((w) => w.startMinute), [9 * 60, 15 * 60]);
    expect(monday.windows.map((w) => w.endMinute), [13 * 60, 18 * 60]);
    expect(sunday.enabled, isFalse);
    expect(sunday.windows.single.endMinute, 13 * 60);
  });

  test('un horario nuevo de lunes a viernes publica 09:00 a 17:00', () {
    final slots = publishedHourSlots(WeeklySchedule.weekdaysNineToSix().days);
    expect(slots.where((slot) => slot['dia'] == 1).length, 9);
    expect(slots.any((slot) => slot['dia'] == 6), isFalse);
    expect(slots.first['hora'], '09:00');
    expect(slots.where((slot) => slot['dia'] == 1).last['hora'], '17:00');
  });
}

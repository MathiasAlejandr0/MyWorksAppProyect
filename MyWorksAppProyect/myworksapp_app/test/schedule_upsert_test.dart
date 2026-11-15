import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/weekly_schedule.dart';

void main() {
  test('el upsert usa un conflicto por usuario y día', () {
    expect(scheduleUpsertConflict, 'id_usuario,dia_semana');
  });

  test('arma una fila por día y no manda la fila legada sin día', () {
    final rows = scheduleDayRows(
      userId: 'user-1',
      days: const [
        DayWindow(weekday: 1, startMinute: 9 * 60, endMinute: 18 * 60),
        DayWindow(
          weekday: 7,
          startMinute: 10 * 60,
          endMinute: 13 * 60,
          enabled: false,
        ),
      ],
      updatedAt: DateTime.utc(2026, 11, 15, 12),
    );

    expect(rows, hasLength(2));
    expect(rows.map((row) => row['dia_semana']), [1, 7]);
    expect(rows.every((row) => row['id_usuario'] == 'user-1'), isTrue);
    expect(rows.every((row) => !row.containsKey('id')), isTrue);
    expect(rows.first['hora_inicio'], '09:00');
    expect(rows.last['activo'], isFalse);
    expect(
      rows.every((row) => row['dia_semana'] != null),
      isTrue,
    );
  });
}

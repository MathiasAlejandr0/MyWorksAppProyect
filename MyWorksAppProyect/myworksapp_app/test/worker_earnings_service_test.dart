import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/worker_earnings_snapshot.dart';
import 'package:myworksapp/core/utils/santiago_time.dart';

void main() {
  test('WorkerEarningsSnapshot.totalRecordedClp suma categorías', () {
    const snap = WorkerEarningsSnapshot(
      escrowClp: 50000,
      releasedClp: 120000,
      pendingClp: 10000,
      paymentCount: 3,
    );
    expect(snap.totalRecordedClp, 180000);
    expect(snap.growthPercent, isNull);
  });

  final now = DateTime(2026, 11, 16);

  ({int amountClp, DateTime at}) pay(int amount, DateTime at) =>
      (amountClp: amount, at: at);

  test('sin liberaciones el mes anterior no hay porcentaje', () {
    final growth = releasedMonthOverMonthPercent(
      released: [
        pay(32000, DateTime(2026, 11, 2)),
        pay(32000, DateTime(2026, 9, 20)),
      ],
      now: now,
    );
    expect(growth, isNull);
  });

  test('3 liberados el mes pasado y 5 este mes, mismo monto, es +67%', () {
    final released = [
      for (var i = 0; i < 3; i++) pay(32000, DateTime(2026, 10, 20, 10 + i)),
      for (var i = 0; i < 5; i++) pay(32000, DateTime(2026, 11, 2, 10 + i)),
    ];
    expect(
      releasedMonthOverMonthPercent(released: released, now: now),
      67,
    );
  });

  test('el mes anterior con este mes en cero es -100%', () {
    expect(
      releasedMonthOverMonthPercent(
        released: [pay(10000, DateTime(2026, 10, 4))],
        now: now,
      ),
      -100,
    );
  });

  test('montos iguales en ambos meses es 0%', () {
    expect(
      releasedMonthOverMonthPercent(
        released: [
          pay(15000, DateTime(2026, 10, 8)),
          pay(15000, DateTime(2026, 11, 3)),
        ],
        now: now,
      ),
      0,
    );
  });

  test('enero se compara con diciembre del año anterior', () {
    expect(
      releasedMonthOverMonthPercent(
        released: [
          pay(100000, DateTime(2025, 12, 18)),
          pay(112000, DateTime(2026, 1, 6)),
        ],
        now: DateTime(2026, 1, 20),
      ),
      12,
    );
  });

  test('un monto en cero no cuenta como mes con datos', () {
    expect(
      releasedMonthOverMonthPercent(
        released: [
          pay(0, DateTime(2026, 10, 2)),
          pay(40000, DateTime(2026, 11, 2)),
        ],
        now: now,
      ),
      isNull,
    );
  });

  test('las 02:30 UTC del día 1 siguen en el mes anterior en Santiago', () {
    SantiagoTime.ensureInitialized();
    final wall = SantiagoTime.wall(DateTime.utc(2026, 3, 1, 2, 30));
    expect(wall.year, 2026);
    expect(wall.month, 2);
  });
}

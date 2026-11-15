import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/worker_earnings_snapshot.dart';

void main() {
  test('WorkerEarningsSnapshot.totalRecordedClp suma categorías', () {
    const snap = WorkerEarningsSnapshot(
      escrowClp: 50000,
      releasedClp: 120000,
      pendingClp: 10000,
      paymentCount: 3,
    );
    expect(snap.totalRecordedClp, 180000);
  });
}

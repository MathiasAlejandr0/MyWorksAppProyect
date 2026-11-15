import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/utils/job_schedule_grouping.dart';
import 'package:myworksapp/core/utils/santiago_time.dart';

JobModel _job({
  required String id,
  DateTime? scheduled,
  required DateTime created,
}) {
  return JobModel(
    id: id,
    userId: 'user',
    serviceId: 'svc',
    status: 'pendiente',
    address: 'Santiago',
    scheduledDate: scheduled,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  setUpAll(SantiagoTime.ensureInitialized);

  test('agrupa por fecha programada en America/Santiago', () {
    final lateUtc = DateTime.utc(2026, 11, 15, 1, 30);
    final morning = DateTime.utc(2026, 11, 14, 15, 0);
    final groups = groupJobsBySantiagoDay([
      _job(id: 'late', scheduled: lateUtc, created: DateTime.utc(2026, 1, 1)),
      _job(
          id: 'morning', scheduled: morning, created: DateTime.utc(2026, 1, 2)),
    ]);

    expect(groups, hasLength(1));
    expect(groups.single.day, DateTime(2026, 11, 14));
    expect(groups.single.jobs.map((job) => job.id), ['morning', 'late']);
    expect(SantiagoTime.wall(lateUtc), DateTime(2026, 11, 14, 22, 30));
  });

  test('si no hay fecha programada usa la creación', () {
    final created = DateTime.utc(2026, 7, 15, 4, 0);
    final groups = groupJobsBySantiagoDay([
      _job(id: 'solo', scheduled: null, created: created),
    ]);
    expect(groups.single.day, SantiagoTime.day(created));
    expect(groups.single.jobs.single.id, 'solo');
  });
}

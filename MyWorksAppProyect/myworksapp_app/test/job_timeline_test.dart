import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/job_status_timeline.dart';

void main() {
  test('la línea marca en camino entre aceptado y en curso', () {
    expect(jobTimelineIndex('en_camino'), 2);
    expect(jobTimelineIndex('en_curso'), greaterThan(jobTimelineIndex('en_camino')));
    expect(jobTimelineIndex('cancelado'), -1);
  });
}

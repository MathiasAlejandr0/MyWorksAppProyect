import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/job_status_timeline.dart';

void main() {
  test('la línea marca en camino entre aceptado y en curso', () {
    expect(jobTimelineIndex('en_camino'), 2);
    expect(jobTimelineIndex('en_curso'), greaterThan(jobTimelineIndex('en_camino')));
    expect(jobTimelineIndex('cancelado'), -1);
  });

  test('en curso queda en el paso 4 de 6', () {
    expect(jobProgressStep('en_curso'), 4);
    expect(jobTimelineSteps, hasLength(6));
    expect(jobProgressFraction('en_curso'), closeTo(4 / 6, 0.001));
    expect(jobProgressNextStatus('en_curso'), 'esperando_aprobacion_cliente');
    expect(jobProgressFraction('completado'), 1);
    expect(jobProgressStep('cancelado'), 0);
    expect(jobProgressFraction('cancelado'), 0);
    expect(jobProgressNextStatus('completado'), isNull);
  });
}

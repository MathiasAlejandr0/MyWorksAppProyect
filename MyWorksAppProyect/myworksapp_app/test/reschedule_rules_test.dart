import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/reschedule_rules.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 12);

  group('RescheduleRules.canPropose', () {
    test('solo antes de salir en camino y con hora futura', () {
      final future = now.add(const Duration(days: 1));
      expect(
        RescheduleRules.canPropose(
            status: 'aceptado', scheduledAt: future, workerId: 'w', now: now),
        isTrue,
      );
      expect(
        RescheduleRules.canPropose(
            status: 'en_camino', scheduledAt: future, workerId: 'w', now: now),
        isFalse,
      );
      expect(
        RescheduleRules.canPropose(
            status: 'pendiente',
            scheduledAt: now.subtract(const Duration(hours: 1)),
            workerId: 'w',
            now: now),
        isFalse,
      );
      expect(
        RescheduleRules.canPropose(
            status: 'pendiente', scheduledAt: future, workerId: null, now: now),
        isFalse,
      );
    });
  });

  test('slotOptions descarta la hora actual y las de menos de 1 h', () {
    final current = now.add(const Duration(days: 1));
    final soon = now.add(const Duration(minutes: 30));
    final later = now.add(const Duration(days: 2));
    final options =
        RescheduleRules.slotOptions([later, current, soon], current, now: now);
    expect(options, [later]);
  });

  test('responde solo la otra parte y solo si está pendiente', () {
    final proposal = RescheduleProposal.fromMap({
      'id': 'r1',
      'id_trabajo': 'j1',
      'propuesta_por': 'cliente-1',
      'rol_proponente': 'cliente',
      'fecha_anterior': '2026-11-17 14:00:00+00',
      'fecha_propuesta': '2026-11-18T15:00:00+00:00',
      'estado': 'pendiente',
      'creado_en': '2026-11-15T12:00:00+00:00',
    });
    expect(proposal.previousAt, DateTime.utc(2026, 11, 17, 14));
    expect(RescheduleRules.canRespond(proposal, 'cliente-1'), isFalse);
    expect(RescheduleRules.canRespond(proposal, 'pro-1'), isTrue);
    expect(RescheduleRules.statusLabel('vencida'), 'Venció');
  });
}

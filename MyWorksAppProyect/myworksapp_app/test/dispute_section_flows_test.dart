// DisputeSection: tarjeta abierta (acuerdo, comentario, cancelar solicitud),
// cerrada por el sistema (apelación) y los diálogos para abrir una disputa.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/dispute_model.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/dispute_section.dart';

import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<bool> _tap(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) return false;
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _pasos(t);
  return true;
}

Finder _tipo(String nombre) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == nombre);

DisputeModel _disputa(String estado, {String? origen = 'usuario'}) =>
    DisputeModel(
      id: 'd1',
      jobId: 'job-1',
      openedBy: 'user-1',
      reason: 'trabajo_incompleto',
      description: 'Quedó una llave goteando',
      status: estado,
      resolution: estado == 'resuelta' ? 'Reembolso parcial' : null,
      rule: 'R-3',
      origin: origen,
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 2),
    );

void main() {
  final llamadas = <String>[];

  Widget envolver(DisputeSection s) =>
      Scaffold(body: SingleChildScrollView(child: s));

  testWidgets('disputa abierta con acuerdo y comentario', (t) async {
    llamadas.clear();
    await smokeWidget(
      t,
      () => envolver(DisputeSection(
        dispute: _disputa('abierta'),
        canOpenDispute: false,
        isParticipant: true,
        canNegotiate: true,
        pendingAgreementType: 'reembolso_parcial',
        pendingAgreementId: 'ac-1',
        onAddComment: (c) async => llamadas.add('comentario:$c'),
        onRespondAgreement: (a) async => llamadas.add('acuerdo:$a'),
        onCancelRequest: () => llamadas.add('cancelar'),
        onAppeal: (m) async => llamadas.add('apelar'),
      )),
      interact: false,
      script: (t) async {
        await _pasos(t);
        await _tap(t, find.text('Confirmar acuerdo'));
        await _tap(t, find.text('Rechazar'));
        await _tap(t, find.text('Agregar comentario').last);
        await t.enterText(find.byType(TextField).first, 'Mando fotos');
        await _tap(t, find.text('Agregar comentario').last);
        await _tap(t, find.text('Cancelar solicitud'));
      },
    );
    expect(llamadas, contains('comentario:Mando fotos'));
  });

  for (final motivo in [null, 'corto', 'El sistema se equivocó al cerrar']) {
    testWidgets('apelación de cierre automático: $motivo', (t) async {
      llamadas.clear();
      await smokeWidget(
        t,
        () => envolver(DisputeSection(
          dispute: _disputa('resuelta', origen: 'sistema'),
          canOpenDispute: false,
          isParticipant: true,
          onAppeal: (m) async => llamadas.add('apelar:$m'),
        )),
        interact: false,
        script: (t) async {
          await _pasos(t);
          await _tap(t, find.text('Pedir revisión humana'));
          if (motivo == null) {
            await _tap(t, find.text('Cancelar'));
          } else {
            await t.enterText(find.byType(TextField).last, motivo);
            await _tap(t, find.text('Enviar'));
          }
        },
      );
    });
  }

  testWidgets('abrir disputa: volver, cancelar y flujo completo', (t) async {
    llamadas.clear();
    await smokeWidget(
      t,
      () => envolver(DisputeSection(
        dispute: null,
        canOpenDispute: true,
        isParticipant: true,
        onOpenDispute: (r, d, o) async => llamadas.add('abrir:$r:$d:$o'),
        onCancelRequest: () => llamadas.add('cancelar'),
      )),
      interact: false,
      script: (t) async {
        await _pasos(t);
        // Volver desde el primer diálogo.
        await _tap(t, find.text('Abrir disputa'));
        await _tap(t, find.text('Volver'));
        // Cancelar la solicitud desde el primer diálogo.
        await _tap(t, find.text('Abrir disputa'));
        await _tap(t, find.text('Cancelar solicitud'));
        // Elegir resultado y cancelar en el motivo.
        await _tap(t, find.text('Abrir disputa'));
        await _tap(t, _tipo('_SelectableOptionCard'));
        await _tap(t, find.text('Cancelar'));
        // Elegir resultado, motivo y cancelar el detalle.
        await _tap(t, find.text('Abrir disputa'));
        await _tap(t, _tipo('_SelectableOptionCard'));
        await _tap(t, _tipo('_SelectableOptionCard'));
        await _tap(t, find.text('Continuar'));
        await _tap(t, find.text('Cancelar'));
        // Flujo completo sin descripción y con descripción.
        for (final texto in ['', 'No terminó la instalación']) {
          await _tap(t, find.text('Abrir disputa'));
          await _tap(t, _tipo('_SelectableOptionCard').last);
          await _tap(t, _tipo('_SelectableOptionCard').last);
          await _tap(t, find.text('Continuar'));
          if (texto.isNotEmpty) {
            await t.enterText(find.byType(TextField).last, texto);
          }
          await _tap(t, find.text('Enviar disputa'));
        }
      },
    );
    expect(llamadas.where((l) => l.startsWith('abrir')), hasLength(2));
  });

  testWidgets('sin permiso para abrir no muestra nada', (t) async {
    await smokeWidget(
      t,
      () => envolver(const DisputeSection(
        dispute: null,
        canOpenDispute: false,
        isParticipant: false,
      )),
      interact: false,
      script: (t) async {
        await _pasos(t);
        expect(find.text('Abrir disputa'), findsNothing);
      },
    );
  });
}

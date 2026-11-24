import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/evidence_shutter_button.dart';

void main() {
  testWidgets('un toque dispara una foto y no empieza un video', (tester) async {
    var fotos = 0;
    var inicios = 0;
    var fines = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EvidenceShutterButton(
            onPhoto: () => fotos++,
            onVideoStart: () => inicios++,
            onVideoEnd: () => fines++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(EvidenceShutterButton.shutterKey));
    await tester.pump();

    expect(fotos, 1);
    expect(inicios, 0);
    expect(fines, 0);
  });

  testWidgets('mantener presionado graba y al soltar detiene', (tester) async {
    var fotos = 0;
    var inicios = 0;
    var fines = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EvidenceShutterButton(
            onPhoto: () => fotos++,
            onVideoStart: () => inicios++,
            onVideoEnd: () => fines++,
          ),
        ),
      ),
    );

    final centro = tester.getCenter(find.byKey(EvidenceShutterButton.shutterKey));
    final gesto = await tester.startGesture(centro);
    await tester.pump(const Duration(milliseconds: 800));
    expect(inicios, 1);
    expect(fotos, 0);

    await gesto.up();
    await tester.pump();
    expect(fines, 1);
    expect(fotos, 0);
  });

  testWidgets('muestra el indicador de grabación cuando está grabando', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EvidenceShutterButton(
            onPhoto: _noop,
            onVideoStart: _noop,
            onVideoEnd: _noop,
            isRecording: true,
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Grabando video. Suelta para detener.'),
      findsOneWidget,
    );
  });
}

void _noop() {}

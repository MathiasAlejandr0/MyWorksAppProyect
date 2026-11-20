import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/worker/presentation/widgets/worker_profile_section_card.dart';

void main() {
  testWidgets('la carta muestra el resumen y abre solo esa sección', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var editing = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: WorkerProfileSectionCard(
                icon: Icons.person_outline,
                title: 'Datos personales',
                summary: const ['Camila Soto', 'camila@correo.cl'],
                editing: editing,
                onEdit: () => setState(() => editing = true),
                onCancel: () => setState(() => editing = false),
                onSave: () => setState(() => editing = false),
                child: const TextField(
                  decoration: InputDecoration(labelText: 'Nombre completo'),
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Camila Soto'), findsOneWidget);
    expect(find.text('Nombre completo'), findsNothing);

    await tester.tap(find.text('Editar'));
    await tester.pump();

    expect(find.text('Camila Soto'), findsNothing);
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/user_role.dart';
import 'package:myworksapp/features/auth/presentation/widgets/role_selector_chips.dart';

void main() {
  testWidgets('RoleSelectorChips cambia entre Cliente y Especialista',
      (tester) async {
    var selected = UserRole.cliente;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return RoleSelectorChips(
                selected: selected,
                onChanged: (role) => setState(() => selected = role),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('Especialista'), findsOneWidget);

    await tester.tap(find.text('Especialista'));
    await tester.pump();

    expect(selected, UserRole.especialista);
  });
}

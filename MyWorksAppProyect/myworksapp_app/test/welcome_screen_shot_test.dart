import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/theme/app_theme.dart';
import 'package:myworksapp/features/role_selector/presentation/pages/welcome_page.dart';

void main() {
  testWidgets('la bienvenida pinta la marca', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const WelcomePage(),
      ),
    );
    await tester.pump();

    expect(find.text('My Works App'), findsOneWidget);
    expect(find.text('Comenzar Ahora'), findsOneWidget);
  });
}

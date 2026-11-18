import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/theme/app_colors.dart';
import 'package:myworksapp/core/theme/app_theme.dart';
import 'package:myworksapp/core/widgets/location_picker_widget.dart';

double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  group('LocationCardPalette', () {
    for (final brightness in Brightness.values) {
      final canvas = brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight;
      for (final status in LocationStatus.values) {
        test('textos legibles (≥ 4.5:1) en $brightness / $status', () {
          final p = LocationCardPalette.of(brightness, status);
          final bg = Color.alphaBlend(p.background, canvas);
          expect(_contrast(p.title, bg), greaterThanOrEqualTo(4.5));
          expect(_contrast(p.body, bg), greaterThanOrEqualTo(4.5));
          expect(_contrast(p.hint, bg), greaterThanOrEqualTo(4.5));
          expect(_contrast(p.icon, bg), greaterThanOrEqualTo(3.0));
        });
      }
    }
  });

  for (final dark in [true, false]) {
    for (final status in LocationStatus.values) {
      testWidgets(
          'el título de la tarjeta se lee en tema ${dark ? 'oscuro' : 'claro'} ($status)',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(411, 800);
        addTearDown(tester.view.reset);

        final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: LocationStatusCard(
                  status: status,
                  address: 'Puerto Montt, Los Lagos',
                  hasCoords: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final title = switch (status) {
          LocationStatus.loading => 'Detectando ubicación',
          LocationStatus.ready => 'Ubicación detectada',
          LocationStatus.error => 'Error de ubicación',
        };
        final text = tester.widget<Text>(find.text(title));
        final container = tester.widget<Container>(
          find
              .ancestor(of: find.text(title), matching: find.byType(Container))
              .first,
        );
        final decoration = container.decoration! as BoxDecoration;
        final bg = Color.alphaBlend(
          decoration.color!,
          theme.scaffoldBackgroundColor,
        );
        expect(_contrast(text.style!.color!, bg), greaterThanOrEqualTo(4.5));
      });
    }
  }
}

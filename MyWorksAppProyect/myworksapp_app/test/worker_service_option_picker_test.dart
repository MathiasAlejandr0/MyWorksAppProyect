import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/worker_model.dart';
import 'package:myworksapp/core/theme/app_colors.dart';
import 'package:myworksapp/core/theme/app_theme.dart';
import 'package:myworksapp/core/database/models/service_model.dart';
import 'package:myworksapp/features/user/presentation/widgets/worker_service_option_picker.dart';

double _luminance(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

WorkerModel _worker() => WorkerModel.fromMap({
      'id_usuario': '11111111-1111-4111-8111-000000000206',
      'profesion': 'Armador de muebles',
      'calificacion': 4.7,
      'tarifa_visita': 25000,
      'categoria_servicio': ServiceCategories.assembly,
    });

void main() {
  group('OptionCardPalette', () {
    for (final brightness in Brightness.values) {
      final canvas = brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight;
      for (final selected in [false, true]) {
        test('título y subtítulo legibles ($brightness, elegida: $selected)',
            () {
          final palette =
              OptionCardPalette.of(brightness, selected: selected);
          final bg = Color.alphaBlend(palette.background, canvas);
          expect(_contrast(palette.title, bg), greaterThanOrEqualTo(4.5));
          expect(_contrast(palette.subtitle, bg), greaterThanOrEqualTo(4.5));
          expect(_contrast(palette.icon, bg), greaterThanOrEqualTo(3.0));
        });
      }
    }
  });

  for (final dark in [false, true]) {
    testWidgets(
        'los títulos «Muebles medianos/grandes» se leen en tema ${dark ? 'oscuro' : 'claro'}',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(411, 900);
      addTearDown(tester.view.reset);

      final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: WorkerServiceOptionPicker(
                worker: _worker(),
                category: ServiceCategories.assembly,
                initialOptionId: 'small_furniture',
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final canvas = theme.scaffoldBackgroundColor;
      for (final title in [
        'Muebles pequeños',
        'Muebles medianos',
        'Muebles grandes',
      ]) {
        final text = tester.widget<Text>(find.text(title));
        final color = text.style!.color!;
        final material = tester.widget<Material>(
          find
              .ancestor(of: find.text(title), matching: find.byType(Material))
              .first,
        );
        final bg = Color.alphaBlend(material.color!, canvas);
        expect(
          _contrast(color, bg),
          greaterThanOrEqualTo(4.5),
          reason: '$title (${dark ? 'oscuro' : 'claro'})',
        );
      }
    });
  }
}

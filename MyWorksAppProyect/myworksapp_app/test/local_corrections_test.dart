import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myworksapp/core/utils/mock_reserved_slots.dart';
import 'package:myworksapp/features/user/presentation/widgets/time_slot_selector.dart';
import 'package:myworksapp/features/worker/presentation/widgets/sii_tax_info_widget.dart';
import 'package:myworksapp/utils/content_filter.dart';

void main() {
  group('ContentFilter.hasSensitiveData', () {
    test('coincide con los casos compartidos y con el script SQL', () {
      final cases = jsonDecode(
        File('../shared/src/chat/contactCases.json').readAsStringSync(),
      ) as List<dynamic>;
      final sql = File('supabase/tests/texto_tiene_contacto_casos.sql')
          .readAsStringSync();
      expect(ContentFilter.hasSensitiveData(''), isFalse);
      for (final row in cases) {
        final text = row['text'] as String;
        expect(
          ContentFilter.hasSensitiveData(text),
          row['contact'] as bool,
          reason: text,
        );
        expect(sql.contains(text), isTrue,
            reason: 'falta en el script SQL: $text');
      }
    });
  });

  group('MockReservedSlots', () {
    test('marca como ocupadas solo las horas de prueba', () {
      expect(MockReservedSlots.isReserved(const TimeOfDay(hour: 9, minute: 0)),
          isTrue);
      expect(MockReservedSlots.isReserved(const TimeOfDay(hour: 11, minute: 0)),
          isTrue);
      expect(MockReservedSlots.isReserved(const TimeOfDay(hour: 15, minute: 0)),
          isTrue);
      expect(MockReservedSlots.isReserved(const TimeOfDay(hour: 18, minute: 0)),
          isTrue);
      expect(MockReservedSlots.isReserved(const TimeOfDay(hour: 10, minute: 0)),
          isFalse);
      expect(
          mockReservedSlots, containsAll(['09:00', '11:00', '15:00', '18:00']));
    });
  });

  testWidgets('una hora ocupada avisa y no queda seleccionada', (tester) async {
    TimeOfDay? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeSlotSelector(
            selected: null,
            availableLabels: mockBookableSlots,
            reservedLabels: mockReservedSlots.toSet(),
            onChanged: (time) => picked = time,
          ),
        ),
      ),
    );

    await tester.tap(find.text('09:00'));
    await tester.pump();

    expect(find.text(MockReservedSlots.reservedMessage), findsOneWidget);
    expect(picked, isNull);

    await tester.tap(find.text('10:00'));
    await tester.pump();
    expect(picked, const TimeOfDay(hour: 10, minute: 0));
  });

  testWidgets('el formulario SII muestra campos, selector y los 3 pasos',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: SiiTaxInfoWidget())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RUT / Razón Social'), findsOneWidget);
    expect(find.text('Giro o actividad económica'), findsOneWidget);
    expect(find.text('Boleta de Honorarios Electrónica'), findsOneWidget);
    expect(find.text('Factura'), findsOneWidget);
    expect(find.textContaining('Ingresa a sii.cl'), findsOneWidget);
    expect(find.textContaining('Boletas de honorarios electrónicas'),
        findsOneWidget);
    expect(find.textContaining('monto bruto'), findsOneWidget);
  });
}

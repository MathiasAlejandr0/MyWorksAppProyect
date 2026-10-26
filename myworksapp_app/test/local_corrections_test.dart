import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myworksapp/core/utils/mock_reserved_slots.dart';
import 'package:myworksapp/features/user/presentation/widgets/time_slot_selector.dart';
import 'package:myworksapp/features/worker/presentation/widgets/sii_tax_info_widget.dart';
import 'package:myworksapp/utils/content_filter.dart';

void main() {
  group('ContentFilter.hasSensitiveData', () {
    test('detecta correos', () {
      expect(ContentFilter.hasSensitiveData('escribeme a example@email.com'), isTrue);
    });

    test('detecta móviles chilenos con distintos formatos', () {
      expect(ContentFilter.hasSensitiveData('mi celu es +56912345678'), isTrue);
      expect(ContentFilter.hasSensitiveData('+56 9 8765 4321'), isTrue);
      expect(ContentFilter.hasSensitiveData('912345678'), isTrue);
      expect(ContentFilter.hasSensitiveData('9.1234.5678'), isTrue);
      expect(ContentFilter.hasSensitiveData('9 1234 5678'), isTrue);
    });

    test('detecta palabras de evasión', () {
      expect(ContentFilter.hasSensitiveData('hablame por whatsapp'), isTrue);
      expect(ContentFilter.hasSensitiveData('te paso mi wsp'), isTrue);
      expect(ContentFilter.hasSensitiveData('llamame cuando puedas'), isTrue);
      expect(ContentFilter.hasSensitiveData('Háblame al fijo'), isTrue);
    });

    test('detecta enlaces y correos escritos con arroba', () {
      expect(ContentFilter.hasSensitiveData('mira https://wa.me/56911111111'), isTrue);
      expect(ContentFilter.hasSensitiveData('mi sitio es ejemplo.cl'), isTrue);
      expect(ContentFilter.hasSensitiveData('es ana arroba correo.cl'), isTrue);
      expect(ContentFilter.hasSensitiveData('hablame por telegram'), isTrue);
    });

    test('permite texto de trabajo sin datos de contacto', () {
      expect(
        ContentFilter.hasSensitiveData('El enchufe de la cocina no funciona'),
        isFalse,
      );
      expect(ContentFilter.hasSensitiveData(''), isFalse);
    });
  });

  group('MockReservedSlots', () {
    test('marca como ocupadas solo las horas de prueba', () {
      expect(MockReservedSlots.isReserved(const TimeOfDay(hour: 9, minute: 0)), isTrue);
      expect(MockReservedSlots.isReserved(const TimeOfDay(hour: 11, minute: 0)), isTrue);
      expect(MockReservedSlots.isReserved(const TimeOfDay(hour: 15, minute: 0)), isTrue);
      expect(MockReservedSlots.isReserved(const TimeOfDay(hour: 18, minute: 0)), isTrue);
      expect(MockReservedSlots.isReserved(const TimeOfDay(hour: 10, minute: 0)), isFalse);
      expect(mockReservedSlots, containsAll(['09:00', '11:00', '15:00', '18:00']));
    });
  });

  testWidgets('una hora ocupada avisa y no queda seleccionada', (tester) async {
    TimeOfDay? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeSlotSelector(
            selected: null,
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

  testWidgets('el formulario SII muestra campos, selector y los 3 pasos', (tester) async {
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
    expect(find.textContaining('Boletas de honorarios electrónicas'), findsOneWidget);
    expect(find.textContaining('monto bruto'), findsOneWidget);
  });
}

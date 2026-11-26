// DynamicServiceForm: campos de texto, número, selección y sí/no; valores
// iniciales, validación requerida y opcional, cambios y esquema vacío.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/service_config_model.dart';
import 'package:myworksapp/features/user/presentation/widgets/dynamic_service_form.dart';

ServiceConfigModel _config(List<Map<String, dynamic>> fields) =>
    ServiceConfigModel(
      id: 'cfg-1',
      serviceId: 'svc-1',
      configSchema: {'fields': fields},
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

const _campos = <Map<String, dynamic>>[
  {'name': 'detalle', 'type': 'text', 'label': 'Detalle', 'required': true},
  {'name': 'nota', 'type': 'text', 'label': 'Nota'},
  {'name': 'metros', 'type': 'number', 'label': 'Metros', 'required': true},
  {'name': 'pisos', 'type': 'number', 'label': 'Pisos'},
  {
    'name': 'material',
    'type': 'select',
    'label': 'Material',
    'required': true,
    'options': ['PVC', 'Cobre'],
  },
  {
    'name': 'color',
    'type': 'select',
    'label': 'Color',
    'options': ['Blanco']
  },
  {'name': 'urgente', 'type': 'boolean', 'label': 'Urgente'},
  {'name': 'libre', 'type': 'otro', 'label': 'Libre'},
];

void main() {
  for (final iniciales in [false, true]) {
    testWidgets('formulario completo (iniciales $iniciales)', (t) async {
      final key = GlobalKey<FormState>();
      final cambios = <Map<String, dynamic>>[];
      await t.pumpWidget(MaterialApp(
        theme: iniciales ? ThemeData.dark() : ThemeData.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DynamicServiceForm(
              config: _config(_campos),
              formKey: key,
              initialValues: iniciales
                  ? {
                      'detalle': 'Ya escrito',
                      'metros': 12,
                      'material': 'PVC',
                      'urgente': true,
                    }
                  : null,
              onChanged: cambios.add,
            ),
          ),
        ),
      ));
      await t.pump();
      // Validar vacío y con número inválido.
      key.currentState!.validate();
      await t.pump();
      final campos = find.byType(TextFormField);
      await t.enterText(campos.at(0), 'Cambio de llave');
      await t.enterText(campos.at(2), 'doce');
      await t.enterText(campos.at(3), 'x');
      await t.pump();
      key.currentState!.validate();
      await t.pump();
      await t.enterText(campos.at(2), '15');
      await t.enterText(campos.at(3), '2');
      await t.pump();
      await t.tap(find.byType(DropdownButtonFormField<String>).first);
      await t.pumpAndSettle();
      await t.tap(find.text('Cobre').last);
      await t.pumpAndSettle();
      await t.tap(find.byType(Switch));
      await t.pumpAndSettle();
      key.currentState!.validate();
      await t.pump();
      expect(cambios, isNotEmpty);
    });
  }

  testWidgets('sin campos no muestra nada', (t) async {
    await t.pumpWidget(MaterialApp(
      home: DynamicServiceForm(config: _config(const []), onChanged: (_) {}),
    ));
    expect(find.text('Información adicional del servicio'), findsNothing);
  });
}

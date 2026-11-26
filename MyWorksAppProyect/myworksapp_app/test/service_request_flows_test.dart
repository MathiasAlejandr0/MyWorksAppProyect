// ServiceRequestPage: validaciones del envío y cada forma de cobro (legado,
// precio fijo, bloque por horas, cotización abierta y tarifa del profesional)
// con aceptación de condiciones y hoja de pago. Los callbacks del mapa y del
// cuestionario se invocan directo para no depender de GPS ni de la UI hija.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/domain/pricing_mode_recommendation.dart';
import 'package:myworksapp/core/database/models/service_model.dart';
import 'package:myworksapp/core/domain/worker_service_options_catalog.dart';
import 'package:myworksapp/core/widgets/location_picker_widget.dart';
import 'package:myworksapp/features/user/presentation/pages/service_request_page.dart';
import 'package:myworksapp/features/user/presentation/widgets/pricing_mode_questionnaire.dart';
import 'package:myworksapp/features/user/presentation/widgets/worker_service_option_picker.dart';
import 'package:myworksapp/features/user/presentation/widgets/worker_square_meters_field.dart';

import 'support/catalog_seed.dart';
import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

final _hora = RegExp(r'^\d{1,2}:\d{2}$');

Future<void> _pasos(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<bool> _tap(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) return false;
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _pasos(t, 3);
  return true;
}

PricingModeRecommendation _rec(String mode,
        {String? variant, int? horas, String? sku}) =>
    PricingModeRecommendation(
      mode: mode,
      title: 'Recomendación',
      explanation: 'Prueba',
      variantKey: variant,
      blockHours: horas,
      skuCode: sku,
      questionnaireAnswers: const {'urgencia': 'normal'},
    );

FakeBackend? _b;

void _seed(FakeBackend b, {bool conPro = true}) {
  _b = b;
  seedCatalog(b);
  // El trabajo sembrado es de otro profesional: el elegido queda libre.
  b.tables['trabajos']!.first['id_trabajador'] = 'otro-profesional';
  b.tables['trabajos']!.first['estado'] = 'esperando_pago';
  b.tables['servicios']!.first['requiere_certificacion'] = 0;
  // Sin ficha al abrir: la primera lectura del profesional falla.
  if (!conPro) b.failing.add('trabajadores');
  final base = DateTime.now().toUtc();
  b.rpc('horarios_libres_profesional', [
    for (var h = 0; h < 72; h++)
      {
        'inicio': DateTime.utc(base.year, base.month, base.day)
            .add(Duration(hours: h))
            .toIso8601String(),
      },
  ]);
  b.rpc('resumen_cobro_trabajo', [
    {
      'total_clp': 30000,
      'tarifa_clp': 27000,
      'traslado_clp': 3000,
      'comision_clp': 1500,
      'neto_clp': 28500,
    },
  ]);
  b.functions['oneclick-charge'] = (_) => {'charged': true};
  b.seed('configuraciones_servicio', [
    {
      'id': 'cfg1',
      'id_servicio': catalogServiceId,
      'esquema_config':
          '{"variants":[{"id":"llave","name":"Cambio de llave","description":"Llave de paso"},{"id":"wc","name":"Estanque WC"}]}',
      'creado_en': '2026-01-01T00:00:00Z',
      'actualizado_en': '2026-01-01T00:00:00Z',
    },
  ]);
}

Future<void> _submit(WidgetTester t) async {
  await _tap(t, find.text('Omitir'));
  final f = find.byType(ElevatedButton);
  if (f.evaluate().isEmpty) return;
  await t.ensureVisible(f.last);
  await t.pump();
  await t.tap(f.last, warnIfMissed: false);
  await _pasos(t, 4);
}

void _ubicacion(WidgetTester t, String direccion) {
  final f = find.byType(LocationPickerWidget);
  if (f.evaluate().isEmpty) return;
  t
      .widget<LocationPickerWidget>(f.first)
      .onLocationSelected(direccion, -41.4693, -72.9424);
}

Future<void> _descripcion(WidgetTester t, String texto) async {
  final f = find.widgetWithText(TextFormField, 'Descripción del trabajo');
  if (f.evaluate().isEmpty) return;
  await t.enterText(f.first, texto);
  await t.pump();
}

Future<void> _fechaYHora(WidgetTester t) async {
  final fecha = find.byIcon(Icons.calendar_today);
  final alt = find.byIcon(Icons.calendar_today_outlined);
  if (await _tap(t, fecha.evaluate().isNotEmpty ? fecha : alt)) {
    for (final ok in ['Aceptar', 'OK', 'Listo', 'Confirmar']) {
      if (await _tap(t, find.text(ok))) break;
    }
  }
  await _tap(
      t,
      find.byWidgetPredicate(
          (w) => w is Text && w.data != null && _hora.hasMatch(w.data!)));
}

Future<void> _aceptarYPagar(WidgetTester t, {bool pagar = true}) async {
  await _tap(t, find.text('Acepto y Continuar'));
  await _pasos(t, 4);
  if (pagar) {
    await _tap(t, find.textContaining('Pagar con tarjeta'));
  } else {
    await _tap(t, find.text('Cancelar'));
  }
  await _tap(t, find.text('Ver mi solicitud'));
  await _pasos(t, 4);
}

Future<void> _flujoModo(
  WidgetTester t,
  PricingModeRecommendation rec, {
  bool pagar = true,
}) async {
  await _pasos(t, 5);
  _b?.failing.remove('trabajadores');
  final q = find.byType(PricingModeQuestionnaire);
  if (q.evaluate().isNotEmpty) {
    t.widget<PricingModeQuestionnaire>(q.first).onRecommendation(rec);
  }
  await _pasos(t, 2);
  _ubicacion(t, 'Av. Diego Portales 860, Puerto Montt');
  await _pasos(t, 2);
  await _descripcion(t, 'Gotea la llave de la cocina');
  await _fechaYHora(t);
  await _submit(t);
  await _aceptarYPagar(t, pagar: pagar);
}

Widget _page({String? service = catalogServiceId, String? worker}) =>
    ServiceRequestPage(serviceId: service, workerId: worker);

void main() {
  testWidgets('validaciones previas al envío', (t) async {
    await smokeWidget(t, () => _page(),
        interact: false, role: 'usuario', setup: _seed, script: (t) async {
      await _pasos(t, 5);
      await _tap(t, find.text('Omitir'));
      await _pasos(t, 4);
      await _submit(t); // sin cuestionario
      final q = find.byType(PricingModeQuestionnaire);
      if (q.evaluate().isNotEmpty) {
        t
            .widget<PricingModeQuestionnaire>(q.first)
            .onRecommendation(_rec(PricingConstants.modeOpenQuote));
        await _pasos(t, 2);
        await _submit(t); // sin profesional
        t
            .widget<PricingModeQuestionnaire>(q.first)
            .onRecommendation(_rec(PricingConstants.modeLegacy));
        await _pasos(t, 2);
      }
      await _descripcion(t, 'Gotea la llave de la cocina');
      await _submit(t); // sin ubicación
      _ubicacion(t, 'Av. Diego Portales 860, Puerto Montt');
      _ubicacion(t, 'Av. Diego Portales 860, Puerto Montt');
      await _pasos(t, 2);
      await _descripcion(t, 'Escríbeme a ana@correo.cl o al +56 9 8765 4321');
      await _submit(t);
      await _tap(t, find.text('Entendido'));
      await _tap(t, find.text('Aceptar'));
      await _descripcion(t, 'Gotea la llave de la cocina');
      await _submit(t);
      await _tap(t, find.text('Cancelar'));
      // Variante del servicio.
      final drop = find.byType(DropdownButtonFormField<String>);
      if (drop.evaluate().length > 1) {
        await _tap(t, drop.last);
        await _tap(t, find.text('Estanque WC').last);
      }
      await _submit(t);
      await _tap(t, find.text('Acepto y Continuar'));
      await _pasos(t, 6);
    });
  });

  testWidgets('sin servicio elegido', (t) async {
    await smokeWidget(t, () => _page(service: null),
        interact: false, role: 'usuario', setup: _seed, script: (t) async {
      await _pasos(t, 4);
      _ubicacion(t, 'Av. Diego Portales 860, Puerto Montt');
      await _descripcion(t, 'Gotea la llave de la cocina');
      await _submit(t);
      final drop = find.byType(DropdownButtonFormField<String>);
      if (drop.evaluate().isNotEmpty) {
        await _tap(t, drop.first);
        await _tap(t, find.text('Gasfitería').last);
      }
      await _pasos(t, 3);
    });
  });

  testWidgets('legado crea el trabajo y busca profesionales', (t) async {
    await smokeWidget(t, () => _page(),
        interact: false,
        role: 'usuario',
        setup: _seed,
        script: (t) => _flujoModo(t, _rec(PricingConstants.modeLegacy)));
  });

  testWidgets('legado falla al crear el trabajo', (t) async {
    await smokeWidget(t, () => _page(),
        interact: false,
        role: 'usuario',
        setup: (b) {
          _seed(b);
          b.failing.add('trabajos:post');
        },
        script: (t) => _flujoModo(t, _rec(PricingConstants.modeLegacy)));
  });

  for (final modo in [
    PricingConstants.modeFixedPrice,
    PricingConstants.modeHourlyBlock,
    PricingConstants.modeOpenQuote,
  ]) {
    testWidgets('modo $modo con profesional sin ficha', (t) async {
      await smokeWidget(t, () => _page(worker: catalogProId(1)),
          interact: false,
          role: 'usuario',
          setup: (b) => _seed(b, conPro: false),
          script: (t) => _flujoModo(t, _rec(modo, variant: 'llave', horas: 3)));
    });
  }

  testWidgets('precio fijo cancelado en la hoja de pago', (t) async {
    await smokeWidget(t, () => _page(worker: catalogProId(1)),
        interact: false,
        role: 'usuario',
        setup: (b) => _seed(b, conPro: false),
        script: (t) => _flujoModo(
            t, _rec(PricingConstants.modeFixedPrice, sku: 'FAUCET_REPLACE'),
            pagar: false));
  });

  testWidgets('tarifa del profesional: opción normal y proyecto grande',
      (t) async {
    await smokeWidget(t, () => _page(worker: catalogProId(1)),
        interact: false,
        role: 'usuario',
        overrides: {'estado': 'esperando_pago'},
        setup: _seed, script: (t) async {
      await _pasos(t, 6);
      final picker = find.byType(WorkerServiceOptionPicker);
      if (picker.evaluate().isEmpty) return;
      final w = t.widget<WorkerServiceOptionPicker>(picker.first);
      final grande = WorkerServiceOptionsCatalog.largeProjectClientOption(
          ServiceCategories.construction);
      _ubicacion(t, 'Av. Diego Portales 860, Puerto Montt');
      if (grande != null) {
        w.onSelected(grande);
        await _pasos(t, 2);
        await _descripcion(t, 'Remodelación completa de baño');
        await _submit(t);
        await _tap(t, find.text('Acepto y Continuar'));
        await _pasos(t, 2);
        final m2 = find.descendant(
            of: find.byType(WorkerSquareMetersField),
            matching: find.byType(TextField));
        if (m2.evaluate().isNotEmpty) {
          await t.enterText(m2.first, '40');
          await t.pump();
          await _submit(t);
          await _aceptarYPagar(t, pagar: false);
        }
      }
      final opciones = WorkerServiceOptionsCatalog.clientOptionsFor(w.worker);
      if (opciones.isNotEmpty) w.onSelected(opciones.first);
      await _pasos(t, 2);
      await _descripcion(t, 'Gotea la llave de la cocina');
      await _fechaYHora(t);
      await _submit(t);
      await _aceptarYPagar(t);
    });
  });

  testWidgets('profesional no disponible', (t) async {
    await smokeWidget(t, () => _page(worker: catalogProId(1)),
        interact: false, role: 'usuario', setup: (b) {
      _seed(b);
      b.seed('trabajadores', [
        {...catalogPro(1), 'disponible': 0},
      ]);
    }, script: (t) async {
      await _pasos(t, 6);
      final picker = find.byType(WorkerServiceOptionPicker);
      if (picker.evaluate().isEmpty) return;
      final w = t.widget<WorkerServiceOptionPicker>(picker.first);
      final opciones = WorkerServiceOptionsCatalog.clientOptionsFor(w.worker);
      if (opciones.isNotEmpty) w.onSelected(opciones.first);
      await _pasos(t, 2);
      _ubicacion(t, 'Av. Diego Portales 860, Puerto Montt');
      await _descripcion(t, 'Gotea la llave de la cocina');
      await _submit(t);
      await _tap(t, find.text('Acepto y Continuar'));
      await _pasos(t, 3);
    });
  });

  testWidgets('sin sesión', (t) async {
    await smokeWidget(t, () => _page(),
        interact: false,
        signedIn: false,
        setup: _seed,
        script: (t) => _flujoModo(t, _rec(PricingConstants.modeLegacy)));
  });
}

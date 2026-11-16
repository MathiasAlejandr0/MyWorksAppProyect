import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/utils/job_display_utils.dart';
import 'package:myworksapp/core/utils/job_status_copy.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CL');
  });

  group('JobStatusCopy', () {
    test('traduce todos los estados que llegan desde la base', () {
      const estados = [
        'pendiente',
        'aceptado',
        'en_camino',
        'en_curso',
        'completado',
        'cancelado',
        'expirado',
        'no_asistio',
        'esperando_pago',
        'esperando_cotizaciones',
        'cotizacion_seleccionada',
        'pausado_orden_cambio',
        'esperando_aprobacion_cliente',
      ];
      for (final estado in estados) {
        final label = JobStatusCopy.label(estado);
        expect(JobStatusCopy.isKnown(estado), isTrue, reason: estado);
        expect(label, isNot(contains('_')), reason: estado);
        expect(JobStatusCopy.icon(estado), isNot(Icons.info_outline));
      }
    });

    test('esperando_pago y en_camino no se muestran crudos', () {
      expect(JobStatusCopy.chipLabel('esperando_pago'), 'ESPERANDO PAGO');
      expect(JobStatusCopy.label('en_camino'), 'En camino');
      expect(JobStatusCopy.icon('en_camino'), Icons.directions_car_outlined);
    });

    test('un estado desconocido no expone el valor interno', () {
      expect(JobStatusCopy.label('estado_raro'), JobStatusCopy.unknownLabel);
      expect(JobStatusCopy.icon('estado_raro'), Icons.info_outline);
    });
  });

  group('Hora del trabajo en Santiago', () {
    test('una visita 13:00 UTC se muestra 10:00 en Chile (verano)', () {
      final now = DateTime.utc(2026, 11, 1);
      final job = JobModel(
        id: 'j',
        userId: 'u',
        serviceId: 's',
        status: 'aceptado',
        address: 'x',
        scheduledDate: DateTime.utc(2026, 11, 20, 13),
        createdAt: now,
        updatedAt: now,
      );
      expect(JobDisplayUtils.dateLine(job), contains('10:00'));
    });
  });
}

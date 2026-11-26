// Flujos del detalle de trabajo: cotización abierta, horas extra, pago en
// garantía, recibo conforme o reclamo y cobros adicionales.
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_supabase.dart';
import 'support/job_detail_script.dart';
import 'support/widget_harness.dart';

Map<String, dynamic> _propuesta(String id, {String estado = 'enviada'}) => {
      'id': id,
      'id_trabajo': detailJobId,
      'id_trabajador': detailOtherId,
      'monto_total_clp': 85000,
      'descripcion': 'Cambio de llave y sifón',
      'estado': estado,
      'horas_estimadas': 3,
      'creado_en': '2026-11-20T10:00:00Z',
      'propuesta_cotizacion_items': <Object>[],
    };

Map<String, dynamic> _orden(String id, {String estado = 'pendiente'}) => {
      'id': id,
      'id_trabajo': detailJobId,
      'id_trabajador': detailOtherId,
      'tipo': 'adicional',
      'titulo': 'Cambio de cañería',
      'descripcion': 'Se encontró una fuga',
      'monto_clp': 25000,
      'estado': estado,
      'creado_en': '2026-11-20T10:00:00Z',
    };

const _abierta = {
  'modalidad_cobro': 'cotizacion_abierta',
  'metadatos_servicio': {'invited_worker_id': fakeUserId},
};

final _casos = [
  const DetailCase(
      'cotizar como profesional invitado',
      'trabajador',
      'esperando_cotizaciones',
      [
        'Responder cotización',
        'campo:Materiales (CLP)=20000',
        'campo:Mano de obra (CLP)=40000',
        'campo:Horas estimadas=3',
        'campo:Alcance y detalle del trabajo=Cambio completo de la llave',
        'Enviar propuesta',
      ],
      extra: _abierta,
      bounded: false),
  const DetailCase(
      'cotizar con error',
      'trabajador',
      'esperando_cotizaciones',
      [
        'Responder cotización',
        'campo:Materiales (CLP)=20000',
        'campo:Mano de obra (CLP)=40000',
        'campo:Alcance y detalle del trabajo=Cambio completo de la llave',
        'Enviar propuesta',
      ],
      extra: _abierta,
      failing: ['propuestas_cotizacion'],
      bounded: false),
  const DetailCase('cotizar sin invitación', 'trabajador',
      'esperando_cotizaciones', ['Responder cotización'],
      extra: {'modalidad_cobro': 'cotizacion_abierta'},
      bounded: false),
  DetailCase(
      'cliente acepta y rechaza cotización',
      'usuario',
      'esperando_cotizaciones',
      [
        'Aceptar cotización y continuar al pago',
        'Rechazar',
        'Aceptar cotización y continuar al pago',
        'Aceptar precio',
      ],
      extra: _abierta,
      seed: {
        'propuestas_cotizacion': [_propuesta('p1'), _propuesta('p2')],
      }),
  DetailCase(
      'cliente acepta cotización con error',
      'usuario',
      'esperando_cotizaciones',
      [
        'Aceptar cotización y continuar al pago',
        'Aceptar precio',
      ],
      extra: _abierta,
      seed: {
        'propuestas_cotizacion': [_propuesta('p1')],
      },
      failing: ['seleccionar_propuesta_cotizacion'],
      rpcErrors: {
        'seleccionar_propuesta_cotizacion': 'La propuesta ya no está vigente'
      }),
  const DetailCase('horas extra', 'trabajador', 'en_curso', [
    'Solicitar horas extra',
    'campo:Horas adicionales (1-8)=2',
    'Solicitar',
  ], extra: {
    'modalidad_cobro': 'bloque_horas',
    'horas_bloque': 4,
  }, bounded: false),
  const DetailCase('horas extra cancelar', 'trabajador', 'en_curso', [
    'Solicitar horas extra',
    'Cancelar',
  ], extra: {
    'modalidad_cobro': 'bloque_horas',
    'horas_bloque': 4,
  }, bounded: false),
  const DetailCase('pagar en garantía', 'usuario', 'esperando_pago',
      ['Pagar y confirmar reserva'],
      functionResult: {'url': 'https://webpay.test/x', 'token': 't'}),
  const DetailCase(
      'recibo conforme', 'usuario', 'esperando_aprobacion_cliente', [
    'Segunda confirmación: recibo conforme',
    'Cancelar',
    'Segunda confirmación: recibo conforme',
    'Liberar fondos',
  ]),
  const DetailCase(
      'recibo conforme con error',
      'usuario',
      'esperando_aprobacion_cliente',
      ['Segunda confirmación: recibo conforme', 'Liberar fondos'],
      failing: ['transicionar_trabajo', 'aprobar_finalizacion_trabajo']),
  const DetailCase(
      'no estoy conforme', 'usuario', 'esperando_aprobacion_cliente', [
    'No estoy conforme',
    'campo:Qué no quedó bien=Quedó goteando',
    'Abrir ticket',
  ], bounded: false),
  const DetailCase('cobro adicional', 'trabajador', 'en_curso', [
    'Solicitar',
    'campo:Título=Cañería extra',
    'campo:Descripción=Tramo dañado',
    'campo:Monto (CLP)=25000',
    'Enviar',
  ], bounded: false),
  const DetailCase('cobro adicional inválido', 'trabajador', 'en_curso', [
    'Solicitar',
    'campo:Título=X',
    'campo:Monto (CLP)=10',
    'Enviar',
  ], bounded: false),
  DetailCase('cliente revisa cobro adicional', 'usuario', 'en_curso', [
    'Revisar y decidir',
    'Rechazar',
    'Revisar y decidir',
    'Aprobar y pagar',
  ], seed: {
    'ordenes_cambio': [_orden('o1')],
  }, functionResult: {
    'url': 'https://webpay.test/x',
    'token': 't'
  }),
];

void main() {
  for (final c in _casos) {
    testWidgets('JobDetailPage flujo: ${c.name}', (t) async {
      await runDetailCase(t, c);
      // Regresión B1 (botones con el tema real) y B6 (diálogos sin usar
      // controladores ya liberados).
      if (c.bounded) return;
      expect(smokeBugErrors(), isEmpty);
    });
  }
}

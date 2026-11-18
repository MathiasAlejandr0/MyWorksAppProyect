import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/payout_summary.dart';
import 'package:myworksapp/core/domain/worker_charge.dart';
import 'package:myworksapp/core/domain/worker_earnings_snapshot.dart';
import 'package:myworksapp/core/services/pricing_service.dart';
import 'package:myworksapp/core/theme/app_theme.dart';
import 'package:myworksapp/features/worker/presentation/widgets/worker_earnings_summary.dart';

/// Filas como las entrega la vista `cobros_profesional` para un profesional
/// con cuatro visitas de $32.000 liberadas y transferidas y una reembolsada.
List<Map<String, dynamic>> _rows() => [
      for (var i = 0; i < 4; i++)
        {
          'id_pago': 'p$i',
          'id_trabajo': 'j$i',
          'tipo_pago': 'principal',
          'estado_pago': 'liberado',
          'bruto_clp': 32000,
          'comision_clp': 1600,
          'neto_clp': 30400,
          'estado_transferencia': 'transferido',
          'referencia_transferencia': 'ref$i',
          'liquidado_en': '2026-11-16 04:43:02.237295+00',
          'liberado_en': '2026-11-16T04:43:02Z',
          'creado_en': '2026-11-16 04:11:12.185338+00',
        },
      {
        'id_pago': 'p4',
        'id_trabajo': 'j4',
        'tipo_pago': 'principal',
        'estado_pago': 'reembolsado',
        'bruto_clp': 32000,
        'comision_clp': 1600,
        'neto_clp': 30400,
        'estado_transferencia': null,
        'creado_en': '2026-11-16T04:17:02.088Z',
      },
    ];

void main() {
  test('WorkerCharge lee bruto, comisión y neto de la vista', () {
    final charge = WorkerCharge.fromRow(_rows().first);
    expect(charge.grossClp, 32000);
    expect(charge.feeClp, 1600);
    expect(charge.netClp, 30400);
    expect(charge.settledAt, isNotNull);
    expect(charge.releasedAt, DateTime.utc(2026, 11, 16, 4, 43, 2));
  });

  test('sin neto en la fila, el neto es bruto menos comisión', () {
    final row = Map<String, dynamic>.from(_rows().first)..remove('neto_clp');
    expect(WorkerCharge.fromRow(row).netClp, 30400);
  });

  test('las ganancias suman el neto de lo liberado y guardan el desglose', () {
    final snapshot = WorkerEarningsSnapshot.fromCharges(
      _rows().map(WorkerCharge.fromRow),
      now: DateTime(2026, 11, 18),
    );
    expect(snapshot.releasedClp, 121600);
    expect(snapshot.releasedGrossClp, 128000);
    expect(snapshot.releasedFeeClp, 6400);
    expect(snapshot.escrowClp, 0);
    expect(snapshot.paymentCount, 5);
  });

  test('lo por recibir y lo transferido se informan en neto', () {
    final summary = PayoutSummary(movements: [
      for (final row in _rows())
        PayoutMovement.fromCharge(WorkerCharge.fromRow(row)),
      PayoutMovement.fromCharge(WorkerCharge.fromRow({
        'id_pago': 'p5',
        'id_trabajo': 'j5',
        'estado_pago': 'retenido',
        'bruto_clp': 50000,
        'comision_clp': 2500,
        'neto_clp': 47500,
      })),
    ]);
    expect(summary.transferredClp, 121600);
    expect(summary.transferredGrossClp, 128000);
    expect(summary.transferredFeeClp, 6400);
    expect(summary.pendingClp, 47500);
    expect(summary.pendingGrossClp, 50000);
    expect(summary.pendingFeeClp, 2500);
    expect(summary.history, hasLength(4));
  });

  test('la regla de la base coincide con la que cotiza la app', () {
    final sql = File(
      'supabase/migrations/20261118053913_cobros_profesional_neto.sql',
    ).readAsStringSync();
    expect(sql, contains('GREATEST(1000, round(p_bruto * 0.05)'));
    expect(PricingService.serviceFeeRate, 0.05);
    expect(PricingService.minServiceFeeClp, 1000);
    final pricing = PricingService.instance;
    // Mismos casos que se probaron contra comision_servicio_clp en la base.
    expect(pricing.serviceFeeFor(32000), 1600);
    expect(pricing.serviceFeeFor(19999), 1000);
    expect(pricing.serviceFeeFor(20010), 1001);
  });

  testWidgets('la tarjeta muestra el total neto y el desglose', (tester) async {
    final snapshot = WorkerEarningsSnapshot.fromCharges(
      _rows().map(WorkerCharge.fromRow),
      now: DateTime(2026, 11, 18),
    );
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: WorkerEarningsCard(data: snapshot)),
    ));
    expect(find.textContaining('121.600'), findsOneWidget);
    final breakdown = find.textContaining(
      RegExp(r'128\.000.*cobrados − .*6\.400.*de comisión'),
    );
    expect(breakdown, findsOneWidget);
  });
}

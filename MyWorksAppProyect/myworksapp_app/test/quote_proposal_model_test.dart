import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/quote_proposal_model.dart';

void main() {
  Map<String, dynamic> row() => {
        'id': 'p1',
        'id_trabajo': 'j1',
        'id_trabajador': 'w1',
        'monto_total_clp': 90000,
        'descripcion': 'Cambio de llave',
        'estado': 'enviada',
        'creado_en': '2026-11-17T10:00:00Z',
      };

  test('fromMap arma el desglose desde las líneas y las horas estimadas', () {
    final proposal = QuoteProposalModel.fromMap({
      ...row(),
      'horas_estimadas': 3,
      'propuesta_cotizacion_items': [
        {'linea': 1, 'concepto': 'materiales', 'monto': 30000},
        {'linea': 2, 'concepto': 'mano_obra', 'monto': 60000},
      ],
    });
    expect(proposal.desglose, {
      'materiales_clp': 30000,
      'mano_obra_clp': 60000,
      'horas_estimadas': 3,
    });
  });

  test('sin líneas ni horas no hay desglose', () {
    expect(QuoteProposalModel.fromMap(row()).desglose, isNull);
  });

  test('itemRows numera las líneas y toMap no escribe desglose', () {
    final proposal = QuoteProposalModel.fromMap({
      ...row(),
      'horas_estimadas': 2,
      'propuesta_cotizacion_items': [
        {'linea': 1, 'concepto': 'mano_obra', 'monto': 60000},
      ],
    });
    expect(proposal.itemRows(), [
      {'id_propuesta': 'p1', 'linea': 1, 'concepto': 'mano_obra', 'monto': 60000},
    ]);
    final map = proposal.toMap();
    expect(map.containsKey('desglose'), isFalse);
    expect(map['horas_estimadas'], 2);
  });
}

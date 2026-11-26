// Cotizaciones abiertas (QuoteProposalService) contra el backend Supabase
// falso: validaciones de submit, selección por el cliente y retiro.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/services/quote_proposal_service.dart';
import 'package:myworksapp/core/utils/app_error.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';

const _job = '00000000-0000-4000-8000-00000000j0b1';
const _worker = '00000000-0000-4000-8000-0000000000w1';
const _quote = '00000000-0000-4000-8000-0000000000q1';

Map<String, dynamic> _jobRow({
  String modo = PricingConstants.modeOpenQuote,
  String estado = PricingConstants.jobAwaitingQuotes,
  String? invitado = _worker,
}) =>
    {
      ...sampleJobModel,
      'id': _job,
      'id_usuario': fakeUserId,
      'modalidad_cobro': modo,
      'estado': estado,
      'metadatos_servicio': {
        if (invitado != null) 'invited_worker_id': invitado,
      },
    };

Map<String, dynamic> _quoteRow({
  String estado = PricingConstants.quoteSubmitted,
  String worker = _worker,
  String job = _job,
}) =>
    {
      ...sampleQuoteProposalModel,
      'id': _quote,
      'id_trabajo': job,
      'id_trabajador': worker,
      'estado': estado,
    };

Future<FakeBackend> _backend({
  Map<String, dynamic>? job,
  List<Map<String, dynamic>> quotes = const [],
}) async {
  final b = await setUpFakeSupabase(signedIn: true);
  b.seed('trabajos', [if (job != null) job]);
  b.seed('propuestas_cotizacion', quotes);
  b.rpc('obtener_trabajo_sin_direccion', null);
  return b;
}

final _svc = QuoteProposalService.instance;

Future<Object?> _err(Future<Object?> Function() f) async {
  try {
    await f();
    return null;
  } catch (e) {
    return e;
  }
}

Future<Object?> _submit({int monto = 20000, bool desglose = true}) => _err(
      () => _svc.submit(
        jobId: _job,
        workerId: _worker,
        montoTotalClp: monto,
        descripcion: '  Reparación del calefón  ',
        materialesClp: desglose ? 8000 : null,
        manoObraClp: desglose ? 12000 : null,
        horasEstimadas: desglose ? 3 : null,
      ),
    );

void main() {
  test('submit: validaciones en orden', () async {
    await _backend();
    expect(await _submit(), isA<AppError>());
    await _backend(job: _jobRow(modo: PricingConstants.modeFixedPrice));
    expect(await _submit(), isA<AppError>());
    await _backend(job: _jobRow(estado: 'aceptado'));
    expect(await _submit(), isA<AppError>());
    await _backend(job: _jobRow(invitado: 'otro'));
    expect(await _submit(), isA<AppError>());
    await _backend(job: _jobRow());
    expect(await _submit(monto: 100), isA<AppError>());
    await _backend(job: _jobRow(), quotes: [_quoteRow()]);
    expect(await _submit(), isA<AppError>());
  });

  test('submit: crea la propuesta con y sin desglose', () async {
    await _backend(job: _jobRow());
    expect(await _submit(), isNull);
    await _backend(job: _jobRow());
    expect(await _submit(desglose: false), isNull);
    await _backend(job: _jobRow());
    expect(await _svc.listForJob(_job), isA<List>());
  });

  test('selectProposal: permisos, estados y selección', () async {
    Future<Object?> sel({String client = fakeUserId}) => _err(
          () => _svc.selectProposal(
            jobId: _job,
            proposalId: _quote,
            clientUserId: client,
          ),
        );
    await _backend();
    expect(await sel(), isA<AppError>());
    await _backend(job: _jobRow());
    expect(await sel(client: 'otro'), isA<AppError>());
    await _backend(job: _jobRow(estado: 'en_curso'));
    expect(await sel(), isA<AppError>());
    await _backend(job: _jobRow());
    expect(await sel(), isNotNull);
    await _backend(job: _jobRow(), quotes: [_quoteRow(job: 'otro')]);
    expect(await sel(), isNotNull);
    await _backend(
      job: _jobRow(),
      quotes: [_quoteRow(estado: PricingConstants.quoteRejected)],
    );
    expect(await sel(), isNotNull);
    await _backend(job: _jobRow(), quotes: [_quoteRow()]);
    await sel();
    await _backend(
      job: _jobRow(estado: PricingConstants.jobQuoteSelected),
      quotes: [_quoteRow(estado: PricingConstants.quoteAccepted)],
    );
    await sel();
  });

  test('withdraw: no encontrada, sin permiso, estado y retiro', () async {
    Future<Object?> wd({String worker = _worker}) =>
        _err(() => _svc.withdraw(proposalId: _quote, workerId: worker));
    await _backend();
    expect(await wd(), isA<AppError>());
    await _backend(quotes: [_quoteRow()]);
    expect(await wd(worker: 'otro'), isA<AppError>());
    await _backend(
      quotes: [_quoteRow(estado: PricingConstants.quoteRejected)],
    );
    expect(await wd(), isA<AppError>());
    await _backend(quotes: [_quoteRow()]);
    await wd();
  });
}

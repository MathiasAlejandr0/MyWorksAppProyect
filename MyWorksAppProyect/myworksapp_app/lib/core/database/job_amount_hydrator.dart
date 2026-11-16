import '../services/job_price.dart';
import 'models/job_model.dart';
import 'models/payment_model.dart';
import 'supabase_db.dart';

/// Completa [JobModel.recordedAmountClp] con el monto real de un pago o
/// una cotización cuando el snapshot o los metadatos no lo traen.
Future<List<JobModel>> hydrateJobKnownAmounts(List<JobModel> jobs) async {
  if (jobs.isEmpty) return jobs;

  final missing = <String>[];
  for (final job in jobs) {
    if (_alreadyPriced(job)) continue;
    missing.add(job.id);
  }
  if (missing.isEmpty) return jobs;

  final amounts = <String, int>{};
  try {
    amounts.addAll(await _amountsFromPayments(missing));
  } catch (_) {
    // Si RLS oculta los pagos, se intenta con las cotizaciones.
  }
  final still = missing.where((id) => !amounts.containsKey(id)).toList();
  if (still.isNotEmpty) {
    try {
      amounts.addAll(await _amountsFromQuotes(still, jobs));
    } catch (_) {}
  }
  if (amounts.isEmpty) return jobs;

  return [
    for (final job in jobs)
      if (amounts[job.id] != null)
        job.copyWith(recordedAmountClp: amounts[job.id])
      else
        job,
  ];
}

bool _alreadyPriced(JobModel job) {
  return agreedJobPriceClp(
        pricingSnapshot: job.pricingSnapshot,
        serviceMetadata: job.serviceMetadata,
        recordedAmountClp: job.recordedAmountClp,
      ) !=
      null;
}

Future<Map<String, int>> _amountsFromPayments(List<String> jobIds) async {
  final rows = await supabase
      .from('pagos')
      .select(
        'id_trabajo, monto, estado, tipo_pago, id_orden_cambio, creado_en',
      )
      .inFilter('id_trabajo', jobIds)
      .gt('monto', 0);
  final best = <String, _Candidate>{};
  for (final row in rows as List) {
    final map = Map<String, dynamic>.from(row as Map);
    final jobId = map['id_trabajo'] as String?;
    final amount = (map['monto'] as num?)?.round();
    if (jobId == null || amount == null || amount <= 0) continue;
    final status = map['estado'] as String? ?? '';
    if (status == 'reembolsado') continue;
    final candidate = _Candidate(
      amount: amount,
      rank: _paymentRank(
        status: status,
        type: map['tipo_pago'] as String?,
        changeOrderId: map['id_orden_cambio'] as String?,
      ),
    );
    final current = best[jobId];
    if (current == null || candidate.rank < current.rank) {
      best[jobId] = candidate;
    }
  }
  return {for (final e in best.entries) e.key: e.value.amount};
}

Future<Map<String, int>> _amountsFromQuotes(
  List<String> jobIds,
  List<JobModel> jobs,
) async {
  final selectedByJob = {
    for (final job in jobs)
      if (job.selectedQuoteId != null) job.id: job.selectedQuoteId!,
  };
  final rows = await supabase
      .from('propuestas_cotizacion')
      .select('id, id_trabajo, monto_total_clp, estado, creado_en')
      .inFilter('id_trabajo', jobIds)
      .gt('monto_total_clp', 0);
  final best = <String, _Candidate>{};
  for (final row in rows as List) {
    final map = Map<String, dynamic>.from(row as Map);
    final jobId = map['id_trabajo'] as String?;
    final amount = (map['monto_total_clp'] as num?)?.round();
    if (jobId == null || amount == null || amount <= 0) continue;
    final id = map['id'] as String?;
    final status = map['estado'] as String? ?? '';
    final candidate = _Candidate(
      amount: amount,
      rank: _quoteRank(
        isSelected: id != null && selectedByJob[jobId] == id,
        status: status,
      ),
    );
    final current = best[jobId];
    if (current == null || candidate.rank < current.rank) {
      best[jobId] = candidate;
    }
  }
  return {for (final e in best.entries) e.key: e.value.amount};
}

class _Candidate {
  const _Candidate({required this.amount, required this.rank});
  final int amount;
  final int rank;
}

int _paymentRank({
  required String status,
  String? type,
  String? changeOrderId,
}) {
  final typeRank = (type == 'principal' || changeOrderId == null) ? 0 : 1;
  final statusRank = switch (status) {
    'liberado' => 0,
    'retenido' => 1,
    'autorizado' => 2,
    'pendiente' => 3,
    _ => 9,
  };
  return typeRank * 10 + statusRank;
}

int _quoteRank({required bool isSelected, required String status}) {
  if (isSelected) return 0;
  return switch (status) {
    'aceptada' || 'seleccionada' => 1,
    _ => 5,
  };
}

/// Elige el monto de un pago principal (para tests, sin ir a la red).
int? knownAmountFromPayments(Iterable<PaymentModel> payments) {
  _Candidate? best;
  for (final payment in payments) {
    final amount = payment.amount.round();
    if (amount <= 0) continue;
    if (payment.status == 'reembolsado') continue;
    final candidate = _Candidate(
      amount: amount,
      rank: _paymentRank(
        status: payment.status,
        type: payment.paymentType,
        changeOrderId: payment.changeOrderId,
      ),
    );
    if (best == null || candidate.rank < best.rank) best = candidate;
  }
  return best?.amount;
}

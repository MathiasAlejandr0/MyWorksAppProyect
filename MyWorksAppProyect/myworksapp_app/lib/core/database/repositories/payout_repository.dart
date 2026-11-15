import '../supabase_db.dart';
import '../../domain/payout_summary.dart';

class BankAccount {
  const BankAccount({
    required this.bank,
    required this.accountType,
    required this.accountNumber,
    required this.holderRut,
    required this.holderName,
  });

  final String bank;
  final String accountType;
  final String accountNumber;
  final String holderRut;
  final String holderName;

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      bank: map['banco'] as String? ?? '',
      accountType: map['tipo_cuenta'] as String? ?? 'vista',
      accountNumber: map['numero_cuenta'] as String? ?? '',
      holderRut: map['rut_titular'] as String? ?? '',
      holderName: map['nombre_titular'] as String? ?? '',
    );
  }
}

class PayoutRepository {
  Future<BankAccount?> loadAccount(String userId) async {
    final row = await supabase
        .from('cuentas_bancarias')
        .select()
        .eq('id_usuario', userId)
        .maybeSingle();
    if (row == null) return null;
    return BankAccount.fromMap(row);
  }

  Future<void> saveAccount({
    required String userId,
    required BankAccount account,
  }) async {
    final problem = validateBankAccount(
      bank: account.bank,
      accountType: account.accountType,
      accountNumber: account.accountNumber,
      holderRut: account.holderRut,
      holderName: account.holderName,
    );
    if (problem != null) throw StateError(problem);
    await supabase.from('cuentas_bancarias').upsert({
      'id_usuario': userId,
      'banco': account.bank.trim(),
      'tipo_cuenta': account.accountType,
      'numero_cuenta': account.accountNumber.replaceAll(RegExp(r'\s'), ''),
      'rut_titular': account.holderRut.trim(),
      'nombre_titular': account.holderName.trim(),
      'actualizado_en': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<PayoutSummary> summaryForWorker(String userId) async {
    final jobs = await supabase
        .from('trabajos')
        .select('id')
        .eq('id_trabajador', userId);
    final jobIds = [
      for (final row in jobs as List) (row as Map)['id'] as String,
    ];
    final payments = jobIds.isEmpty
        ? const <dynamic>[]
        : await supabase
            .from('pagos')
            .select('id, id_trabajo, monto, estado')
            .inFilter('id_trabajo', jobIds);
    final settlements = await supabase
        .from('liquidaciones')
        .select(
          'id_pago, id_trabajo, monto_clp, estado_transferencia, referencia_transferencia, creado_en',
        )
        .eq('id_trabajador', userId);
    final byPayment = <String, Map<String, dynamic>>{};
    for (final row in settlements as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final paymentId = map['id_pago'] as String?;
      if (paymentId != null) byPayment[paymentId] = map;
    }
    final movements = <PayoutMovement>[];
    for (final row in payments) {
      final map = Map<String, dynamic>.from(row as Map);
      final paymentId = map['id'] as String;
      final settlement = byPayment[paymentId];
      movements.add(
        PayoutMovement(
          paymentId: paymentId,
          jobId: map['id_trabajo'] as String? ?? '',
          amountClp: (map['monto'] as num?)?.round() ?? 0,
          paymentStatus: map['estado'] as String? ?? '',
          transferStatus: settlement?['estado_transferencia'] as String?,
          transferReference: settlement?['referencia_transferencia'] as String?,
          settledAt: settlement?['creado_en'] == null
              ? null
              : DateTime.tryParse(settlement!['creado_en'] as String),
        ),
      );
    }
    return PayoutSummary(movements: movements);
  }

  Future<List<Map<String, dynamic>>> pendingForAdmin() async {
    final payments = await supabase
        .from('pagos')
        .select('id, id_trabajo, monto, estado, creado_en')
        .inFilter('estado', ['autorizado', 'retenido', 'liberado'])
        .order('creado_en', ascending: false)
        .limit(100);
    final settlements = await supabase.from('liquidaciones').select(
        'id_pago, estado_transferencia, referencia_transferencia, id_trabajador');
    final transferred = <String>{};
    for (final row in settlements as List) {
      final map = Map<String, dynamic>.from(row as Map);
      if (map['estado_transferencia'] == 'transferido') {
        final id = map['id_pago'] as String?;
        if (id != null) transferred.add(id);
      }
    }
    return [
      for (final row in payments as List)
        if (!transferred.contains((row as Map)['id']))
          Map<String, dynamic>.from(row),
    ];
  }

  Future<void> markPaid({
    required String paymentId,
    required String reference,
    String? notes,
  }) async {
    await supabase.rpc('registrar_transferencia_profesional', params: {
      'p_id_pago': paymentId,
      'p_referencia': reference,
      'p_notas': notes,
    });
  }
}

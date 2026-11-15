import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/reschedule_rules.dart';
import '../../utils/app_error.dart';
import '../supabase_db.dart';

/// Reagendar un trabajo vía RPC (proponer / responder / retirar).
class RescheduleRepository {
  static const String _table = 'reprogramaciones_trabajo';

  Future<List<RescheduleProposal>> history(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_trabajo', jobId)
        .order('creado_en', ascending: false)
        .limit(20);
    return (rows as List)
        .map((row) =>
            RescheduleProposal.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<RescheduleProposal> propose({
    required String jobId,
    required DateTime at,
    String? reason,
  }) =>
      _call(
          'proponer_reprogramacion',
          {
            'p_trabajo_id': jobId,
            'p_fecha': at.toUtc().toIso8601String(),
            if (reason != null && reason.trim().isNotEmpty)
              'p_motivo': reason.trim(),
          },
          'No se pudo proponer la nueva hora.');

  Future<RescheduleProposal> respond(String proposalId,
          {required bool accept}) =>
      _call(
          'responder_reprogramacion',
          {
            'p_id': proposalId,
            'p_acepta': accept,
          },
          'No se pudo responder la propuesta.');

  Future<RescheduleProposal> withdraw(String proposalId) => _call(
        'retirar_reprogramacion',
        {'p_id': proposalId},
        'No se pudo retirar la propuesta.',
      );

  Future<RescheduleProposal> _call(
    String rpc,
    Map<String, dynamic> params,
    String fallback,
  ) async {
    try {
      final row = await supabase.rpc(rpc, params: params);
      return RescheduleProposal.fromMap(Map<String, dynamic>.from(row as Map));
    } on PostgrestException catch (error) {
      final message = error.message.trim();
      if (message.isEmpty ||
          RegExp('forbidden|permission|jwt', caseSensitive: false)
              .hasMatch(message)) {
        throw AppError.validation(fallback);
      }
      throw AppError.validation(message);
    }
  }
}

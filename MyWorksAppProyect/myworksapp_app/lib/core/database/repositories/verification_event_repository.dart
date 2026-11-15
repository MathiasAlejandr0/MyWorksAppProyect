import '../supabase_db.dart';

class VerificationEvent {
  const VerificationEvent({
    required this.status,
    required this.createdAt,
    this.note,
  });

  final String status;
  final String? note;
  final DateTime createdAt;
}

class VerificationEventRepository {
  Future<List<VerificationEvent>> history(String userId) async {
    final rows = await supabase
        .from('verificacion_eventos')
        .select('estado, nota, creado_en')
        .eq('id_usuario', userId)
        .order('creado_en', ascending: true);
    return [
      for (final row in rows as List)
        VerificationEvent(
          status: (row as Map)['estado'] as String? ?? 'pendiente',
          note: row['nota'] as String?,
          createdAt: DateTime.tryParse(row['creado_en'] as String? ?? '') ??
              DateTime.now(),
        ),
    ];
  }
}

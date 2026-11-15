import '../supabase_db.dart';

class ClientReputation {
  const ClientReputation({
    required this.score,
    required this.ratings,
    required this.disputes,
  });

  final double? score;
  final int ratings;
  final int disputes;
}

class ClientRatingRepository {
  Future<ClientReputation?> fetchReputation(String clientId) async {
    final rows = await supabase.rpc('ver_reputacion_cliente', params: {
      'p_cliente': clientId,
    });
    if (rows is! List || rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    return ClientReputation(
      score: (row['reputacion'] as num?)?.toDouble(),
      ratings: (row['calificaciones'] as num?)?.toInt() ?? 0,
      disputes: (row['disputas'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> rateClient({
    required String jobId,
    required int score,
    String? comment,
  }) async {
    await supabase.rpc('calificar_cliente', params: {
      'p_trabajo_id': jobId,
      'p_puntaje': score,
      'p_comentario': comment,
    });
  }
}

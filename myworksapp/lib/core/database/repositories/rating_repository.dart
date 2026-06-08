import '../models/rating_model.dart';
import '../models/worker_review_model.dart';
import '../supabase_db.dart';

class RatingRepository {
  static const String _table = 'ratings';

  Future<void> createRating(RatingModel rating) async {
    await supabase.from(_table).insert(rating.toMap());
  }

  Future<RatingModel?> getRatingByJobId(String jobId) async {
    final row =
        await supabase.from(_table).select().eq('jobId', jobId).maybeSingle();
    if (row == null) return null;
    return RatingModel.fromMap(row);
  }

  Future<List<RatingModel>> getRatingsByWorkerId(String workerId) async {
    final rows = await _fetchRatingRowsForWorker(workerId);
    return rows.map<RatingModel>((m) => RatingModel.fromMap(m)).toList();
  }

  Future<double> getAverageRatingByWorkerId(String workerId) async {
    final ratings = await getRatingsByWorkerId(workerId);
    if (ratings.isEmpty) return 0.0;
    final total = ratings.fold<int>(0, (sum, r) => sum + r.score);
    return total / ratings.length;
  }

  /// Obtiene todas las calificaciones donde el usuario es el calificador
  Future<List<RatingModel>> getRatingsByUserId(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('userId', userId)
        .order('createdAt', ascending: false);
    return rows.map<RatingModel>((m) => RatingModel.fromMap(m)).toList();
  }

  /// Reseñas públicas del trabajador con nombre del cliente (si existe).
  Future<List<WorkerReviewModel>> getWorkerReviewsForProfile(
    String workerId, {
    int limit = 20,
  }) async {
    final rows = await _fetchRatingRowsForWorker(workerId, limit: limit);
    final ratings =
        rows.map<RatingModel>((m) => RatingModel.fromMap(m)).toList();
    if (ratings.isEmpty) return [];

    final reviewerIds = ratings
        .map((r) => r.userId)
        .whereType<String>()
        .toSet()
        .toList();

    final namesByUserId = <String, String>{};
    if (reviewerIds.isNotEmpty) {
      final profiles = await supabase
          .from('profiles')
          .select('id, name')
          .inFilter('id', reviewerIds);
      for (final profile in profiles) {
        final id = profile['id'] as String?;
        final name = profile['name'] as String?;
        if (id != null && name != null && name.trim().isNotEmpty) {
          namesByUserId[id] = name.trim();
        }
      }
    }

    return ratings
        .map(
          (rating) => WorkerReviewModel(
            id: rating.id,
            score: rating.score,
            comment: rating.comment,
            createdAt: rating.createdAt,
            reviewerName: rating.userId != null
                ? namesByUserId[rating.userId!]
                : null,
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchRatingRowsForWorker(
    String workerId, {
    int? limit,
  }) async {
    final jobIds = await _jobIdsForWorker(workerId);
    if (jobIds.isEmpty) return [];

    var query = supabase
        .from(_table)
        .select()
        .inFilter('jobId', jobIds)
        .order('createdAt', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final rows = await query;
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<String>> _jobIdsForWorker(String workerId) async {
    final jobs = await supabase
        .from('jobs')
        .select('id')
        .eq('workerId', workerId)
        .eq('status', 'completed');
    return jobs.map<String>((m) => m['id'] as String).toList();
  }
}

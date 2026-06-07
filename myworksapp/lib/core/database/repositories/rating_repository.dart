import '../models/rating_model.dart';
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
    final jobIds = await _jobIdsForWorker(workerId);
    if (jobIds.isEmpty) return [];
    final rows = await supabase
        .from(_table)
        .select()
        .inFilter('jobId', jobIds)
        .order('createdAt', ascending: false);
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

  Future<List<String>> _jobIdsForWorker(String workerId) async {
    final jobs =
        await supabase.from('jobs').select('id').eq('workerId', workerId);
    return jobs.map<String>((m) => m['id'] as String).toList();
  }
}

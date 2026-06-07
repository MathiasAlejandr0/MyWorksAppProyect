import '../models/job_photo_model.dart';
import '../supabase_db.dart';

class JobPhotoRepository {
  static const String _table = 'job_photos';

  Future<void> createJobPhoto(JobPhotoModel photo) async {
    await supabase.from(_table).insert(photo.toMap());
  }

  Future<List<JobPhotoModel>> getPhotosByJobId(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('jobId', jobId)
        .order('createdAt', ascending: false);
    return rows.map<JobPhotoModel>((m) => JobPhotoModel.fromMap(m)).toList();
  }

  Future<void> deleteJobPhoto(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }

  Future<void> deletePhotosByJobId(String jobId) async {
    await supabase.from(_table).delete().eq('jobId', jobId);
  }

  // Contar fotos de un trabajo
  Future<int> getPhotoCountByJobId(String jobId) async {
    final rows = await supabase.from(_table).select('id').eq('jobId', jobId);
    return rows.length;
  }
}

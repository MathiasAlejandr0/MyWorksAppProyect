import '../models/job_photo_model.dart';
import '../supabase_db.dart';

class JobPhotoRepository {
  static const String _table = 'fotos_trabajo';

  Future<void> createJobPhoto(JobPhotoModel photo) async {
    await supabase.from(_table).insert(photo.toMap());
  }

  Future<List<JobPhotoModel>> getPhotosByJobId(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_trabajo', jobId)
        .order('creado_en', ascending: false);
    return rows.map<JobPhotoModel>((m) => JobPhotoModel.fromMap(m)).toList();
  }

  Future<void> deleteJobPhoto(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }

  Future<void> deletePhotosByJobId(String jobId) async {
    await supabase.from(_table).delete().eq('id_trabajo', jobId);
  }

  Future<int> getPhotoCountByJobId(String jobId) async {
    final rows = await supabase.from(_table).select('id').eq('id_trabajo', jobId);
    return rows.length;
  }

  Future<int> getEvidenceCountByJobId(String jobId) async {
    return getPhotoCountByJobId(jobId);
  }
}

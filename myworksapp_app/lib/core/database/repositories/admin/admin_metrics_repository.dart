import '../../supabase_db.dart';
import 'admin_models.dart';

class AdminMetricsRepository {
  Future<AdminMetrics> getMetrics() async {
    final results = await Future.wait([
      supabase.from('perfiles').select('id'),
      supabase.from('trabajadores').select('id_usuario'),
      supabase.from('trabajos').select('id'),
      supabase.from('disputas').select('id').eq('estado', 'abierta'),
      supabase.from('disputas').select('id').eq('estado', 'en_revision'),
      supabase.from('reportes').select('id').eq('estado', 'pendiente'),
      supabase
          .from('trabajos')
          .select('id')
          .inFilter('estado', ['pendiente', 'aceptado', 'en_curso']),
      supabase.from('registros_error_app').select('id').eq('estado', 'nuevo'),
      supabase.from('eventos_abuso').select('id').eq('resuelto', 0),
      supabase.from('acciones_pendientes').select('id').eq('estado', 'fallido'),
    ]);

    return AdminMetrics(
      usersCount: (results[0] as List).length,
      workersCount: (results[1] as List).length,
      jobsCount: (results[2] as List).length,
      openDisputesCount: (results[3] as List).length,
      underReviewDisputesCount: (results[4] as List).length,
      pendingReportsCount: (results[5] as List).length,
      activeJobsCount: (results[6] as List).length,
      newErrorsCount: (results[7] as List).length,
      unresolvedAbuseCount: (results[8] as List).length,
      failedSyncCount: (results[9] as List).length,
    );
  }
}

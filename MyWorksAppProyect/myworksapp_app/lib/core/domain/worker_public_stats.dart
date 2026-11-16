/// Cifras públicas de un profesional, con la misma definición en app, web y panel.
///
/// [averageRating] es el promedio simple de reseñas reales (null si no hay).
/// [completedJobs] son los trabajos en estado completado.
class WorkerPublicStats {
  const WorkerPublicStats({
    required this.completedJobs,
    required this.ratingCount,
    this.averageRating,
    this.isElite = false,
  });

  final double? averageRating;
  final int ratingCount;
  final int completedJobs;
  final bool isElite;

  factory WorkerPublicStats.fromMap(Map<String, dynamic> map) {
    final count = (map['n_calificaciones'] as num?)?.toInt() ?? 0;
    final raw = (map['calificacion'] as num?)?.toDouble();
    final jobs = (map['trabajos_completados'] as num?)?.toInt() ?? 0;
    final average = (count <= 0 || raw == null || raw <= 0) ? null : raw;
    return WorkerPublicStats(
      averageRating: average,
      ratingCount: count,
      completedJobs: jobs,
      isElite: map['es_elite'] == true || ((average ?? 0) >= 4.7 && jobs >= 5),
    );
  }

  /// Una decimal, o «Nuevo» cuando todavía no hay reseñas.
  static String ratingLabel(double? rating, {int? ratingCount}) {
    if (ratingCount != null && ratingCount <= 0) return 'Nuevo';
    if (rating == null || rating <= 0) return 'Nuevo';
    return rating.toStringAsFixed(1);
  }
}

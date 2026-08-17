/// Reseña pública de un trabajador, lista para mostrar en el perfil.
class WorkerReviewModel {
  const WorkerReviewModel({
    required this.id,
    required this.score,
    required this.createdAt,
    this.comment,
    this.reviewerName,
  });

  final String id;
  final int score;
  final DateTime createdAt;
  final String? comment;
  final String? reviewerName;

  String get displayReviewerName {
    final name = reviewerName?.trim();
    if (name == null || name.isEmpty) return 'Cliente verificado';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first;
    final lastInitial =
        parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
    return '${parts.first} $lastInitial.';
  }

  bool get hasComment => comment != null && comment!.trim().isNotEmpty;
}

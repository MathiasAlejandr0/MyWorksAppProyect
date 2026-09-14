class RatingModel {
  final String id;
  final String jobId;
  final String? userId;
  final int score; // 1-5
  final String? comment;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.jobId,
    this.userId,
    required this.score,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_trabajo': jobId,
      if (userId != null) 'id_usuario': userId,
      'puntaje': score,
      'comentario': comment,
      'creado_en': createdAt.toIso8601String(),
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] as String,
      jobId: map['id_trabajo'] as String,
      userId: map['id_usuario'] as String?,
      score: map['puntaje'] as int,
      comment: map['comentario'] as String?,
      createdAt: _parseDate(map['creado_en'] as String),
    );
  }

  static DateTime _parseDate(String raw) {
    final normalized = raw.contains(' ')
        ? raw.replaceFirst(' ', 'T').replaceFirst(RegExp(r'\+00$'), '+00:00')
        : raw;
    return DateTime.parse(normalized);
  }
}

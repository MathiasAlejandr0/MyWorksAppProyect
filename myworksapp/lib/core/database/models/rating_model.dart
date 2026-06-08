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
      'jobId': jobId,
      if (userId != null) 'userId': userId,
      'score': score,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] as String,
      jobId: map['jobId'] as String,
      userId: map['userId'] as String?,
      score: map['score'] as int,
      comment: map['comment'] as String?,
      createdAt: _parseDate(map['createdAt'] as String),
    );
  }

  static DateTime _parseDate(String raw) {
    final normalized = raw.contains(' ')
        ? raw.replaceFirst(' ', 'T').replaceFirst(RegExp(r'\+00$'), '+00:00')
        : raw;
    return DateTime.parse(normalized);
  }
}

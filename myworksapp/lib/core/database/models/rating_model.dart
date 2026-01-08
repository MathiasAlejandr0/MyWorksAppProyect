class RatingModel {
  final String id;
  final String jobId;
  final int score; // 1-5
  final String? comment;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.jobId,
    required this.score,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'score': score,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] as String,
      jobId: map['jobId'] as String,
      score: map['score'] as int,
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}


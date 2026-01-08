class JobPhotoModel {
  final String id;
  final String jobId;
  final String photoPath;
  final DateTime createdAt;

  JobPhotoModel({
    required this.id,
    required this.jobId,
    required this.photoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JobPhotoModel.fromMap(Map<String, dynamic> map) {
    return JobPhotoModel(
      id: map['id'] as String,
      jobId: map['jobId'] as String,
      photoPath: map['photoPath'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}


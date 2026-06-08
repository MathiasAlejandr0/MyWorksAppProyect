class JobPhotoModel {
  static const String mediaPhoto = 'photo';
  static const String mediaVideo = 'video';

  final String id;
  final String jobId;
  final String photoPath;
  final String mediaType;
  final DateTime createdAt;

  JobPhotoModel({
    required this.id,
    required this.jobId,
    required this.photoPath,
    this.mediaType = mediaPhoto,
    required this.createdAt,
  });

  bool get isVideo => mediaType == mediaVideo;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'photoPath': photoPath,
      'mediaType': mediaType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JobPhotoModel.fromMap(Map<String, dynamic> map) {
    return JobPhotoModel(
      id: map['id'] as String,
      jobId: map['jobId'] as String,
      photoPath: map['photoPath'] as String,
      mediaType: (map['mediaType'] as String?) ?? mediaPhoto,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

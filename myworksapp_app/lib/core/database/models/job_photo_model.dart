class JobPhotoModel {
  static const String mediaPhoto = 'foto';
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
      'id_trabajo': jobId,
      'ruta_foto': photoPath,
      'tipo_medio': mediaType,
      'creado_en': createdAt.toIso8601String(),
    };
  }

  factory JobPhotoModel.fromMap(Map<String, dynamic> map) {
    return JobPhotoModel(
      id: map['id'] as String,
      jobId: map['id_trabajo'] as String,
      photoPath: map['ruta_foto'] as String,
      mediaType: (map['tipo_medio'] as String?) ?? mediaPhoto,
      createdAt: DateTime.parse(map['creado_en'] as String),
    );
  }
}

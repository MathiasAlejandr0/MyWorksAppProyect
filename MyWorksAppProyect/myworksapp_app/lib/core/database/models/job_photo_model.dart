import 'dart:typed_data';

import '../../utils/bytea_codec.dart';

class JobPhotoModel {
  static const String mediaPhoto = 'foto';
  static const String mediaVideo = 'video';

  final String id;
  final String jobId;
  final String photoPath;
  final String mediaType;
  final DateTime createdAt;
  final Uint8List? webpBytes;

  JobPhotoModel({
    required this.id,
    required this.jobId,
    required this.photoPath,
    this.mediaType = mediaPhoto,
    required this.createdAt,
    this.webpBytes,
  });

  bool get isVideo => mediaType == mediaVideo;

  bool get hasRenderablePhoto =>
      !isVideo && webpBytes != null && webpBytes!.isNotEmpty;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'id_trabajo': jobId,
      'ruta_foto': photoPath.isEmpty ? 'evidencia.webp' : photoPath,
      'tipo_medio': mediaType,
      'creado_en': createdAt.toIso8601String(),
    };
    if (webpBytes != null && webpBytes!.isNotEmpty) {
      map['imagen_webp'] = encodeByteaHex(webpBytes!);
    }
    return map;
  }

  factory JobPhotoModel.fromMap(Map<String, dynamic> map) {
    return JobPhotoModel(
      id: map['id'] as String,
      jobId: map['id_trabajo'] as String,
      photoPath: (map['ruta_foto'] as String?) ?? 'evidencia.webp',
      mediaType: (map['tipo_medio'] as String?) ?? mediaPhoto,
      createdAt: DateTime.parse(map['creado_en'] as String),
      webpBytes: decodeBytea(map['imagen_webp']),
    );
  }
}

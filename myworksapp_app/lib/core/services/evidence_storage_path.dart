/// Convención de la ruta privada del bucket `evidencias`.
class EvidenceStoragePath {
  EvidenceStoragePath._();

  static const String bucket = 'evidencias';
  static const int maxImageBytes = 8 * 1024 * 1024;
  static const int maxVideoBytes = 20 * 1024 * 1024;

  static const _imageExt = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
    'image/heic': 'heic',
    'image/heif': 'heif',
  };

  static const _videoExt = {
    'video/mp4': 'mp4',
    'video/quicktime': 'mov',
    'video/webm': 'webm',
  };

  static String? mediaForMime(String mime) {
    final normalized = mime.toLowerCase().split(';').first.trim();
    if (_imageExt.containsKey(normalized)) return 'foto';
    if (_videoExt.containsKey(normalized)) return 'video';
    return null;
  }

  static String? validate({required String mime, required int byteLength}) {
    final media = mediaForMime(mime);
    if (media == null) {
      return 'Solo se aceptan fotos JPG, PNG, WEBP o videos MP4, MOV y WEBM';
    }
    if (byteLength <= 0) return 'El archivo está vacío';
    final limit = media == 'foto' ? maxImageBytes : maxVideoBytes;
    if (byteLength > limit) {
      return 'El archivo supera ${limit ~/ (1024 * 1024)} MB';
    }
    return null;
  }

  static String objectPath({
    required String jobId,
    required String userId,
    required String fileId,
    required String mime,
  }) {
    final normalized = mime.toLowerCase().split(';').first.trim();
    final ext = _imageExt[normalized] ?? _videoExt[normalized];
    if (jobId.trim().isEmpty ||
        userId.trim().isEmpty ||
        fileId.trim().isEmpty ||
        ext == null) {
      throw ArgumentError('Datos de evidencia incompletos');
    }
    if ([jobId, userId, fileId].any((part) => part.contains('/'))) {
      throw ArgumentError('El identificador no puede incluir barras');
    }
    return '${jobId.trim()}/${userId.trim()}/${fileId.trim()}.$ext';
  }

  static bool isStoragePath(String path) {
    if (path.isEmpty || path.contains('://') || path.contains(r'\')) {
      return false;
    }
    final parts = path.split('/');
    return parts.length == 3 &&
        parts.every((part) => part.isNotEmpty && !part.contains('..'));
  }
}

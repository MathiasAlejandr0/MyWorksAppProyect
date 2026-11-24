import 'dart:async';

import 'package:crypto/crypto.dart';

import 'evidence_storage_path.dart';

/// Tope de la cámara de evidencia en el plan gratuito de Storage (~720p, 30 s).
class EvidenceVideoLimits {
  static const Duration minDuration = Duration(seconds: 1);
  static const Duration maxDuration = Duration(seconds: 30);
  /// Un segundo extra por el cierre del encoder al auto-detener.
  static const int maxDurationSecondsGrace = 31;
  static const int maxBytes = EvidenceStoragePath.maxVideoBytes;
  /// ResolutionPreset.high del paquete camera (1280×720).
  static const int maxHeight = 720;

  static String? validate({
    required int byteLength,
    required Duration duration,
    String? mime,
  }) {
    if (mime != null && mime.isNotEmpty && !mime.startsWith('video/')) {
      return 'El archivo no es un video';
    }
    if (byteLength <= 0) {
      return 'El video está vacío';
    }
    if (byteLength > maxBytes) {
      return 'El video supera el tope de 20 MB';
    }
    if (duration < minDuration) {
      return 'El video es demasiado corto. Mantén presionado el disparador, o toca para una foto.';
    }
    if (duration > maxDuration + const Duration(seconds: 1)) {
      return 'El video no puede durar más de 30 segundos';
    }
    return null;
  }
}

/// Misma regla de procedencia que la foto: nonce, SHA-256 y GPS, más el tope de video.
class EvidenceVideoProvenance {
  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');

  static String? validate({
    required String nonce,
    required String hashSha256,
    required int byteLength,
    required Duration duration,
    required String mime,
    double? lat,
    double? lng,
  }) {
    if (nonce.trim().isEmpty) {
      return 'falta el nonce';
    }
    if (!_sha256.hasMatch(hashSha256.toLowerCase())) {
      return 'hash sha256 invalido';
    }
    final limits = EvidenceVideoLimits.validate(
      byteLength: byteLength,
      duration: duration,
      mime: mime,
    );
    if (limits != null) return limits;
    if (lat == null || lng == null || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return 'falta el gps de la captura';
    }
    return null;
  }
}

Future<String> sha256OfBytesStream(Stream<List<int>> bytes) async {
  final digest = await sha256.bind(bytes).first;
  return digest.toString();
}

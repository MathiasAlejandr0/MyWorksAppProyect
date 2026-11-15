import 'dart:typed_data';

Future<Uint8List> encodeEvidenceWebpFallback(Uint8List _) {
  throw StateError(
    'No se pudo convertir la evidencia a WebP en este dispositivo.',
  );
}

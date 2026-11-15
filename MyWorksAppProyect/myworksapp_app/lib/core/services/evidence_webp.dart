import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../utils/bytea_codec.dart';
import 'evidence_webp_stub.dart'
    if (dart.library.html) 'evidence_webp_web.dart'
    if (dart.library.io) 'evidence_webp_io.dart' as webp_fallback;

const int maxEvidenceWebpBytes = 380 * 1024;

Future<Uint8List> encodeEvidenceWebp(Uint8List source) async {
  if (source.isEmpty) {
    throw StateError('La imagen está vacía.');
  }

  Uint8List? last;
  for (final quality in const [72, 58, 42]) {
    final encoded = await _tryEncode(source, quality);
    if (encoded == null || !isWebpBytes(encoded)) continue;
    last = encoded;
    if (encoded.length <= maxEvidenceWebpBytes) return encoded;
  }

  if (last != null && last.length <= maxEvidenceWebpBytes * 2) {
    return last;
  }
  throw StateError('La foto quedó demasiado grande. Prueba con otra imagen.');
}

Future<Uint8List?> _tryEncode(Uint8List source, int quality) async {
  try {
    final compressed = await FlutterImageCompress.compressWithList(
      source,
      minWidth: 1280,
      minHeight: 1280,
      quality: quality,
      format: CompressFormat.webp,
      keepExif: false,
    );
    final out = Uint8List.fromList(compressed);
    if (isWebpBytes(out)) return out;
  } catch (_) {}

  try {
    final fallback = await webp_fallback.encodeEvidenceWebpFallback(source);
    if (isWebpBytes(fallback)) return fallback;
  } catch (_) {}
  return null;
}

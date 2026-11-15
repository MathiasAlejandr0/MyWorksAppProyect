// Fallback WebP en Flutter web (canvas). dart:html solo se importa en esta rama.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../utils/bytea_codec.dart';

Future<Uint8List> encodeEvidenceWebpFallback(Uint8List source) async {
  final blob = html.Blob([source]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    final image = html.ImageElement()..src = url;
    await image.onLoad.first.timeout(const Duration(seconds: 8));
    final width = image.naturalWidth;
    final height = image.naturalHeight;
    if (width <= 0 || height <= 0) {
      throw StateError('La imagen de evidencia no se pudo leer.');
    }
    const maxEdge = 1280;
    final longest = width > height ? width : height;
    final scale = longest > maxEdge ? maxEdge / longest : 1.0;
    final targetW = (width * scale).round().clamp(1, maxEdge);
    final targetH = (height * scale).round().clamp(1, maxEdge);
    final canvas = html.CanvasElement(width: targetW, height: targetH);
    canvas.context2D.drawImageScaled(image, 0, 0, targetW, targetH);
    final out = await _canvasToWebp(canvas);
    if (!isWebpBytes(out)) {
      throw StateError('El navegador no pudo generar WebP.');
    }
    return out;
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}

Future<Uint8List> _canvasToWebp(html.CanvasElement canvas) async {
  final blob = await canvas.toBlob('image/webp', 0.72);
  final reader = html.FileReader();
  final loaded = reader.onLoad.first;
  reader.readAsArrayBuffer(blob);
  await loaded.timeout(const Duration(seconds: 8));
  final result = reader.result;
  if (result is ByteBuffer) {
    return Uint8List.view(result);
  }
  if (result is Uint8List) {
    return result;
  }
  throw StateError('El navegador no pudo generar WebP.');
}

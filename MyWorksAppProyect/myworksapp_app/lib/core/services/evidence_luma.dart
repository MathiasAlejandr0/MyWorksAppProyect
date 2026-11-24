import 'dart:typed_data';
import 'dart:ui' as ui;

/// Reduce la foto de la cámara a 72 luminancias (9×8) para el dHash.
Future<Uint8List> luma9x8(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final width = image.width;
  final height = image.height;
  image.dispose();
  codec.dispose();
  if (data == null || width == 0 || height == 0) {
    throw StateError('No se pudo leer la foto');
  }
  final out = Uint8List(72);
  for (var row = 0; row < 8; row++) {
    for (var col = 0; col < 9; col++) {
      final sx = (col * width / 9).floor().clamp(0, width - 1);
      final sy = (row * height / 8).floor().clamp(0, height - 1);
      final i = (sy * width + sx) * 4;
      final r = data.getUint8(i);
      final g = data.getUint8(i + 1);
      final b = data.getUint8(i + 2);
      out[row * 9 + col] = ((r * 30 + g * 59 + b * 11) / 100).round().clamp(0, 255);
    }
  }
  return out;
}

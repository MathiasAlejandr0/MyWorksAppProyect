import 'dart:typed_data';
import 'dart:ui' as ui;

/// Recorta el borde inferior, donde suele ir el RUT del carnet.
Future<Uint8List> recortarFraccionInferior(Uint8List origen, double fraccion) async {
  final codec = await ui.instantiateImageCodec(origen);
  final frame = await codec.getNextFrame();
  final src = frame.image;
  final alto = (src.height * (1 - fraccion)).round().clamp(1, src.height);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImageRect(
    src,
    ui.Rect.fromLTWH(0, 0, src.width.toDouble(), alto.toDouble()),
    ui.Rect.fromLTWH(0, 0, src.width.toDouble(), alto.toDouble()),
    ui.Paint(),
  );
  final imagen = await recorder.endRecording().toImage(src.width, alto);
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  if (datos == null) {
    throw StateError('No se pudo recortar la foto.');
  }
  return datos.buffer.asUint8List();
}

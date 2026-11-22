import 'dart:typed_data';

import '../utils/bytea_codec.dart';

typedef Recortador = Uint8List Function(Uint8List origen, double fraccionInferior);
typedef CodificadorWebp = Future<Uint8List> Function(Uint8List origen);

/// Recorta la fracción inferior (zona habitual del RUT) y comprime a WebP.
Future<Uint8List> prepararDocumentoWebp(
  Uint8List origen, {
  required Recortador recortar,
  required CodificadorWebp aWebp,
  double fraccionInferior = 0.28,
}) async {
  if (origen.isEmpty) {
    throw StateError('La foto está vacía.');
  }
  final recorte = recortar(origen, fraccionInferior);
  final webp = await aWebp(recorte);
  if (!isWebpBytes(webp)) {
    throw StateError('La foto tiene que quedar en WebP.');
  }
  return webp;
}

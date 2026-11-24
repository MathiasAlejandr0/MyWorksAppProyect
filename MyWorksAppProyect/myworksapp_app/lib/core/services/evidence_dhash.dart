import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// dHash de 64 bits sobre 72 luminancias (9 de ancho por 8 de alto).
/// El mismo algoritmo está en Postgres (`dhash_desde_luma`) y en la web.
String dhashDesdeLuma(Uint8List luma) {
  if (luma.length != 72) {
    throw StateError('la muestra perceptual debe tener 72 bytes');
  }
  final hex = StringBuffer();
  var nibble = 0;
  var count = 0;
  for (var row = 0; row < 8; row++) {
    for (var col = 0; col < 8; col++) {
      final left = luma[row * 9 + col];
      final right = luma[row * 9 + col + 1];
      nibble = nibble * 2 + (left > right ? 1 : 0);
      count++;
      if (count == 4) {
        hex.write(nibble.toRadixString(16));
        nibble = 0;
        count = 0;
      }
    }
  }
  return hex.toString();
}

String sha256Hex(Uint8List bytes) => sha256.convert(bytes).toString();

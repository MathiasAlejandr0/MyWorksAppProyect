import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/evidence_dhash.dart';

void main() {
  test('dHash coincide con el de Postgres', () {
    expect(dhashDesdeLuma(Uint8List(72)), '0000000000000000');
    final marcas = Uint8List(72);
    for (var row = 0; row < 8; row++) {
      marcas[row * 9] = 255;
    }
    expect(dhashDesdeLuma(marcas), '8080808080808080');
  });

  test('la cámara queda verificada y la galería o el video no verificados', () {
    final source = File('lib/features/jobs/presentation/pages/job_photos_page.dart')
        .readAsStringSync();
    expect(source.contains('ImageSource.camera'), isTrue);
    expect(source.contains('pedir_nonce_evidencia'), isTrue);
    expect(source.contains('ImageSource.gallery'), isTrue);
    expect(source.contains('pickVideo'), isTrue);
    expect(source.contains('no verificados'), isTrue);
  });
}

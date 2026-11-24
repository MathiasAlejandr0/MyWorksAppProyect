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

  test('la cámara de la app queda verificada y la galería no verificada', () {
    final source = File('lib/features/jobs/presentation/pages/job_photos_page.dart')
        .readAsStringSync();
    expect(source.contains('EvidenceShutterCameraPage'), isTrue);
    expect(source.contains('registrar_evidencia_video_captura'), isTrue);
    expect(source.contains('pedir_nonce_evidencia'), isTrue);
    expect(source.contains('ImageSource.gallery'), isTrue);
    expect(source.contains('pickVideo'), isTrue);
    expect(source.contains('no verificada'), isTrue);
    expect(source.contains('no verificado'), isTrue);
    expect(source.contains('ImageSource.camera'), isFalse);
  });
}

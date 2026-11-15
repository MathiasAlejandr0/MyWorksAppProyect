import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_photo_model.dart';
import 'package:myworksapp/core/utils/bytea_codec.dart';

const tinyWebpHex =
    '524946463a00000057454250565038202e0000003002009d012a0200020001402625a00274ba01f801f800061e00009bffdbb34c63f7f789ffef60b62f197faf8000';

void main() {
  test('decodeBytea lee el hex de PostgREST', () {
    final bytes = decodeBytea('\\x$tinyWebpHex');
    expect(bytes, isNotNull);
    expect(isWebpBytes(bytes!), isTrue);
    expect(encodeByteaHex(bytes), '\\x$tinyWebpHex');
  });

  test('JobPhotoModel guarda y lee imagen_webp', () {
    final bytes = decodeBytea('\\x$tinyWebpHex')!;
    final photo = JobPhotoModel(
      id: 'p1',
      jobId: 'j1',
      photoPath: 'evidencia.webp',
      createdAt: DateTime.utc(2026, 11, 8),
      webpBytes: bytes,
    );
    final map = photo.toMap();
    expect(map['imagen_webp'], '\\x$tinyWebpHex');
    expect(map['ruta_foto'], 'evidencia.webp');

    final parsed = JobPhotoModel.fromMap({
      ...map,
      'imagen_webp': map['imagen_webp'],
    });
    expect(parsed.hasRenderablePhoto, isTrue);
    expect(parsed.webpBytes, bytes);
  });

  test('sin bytes no hay foto pintable', () {
    final photo = JobPhotoModel(
      id: 'p2',
      jobId: 'j1',
      photoPath: 'C:\\tmp\\local.jpg',
      createdAt: DateTime.utc(2026, 11, 8),
    );
    expect(photo.hasRenderablePhoto, isFalse);
    expect(photo.toMap().containsKey('imagen_webp'), isFalse);
  });

  test('lista de enteros también se decodifica', () {
    expect(decodeBytea([0x52, 0x49, 0x46, 0x46]), Uint8List.fromList([0x52, 0x49, 0x46, 0x46]));
  });
}

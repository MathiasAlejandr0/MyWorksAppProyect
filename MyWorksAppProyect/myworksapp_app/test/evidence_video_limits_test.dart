import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/evidence_storage_path.dart';
import 'package:myworksapp/core/services/evidence_video_limits.dart';

void main() {
  group('EvidenceVideoLimits', () {
    test('acepta un video de 30 s y menos de 20 MB', () {
      expect(
        EvidenceVideoLimits.validate(
          byteLength: 5 * 1024 * 1024,
          duration: const Duration(seconds: 30),
          mime: 'video/mp4',
        ),
        isNull,
      );
    });

    test('rechaza un video de más de 30 s', () {
      expect(
        EvidenceVideoLimits.validate(
          byteLength: 1024,
          duration: const Duration(seconds: 32),
          mime: 'video/mp4',
        ),
        contains('30 segundos'),
      );
    });

    test('rechaza un video que supera 20 MB', () {
      expect(
        EvidenceVideoLimits.validate(
          byteLength: EvidenceStoragePath.maxVideoBytes + 1,
          duration: const Duration(seconds: 10),
          mime: 'video/mp4',
        ),
        contains('20 MB'),
      );
    });

    test('rechaza un video demasiado corto', () {
      expect(
        EvidenceVideoLimits.validate(
          byteLength: 1024,
          duration: const Duration(milliseconds: 400),
          mime: 'video/mp4',
        ),
        contains('demasiado corto'),
      );
    });

    test('rechaza un mime que no es video', () {
      expect(
        EvidenceVideoLimits.validate(
          byteLength: 1024,
          duration: const Duration(seconds: 5),
          mime: 'image/jpeg',
        ),
        contains('no es un video'),
      );
    });

    test('el tope coincide con el de Storage y apunta a 720p / 30 s', () {
      expect(EvidenceVideoLimits.maxBytes, EvidenceStoragePath.maxVideoBytes);
      expect(EvidenceVideoLimits.maxDuration, const Duration(seconds: 30));
      expect(EvidenceVideoLimits.maxHeight, 720);
    });
  });

  group('EvidenceVideoProvenance', () {
    const hash =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

    test('acepta nonce, hash sha-256, gps y límites válidos', () {
      expect(
        EvidenceVideoProvenance.validate(
          nonce: 'nonce-de-prueba',
          hashSha256: hash,
          byteLength: 2048,
          duration: const Duration(seconds: 8),
          mime: 'video/mp4',
          lat: -41.4717,
          lng: -72.9366,
        ),
        isNull,
      );
    });

    test('rechaza un hash que no es sha-256', () {
      expect(
        EvidenceVideoProvenance.validate(
          nonce: 'nonce-de-prueba',
          hashSha256: 'no-es-un-hash',
          byteLength: 2048,
          duration: const Duration(seconds: 8),
          mime: 'video/mp4',
          lat: -41.4717,
          lng: -72.9366,
        ),
        contains('hash sha256 invalido'),
      );
    });

    test('rechaza si falta el nonce', () {
      expect(
        EvidenceVideoProvenance.validate(
          nonce: '  ',
          hashSha256: hash,
          byteLength: 2048,
          duration: const Duration(seconds: 8),
          mime: 'video/mp4',
          lat: -41.4717,
          lng: -72.9366,
        ),
        contains('nonce'),
      );
    });

    test('rechaza si falta el gps', () {
      expect(
        EvidenceVideoProvenance.validate(
          nonce: 'nonce-de-prueba',
          hashSha256: hash,
          byteLength: 2048,
          duration: const Duration(seconds: 8),
          mime: 'video/mp4',
          lat: null,
          lng: -72.9366,
        ),
        contains('gps'),
      );
    });

    test('rechaza un video fuera de los límites aunque el hash sea válido', () {
      expect(
        EvidenceVideoProvenance.validate(
          nonce: 'nonce-de-prueba',
          hashSha256: hash,
          byteLength: EvidenceStoragePath.maxVideoBytes + 10,
          duration: const Duration(seconds: 8),
          mime: 'video/mp4',
          lat: -41.4717,
          lng: -72.9366,
        ),
        contains('20 MB'),
      );
    });
  });
}

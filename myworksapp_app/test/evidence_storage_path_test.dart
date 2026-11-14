import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/evidence_storage_path.dart';

void main() {
  test('la ruta queda acotada al trabajo y al usuario', () {
    expect(
      EvidenceStoragePath.objectPath(
        jobId: 'job-1',
        userId: 'user-1',
        fileId: 'file-1',
        mime: 'image/jpeg',
      ),
      'job-1/user-1/file-1.jpg',
    );
    expect(EvidenceStoragePath.isStoragePath('job-1/user-1/file-1.jpg'), isTrue);
    expect(
      EvidenceStoragePath.isStoragePath(r'/data/user/0/foto.jpg'),
      isFalse,
    );
  });

  test('rechaza un video demasiado grande y un tipo desconocido', () {
    expect(
      EvidenceStoragePath.validate(mime: 'video/mp4', byteLength: 1024),
      isNull,
    );
    expect(
      EvidenceStoragePath.validate(
        mime: 'video/mp4',
        byteLength: 51 * 1024 * 1024,
      ),
      contains('50 MB'),
    );
    expect(
      EvidenceStoragePath.validate(mime: 'text/plain', byteLength: 10),
      contains('JPG'),
    );
  });
}

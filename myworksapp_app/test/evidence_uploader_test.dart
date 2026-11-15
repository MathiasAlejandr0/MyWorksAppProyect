import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/evidence_uploader.dart';

class _FakeGateway implements EvidenceStorageGateway {
  int uploads = 0;
  final List<String> removed = [];
  bool failInsert = false;
  int failUploads = 0;

  @override
  Future<void> insertRow(Map<String, dynamic> row) async {
    if (failInsert) throw StateError('insert');
  }

  @override
  Future<void> remove(String path) async {
    removed.add(path);
  }

  @override
  Future<String?> signedUrl(String path) async =>
      'https://signed.example/$path';

  @override
  Future<void> upload(String path, Uint8List bytes, String mime) async {
    uploads++;
    if (uploads <= failUploads) throw StateError('red');
  }

  @override
  Future<void> uploadFile(String path, String filePath, String mime) async {
    uploads++;
  }
}

void main() {
  test('reintenta la subida y devuelve la ruta del bucket', () async {
    final gateway = _FakeGateway()..failUploads = 1;
    final uploader = EvidenceUploader(gateway: gateway);
    final fractions = <double>[];

    final path = await uploader.save(
      jobId: 'job-1',
      userId: 'user-1',
      fileId: 'file-1',
      bytes: Uint8List.fromList([1, 2, 3]),
      mime: 'image/png',
      onProgress: (progress) => fractions.add(progress.fraction),
    );

    expect(path, 'job-1/user-1/file-1.png');
    expect(gateway.uploads, 2);
    expect(gateway.removed, isEmpty);
    expect(fractions.last, 1);
  });

  test('borra el objeto si la fila no se guarda', () async {
    final gateway = _FakeGateway()..failInsert = true;
    final uploader = EvidenceUploader(gateway: gateway);

    await expectLater(
      uploader.save(
        jobId: 'job-1',
        userId: 'user-1',
        fileId: 'file-2',
        bytes: Uint8List.fromList([9]),
        mime: 'video/mp4',
      ),
      throwsA(isA<StateError>()),
    );
    expect(gateway.removed, ['job-1/user-1/file-2.mp4']);
  });
}

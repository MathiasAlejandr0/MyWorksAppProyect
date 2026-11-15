import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_photo_model.dart';
import 'package:myworksapp/core/utils/bytea_codec.dart';
import 'package:myworksapp/core/widgets/evidence_photo_image.dart';

const tinyWebpHex =
    '524946463a00000057454250565038202e0000003002009d012a0200020001402625a00274ba01f801f800061e00009bffdbb34c63f7f789ffef60b62f197faf8000';

void main() {
  testWidgets('pinta la evidencia WebP desde los bytes de la base', (tester) async {
    final bytes = decodeBytea('\\x$tinyWebpHex')!;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 120,
          height: 120,
          child: EvidencePhotoImage(
            photo: JobPhotoModel(
              id: 'p1',
              jobId: 'j1',
              photoPath: 'evidencia.webp',
              createdAt: DateTime.utc(2026, 11, 8),
              webpBytes: bytes,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
  });

  testWidgets('sin WebP muestra el placeholder, no un File local', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 120,
          height: 120,
          child: EvidencePhotoImage(
            photo: JobPhotoModel(
              id: 'p2',
              jobId: 'j1',
              photoPath: '/tmp/no-existe.jpg',
              createdAt: DateTime.utc(2026, 11, 8),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(BrokenEvidencePlaceholder), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}

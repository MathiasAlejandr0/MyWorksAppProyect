import 'package:flutter/material.dart';

import '../database/models/job_photo_model.dart';
import '../theme/app_colors.dart';

/// Muestra evidencia desde WebP guardado en la base (o un placeholder).
class EvidencePhotoImage extends StatelessWidget {
  const EvidencePhotoImage({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
  });

  final JobPhotoModel photo;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (photo.isVideo) {
      return const ColoredBox(
        color: AppColors.grayDark,
        child: Center(
          child: Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 48,
          ),
        ),
      );
    }

    final bytes = photo.webpBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const BrokenEvidencePlaceholder(),
      );
    }

    final path = photo.photoPath;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => const BrokenEvidencePlaceholder(),
      );
    }

    return const BrokenEvidencePlaceholder();
  }
}

class BrokenEvidencePlaceholder extends StatelessWidget {
  const BrokenEvidencePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.grayDark,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white70,
        ),
      ),
    );
  }
}

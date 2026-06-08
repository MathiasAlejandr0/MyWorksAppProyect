import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/portfolio_media_resolver.dart';
import 'portfolio_media_viewer.dart';

/// Muestra ítems de portafolio (URL remota, archivo local o placeholder).
/// Al tocar: imagen ampliada o reproductor de video.
class PortfolioMediaTile extends StatelessWidget {
  const PortfolioMediaTile({
    super.key,
    required this.photoPath,
    required this.mediaType,
    this.description,
    this.enableViewer = true,
  });

  final String photoPath;
  final String mediaType;
  final String? description;
  final bool enableViewer;

  bool get _isVideo => PortfolioMediaResolver.isVideo(mediaType);

  String get _thumbnailPath =>
      PortfolioMediaResolver.thumbnailPath(photoPath, mediaType);

  bool get _isNetwork => PortfolioMediaResolver.isNetwork(_thumbnailPath);

  bool get _isLocalFile => PortfolioMediaResolver.isLocalFile(_thumbnailPath);

  void _openViewer(BuildContext context) {
    if (!enableViewer) return;
    PortfolioMediaViewer.open(
      context,
      photoPath: photoPath,
      mediaType: mediaType,
      description: description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enableViewer ? () => _openViewer(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_isNetwork)
                CachedNetworkImage(
                  imageUrl: _thumbnailPath,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _placeholder(),
                  errorWidget: (_, __, ___) => _placeholder(),
                )
              else if (_isLocalFile)
                Image.file(
                  File(_thumbnailPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              else
                _placeholder(),
              if (_isVideo)
                Container(
                  color: Colors.black.withValues(alpha: 0.28),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              if (description != null && description!.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    final demoKey =
        photoPath.startsWith('demo:') ? photoPath.substring(5) : photoPath;
    final accent = _accentForKey(demoKey);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.35),
            accent.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Icon(
        _isVideo ? Icons.play_circle_fill_rounded : Icons.image_rounded,
        color: accent,
        size: 36,
      ),
    );
  }

  Color _accentForKey(String key) {
    if (key.contains('construction')) return AppColors.brandOrangeDark;
    if (key.contains('plumbing')) return AppColors.brandOrange;
    if (key.contains('electrical')) return const Color(0xFFE86A1F);
    if (key.contains('cleaning')) return const Color(0xFFF5934A);
    if (key.contains('assembly')) return AppColors.brandOrangeDark;
    if (key.contains('tech')) return AppColors.brandOrange;
    if (key.contains('garden')) return const Color(0xFFF5934A);
    if (key.contains('moving')) return AppColors.brandOrange;
    return AppColors.brandOrange;
  }
}

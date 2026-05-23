import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/demo_free_media.dart';
import '../theme/app_colors.dart';

/// Muestra ítems de portafolio (URL remota, archivo local o placeholder).
class PortfolioMediaTile extends StatelessWidget {
  const PortfolioMediaTile({
    super.key,
    required this.photoPath,
    required this.mediaType,
    this.description,
  });

  final String photoPath;
  final String mediaType;
  final String? description;

  String get _resolvedPath {
    if (photoPath.startsWith('demo:')) {
      return DemoFreeMedia.portfolioForKey(photoPath.substring(5));
    }
    return photoPath;
  }

  bool get _isNetwork {
    final path = _resolvedPath;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  bool get _isLocalFile {
    if (_isNetwork || _resolvedPath.startsWith('demo:')) return false;
    return File(_resolvedPath).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = mediaType == 'video';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isNetwork)
            CachedNetworkImage(
              imageUrl: _resolvedPath,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(isVideo),
              errorWidget: (_, __, ___) => _placeholder(isVideo),
            )
          else if (_isLocalFile)
            Image.file(
              File(_resolvedPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(isVideo),
            )
          else
            _placeholder(isVideo),
          if (isVideo)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
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
    );
  }

  Widget _placeholder(bool isVideo) {
    final demoKey = photoPath.startsWith('demo:') ? photoPath.substring(5) : photoPath;
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
        isVideo ? Icons.play_circle_fill_rounded : Icons.image_rounded,
        color: accent,
        size: 36,
      ),
    );
  }

  Color _accentForKey(String key) {
    if (key.contains('construction')) return const Color(0xFFF97316);
    if (key.contains('plumbing')) return const Color(0xFF14B8A6);
    if (key.contains('electrical')) return const Color(0xFF6366F1);
    if (key.contains('cleaning')) return const Color(0xFF0EA5E9);
    if (key.contains('assembly')) return const Color(0xFF8B5CF6);
    if (key.contains('tech')) return const Color(0xFF3B82F6);
    if (key.contains('garden')) return const Color(0xFF22C55E);
    if (key.contains('moving')) return const Color(0xFFEC4899);
    return AppColors.primaryLight;
  }
}

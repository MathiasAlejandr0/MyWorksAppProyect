import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/demo_free_media.dart';

/// Resuelve rutas de portafolio para miniatura y reproducción.
class PortfolioMediaResolver {
  PortfolioMediaResolver._();

  static bool isVideo(String mediaType) => mediaType == 'video';

  static String resolvePath(String photoPath) {
    if (photoPath.startsWith('demo:')) {
      return DemoFreeMedia.portfolioForKey(photoPath.substring(5));
    }
    return photoPath;
  }

  /// Miniatura en la grilla (foto o poster del video).
  static String thumbnailPath(String photoPath, String mediaType) {
    if (photoPath.startsWith('demo:')) {
      final key = photoPath.substring(5);
      if (isVideo(mediaType)) {
        return DemoFreeMedia.portfolioThumbnailForKey(key);
      }
      return DemoFreeMedia.portfolioForKey(key);
    }
    return photoPath;
  }

  /// URL o ruta para reproducir el contenido ampliado.
  static String? playbackPath(String photoPath, String mediaType) {
    if (photoPath.startsWith('demo:')) {
      final key = photoPath.substring(5);
      if (isVideo(mediaType)) {
        return DemoFreeMedia.portfolioVideoForKey(key);
      }
      return DemoFreeMedia.portfolioForKey(key);
    }
    return photoPath;
  }

  static bool isNetwork(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  static bool isAsset(String path) => path.startsWith('assets/');

  static bool isLocalFile(String path) {
    if (kIsWeb) return false;
    if (isNetwork(path) || path.startsWith('demo:') || isAsset(path)) {
      return false;
    }
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}

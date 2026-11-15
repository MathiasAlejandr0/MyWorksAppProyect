import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Permisos de galería/fotos compatibles con Android 13+ e iOS.
class AppMediaPermissions {
  AppMediaPermissions._();

  /// Permiso principal para leer imágenes de la galería.
  static Permission get galleryRead {
    if (Platform.isAndroid) {
      return Permission.photos;
    }
    return Permission.photos;
  }

  /// Solicita acceso a la galería (incluye [PermissionStatus.limited] en iOS).
  static Future<bool> requestGalleryAccess() async {
    final status = await galleryRead.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> isGalleryGranted() async {
    final status = await galleryRead.status;
    return status.isGranted || status.isLimited;
  }
}

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';

/// Avatar circular con soporte URL, archivo local o iniciales.
class ProfileAvatarImage extends StatelessWidget {
  const ProfileAvatarImage({
    super.key,
    required this.displayName,
    this.photoPath,
    this.radius = 40,
    this.onDarkBackground = true,
  });

  final String displayName;
  final String? photoPath;
  final double radius;
  final bool onDarkBackground;

  bool get _isNetwork =>
      photoPath != null &&
      (photoPath!.startsWith('http://') || photoPath!.startsWith('https://'));

  bool get _isLocalFile {
    if (photoPath == null || _isNetwork) return false;
    return File(photoPath!).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
  final initial = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?';

    if (_isNetwork) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            imageUrl: photoPath!,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initialCircle(initial),
            errorWidget: (_, __, ___) => _initialCircle(initial),
          ),
        ),
      );
    }

    if (_isLocalFile) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.file(
            File(photoPath!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialCircle(initial),
          ),
        ),
      );
    }

    return _initialCircle(initial);
  }

  Widget _initialCircle(String initial) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: onDarkBackground
          ? Colors.white.withValues(alpha: 0.15)
          : AppColors.primaryLight.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w800,
          color: onDarkBackground ? Colors.white : AppColors.brandNavy,
        ),
      ),
    );
  }
}

/// Avatar de solo lectura (p. ej. perfil público del trabajador).
class ProfileAvatarView extends StatelessWidget {
  const ProfileAvatarView({
    super.key,
    required this.displayName,
    this.photoPath,
    this.radius = 40,
    this.onDarkBackground = true,
  });

  final String displayName;
  final String? photoPath;
  final double radius;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    return ProfileAvatarImage(
      displayName: displayName,
      photoPath: photoPath,
      radius: radius,
      onDarkBackground: onDarkBackground,
    );
  }
}

/// Avatar editable: galería, cámara o quitar foto.
class ProfileAvatarPicker extends StatelessWidget {
  const ProfileAvatarPicker({
    super.key,
    required this.displayName,
    this.photoPath,
    this.radius = 50,
    this.isLoading = false,
    required this.onPickFromSource,
    this.onRemove,
  });

  final String displayName;
  final String? photoPath;
  final double radius;
  final bool isLoading;
  final Future<void> Function(ImageSource source) onPickFromSource;
  final Future<void> Function()? onRemove;

  Future<void> _showOptions(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primaryLight),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryLight),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (photoPath != null && photoPath!.isNotEmpty && onRemove != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Quitar foto'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onRemove!();
                  },
                ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      await onPickFromSource(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => _showOptions(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ProfileAvatarImage(
            displayName: displayName,
            photoPath: photoPath,
            radius: radius,
            onDarkBackground: false,
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// Compatibilidad con código que usa ImageProvider.
  static ImageProvider? imageProviderFor(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CachedNetworkImageProvider(path);
    }
    final file = File(path);
    if (file.existsSync()) return FileImage(file);
    return null;
  }
}

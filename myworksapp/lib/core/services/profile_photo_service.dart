import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'photo_service.dart';

/// Gestiona la foto de perfil del usuario (galería, cámara, eliminar).
class ProfilePhotoService {
  ProfilePhotoService._();

  static final ProfilePhotoService instance = ProfilePhotoService._();

  Future<String?> pickAndSave({
    required String userId,
    required ImageSource source,
    String? currentPath,
  }) async {
    final file = await PhotoService.instance.pickImage(source: source);
    if (file == null) return null;

    final savedPath = await PhotoService.instance.saveProfilePhoto(file, userId);
    if (savedPath != null) {
      await _deleteLocalFile(currentPath);
    }
    return savedPath;
  }

  Future<void> removePhoto(String? currentPath) async {
    await _deleteLocalFile(currentPath);
  }

  Future<void> _deleteLocalFile(String? path) async {
    if (path == null || path.isEmpty) return;
    if (path.startsWith('http://') || path.startsWith('https://')) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

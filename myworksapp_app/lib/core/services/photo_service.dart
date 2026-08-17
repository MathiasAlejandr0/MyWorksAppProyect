import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../utils/app_logger.dart';

/// Servicio profesional para manejo de fotos
class PhotoService {
  static final PhotoService instance = PhotoService._();
  PhotoService._();

  final ImagePicker _imagePicker = ImagePicker();
  static const int maxImageSizeKB = 500; // 500KB máximo
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int quality = 85;

  /// Obtiene el directorio de documentos de la app
  Future<Directory> _getAppDocumentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final myWorksDir = Directory('${appDir.path}/myworksapp');
    if (!await myWorksDir.exists()) {
      await myWorksDir.create(recursive: true);
    }
    return myWorksDir;
  }

  /// Obtiene el directorio de fotos de trabajos
  Future<Directory> _getJobsPhotosDirectory(String jobId) async {
    final appDir = await _getAppDocumentsDirectory();
    final jobsDir = Directory('${appDir.path}/jobs/$jobId');
    if (!await jobsDir.exists()) {
      await jobsDir.create(recursive: true);
    }
    return jobsDir;
  }

  /// Directorio de fotos de perfil por usuario.
  Future<Directory> _getProfileDirectory(String userId) async {
    final appDir = await _getAppDocumentsDirectory();
    final profileDir = Directory('${appDir.path}/profiles/$userId');
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }
    return profileDir;
  }

  /// Obtiene el directorio de portafolio de trabajador
  Future<Directory> _getPortfolioDirectory(String workerId) async {
    final appDir = await _getAppDocumentsDirectory();
    final portfolioDir = Directory('${appDir.path}/portfolio/$workerId');
    if (!await portfolioDir.exists()) {
      await portfolioDir.create(recursive: true);
    }
    return portfolioDir;
  }

  /// Selecciona una imagen desde galería o cámara
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: quality,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      AppLogger.e('Error al seleccionar imagen', e);
      return null;
    }
  }

  /// Comprime una imagen
  Future<File?> compressImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final fileSizeKB = imageBytes.length / 1024;

      // Si ya es menor al tamaño máximo, retornar sin comprimir
      if (fileSizeKB <= maxImageSizeKB) {
        return imageFile;
      }

      // Comprimir imagen
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: maxImageWidth,
        minHeight: maxImageHeight,
        quality: quality,
      );

      if (compressedBytes == null) {
        AppLogger.w('No se pudo comprimir la imagen');
        return imageFile; // Retornar original si falla
      }

      // Verificar tamaño después de compresión
      final compressedSizeKB = compressedBytes.length / 1024;
      if (compressedSizeKB > maxImageSizeKB) {
        AppLogger.w('Imagen aún grande después de compresión: ${compressedSizeKB}KB');
      }

      // Guardar imagen comprimida temporalmente
      final tempFile = File('${imageFile.path}_compressed.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      return tempFile;
    } catch (e) {
      AppLogger.e('Error al comprimir imagen', e);
      return imageFile; // Retornar original si falla
    }
  }

  /// Guarda una foto de trabajo
  Future<String?> saveJobPhoto(File imageFile, String jobId) async {
    try {
      // Comprimir imagen
      final compressedFile = await compressImage(imageFile);
      if (compressedFile == null) return null;

      // Obtener directorio de fotos del trabajo
      final jobsDir = await _getJobsPhotosDirectory(jobId);

      // Generar nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'job_${jobId}_$timestamp.jpg';
      final savedFile = File('${jobsDir.path}/$fileName');

      // Copiar archivo comprimido
      await compressedFile.copy(savedFile.path);

      // Eliminar archivo temporal si existe
      if (compressedFile.path != imageFile.path && await compressedFile.exists()) {
        await compressedFile.delete();
      }

      AppLogger.i('Foto de trabajo guardada: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      AppLogger.e('Error al guardar foto de trabajo', e);
      return null;
    }
  }

  /// Guarda la foto de perfil del usuario.
  Future<String?> saveProfilePhoto(File imageFile, String userId) async {
    try {
      final compressedFile = await compressImage(imageFile);
      if (compressedFile == null) return null;

      final profileDir = await _getProfileDirectory(userId);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedFile = File('${profileDir.path}/avatar_$timestamp.jpg');

      await compressedFile.copy(savedFile.path);

      if (compressedFile.path != imageFile.path && await compressedFile.exists()) {
        await compressedFile.delete();
      }

      AppLogger.i('Foto de perfil guardada: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      AppLogger.e('Error al guardar foto de perfil', e);
      return null;
    }
  }

  /// Guarda una foto de portafolio
  Future<String?> savePortfolioPhoto(File imageFile, String workerId) async {
    try {
      // Comprimir imagen
      final compressedFile = await compressImage(imageFile);
      if (compressedFile == null) return null;

      // Obtener directorio de portafolio
      final portfolioDir = await _getPortfolioDirectory(workerId);

      // Generar nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'portfolio_${workerId}_$timestamp.jpg';
      final savedFile = File('${portfolioDir.path}/$fileName');

      // Copiar archivo comprimido
      await compressedFile.copy(savedFile.path);

      // Eliminar archivo temporal si existe
      if (compressedFile.path != imageFile.path && await compressedFile.exists()) {
        await compressedFile.delete();
      }

      AppLogger.i('Foto de portafolio guardada: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      AppLogger.e('Error al guardar foto de portafolio', e);
      return null;
    }
  }

  /// Elimina todas las fotos de un trabajo
  Future<void> deleteJobPhotos(String jobId) async {
    try {
      final jobsDir = await _getJobsPhotosDirectory(jobId);
      if (await jobsDir.exists()) {
        await jobsDir.delete(recursive: true);
        AppLogger.i('Fotos del trabajo eliminadas: $jobId');
      }
    } catch (e) {
      AppLogger.e('Error al eliminar fotos del trabajo', e);
    }
  }

  /// Elimina todas las fotos del portafolio de un trabajador
  Future<void> deletePortfolioPhotos(String workerId) async {
    try {
      final portfolioDir = await _getPortfolioDirectory(workerId);
      if (await portfolioDir.exists()) {
        await portfolioDir.delete(recursive: true);
        AppLogger.i('Fotos del portafolio eliminadas: $workerId');
      }
    } catch (e) {
      AppLogger.e('Error al eliminar fotos del portafolio', e);
    }
  }

  /// Obtiene el tamaño de un archivo en KB
  Future<double> getFileSizeKB(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / 1024;
      }
      return 0;
    } catch (e) {
      AppLogger.e('Error al obtener tamaño de archivo', e);
      return 0;
    }
  }

  /// Verifica si un archivo existe
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}


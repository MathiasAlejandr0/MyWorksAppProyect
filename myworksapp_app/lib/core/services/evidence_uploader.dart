import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/supabase_db.dart';
import 'evidence_storage_path.dart';

class EvidenceUploadProgress {
  const EvidenceUploadProgress(this.fraction, this.label);

  final double fraction;
  final String label;
}

/// Operaciones de Storage y de la fila. El servicio real habla con Supabase.
abstract class EvidenceStorageGateway {
  Future<void> upload(String path, Uint8List bytes, String mime);
  Future<void> uploadFile(String path, String filePath, String mime);
  Future<void> remove(String path);
  Future<void> insertRow(Map<String, dynamic> row);
  Future<String?> signedUrl(String path);
}

class SupabaseEvidenceGateway implements EvidenceStorageGateway {
  @override
  Future<void> upload(String path, Uint8List bytes, String mime) {
    return supabase.storage.from(EvidenceStoragePath.bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
          retryAttempts: 0,
        );
  }

  @override
  Future<void> uploadFile(String path, String filePath, String mime) {
    return supabase.storage.from(EvidenceStoragePath.bucket).upload(
          path,
          File(filePath),
          fileOptions: FileOptions(contentType: mime, upsert: false),
          retryAttempts: 0,
        );
  }

  @override
  Future<void> remove(String path) async {
    await supabase.storage.from(EvidenceStoragePath.bucket).remove([path]);
  }

  @override
  Future<void> insertRow(Map<String, dynamic> row) async {
    await supabase.from('fotos_trabajo').insert(row);
  }

  @override
  Future<String?> signedUrl(String path) async {
    try {
      return await supabase.storage
          .from(EvidenceStoragePath.bucket)
          .createSignedUrl(path, 60 * 60);
    } catch (_) {
      return null;
    }
  }
}

/// Necesita el import de FileOptions. I'll add it.
class EvidenceUploader {
  EvidenceUploader({EvidenceStorageGateway? gateway})
      : _gateway = gateway ?? SupabaseEvidenceGateway();

  final EvidenceStorageGateway _gateway;

  Future<String> save({
    required String jobId,
    required String userId,
    required String fileId,
    required Uint8List bytes,
    required String mime,
    void Function(EvidenceUploadProgress progress)? onProgress,
  }) async {
    final problem = EvidenceStoragePath.validate(
      mime: mime,
      byteLength: bytes.length,
    );
    if (problem != null) throw StateError(problem);
    final media = EvidenceStoragePath.mediaForMime(mime)!;
    final path = EvidenceStoragePath.objectPath(
      jobId: jobId,
      userId: userId,
      fileId: fileId,
      mime: mime,
    );
    onProgress?.call(const EvidenceUploadProgress(0.1, 'Preparando'));

    var uploaded = false;
    for (var attempt = 0; attempt < 3 && !uploaded; attempt++) {
      try {
        onProgress?.call(
          EvidenceUploadProgress(0.25 + attempt * 0.15, 'Subiendo'),
        );
        await _gateway.upload(path, bytes, mime);
        uploaded = true;
      } catch (_) {}
    }
    if (!uploaded) {
      throw StateError('No se pudo subir la evidencia');
    }
    onProgress?.call(const EvidenceUploadProgress(0.8, 'Guardando'));
    try {
      await _gateway.insertRow({
        'id': fileId,
        'id_trabajo': jobId,
        'ruta_foto': path,
        'tipo_medio': media,
        'creado_en': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      try {
        await _gateway.remove(path);
      } catch (_) {}
      throw StateError('No se pudo registrar la evidencia');
    }
    onProgress?.call(const EvidenceUploadProgress(1, 'Listo'));
    return path;
  }

  /// Sube desde disco. El video no se carga entero en memoria.
  Future<String> saveFile({
    required String jobId,
    required String userId,
    required String fileId,
    required String filePath,
    required int byteLength,
    required String mime,
    void Function(EvidenceUploadProgress progress)? onProgress,
  }) async {
    final problem = EvidenceStoragePath.validate(
      mime: mime,
      byteLength: byteLength,
    );
    if (problem != null) throw StateError(problem);
    final media = EvidenceStoragePath.mediaForMime(mime)!;
    final path = EvidenceStoragePath.objectPath(
      jobId: jobId,
      userId: userId,
      fileId: fileId,
      mime: mime,
    );
    onProgress?.call(const EvidenceUploadProgress(0.2, 'Subiendo'));
    var uploaded = false;
    for (var attempt = 0; attempt < 3 && !uploaded; attempt++) {
      try {
        await _gateway.uploadFile(path, filePath, mime);
        uploaded = true;
      } catch (_) {}
    }
    if (!uploaded) {
      throw StateError('No se pudo subir la evidencia');
    }
    try {
      await _gateway.insertRow({
        'id': fileId,
        'id_trabajo': jobId,
        'ruta_foto': path,
        'tipo_medio': media,
        'creado_en': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      try {
        await _gateway.remove(path);
      } catch (_) {}
      throw StateError('No se pudo registrar la evidencia');
    }
    onProgress?.call(const EvidenceUploadProgress(1, 'Listo'));
    return path;
  }

  Future<String?> signedUrl(String path) => _gateway.signedUrl(path);

  Future<void> removeStored(String path) => _gateway.remove(path);
}

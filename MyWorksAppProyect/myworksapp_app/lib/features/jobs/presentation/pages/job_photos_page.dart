import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/database/models/job_photo_model.dart';
import '../../../../core/database/repositories/job_photo_repository.dart';
import '../../../../core/database/supabase_db.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/services/evidence_dhash.dart';
import '../../../../core/services/evidence_luma.dart';
import '../../../../core/services/evidence_storage_path.dart';
import '../../../../core/services/evidence_uploader.dart';
import '../../../../core/services/evidence_video_limits.dart';
import '../../../../core/services/evidence_webp.dart';
import '../../../../core/utils/bytea_codec.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/evidence_photo_image.dart';
import 'evidence_shutter_camera_page.dart';

class JobPhotosPage extends StatefulWidget {
  final String jobId;
  final bool canAddPhotos;

  const JobPhotosPage({
    super.key,
    required this.jobId,
    this.canAddPhotos = true,
  });

  @override
  State<JobPhotosPage> createState() => _JobPhotosPageState();
}

class _JobPhotosPageState extends State<JobPhotosPage> {
  final JobPhotoRepository _photoRepository = JobPhotoRepository();
  final EvidenceUploader _uploader = EvidenceUploader();
  final ImagePicker _imagePicker = ImagePicker();
  List<JobPhotoModel> _photos = [];
  final Map<String, String> _signedUrls = {};
  bool _isLoading = true;
  bool _uploading = false;
  double _uploadFraction = 0;
  String? _uploadError;
  _PendingEvidence? _pendingRetry;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final photos = await _photoRepository.getPhotosByJobId(widget.jobId);
      final signed = <String, String>{};
      for (final photo in photos) {
        if (!EvidenceStoragePath.isStoragePath(photo.photoPath)) continue;
        final url = await _uploader.signedUrl(photo.photoPath);
        if (url != null) signed[photo.id] = url;
      }
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _signedUrls
          ..clear()
          ..addAll(signed);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEvidence(XFile file, String mime) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Inicia sesión para subir evidencia');
    }
    final length = await file.length();
    final problem =
        EvidenceStoragePath.validate(mime: mime, byteLength: length);
    if (problem != null) {
      throw StateError(problem);
    }
    setState(() {
      _uploading = true;
      _uploadFraction = 0;
      _uploadError = null;
      _pendingRetry = _PendingEvidence(file, mime);
    });
    try {
      final fileId = const Uuid().v4();
      if (mime.startsWith('video/')) {
        await _uploader.saveFile(
          jobId: widget.jobId,
          userId: userId,
          fileId: fileId,
          filePath: file.path,
          byteLength: length,
          mime: mime,
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _uploadFraction = progress.fraction);
          },
        );
      } else {
        final raw = await file.readAsBytes();
        final webp = await encodeEvidenceWebp(raw);
        await _uploader.save(
          jobId: widget.jobId,
          userId: userId,
          fileId: fileId,
          bytes: webp,
          mime: 'image/webp',
          imageWebp: webp,
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _uploadFraction = progress.fraction);
          },
        );
      }
      if (!mounted) return;
      setState(() => _pendingRetry = null);
      await _loadPhotos();
      if (!mounted) return;
      showAppSnackBar(
        context,
        mime.startsWith('video/') ? 'Video agregado' : 'Foto agregada',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadError = ErrorHandler.getErrorMessage(e));
      showAppSnackBar(context, ErrorHandler.getErrorMessage(e),
          type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }


  Future<Position> _gpsDeLaCaptura() async {
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      throw StateError(
        'Se necesita el GPS del teléfono para registrar la evidencia.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  /// Cámara de la app: un toque saca foto; mantener presionado graba video.
  Future<void> _capturar(String tipo) async {
    if (kIsWeb) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'La cámara de evidencia verificada está en la app Android e iOS.',
        type: AppSnackBarType.error,
      );
      return;
    }
    try {
      final capture = await Navigator.of(context).push<EvidenceCapture>(
        MaterialPageRoute(
          builder: (_) => const EvidenceShutterCameraPage(),
        ),
      );
      if (capture == null) return;
      if (capture.isVideo) {
        await _registrarVideoCaptura(capture, tipo);
      } else {
        await _registrarCaptura(capture.file, tipo);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, ErrorHandler.getErrorMessage(e),
          type: AppSnackBarType.error);
    }
  }

  Future<void> _registrarVideoCaptura(
    EvidenceCapture capture,
    String tipo,
  ) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Inicia sesión para subir evidencia');
    }
    final file = capture.file;
    final mime = _mimeFor(file, video: true);
    final length = await file.length();
    final duration = capture.duration ?? Duration.zero;
    final limite = EvidenceVideoLimits.validate(
      byteLength: length,
      duration: duration,
      mime: mime,
    );
    if (limite != null) {
      throw StateError(limite);
    }
    final gps = await _gpsDeLaCaptura();
    final nonce = await supabase.rpc('pedir_nonce_evidencia', params: {
      'p_id_trabajo': widget.jobId,
    });
    final hash = await sha256OfBytesStream(file.openRead());
    final procedencia = EvidenceVideoProvenance.validate(
      nonce: '$nonce',
      hashSha256: hash,
      byteLength: length,
      duration: duration,
      mime: mime,
      lat: gps.latitude,
      lng: gps.longitude,
    );
    if (procedencia != null) {
      throw StateError(procedencia);
    }
    setState(() {
      _uploading = true;
      _uploadFraction = 0;
      _uploadError = null;
      _pendingRetry = _PendingEvidence(
        file,
        mime,
        tipo: tipo,
        verifiedVideo: true,
        duration: duration,
      );
    });
    final fileId = const Uuid().v4();
    try {
      await _uploader.saveFile(
        jobId: widget.jobId,
        userId: userId,
        fileId: fileId,
        filePath: file.path,
        byteLength: length,
        mime: mime,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _uploadFraction = progress.fraction);
        },
      );
      final duracionSeg = duration.inSeconds.clamp(1, EvidenceVideoLimits.maxDurationSecondsGrace);
      final registro = await supabase.rpc(
        'registrar_evidencia_video_captura',
        params: {
          'p_id_foto': fileId,
          'p_id_trabajo': widget.jobId,
          'p_nonce': nonce,
          'p_hash_sha256': hash,
          'p_lat': gps.latitude,
          'p_lng': gps.longitude,
          'p_tipo': tipo,
          'p_bytes': length,
          'p_duracion_seg': duracionSeg,
          'p_capturada_en': null,
        },
      );
      if (!mounted) return;
      setState(() => _pendingRetry = null);
      await _loadPhotos();
      if (!mounted) return;
      final confianza = registro is Map ? registro['confianza'] : null;
      showAppSnackBar(
        context,
        confianza == 'confiable'
            ? 'Video registrado con procedencia verificada'
            : 'El video quedó guardado, pero no cuenta como evidencia verificada',
        type: confianza == 'confiable'
            ? AppSnackBarType.success
            : AppSnackBarType.error,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadError = ErrorHandler.getErrorMessage(e));
      showAppSnackBar(context, ErrorHandler.getErrorMessage(e),
          type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _registrarCaptura(XFile file, String tipo) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Inicia sesión para subir evidencia');
    }
    final original = await file.readAsBytes();
    final gps = await _gpsDeLaCaptura();
    final nonce = await supabase.rpc('pedir_nonce_evidencia', params: {
      'p_id_trabajo': widget.jobId,
    });
    final webp = await encodeEvidenceWebp(original);
    final hashOriginal = sha256Hex(original);
    final hashWebp = sha256Hex(webp);
    final luma = await luma9x8(original);
    final perceptual = dhashDesdeLuma(luma);
    setState(() {
      _uploading = true;
      _uploadFraction = 0;
      _uploadError = null;
      _pendingRetry = _PendingEvidence(file, 'image/webp', tipo: tipo);
    });
    final fileId = const Uuid().v4();
    try {
      await _uploader.save(
        jobId: widget.jobId,
        userId: userId,
        fileId: fileId,
        bytes: webp,
        mime: 'image/webp',
        imageWebp: webp,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _uploadFraction = progress.fraction);
        },
      );
      final registro = await supabase.rpc('registrar_evidencia_captura', params: {
        'p_id_foto': fileId,
        'p_id_trabajo': widget.jobId,
        'p_nonce': nonce,
        'p_hash_sha256': hashWebp,
        'p_hash_original': hashOriginal,
        'p_luma': encodeByteaHex(luma),
        'p_lat': gps.latitude,
        'p_lng': gps.longitude,
        'p_tipo': tipo,
        'p_capturada_en': null,
        'p_hash_perceptual': perceptual,
      });
      if (!mounted) return;
      setState(() => _pendingRetry = null);
      await _loadPhotos();
      if (!mounted) return;
      final confianza = registro is Map ? registro['confianza'] : null;
      showAppSnackBar(
        context,
        confianza == 'confiable'
            ? 'Foto registrada con procedencia verificada'
            : 'La foto quedó guardada, pero no cuenta como evidencia verificada',
        type: confianza == 'confiable'
            ? AppSnackBarType.success
            : AppSnackBarType.error,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadError = ErrorHandler.getErrorMessage(e));
      showAppSnackBar(context, ErrorHandler.getErrorMessage(e),
          type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _mimeFor(XFile file, {required bool video}) {
    final fromPicker = file.mimeType;
    if (fromPicker != null && fromPicker.isNotEmpty) return fromPicker;
    final lower = file.path.toLowerCase();
    if (video || lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image == null) return;
      await _saveEvidence(image, _mimeFor(image, video: false));
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, ErrorHandler.getErrorMessage(e),
          type: AppSnackBarType.error);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (video == null) return;
      await _saveEvidence(video, _mimeFor(video, video: true));
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, ErrorHandler.getErrorMessage(e),
          type: AppSnackBarType.error);
    }
  }

  void _showAddEvidenceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Evidencia del antes'),
              subtitle: const Text(
                'Toque para foto, mantenga para video. Queda verificada.',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _capturar('antes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Evidencia del después'),
              subtitle: const Text(
                'Toque para foto, mantenga para video. Queda verificada.',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _capturar('despues');
              },
            ),
            ListTile(
              leading: const Icon(Icons.center_focus_strong),
              title: const Text('Detalle del trabajo'),
              subtitle: const Text(
                'Toque para foto, mantenga para video. Queda verificada.',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _capturar('detalle');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir foto de galería'),
              subtitle: const Text('Queda como no verificada'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Elegir video de galería'),
              subtitle: const Text('Queda como no verificado'),
              onTap: () {
                Navigator.pop(ctx);
                _pickVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evidencia'),
        content:
            const Text('¿Estás seguro de que quieres eliminar este archivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final photo = _photos.cast<JobPhotoModel?>().firstWhere(
            (item) => item?.id == id,
            orElse: () => null,
          );
      await _photoRepository.deleteJobPhoto(id);
      if (photo != null && EvidenceStoragePath.isStoragePath(photo.photoPath)) {
        try {
          await _uploader.removeStored(photo.photoPath);
        } catch (_) {}
      }
      await _loadPhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Evidencia del trabajo'),
        actions: [
          if (widget.canAddPhotos)
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: _showAddEvidenceSheet,
              tooltip: 'Agregar evidencia',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_uploading || _uploadError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(
                          value: _uploading ? _uploadFraction : 0,
                        ),
                        if (_uploadError != null) ...[
                          const SizedBox(height: 8),
                          Text(_uploadError!,
                              style: const TextStyle(color: AppColors.error)),
                          if (_pendingRetry != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _uploading
                                    ? null
                                    : () {
                                        final pending = _pendingRetry!;
                                        if (pending.tipo != null &&
                                            pending.verifiedVideo) {
                                          _registrarVideoCaptura(
                                            EvidenceCapture(
                                              file: pending.file,
                                              isVideo: true,
                                              duration: pending.duration,
                                            ),
                                            pending.tipo!,
                                          );
                                        } else if (pending.tipo != null) {
                                          _registrarCaptura(
                                            pending.file,
                                            pending.tipo!,
                                          );
                                        } else {
                                          _saveEvidence(
                                            pending.file,
                                            pending.mime,
                                          );
                                        }
                                      },
                                child: const Text('Reintentar'),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                Expanded(
                  child: _photos.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.photo_library,
                          title: 'Sin evidencia',
                          message:
                              'Toma la foto con la cámara de la app para que quede verificada. La galería y el video quedan como no verificados.',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _photos.length,
                          itemBuilder: (context, index) {
                            final photo = _photos[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _EvidenceViewer(
                                      photo: photo,
                                      signedUrl: _signedUrls[photo.id],
                                      onDelete: widget.canAddPhotos
                                          ? () => _deletePhoto(photo.id)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (photo.isVideo)
                                    const ColoredBox(
                                      color: AppColors.grayDark,
                                      child: Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      ),
                                    )
                                  else if (photo.hasRenderablePhoto)
                                    EvidencePhotoImage(photo: photo)
                                  else
                                    _EvidenceThumb(
                                      path: photo.photoPath,
                                      signedUrl: _signedUrls[photo.id],
                                    ),
                                  if (photo.isVideo)
                                    Positioned(
                                      left: 6,
                                      bottom: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.videocam,
                                                color: Colors.white, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'Video',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (widget.canAddPhotos)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: IconButton(
                                        tooltip: 'Eliminar',
                                        icon: const Icon(Icons.delete,
                                            color: AppColors.error),
                                        onPressed: () => _deletePhoto(photo.id),
                                        iconSize: 20,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _PendingEvidence {
  const _PendingEvidence(
    this.file,
    this.mime, {
    this.tipo,
    this.verifiedVideo = false,
    this.duration,
  });
  final XFile file;
  final String mime;
  final String? tipo;
  final bool verifiedVideo;
  final Duration? duration;
}

class _EvidenceThumb extends StatelessWidget {
  const _EvidenceThumb({required this.path, this.signedUrl});

  final String path;
  final String? signedUrl;

  @override
  Widget build(BuildContext context) {
    if (signedUrl != null) {
      return Image.network(
        signedUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const ColoredBox(
            color: AppColors.grayDark,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.brandOrange,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const ColoredBox(
          color: AppColors.grayDark,
          child: Icon(Icons.broken_image, color: Colors.white),
        ),
      );
    }
    if (!kIsWeb && !EvidenceStoragePath.isStoragePath(path)) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      } catch (_) {
        // Fall through to placeholder
      }
    }
    return const ColoredBox(
      color: AppColors.grayDark,
      child: Icon(Icons.broken_image, color: Colors.white),
    );
  }
}

class _EvidenceViewer extends StatefulWidget {
  final JobPhotoModel photo;
  final String? signedUrl;
  final VoidCallback? onDelete;

  const _EvidenceViewer({
    required this.photo,
    this.signedUrl,
    this.onDelete,
  });

  @override
  State<_EvidenceViewer> createState() => _EvidenceViewerState();
}

class _EvidenceViewerState extends State<_EvidenceViewer> {
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    final url = widget.signedUrl;
    if (widget.photo.isVideo && url != null) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _video = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _video = null);
      });
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.photo.isVideo ? 'Video' : 'Foto'),
        actions: [
          if (widget.onDelete != null)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () {
                // Cerrar primero el visor: si se hace después, el pop cierra
                // el diálogo de confirmación recién abierto.
                Navigator.pop(context);
                widget.onDelete!();
              },
            ),
        ],
      ),
      body: Center(
        child: widget.photo.isVideo
            ? (_video != null && _video!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _video!.value.aspectRatio,
                    child: VideoPlayer(_video!),
                  )
                : const Icon(Icons.videocam, color: Colors.white, size: 72))
            : widget.photo.hasRenderablePhoto
                ? InteractiveViewer(
                    child: EvidencePhotoImage(
                      photo: widget.photo,
                      fit: BoxFit.contain,
                    ),
                  )
                : _EvidenceThumb(
                    path: widget.photo.photoPath,
                    signedUrl: widget.signedUrl,
                  ),
      ),
    );
  }
}

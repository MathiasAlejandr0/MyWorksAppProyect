import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../../core/database/repositories/job_photo_repository.dart';
import '../../../../core/database/models/job_photo_model.dart';
import '../../../../core/widgets/empty_state_widget.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  List<JobPhotoModel> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final photos = await _photoRepository.getPhotosByJobId(widget.jobId);
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEvidence({
    required String path,
    required String mediaType,
  }) async {
    final photo = JobPhotoModel(
      id: const Uuid().v4(),
      jobId: widget.jobId,
      photoPath: path,
      mediaType: mediaType,
      createdAt: DateTime.now(),
    );

    await _photoRepository.createJobPhoto(photo);
    await _loadPhotos();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mediaType == JobPhotoModel.mediaVideo
              ? 'Video agregado'
              : 'Foto agregada',
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image == null) return;
      await _saveEvidence(
        path: image.path,
        mediaType: JobPhotoModel.mediaPhoto,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (video == null) return;
      await _saveEvidence(
        path: video.path,
        mediaType: JobPhotoModel.mediaVideo,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir foto de galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Elegir video'),
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
        content: const Text('¿Estás seguro de que quieres eliminar este archivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _photoRepository.deleteJobPhoto(id);
      await _loadPhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          : _photos.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.photo_library,
                  title: 'Sin evidencia',
                  message: 'Sube al menos una foto o un video del trabajo realizado',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                            ColoredBox(
                              color: Colors.grey.shade800,
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            )
                          else
                            Image.file(
                              File(photo.photoPath),
                              fit: BoxFit.cover,
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
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam, color: Colors.white, size: 14),
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
                                icon: const Icon(Icons.delete, color: Colors.red),
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
    );
  }
}

class _EvidenceViewer extends StatelessWidget {
  final JobPhotoModel photo;
  final VoidCallback? onDelete;

  const _EvidenceViewer({
    required this.photo,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(photo.isVideo ? 'Video' : 'Foto'),
        actions: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                onDelete!();
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Center(
        child: photo.isVideo
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white, size: 72),
                    const SizedBox(height: 16),
                    Text(
                      'Video registrado como evidencia',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      photo.photoPath.split(Platform.pathSeparator).last,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Image.file(File(photo.photoPath)),
      ),
    );
  }
}

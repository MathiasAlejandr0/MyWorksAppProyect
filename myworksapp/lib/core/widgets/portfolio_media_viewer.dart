import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_colors.dart';
import '../utils/portfolio_media_resolver.dart';

/// Abre imagen ampliada o reproductor de video del portafolio.
class PortfolioMediaViewer {
  PortfolioMediaViewer._();

  static Future<void> openImagePath(
    BuildContext context, {
    required String imagePath,
    String? description,
    String title = 'Imagen',
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PortfolioImagePage(
          imagePath: imagePath,
          description: description,
          title: title,
        ),
      ),
    );
  }

  static Future<void> open(
    BuildContext context, {
    required String photoPath,
    required String mediaType,
    String? description,
  }) {
    if (PortfolioMediaResolver.isVideo(mediaType)) {
      final playback = PortfolioMediaResolver.playbackPath(photoPath, mediaType);
      if (playback == null) return Future.value();
      return Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => _PortfolioVideoPage(
            videoPath: playback,
            description: description,
          ),
        ),
      );
    }

    final imagePath = PortfolioMediaResolver.playbackPath(photoPath, mediaType) ??
        PortfolioMediaResolver.resolvePath(photoPath);

    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PortfolioImagePage(
          imagePath: imagePath,
          description: description,
          title: 'Trabajo anterior',
        ),
      ),
    );
  }
}

class _PortfolioImagePage extends StatelessWidget {
  const _PortfolioImagePage({
    required this.imagePath,
    this.description,
    this.title = 'Imagen',
  });

  final String imagePath;
  final String? description;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: _buildImage(),
              ),
            ),
          ),
          if (description != null && description!.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Text(
                description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (PortfolioMediaResolver.isNetwork(imagePath)) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: AppColors.brandOrange),
        ),
        errorWidget: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.white54,
          size: 64,
        ),
      );
    }

    if (PortfolioMediaResolver.isLocalFile(imagePath)) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.white54,
          size: 64,
        ),
      );
    }

    return const Icon(
      Icons.image_not_supported_outlined,
      color: Colors.white54,
      size: 64,
    );
  }
}

class _PortfolioVideoPage extends StatefulWidget {
  const _PortfolioVideoPage({
    required this.videoPath,
    this.description,
  });

  final String videoPath;
  final String? description;

  @override
  State<_PortfolioVideoPage> createState() => _PortfolioVideoPageState();
}

class _PortfolioVideoPageState extends State<_PortfolioVideoPage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initPlayer() async {
    try {
      final path = widget.videoPath;
      final VideoPlayerController controller;
      if (PortfolioMediaResolver.isAsset(path)) {
        controller = VideoPlayerController.asset(path);
      } else if (PortfolioMediaResolver.isNetwork(path)) {
        controller = VideoPlayerController.networkUrl(Uri.parse(path));
      } else {
        controller = VideoPlayerController.file(File(path));
      }

      await controller.initialize();
      controller.setLooping(true);
      controller.addListener(_onControllerUpdate);
      if (!mounted) {
        controller.removeListener(_onControllerUpdate);
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      await controller.play();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar el video';
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isPlaying = controller?.value.isPlaying ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Video del trabajo'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator(color: AppColors.brandOrange)
                  : _error != null
                      ? Text(_error!, style: const TextStyle(color: Colors.white70))
                      : controller == null
                          ? const SizedBox.shrink()
                          : GestureDetector(
                              onTap: _togglePlay,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio: controller.value.aspectRatio,
                                    child: VideoPlayer(controller),
                                  ),
                                  if (!isPlaying)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                    ),
                                ],
                              ),
                            ),
            ),
          ),
          if (controller != null && !_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _togglePlay,
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: AppColors.brandOrange,
                      size: 40,
                    ),
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppColors.brandOrange,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (widget.description != null && widget.description!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                widget.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

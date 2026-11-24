import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/evidence_video_limits.dart';
import '../widgets/evidence_shutter_button.dart';

/// Resultado de la cámara de evidencia (foto o video tomados en la app).
class EvidenceCapture {
  const EvidenceCapture({
    required this.file,
    required this.isVideo,
    this.duration,
  });

  final XFile file;
  final bool isVideo;
  final Duration? duration;
}

/// Vista previa con disparador: toque = foto, mantener = video (hasta 30 s).
class EvidenceShutterCameraPage extends StatefulWidget {
  const EvidenceShutterCameraPage({super.key});

  @override
  State<EvidenceShutterCameraPage> createState() =>
      _EvidenceShutterCameraPageState();
}

class _EvidenceShutterCameraPageState extends State<EvidenceShutterCameraPage> {
  CameraController? _controller;
  String? _error;
  bool _busy = false;
  bool _recording = false;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  Stopwatch? _watch;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _abrirCamara();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  Future<void> _abrirCamara() async {
    try {
      final camara = await Permission.camera.request();
      if (!camara.isGranted) {
        throw StateError('Se necesita el permiso de cámara para la evidencia.');
      }
      final microfono = await Permission.microphone.request();
      if (!microfono.isGranted) {
        throw StateError(
          'Se necesita el micrófono para grabar el video de evidencia.',
        );
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('Este dispositivo no tiene una cámara disponible.');
      }
      final back = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('StateError: ', ''));
    }
  }

  String _reloj(Duration value) {
    final total = value.inSeconds;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _tomarFoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy || _recording) {
      return;
    }
    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(EvidenceCapture(file: file, isVideo: false));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo tomar la foto.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _empezarVideo() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _busy ||
        _recording ||
        _stopping) {
      return;
    }
    setState(() => _busy = true);
    try {
      await controller.startVideoRecording();
      final watch = Stopwatch()..start();
      _watch = watch;
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || !_recording) return;
        final elapsed = watch.elapsed;
        setState(() => _elapsed = elapsed);
        if (elapsed >= EvidenceVideoLimits.maxDuration) {
          _detenerVideo();
        }
      });
      if (!mounted) return;
      setState(() {
        _recording = true;
        _elapsed = Duration.zero;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'No se pudo empezar a grabar.';
      });
    }
  }

  Future<void> _detenerVideo() async {
    final controller = _controller;
    if (controller == null || !_recording || _stopping) return;
    _stopping = true;
    _ticker?.cancel();
    final duration = _watch?.elapsed ?? _elapsed;
    _watch?.stop();
    try {
      final file = await controller.stopVideoRecording();
      if (!mounted) return;
      if (duration < EvidenceVideoLimits.minDuration) {
        setState(() {
          _recording = false;
          _elapsed = Duration.zero;
          _stopping = false;
          _error =
              'El video es demasiado corto. Mantén presionado el disparador, o toca para una foto.';
        });
        return;
      }
      Navigator.of(context).pop(
        EvidenceCapture(file: file, isVideo: true, duration: duration),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recording = false;
        _elapsed = Duration.zero;
        _error = 'No se pudo detener la grabación.';
      });
    } finally {
      _stopping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              )
            else if (_error == null)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (_error != null)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            if (_recording)
              const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: _RecordingBadge(),
                ),
              ),
            if (_recording)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Text(
                    _reloj(_elapsed),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFeatures: [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Cerrar',
                onPressed: _recording ? null : () => Navigator.of(context).pop(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _recording
                          ? 'Suelta para detener (máx. 30 s)'
                          : 'Toca para foto · mantén para video',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    EvidenceShutterButton(
                      onPhoto: _tomarFoto,
                      onVideoStart: _empezarVideo,
                      onVideoEnd: _detenerVideo,
                      isRecording: _recording,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingBadge extends StatelessWidget {
  const _RecordingBadge();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xE6E53935),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'REC',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

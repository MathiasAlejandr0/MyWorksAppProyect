import 'package:flutter/material.dart';

/// Disparador de la cámara de evidencia: un toque saca foto; mantener graba video.
class EvidenceShutterButton extends StatefulWidget {
  const EvidenceShutterButton({
    super.key,
    required this.onPhoto,
    required this.onVideoStart,
    required this.onVideoEnd,
    this.isRecording = false,
  });

  final VoidCallback onPhoto;
  final VoidCallback onVideoStart;
  final VoidCallback onVideoEnd;
  final bool isRecording;

  static const Key shutterKey = Key('evidence-shutter');

  @override
  State<EvidenceShutterButton> createState() => _EvidenceShutterButtonState();
}

class _EvidenceShutterButtonState extends State<EvidenceShutterButton> {
  bool _holdStarted = false;

  void _startHold() {
    if (widget.isRecording || _holdStarted) return;
    _holdStarted = true;
    widget.onVideoStart();
  }

  void _endHold() {
    if (!_holdStarted) return;
    _holdStarted = false;
    widget.onVideoEnd();
  }

  @override
  Widget build(BuildContext context) {
    final recording = widget.isRecording;
    final accent = recording ? const Color(0xFFE53935) : Colors.white;
    return Semantics(
      button: true,
      label: recording
          ? 'Grabando video. Suelta para detener.'
          : 'Disparador. Toca para una foto o mantén presionado para grabar un video.',
      child: GestureDetector(
        key: EvidenceShutterButton.shutterKey,
        behavior: HitTestBehavior.opaque,
        onTap: recording ? null : widget.onPhoto,
        onLongPressStart: recording ? null : (_) => _startHold(),
        onLongPressEnd: (_) => _endHold(),
        onLongPressCancel: _endHold,
        child: SizedBox(
          width: 84,
          height: 84,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: recording ? const Color(0xFFE53935) : Colors.white,
                  shape: recording ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: recording ? BorderRadius.circular(12) : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

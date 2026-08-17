import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/app_feedback.dart';
import '../../theme/app_colors.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';

/// Anillo Espacial de Urgencia 3s basado en la Ley de Hick-Hyman.
class SpatialEmergencyPulseDialog extends StatefulWidget {
  const SpatialEmergencyPulseDialog({super.key});

  @override
  State<SpatialEmergencyPulseDialog> createState() => _SpatialEmergencyPulseDialogState();
}

class _SpatialEmergencyPulseDialogState extends State<SpatialEmergencyPulseDialog> {
  double _progress = 0.0;
  bool _isHolding = false;
  bool _dispatched = false;
  Timer? _timer;

  void _startHolding() {
    AppFeedback.medium();
    setState(() {
      _isHolding = true;
      _progress = 0.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_progress >= 1.0) {
        timer.cancel();
        AppFeedback.heavy();
        setState(() {
          _dispatched = true;
        });
      } else {
        setState(() {
          _progress += 0.035;
        });
      }
    });
  }

  void _stopHolding() {
    _timer?.cancel();
    if (!_dispatched) {
      setState(() {
        _isHolding = false;
        _progress = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121826) : AppColors.brandNavy,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.3),
              blurRadius: 25,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_dispatched) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.error, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'URGENCIA 3 SEGUNDOS (HICK-HYMAN)',
                      style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Disparo Espacial de Emergencia 24/7',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Mantén presionado el botón por 3 segundos para convocar al profesional más cercano en un radio de 5km.',
                style: TextStyle(color: Colors.white70, fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Botón de Pulso
              GestureDetector(
                onTapDown: (_) => _startHolding(),
                onTapUp: (_) => _stopHolding(),
                onTapCancel: _stopHolding,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isHolding
                          ? [AppColors.error, AppColors.brandOrangeVibrant]
                          : [AppColors.brandOrangeVibrant, AppColors.brandOrange],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isHolding ? AppColors.error : AppColors.brandOrange).withValues(alpha: 0.6),
                        blurRadius: _isHolding ? 35 : 15,
                        spreadRadius: _isHolding ? 8 : 2,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.radar_rounded, color: Colors.white, size: 40),
                      SizedBox(height: 4),
                      Text(
                        'MANTÉN 3 SEG',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Barra de Progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white10,
                  color: AppColors.error,
                  minHeight: 6,
                ),
              ),
            ] else ...[
              const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 64),
              const SizedBox(height: 16),
              const Text(
                '¡Alerta Transmitida con Éxito!',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Se notificó la urgencia a los profesionales verificados en tu zona.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandOrange),
                child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

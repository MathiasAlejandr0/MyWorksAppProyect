import 'package:flutter/material.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';
import '../../services/app_feedback.dart';
import '../../theme/app_colors.dart';

/// Widget interactivo estilo Apple para comparar fotografías Antes / Después con control táctil.
class BeforeAfterSlider extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;
  final String? title;
  final double height;

  const BeforeAfterSlider({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.title,
    this.height = 240,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _sliderPosition = 0.5; // De 0.0 (Todo antes) a 1.0 (Todo después)

  void _updatePosition(double localDx, double width) {
    if (width <= 0) return;
    final pos = (localDx / width).clamp(0.0, 1.0);
    if ((pos - _sliderPosition).abs() > 0.05) {
      AppFeedback.selection();
    }
    setState(() => _sliderPosition = pos);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                const Icon(Icons.compare_rounded, size: 18, color: AppColors.brandOrange),
                const SizedBox(width: 6),
                Text(
                  widget.title!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.brandNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final clipWidth = width * _sliderPosition;

                return GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _updatePosition(details.localPosition.dx, width),
                  onTapDown: (details) =>
                      _updatePosition(details.localPosition.dx, width),
                  child: Stack(
                    children: [
                      // 1. Imagen "Después" (Fondo Completo)
                      Positioned.fill(
                        child: Image.network(
                          widget.afterImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.brandOrangeSoft,
                            child: const Center(
                              child: Text('Foto Después', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ),

                      // Badge "DESPUÉS" (Esquina Derecha Superior)
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: _BadgeChip(
                          label: '✨ DESPUÉS',
                          color: AppColors.emerald,
                        ),
                      ),

                      // 2. Imagen "Antes" (Recortada dinámicamente)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: clipWidth,
                        child: ClipRect(
                          child: SizedBox(
                            width: width,
                            child: OverflowBox(
                              minWidth: width,
                              maxWidth: width,
                              alignment: Alignment.centerLeft,
                              child: Image.network(
                                widget.beforeImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppColors.grayBorder,
                                  child: const Center(
                                    child: Text('Foto Antes', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Badge "ANTES" (Esquina Izquierda Superior)
                      const Positioned(
                        top: 12,
                        left: 12,
                        child: _BadgeChip(
                          label: '📷 ANTES',
                          color: AppColors.brandNavy,
                        ),
                      ),

                      // 3. Barra Divisora y Tirador Móvil Táctil
                      Positioned(
                        left: clipWidth - 20,
                        top: 0,
                        bottom: 0,
                        width: 40,
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.brandOrange,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.unfold_more_rounded,
                              color: AppColors.brandNavy,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      // Línea divisora blanca vertical
                      Positioned(
                        left: clipWidth - 1,
                        top: 0,
                        bottom: 0,
                        width: 2,
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

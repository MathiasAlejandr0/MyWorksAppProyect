import 'package:flutter/material.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';

/// Bloque "Cómo funciona" — layout horizontal premium, theme-aware.
class HowItWorksCard extends StatelessWidget {
  const HowItWorksCard({super.key});

  static const _steps = [
    (
      '1',
      'Publica tu trabajo',
      'Describe lo que necesitas y tu presupuesto.',
      Icons.work_outline_rounded,
    ),
    (
      '2',
      'Recibe propuestas',
      'Profesionales interesados te envían sus propuestas.',
      Icons.groups_rounded,
    ),
    (
      '3',
      'Elige y colabora',
      'Selecciona al mejor profesional, trabaja seguro y recibe tu proyecto.',
      Icons.verified_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final bodyColor = AppColors.onCanvasMuted(brightness);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: AppDecorations.surfaceCardOf(
        context,
        accent: AppColors.brandOrange,
        radius: 20,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Cómo funciona',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: titleColor,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: AppColors.brandOrange.withValues(alpha: 0.95),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _steps.length; i++)
                Expanded(
                  child: _StepColumn(
                    number: _steps[i].$1,
                    title: _steps[i].$2,
                    body: _steps[i].$3,
                    icon: _steps[i].$4,
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                    showConnectorLeft: i > 0,
                    showConnectorRight: i < _steps.length - 1,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepColumn extends StatelessWidget {
  const _StepColumn({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
    required this.titleColor,
    required this.bodyColor,
    required this.showConnectorLeft,
    required this.showConnectorRight,
  });

  final String number;
  final String title;
  final String body;
  final IconData icon;
  final Color titleColor;
  final Color bodyColor;
  final bool showConnectorLeft;
  final bool showConnectorRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: showConnectorLeft
                          ? CustomPaint(
                              painter: _DashedLinePainter(
                                color: AppColors.brandOrange
                                    .withValues(alpha: 0.4),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: showConnectorRight
                          ? CustomPaint(
                              painter: _DashedLinePainter(
                                color: AppColors.brandOrange
                                    .withValues(alpha: 0.4),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandOrangeVibrant,
                      AppColors.brandOrange,
                    ],
                  ),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: bodyColor,
          ),
        ),
        const SizedBox(height: 8),
        Icon(icon, size: 18, color: AppColors.brandOrange),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = x + dash > size.width ? size.width : x + dash;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Skeleton loader animado con pulso suave.
class LoadingSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacityAnim = Tween<double>(begin: 0.4, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.surfaceDarkElevated
        : AppColors.grayBorder.withValues(alpha: 0.5);

    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius:
                  widget.borderRadius ?? BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton para cards de lista.
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs + 2,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.hairlineOf(context),
        ),
      ),
      child: Row(
        children: [
          LoadingSkeleton(
            width: 54,
            height: 54,
            borderRadius: BorderRadius.circular(27),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(height: 16, width: 140),
                SizedBox(height: AppSpacing.xs + 2),
                LoadingSkeleton(height: 13, width: 190),
                SizedBox(height: AppSpacing.xs + 2),
                LoadingSkeleton(height: 12, width: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de skeletons para pestañas de trabajos / notificaciones.
class JobListSkeleton extends StatelessWidget {
  const JobListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ListItemSkeleton(),
    );
  }
}

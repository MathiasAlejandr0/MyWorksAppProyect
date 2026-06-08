import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum TourTooltipAlign { auto, above, below, center }

/// Paso de la guía interactiva, opcionalmente anclado a un widget.
class GuidedTourStep {
  const GuidedTourStep({
    this.targetKey,
    required this.title,
    required this.description,
    this.align = TourTooltipAlign.auto,
    this.targetPadding = const EdgeInsets.all(4),
  });

  final GlobalKey? targetKey;
  final String title;
  final String description;
  final TourTooltipAlign align;
  final EdgeInsets targetPadding;
}

/// Envuelve un widget para que el spotlight use sus dimensiones reales.
class TourTarget extends StatelessWidget {
  const TourTarget({
    super.key,
    required this.tourKey,
    required this.child,
    this.width,
  });

  final GlobalKey tourKey;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: tourKey,
      width: width,
      child: child,
    );
  }
}

/// Overlay con spotlight y tooltip cerca del elemento explicado.
class AppGuidedTour extends StatefulWidget {
  const AppGuidedTour({
    super.key,
    required this.child,
    required this.steps,
    required this.shouldShow,
    required this.onComplete,
    this.badgeLabel = 'Guía rápida',
  });

  final Widget child;
  final List<GuidedTourStep> steps;
  final Future<bool> Function() shouldShow;
  final Future<void> Function() onComplete;
  final String badgeLabel;

  @override
  State<AppGuidedTour> createState() => _AppGuidedTourState();
}

class _AppGuidedTourState extends State<AppGuidedTour>
    with SingleTickerProviderStateMixin {
  final _layerKey = GlobalKey();
  bool _visible = false;
  int _step = 0;
  Rect? _targetRect;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppGuidedTour oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_visible) {
      _scheduleMeasure();
    }
  }

  Future<void> _init() async {
    final show = await widget.shouldShow();
    if (!mounted) return;
    setState(() => _visible = show);
    if (show) _scheduleMeasure();
  }

  Future<void> _finish() async {
    await widget.onComplete();
    if (mounted) setState(() => _visible = false);
  }

  void _next() {
    if (_step < widget.steps.length - 1) {
      setState(() => _step++);
      _scheduleMeasure();
    } else {
      _finish();
    }
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
  }

  Future<void> _updateTargetRect() async {
    if (!_visible || _step >= widget.steps.length) return;

    final key = widget.steps[_step].targetKey;
    if (key != null) {
      final ctx = key.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
        await Future<void>.delayed(const Duration(milliseconds: 340));
      }
    }

    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;
    setState(() => _targetRect = _measureTarget(_step));
  }

  Rect? _measureTarget(int index) {
    if (index >= widget.steps.length) return null;

    final step = widget.steps[index];
    final targetCtx = step.targetKey?.currentContext;
    final layerCtx = _layerKey.currentContext;
    if (targetCtx == null || layerCtx == null) return null;

    final targetBox = targetCtx.findRenderObject() as RenderBox?;
    final layerBox = layerCtx.findRenderObject() as RenderBox?;
    if (targetBox == null ||
        layerBox == null ||
        !targetBox.hasSize ||
        !layerBox.hasSize) {
      return null;
    }

    final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: layerBox);
    final bottomRight = targetBox.localToGlobal(
      targetBox.size.bottomRight(Offset.zero),
      ancestor: layerBox,
    );

    final pad = step.targetPadding;
    return Rect.fromLTRB(
      topLeft.dx - pad.left,
      topLeft.dy - pad.top,
      bottomRight.dx + pad.right,
      bottomRight.dy + pad.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_visible &&
            notification is ScrollEndNotification &&
            notification.depth == 0) {
          _scheduleMeasure();
        }
        return false;
      },
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_visible && widget.steps.isNotEmpty)
            Positioned.fill(
              key: _layerKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  final step = widget.steps[_step];
                  final hole = _targetRect;
                  final tooltipRect = _tooltipPosition(size, hole, step.align);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: CustomPaint(
                          size: size,
                          painter: _SpotlightPainter(hole: hole),
                        ),
                      ),
                      if (hole != null) ...[
                        Positioned.fromRect(
                          rect: hole,
                          child: const IgnorePointer(child: SizedBox.expand()),
                        ),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final pulse = 1.5 + _pulseController.value * 2.5;
                            return Positioned.fromRect(
                              rect: hole.inflate(pulse),
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.brandOrange
                                          .withValues(alpha: 0.7),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      Positioned(
                        left: tooltipRect.left,
                        top: tooltipRect.top,
                        width: tooltipRect.width,
                        child: _TourTooltipCard(
                          badge: widget.badgeLabel,
                          step: step,
                          current: _step,
                          total: widget.steps.length,
                          onSkip: _finish,
                          onNext: _next,
                          isLast: _step >= widget.steps.length - 1,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Rect _tooltipPosition(Size layer, Rect? hole, TourTooltipAlign align) {
    const margin = 16.0;
    const cardWidth = 300.0;
    final width = layer.width < cardWidth + margin * 2
        ? layer.width - margin * 2
        : cardWidth;
    const estimatedHeight = 210.0;

    if (hole == null || align == TourTooltipAlign.center) {
      return Rect.fromLTWH(
        (layer.width - width) / 2,
        (layer.height - estimatedHeight) / 2,
        width,
        estimatedHeight,
      );
    }

    final preferBelow = align == TourTooltipAlign.below ||
        (align == TourTooltipAlign.auto &&
            hole.bottom + estimatedHeight + margin * 2 <= layer.height);

    double top;
    if (preferBelow) {
      top = hole.bottom + margin;
      if (top + estimatedHeight > layer.height - margin) {
        top = hole.top - estimatedHeight - margin;
      }
    } else {
      top = hole.top - estimatedHeight - margin;
      if (top < margin) {
        top = hole.bottom + margin;
      }
    }

    top = top.clamp(margin, layer.height - estimatedHeight - margin);
    final left = (hole.center.dx - width / 2)
        .clamp(margin, layer.width - width - margin);

    return Rect.fromLTWH(left, top, width, estimatedHeight);
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({this.hole});

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.42);

    if (hole == null) {
      canvas.drawPath(full, paint);
      return;
    }

    final rrect = RRect.fromRectAndRadius(hole!, const Radius.circular(12));
    final holePath = Path()..addRRect(rrect);
    final combined = Path.combine(PathOperation.difference, full, holePath);
    canvas.drawPath(combined, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) => old.hole != hole;
}

class _TourTooltipCard extends StatelessWidget {
  const _TourTooltipCard({
    required this.badge,
    required this.step,
    required this.current,
    required this.total,
    required this.onSkip,
    required this.onNext,
    required this.isLast,
  });

  final String badge;
  final GuidedTourStep step;
  final int current;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: AppColors.brandOrange.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrangeSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.brandOrange,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.grayMedium,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Omitir'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              step.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.grayDark,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              step.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grayMedium,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                total,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == current ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == current
                        ? AppColors.brandOrange
                        : AppColors.grayMedium.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                foregroundColor: Colors.white,
              ),
              child: Text(isLast ? 'Entendido' : 'Siguiente'),
            ),
          ],
        ),
      ),
    );
  }
}

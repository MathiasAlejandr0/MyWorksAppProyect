import 'dart:async';

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
    this.targetPadding = const EdgeInsets.all(6),
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
    return KeyedSubtree(
      key: tourKey,
      child: width == null
          ? child
          : SizedBox(width: width, child: child),
    );
  }
}

/// Overlay con spotlight y tooltip. El hueco se mide ANTES de mostrar el card.
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
  /// Evita mostrar el tooltip centrado antes de tener el spotlight del target.
  bool _anchorReady = false;
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
    if (!show) return;
    setState(() {
      _visible = true;
      _anchorReady = false;
      _targetRect = null;
    });
    // Espera un frame para que el árbol (TourTarget) esté montado.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await _prepareStep(_step);
  }

  Future<void> _finish() async {
    await widget.onComplete();
    if (mounted) {
      setState(() {
        _visible = false;
        _anchorReady = false;
        _targetRect = null;
      });
    }
  }

  Future<void> _next() async {
    if (_step < widget.steps.length - 1) {
      final next = _step + 1;
      setState(() {
        _step = next;
        _anchorReady = false;
        _targetRect = null;
      });
      await _prepareStep(next);
    } else {
      await _finish();
    }
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_visible) {
        unawaited(_prepareStep(_step));
      }
    });
  }

  Future<void> _prepareStep(int index) async {
    if (!_visible || index >= widget.steps.length || !mounted) return;

    final step = widget.steps[index];
    final key = step.targetKey;

    // 1) Scroll al target si existe.
    if (key != null) {
      final ctx = key.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.45,
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      } else {
        // Target aún no en árbol: reintento breve.
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    }

    if (!mounted || _step != index) return;

    // 2) Medir hole.
    Rect? hole;
    for (var attempt = 0; attempt < 6; attempt++) {
      await Future<void>.delayed(Duration(milliseconds: attempt == 0 ? 16 : 50));
      if (!mounted || _step != index) return;
      hole = _measureTarget(index);
      if (hole != null || key == null) break;
    }

    if (!mounted || _step != index) return;

    // 3) Primero pintar spotlight; un frame después el tooltip (fluidez).
    setState(() {
      _targetRect = hole;
      _anchorReady = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted || _step != index) return;
    setState(() => _anchorReady = true);
  }

  Rect? _measureTarget(int index) {
    if (index >= widget.steps.length) return null;

    final step = widget.steps[index];
    if (step.targetKey == null) return null;

    final targetCtx = step.targetKey!.currentContext;
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
                  final showTooltip = _anchorReady &&
                      (step.targetKey == null || hole != null);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: CustomPaint(
                            key: ValueKey('hole-$_step-${hole?.shortHash}'),
                            size: size,
                            painter: _SpotlightPainter(hole: hole),
                          ),
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
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.brandOrange
                                          .withValues(alpha: 0.75),
                                      width: 2.2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      if (showTooltip)
                        _AnimatedTourTooltip(
                          key: ValueKey('tip-$_step'),
                          layerSize: size,
                          hole: hole,
                          align: step.align,
                          child: _TourTooltipCard(
                            badge: widget.badgeLabel,
                            step: step,
                            current: _step,
                            total: widget.steps.length,
                            onSkip: () => unawaited(_finish()),
                            onNext: () => unawaited(_next()),
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
}

extension on Rect {
  int get shortHash =>
      (left * 10).round() ^
      (top * 10).round() ^
      (width * 10).round() ^
      (height * 10).round();
}

class _AnimatedTourTooltip extends StatelessWidget {
  const _AnimatedTourTooltip({
    super.key,
    required this.layerSize,
    required this.hole,
    required this.align,
    required this.child,
  });

  final Size layerSize;
  final Rect? hole;
  final TourTooltipAlign align;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rect = _tooltipPosition(layerSize, hole, align);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - t)),
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }

  Rect _tooltipPosition(Size layer, Rect? hole, TourTooltipAlign align) {
    const margin = 16.0;
    const cardWidth = 300.0;
    final width = layer.width < cardWidth + margin * 2
        ? layer.width - margin * 2
        : cardWidth;
    const estimatedHeight = 220.0;

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
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.48);

    if (hole == null) {
      canvas.drawPath(full, paint);
      return;
    }

    final rrect = RRect.fromRectAndRadius(hole!, const Radius.circular(14));
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
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: AppColors.brandOrange.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              step.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grayMedium,
                    height: 1.4,
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

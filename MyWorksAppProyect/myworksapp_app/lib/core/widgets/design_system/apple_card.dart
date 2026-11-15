import 'package:flutter/material.dart';

import '../../design_system/app_radius.dart';
import '../../theme/app_decorations.dart';

/// Tarjeta táctil estilo Apple HIG con curvatura continua, opacidades dinámicas y animación de presión táctil.
class AppleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? accentColor;
  final double borderRadius;
  final bool isGlass;
  final bool enablePressEffect;

  const AppleCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.accentColor,
    this.borderRadius = AppRadius.lg,
    this.isGlass = false,
    this.enablePressEffect = true,
  });

  @override
  State<AppleCard> createState() => _AppleCardState();
}

class _AppleCardState extends State<AppleCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enablePressEffect) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null && widget.enablePressEffect) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null && widget.enablePressEffect) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final decoration = widget.isGlass
        ? AppDecorations.glassPanel(radius: widget.borderRadius, isDark: isDark)
        : AppDecorations.surfaceCard(
            accent: widget.accentColor,
            radius: widget.borderRadius,
            isDark: isDark,
            overrideColor: widget.backgroundColor,
          );

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: widget.padding ?? const EdgeInsets.all(16),
            decoration: decoration,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';
import 'primary_button.dart';

/// Fondo atmosférico del design system. Respeta [ThemeData.brightness].
class AuthSoftBackground extends StatelessWidget {
  const AuthSoftBackground({
    super.key,
    required this.child,
    this.showDecorations = true,
  });

  final Widget child;
  final bool showDecorations;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: AppDecorations.canvasOf(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.welcomeGradientOf(context),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showDecorations) ...[
              Positioned(
                top: -110,
                right: -40,
                child: _GlowOrb(
                  size: 280,
                  color: AppColors.brandOrange.withValues(
                    alpha: isDark ? 0.18 : 0.10,
                  ),
                ),
              ),
              Positioned(
                top: 180,
                left: -90,
                child: _GlowOrb(
                  size: 220,
                  color: (isDark
                          ? const Color(0xFF1B4F72)
                          : AppColors.brandNavy)
                      .withValues(alpha: isDark ? 0.28 : 0.06),
                ),
              ),
              Positioned(
                bottom: -80,
                right: -30,
                child: _GlowOrb(
                  size: 260,
                  color: AppColors.brandOrange.withValues(
                    alpha: isDark ? 0.08 : 0.06,
                  ),
                ),
              ),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class BrandPrimaryButton extends StatelessWidget {
  const BrandPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}

class BrandLabeledField extends StatelessWidget {
  const BrandLabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: AppColors.headlineOnScreen(context),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

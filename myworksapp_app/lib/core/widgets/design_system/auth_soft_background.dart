import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'primary_button.dart';

/// Fondo blanco con acentos naranjos suaves.
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  AppColors.backgroundDark,
                  Color(0xFF121E33),
                  Color(0xFF1A140E),
                ]
              : const [
                  AppColors.white,
                  AppColors.brandOrangeSoft,
                  Color(0xFFFFFAF7),
                ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showDecorations) ...[
            const _DecorIcon(
              icon: Icons.auto_awesome,
              top: 48,
              left: 16,
              size: 28,
            ),
            const _DecorIcon(
              icon: Icons.cleaning_services_outlined,
              top: 120,
              left: 8,
              size: 32,
            ),
            const _DecorIcon(
              icon: Icons.plumbing_outlined,
              top: 200,
              left: 20,
              size: 30,
              structural: true,
            ),
            const _DecorIcon(
              icon: Icons.bolt_outlined,
              top: 280,
              left: 10,
              size: 28,
            ),
            const _DecorIcon(
              icon: Icons.yard_outlined,
              top: 100,
              right: 12,
              size: 32,
            ),
            const _DecorIcon(
              icon: Icons.handyman_outlined,
              top: 190,
              right: 18,
              size: 30,
              structural: true,
            ),
            const _DecorIcon(
              icon: Icons.home_repair_service_outlined,
              top: 270,
              right: 8,
              size: 28,
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _DecorIcon extends StatelessWidget {
  const _DecorIcon({
    required this.icon,
    required this.top,
    this.left,
    this.right,
    required this.size,
    this.structural = false,
  });

  final IconData icon;
  final double top;
  final double? left;
  final double? right;
  final double size;
  final bool structural;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Icon(
        icon,
        size: size,
        color: AppColors.decorOnCanvas(brightness, structural: structural),
      ),
    );
  }
}

/// Botón CTA de marca — delega en [PrimaryButton] unificado.
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

/// Campo de texto con etiqueta encima (estilo mockup login).
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.white
                : AppColors.grayDark,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

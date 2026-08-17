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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.white,
            AppColors.brandOrangeSoft,
            Color(0xFFFFFAF7),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showDecorations) ...[
            const _DecorIcon(
              icon: Icons.auto_awesome,
              color: AppColors.brandOrange,
              top: 48,
              left: 16,
              size: 28,
            ),
            const _DecorIcon(
              icon: Icons.cleaning_services_outlined,
              color: AppColors.brandOrange,
              top: 120,
              left: 8,
              size: 32,
            ),
            const _DecorIcon(
              icon: Icons.plumbing_outlined,
              color: AppColors.brandNavy,
              top: 200,
              left: 20,
              size: 30,
            ),
            const _DecorIcon(
              icon: Icons.bolt_outlined,
              color: AppColors.brandOrange,
              top: 280,
              left: 10,
              size: 28,
            ),
            const _DecorIcon(
              icon: Icons.yard_outlined,
              color: AppColors.brandOrange,
              top: 100,
              right: 12,
              size: 32,
            ),
            const _DecorIcon(
              icon: Icons.handyman_outlined,
              color: AppColors.brandNavy,
              top: 190,
              right: 18,
              size: 30,
            ),
            const _DecorIcon(
              icon: Icons.home_repair_service_outlined,
              color: AppColors.brandOrange,
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
    required this.color,
    required this.top,
    this.left,
    this.right,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double top;
  final double? left;
  final double? right;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Icon(
        icon,
        size: size,
        color: color.withValues(alpha: 0.4),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.grayDark,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

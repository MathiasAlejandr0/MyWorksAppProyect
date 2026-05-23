import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Fondo suave con gradiente para pantallas de autenticación.
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
            Color(0xFFEAF6FC),
            Color(0xFFF8FAFC),
            Color(0xFFFFF8F3),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showDecorations) ...[
            _DecorIcon(
              icon: Icons.auto_awesome,
              color: const Color(0xFFFFD166),
              top: 48,
              left: 16,
              size: 28,
            ),
            _DecorIcon(
              icon: Icons.cleaning_services_outlined,
              color: AppColors.brandTeal,
              top: 120,
              left: 8,
              size: 32,
            ),
            _DecorIcon(
              icon: Icons.plumbing_outlined,
              color: AppColors.brandNavy,
              top: 200,
              left: 20,
              size: 30,
            ),
            _DecorIcon(
              icon: Icons.bolt_outlined,
              color: AppColors.brandOrange,
              top: 280,
              left: 10,
              size: 28,
            ),
            _DecorIcon(
              icon: Icons.yard_outlined,
              color: const Color(0xFF6BCB77),
              top: 100,
              right: 12,
              size: 32,
            ),
            _DecorIcon(
              icon: Icons.handyman_outlined,
              color: AppColors.brandNavy,
              top: 190,
              right: 18,
              size: 30,
            ),
            _DecorIcon(
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
        color: color.withValues(alpha: 0.55),
      ),
    );
  }
}

/// Botón CTA naranja estilo mockup (pill).
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.brandOrange.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.isLoading,
    required this.onGoogle,
    this.onApple,
  });

  final bool isLoading;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  bool get _showApple =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AppColors.grayMedium.withValues(alpha: 0.35),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'o continúa con',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grayMedium.withValues(alpha: 0.95),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: AppColors.grayMedium.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SocialButton(
          label: 'Continuar con Google',
          icon: Icons.g_mobiledata_rounded,
          foreground: Theme.of(context).brightness == Brightness.dark
              ? AppColors.white
              : AppColors.grayDark,
          background: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDarkElevated
              : Colors.white,
          borderColor: AppColors.brandOrange.withValues(alpha: 0.28),
          onPressed: isLoading ? null : onGoogle,
        ),
        if (_showApple) ...[
          const SizedBox(height: 10),
          _SocialButton(
            label: 'Continuar con Apple',
            icon: Icons.apple,
            foreground: Colors.white,
            background: Colors.black,
            borderColor: Colors.black,
            onPressed: isLoading ? null : onApple,
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.borderColor,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22, color: foreground),
      label: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

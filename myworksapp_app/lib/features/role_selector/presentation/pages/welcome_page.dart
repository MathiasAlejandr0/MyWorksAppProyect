import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_breakpoints.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_brand_logo.dart';
import '../../../../core/widgets/design_system/auth_soft_background.dart';
import '../../../../core/widgets/design_system/premium_glyphs.dart';

/// Pantalla de bienvenida — layout premium alineado al mockup, theme-aware.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final title = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);

    return Scaffold(
      backgroundColor: AppDecorations.canvasOf(context),
      body: AuthSoftBackground(
        showDecorations: true,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppBreakpoints.screenPadding(context) + 12,
            ),
            child: Column(
              children: [
                const SizedBox(height: 28),
                const AppBrandLogo(size: 48, showText: false),
                const SizedBox(height: 10),
                Text(
                  AppConstants.appBrandDisplayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: title,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Soluciones profesionales\npara tu hogar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: title,
                    height: 1.15,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Profesionales verificados, rápidos y de confianza para cada necesidad de tu hogar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.brandOrange,
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandOrange.withValues(alpha: 0.22),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.5),
                      child: Image.asset(
                        'assets/images/welcome_hero.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: AppColors.surfaceOf(context),
                          child: const Center(
                            child: Icon(
                              Icons.handyman_rounded,
                              size: 64,
                              color: AppColors.brandOrange,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _CategoryPills(),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => context.push(
                      AppConstants.routeLogin,
                      extra: {'role': AppConstants.roleUser},
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Comenzar Ahora'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPills extends StatelessWidget {
  const _CategoryPills();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    const items = [
      (PremiumGlyphKind.assembly, 'Armado'),
      (PremiumGlyphKind.electric, 'Electricidad'),
      (PremiumGlyphKind.plumbing, 'Plomería'),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.fieldFillOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.hairlineOf(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PremiumGlyph(
                    kind: items[i].$1,
                    size: 18,
                    color: AppColors.brandOrange,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      items[i].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.onCanvas(brightness),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

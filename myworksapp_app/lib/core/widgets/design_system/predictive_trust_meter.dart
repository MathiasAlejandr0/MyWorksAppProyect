import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';

/// Medidor de Confianza Transaccional basado en la Regla del Pico-Final de Kahneman.
class PredictiveTrustMeterWidget extends StatelessWidget {
  final double score;
  final String fairPriceIndex;
  final int reviewsCount;

  const PredictiveTrustMeterWidget({
    super.key,
    this.score = 99.4,
    this.fairPriceIndex = 'Óptimo (420 cotizaciones)',
    this.reviewsCount = 198,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: AppColors.emerald, size: 20),
              const SizedBox(width: 8),
              Text(
                'Confianza Transaccional IA',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.brandNavy,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$score% Fiabilidad',
                  style: const TextStyle(color: AppColors.emerald, fontSize: 10.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _trustItem(
                  context,
                  Icons.scale_rounded,
                  'Fair Price',
                  fairPriceIndex,
                  AppColors.brandOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _trustItem(
                  context,
                  Icons.verified_user_rounded,
                  'Escrow 100%',
                  'Retenido con PIN',
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustItem(BuildContext context, IconData icon, String title, String val, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : AppColors.grayMedium)),
            ],
          ),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

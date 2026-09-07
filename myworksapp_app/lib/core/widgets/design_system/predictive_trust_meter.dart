import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';

/// Indicadores de confianza basados en métricas medibles (cuando existen).
class PredictiveTrustMeterWidget extends StatelessWidget {
  final double? score;
  final String? fairPriceIndex;
  final int? reviewsCount;

  const PredictiveTrustMeterWidget({
    super.key,
    this.score,
    this.fairPriceIndex,
    this.reviewsCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasScore = score != null;
    final chipLabel = hasScore ? '${score!}% Fiabilidad' : 'Sin métrica';
    final chipColor = hasScore ? AppColors.emerald : AppColors.grayMedium;
    final priceLabel = fairPriceIndex ?? 'Sin datos medidos';

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
                'Indicadores de confianza',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.brandNavy,
                ),
              ),
              const Spacer(),
              if (!hasScore) ...[
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(
                      color: AppColors.brandOrange,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  chipLabel,
                  style: TextStyle(
                    color: chipColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (!hasScore) ...[
            const SizedBox(height: 10),
            Text(
              'Sin datos medidos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.grayMedium,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _trustItem(
                  context,
                  Icons.scale_rounded,
                  'Precio estimado',
                  priceLabel,
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
          if (reviewsCount != null) ...[
            const SizedBox(height: 8),
            Text(
              '$reviewsCount reseñas',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : AppColors.grayMedium,
              ),
            ),
          ],
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

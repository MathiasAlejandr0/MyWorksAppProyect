import 'package:flutter/material.dart';
import '../../../core/domain/pricing_constants.dart';
import '../../../core/utils/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';

/// Badge de estado para trabajos
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color _getStatusColor() {
    switch (status) {
      case AppConstants.jobStatusPending:
        return AppColors.warning;
      case AppConstants.jobStatusAccepted:
        return AppColors.primaryLight; // Usar primaryLight en lugar de info
      case AppConstants.jobStatusInProgress:
        return AppColors.primaryLight;
      case AppConstants.jobStatusCompleted:
        return AppColors.success;
      case AppConstants.jobStatusCancelled:
        return AppColors.error;
      case PricingConstants.jobAwaitingPayment:
        return AppColors.brandOrange;
      case PricingConstants.jobAwaitingQuotes:
        return AppColors.warning;
      case PricingConstants.jobQuoteSelected:
        return AppColors.brandTeal;
      case PricingConstants.jobPausedChangeOrder:
        return AppColors.warning;
      default:
        return AppColors.grayMedium;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case AppConstants.jobStatusPending:
        return 'Pendiente';
      case AppConstants.jobStatusAccepted:
        return 'Aceptado';
      case AppConstants.jobStatusInProgress:
        return 'En Curso';
      case AppConstants.jobStatusCompleted:
        return 'Completado';
      case AppConstants.jobStatusCancelled:
        return 'Cancelado';
      case PricingConstants.jobAwaitingPayment:
        return 'Pago pendiente';
      case PricingConstants.jobAwaitingQuotes:
        return 'Esperando cotizaciones';
      case PricingConstants.jobQuoteSelected:
        return 'Cotización elegida';
      case PricingConstants.jobPausedChangeOrder:
        return 'Cobro extra pendiente';
      default:
        return status;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case AppConstants.jobStatusPending:
        return Icons.pending;
      case AppConstants.jobStatusAccepted:
        return Icons.check_circle_outline;
      case AppConstants.jobStatusInProgress:
        return Icons.work_outline;
      case AppConstants.jobStatusCompleted:
        return Icons.check_circle;
      case AppConstants.jobStatusCancelled:
        return Icons.cancel;
      case PricingConstants.jobAwaitingPayment:
        return Icons.payment_outlined;
      case PricingConstants.jobAwaitingQuotes:
        return Icons.request_quote_outlined;
      case PricingConstants.jobQuoteSelected:
        return Icons.fact_check_outlined;
      case PricingConstants.jobPausedChangeOrder:
        return Icons.pause_circle_outline;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: compact ? 14 : 16,
            color: color,
          ),
          if (!compact) ...[
            SizedBox(width: AppSpacing.xs),
            Text(
              _getStatusLabel(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}


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
        return AppColors.info;
      case AppConstants.jobStatusInProgress:
        return AppColors.info;
      case AppConstants.jobStatusCompleted:
        return AppColors.success;
      case AppConstants.jobStatusCancelled:
        return AppColors.error;
      case PricingConstants.jobAwaitingPayment:
        return AppColors.warning;
      case PricingConstants.jobAwaitingQuotes:
        return AppColors.info;
      case PricingConstants.jobQuoteSelected:
        return AppColors.success;
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
      case PricingConstants.jobAwaitingClientApproval:
        return 'Esperando cliente';
      default:
        return status;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case AppConstants.jobStatusPending:
        return Icons.pending_rounded;
      case AppConstants.jobStatusAccepted:
        return Icons.check_circle_outline_rounded;
      case AppConstants.jobStatusInProgress:
        return Icons.play_circle_outline_rounded;
      case AppConstants.jobStatusCompleted:
        return Icons.task_alt_rounded;
      case AppConstants.jobStatusCancelled:
        return Icons.cancel_rounded;
      case PricingConstants.jobAwaitingPayment:
        return Icons.payment_rounded;
      case PricingConstants.jobAwaitingQuotes:
        return Icons.request_quote_rounded;
      case PricingConstants.jobQuoteSelected:
        return Icons.fact_check_rounded;
      case PricingConstants.jobPausedChangeOrder:
        return Icons.pause_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 3 : AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: compact ? 13 : 15,
            color: color,
          ),
          if (!compact) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              _getStatusLabel(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}



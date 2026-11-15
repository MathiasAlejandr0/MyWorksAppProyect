import 'package:flutter/material.dart';
import '../../../core/utils/job_status_copy.dart';
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

  Color _getStatusColor() => JobStatusCopy.color(status);

  String _getStatusLabel() => JobStatusCopy.label(status);

  IconData _getStatusIcon() => JobStatusCopy.icon(status);

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



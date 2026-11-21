import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class WorkerQuickActionsRow extends StatelessWidget {
  const WorkerQuickActionsRow({
    super.key,
    required this.onCalendar,
    required this.onHistory,
    required this.onEarnings,
  });

  final VoidCallback onCalendar;
  final VoidCallback onHistory;
  final VoidCallback onEarnings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          _ActionTile(
            icon: Icons.calendar_month_outlined,
            label: 'Mi agenda',
            onTap: onCalendar,
          ),
          _ActionTile(
            icon: Icons.history,
            label: 'Historial',
            onTap: onHistory,
          ),
          _ActionTile(
            icon: Icons.payments_outlined,
            label: 'Ingresos',
            onTap: onEarnings,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.onCanvasMuted(Theme.of(context).brightness);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.fieldFillOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairlineOf(context)),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 22, color: AppColors.brandOrange),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

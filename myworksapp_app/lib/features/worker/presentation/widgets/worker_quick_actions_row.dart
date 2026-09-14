import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class WorkerQuickActionsRow extends StatelessWidget {
  const WorkerQuickActionsRow({
    super.key,
    required this.unread,
    required this.onCalendar,
    required this.onStats,
    required this.onHistory,
    required this.onNotifications,
    required this.onEditPricing,
  });

  final int unread;
  final VoidCallback onCalendar;
  final VoidCallback onStats;
  final VoidCallback onHistory;
  final VoidCallback onNotifications;
  final VoidCallback onEditPricing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ActionChip(
            icon: Icons.payments_outlined,
            label: 'Mis tarifas',
            onTap: onEditPricing,
          ),
          const SizedBox(width: 8),
          _ActionChip(icon: Icons.calendar_month, label: 'Calendario', onTap: onCalendar),
          const SizedBox(width: 8),
          _ActionChip(icon: Icons.bar_chart_rounded, label: 'Estadísticas', onTap: onStats),
          const SizedBox(width: 8),
          _ActionChip(icon: Icons.history, label: 'Historial', onTap: onHistory),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.notifications_active_outlined,
            label: unread > 0 ? 'Alertas ($unread)' : 'Alertas',
            onTap: onNotifications,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.brandNavy),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: AppColors.grayMedium.withValues(alpha: 0.22)),
      labelStyle: const TextStyle(
        color: AppColors.brandNavy,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}

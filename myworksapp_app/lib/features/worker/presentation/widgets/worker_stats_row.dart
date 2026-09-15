import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class WorkerStatsRow extends StatelessWidget {
  const WorkerStatsRow({
    super.key,
    required this.pending,
    required this.active,
    required this.completed,
    required this.selectedIndex,
    required this.onTap,
  });

  final int pending;
  final int active;
  final int completed;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Pendientes',
              value: '$pending',
              icon: Icons.inbox_rounded,
              accent: AppColors.brandOrange,
              selected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'En curso',
              value: '$active',
              icon: Icons.engineering_rounded,
              accent: AppColors.info,
              selected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Finalizados',
              value: '$completed',
              icon: Icons.check_circle_rounded,
              accent: AppColors.success,
              selected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? (selected
            ? accent.withValues(alpha: 0.16)
            : AppColors.surfaceDarkElevated)
        : (selected ? accent.withValues(alpha: 0.10) : AppColors.white);
    final valueColor = accent;
    final labelColor = isDark
        ? AppColors.white.withValues(alpha: 0.7)
        : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.65)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.grayBorder),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? accent.withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
                blurRadius: selected ? 16 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.4,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

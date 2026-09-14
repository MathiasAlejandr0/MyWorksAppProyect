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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Pendientes',
              value: '$pending',
              icon: Icons.inbox_outlined,
              color: AppColors.brandOrange,
              selected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'En curso',
              value: '$active',
              icon: Icons.engineering_outlined,
              color: AppColors.brandNavy,
              selected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Finalizados',
              value: '$completed',
              icon: Icons.check_circle_outline,
              color: AppColors.brandTeal,
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
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.55)
                  : AppColors.grayMedium.withValues(alpha: 0.2),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.grayDark,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.grayMedium,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
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

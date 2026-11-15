import 'package:flutter/material.dart';

import '../../../../core/domain/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import 'user_role_ui.dart';

/// Selector de rol Cliente / Especialista (y Admin opcional en debug).
class RoleSelectorChips extends StatelessWidget {
  const RoleSelectorChips({
    super.key,
    required this.selected,
    required this.onChanged,
    this.roles = UserRole.publicRoles,
  });

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  final List<UserRole> roles;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final inactiveFg = AppColors.onCanvasMuted(brightness);

    return Row(
      children: [
        for (var i = 0; i < roles.length; i++) ...[
          Expanded(
            child: _RoleChip(
              role: roles[i],
              selected: selected == roles[i],
              inactiveFg: inactiveFg,
              onTap: () => onChanged(roles[i]),
            ),
          ),
          if (i < roles.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.selected,
    required this.inactiveFg,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final Color inactiveFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: role.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandOrange.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.brandOrange
                  : AppColors.hairlineOf(context),
              width: selected ? 1.6 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.brandOrange.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                role.icon,
                size: 22,
                color: selected ? AppColors.brandOrange : inactiveFg,
              ),
              const SizedBox(height: 6),
              Text(
                role.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.brandOrange : inactiveFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

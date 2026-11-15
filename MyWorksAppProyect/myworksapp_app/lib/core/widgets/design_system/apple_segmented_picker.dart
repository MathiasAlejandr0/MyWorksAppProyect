import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Selector deslizante tipo iOS Segmented Control para filtros y categorización rápida.
class AppleSegmentedPicker<T> extends StatelessWidget {
  final Map<T, String> options;
  final T selectedValue;
  final ValueChanged<T> onValueChanged;
  final EdgeInsetsGeometry? padding;

  const AppleSegmentedPicker({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onValueChanged,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keys = options.keys.toList();

    return Container(
      padding: padding ?? const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : AppColors.grayLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.grayBorder.withValues(alpha: 0.1)
              : AppColors.grayBorder.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: keys.map((key) {
          final isSelected = key == selectedValue;
          final label = options[key] ?? '';

          return Expanded(
            child: GestureDetector(
              onTap: () => onValueChanged(key),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastOutSlowIn,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.surfaceDark : AppColors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? AppColors.white : AppColors.textPrimary)
                        : (isDark ? AppColors.textSecondary : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

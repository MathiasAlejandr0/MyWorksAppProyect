import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Selector de bloque 2 / 4 / 8 horas.
class HourlyBlockSelector extends StatelessWidget {
  const HourlyBlockSelector({
    super.key,
    required this.selectedHours,
    required this.onChanged,
  });

  final int selectedHours;
  final ValueChanged<int> onChanged;

  static const options = [2, 4, 8];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bloque de horas', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: options
              .map((h) => ButtonSegment(value: h, label: Text('$h h')))
              .toList(),
          selected: {selectedHours},
          onSelectionChanged: (s) => onChanged(s.first),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.brandOrange;
              }
              return null;
            }),
          ),
        ),
      ],
    );
  }
}

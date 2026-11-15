import 'package:flutter/material.dart';
import 'package:myworksapp/core/theme/app_colors.dart';
import 'package:myworksapp/core/utils/mock_reserved_slots.dart';

/// Chips de hora publicados por el profesional.
class TimeSlotSelector extends StatelessWidget {
  const TimeSlotSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.availableLabels,
    this.reservedLabels = const {},
    this.emptyHint =
        'Este profesional no tiene horarios libres en el día elegido.',
  });

  final TimeOfDay? selected;
  final ValueChanged<TimeOfDay> onChanged;
  final List<String>? availableLabels;
  final Set<String> reservedLabels;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final selectedLabel =
        selected == null ? null : MockReservedSlots.format(selected!);
    final slots = availableLabels ?? mockBookableSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horario',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          slots.isEmpty
              ? emptyHint
              : 'Solo se muestran las horas que el profesional publicó y que siguen libres.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (slots.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in slots)
                _SlotChip(
                  label: slot,
                  reserved: reservedLabels.contains(slot),
                  selected: selectedLabel == slot,
                  onPick: () => onChanged(MockReservedSlots.parse(slot)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.reserved,
    required this.selected,
    required this.onPick,
  });

  final String label;
  final bool reserved;
  final bool selected;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final disabledColor = Theme.of(context).disabledColor;

    return FilterChip(
      label: Text(label),
      avatar: reserved
          ? Icon(Icons.lock_outline, size: 16, color: disabledColor)
          : null,
      selected: selected && !reserved,
      showCheckmark: !reserved,
      onSelected: (_) {
        if (reserved) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text(MockReservedSlots.reservedMessage)),
            );
          return;
        }
        onPick();
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundColor: reserved
          ? disabledColor.withValues(alpha: 0.12)
          : null,
      labelStyle: TextStyle(
        color: reserved ? disabledColor : null,
        decoration: reserved ? TextDecoration.lineThrough : null,
        fontWeight: selected && !reserved ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: reserved
            ? disabledColor.withValues(alpha: 0.45)
            : selected
                ? AppColors.brandOrange
                : Theme.of(context).dividerColor,
      ),
    );
  }
}

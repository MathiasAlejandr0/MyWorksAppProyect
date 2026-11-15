import 'package:flutter/material.dart';

import '../../../../core/domain/worker_hours.dart';

class WorkerHoursEditor extends StatelessWidget {
  const WorkerHoursEditor({
    super.key,
    required this.hours,
    required this.selectedWeekday,
    required this.onSelectWeekday,
    required this.onAddHour,
    required this.onRemoveHour,
    required this.saving,
  });

  final List<WorkerHourSlot> hours;
  final int selectedWeekday;
  final ValueChanged<int> onSelectWeekday;
  final Future<void> Function(TimeOfDay time) onAddHour;
  final ValueChanged<WorkerHourSlot> onRemoveHour;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final dayHours = hours
        .where((slot) => slot.weekday == selectedWeekday)
        .map((slot) => slot.time)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horarios de atención',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Publica las horas en las que puedes recibir una visita. La misma hora no se puede repetir el mismo día.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final day in WorkerHourSlot.weekdayLabels.entries)
                FilterChip(
                  label: Text(day.value),
                  selected: selectedWeekday == day.key,
                  onSelected: (_) => onSelectWeekday(day.key),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (dayHours.isEmpty)
            Text(
              'Sin horas este día. Agrega las que quieras ofrecer.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final time in dayHours)
                  InputChip(
                    label: Text(time),
                    onDeleted: saving
                        ? null
                        : () => onRemoveHour(
                              WorkerHourSlot(
                                weekday: selectedWeekday,
                                time: time,
                              ),
                            ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: saving
                ? null
                : () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (picked == null) return;
                    await onAddHour(picked);
                  },
            icon: const Icon(Icons.add),
            label: const Text('Agregar hora'),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/domain/weekly_schedule.dart';

/// Horas de un día activo: una o más ventanas de inicio y término.
class WorkerDayWindowsEditor extends StatelessWidget {
  const WorkerDayWindowsEditor({
    super.key,
    required this.name,
    required this.day,
    required this.onChanged,
  });

  final String name;
  final DayWindow day;
  final ValueChanged<DayWindow> onChanged;

  static const _openMinute = 7 * 60;
  static const _closeMinute = 21 * 60;
  static const _maxWindows = 3;

  @override
  Widget build(BuildContext context) {
    final slots = publishedHourSlots([day]);
    final offered = slots.map((slot) => slot['hora'] as String).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: day.enabled,
                  onChanged: (value) => onChanged(day.copyWith(enabled: value)),
                ),
              ],
            ),
            if (!day.enabled)
              Text(
                'Activa el día para definir las horas de inicio y término.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              for (var index = 0; index < day.windows.length; index++)
                _WindowEditor(
                  range: day.windows[index],
                  canRemove: day.windows.length > 1,
                  onStart: () => _pick(context, index: index, start: true),
                  onEnd: () => _pick(context, index: index, start: false),
                  onRemove: () => _remove(index),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: day.windows.length >= _maxWindows
                      ? null
                      : () => _add(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar ventana'),
                ),
              ),
              Text(
                offered.isEmpty
                    ? 'La ventana debe durar al menos una hora.'
                    : 'El cliente podrá agendar: $offered',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context, {
    required int index,
    required bool start,
  }) async {
    final range = day.windows[index];
    final current = start ? range.startMinute : range.endMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (current ~/ 60).clamp(0, 23),
        minute: 0,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !context.mounted) return;
    final minute = picked.hour * 60;
    final next = start
        ? range.copyWith(startMinute: minute)
        : range.copyWith(endMinute: minute);
    if (!next.isValid) {
      _message(context, 'La hora de fin debe ser posterior al inicio.');
      return;
    }
    final ranges = [...day.windows];
    ranges[index] = next;
    final updated = day.copyWith(ranges: ranges);
    final overlap = overlappingWindowsMessage([updated]);
    if (overlap != null) {
      _message(context, overlap);
      return;
    }
    onChanged(updated);
  }

  void _add(BuildContext context) {
    final extra = suggestAdditionalWindow(day.windows);
    if (extra == null) {
      _message(context, 'No queda un hueco libre de al menos una hora.');
      return;
    }
    onChanged(day.copyWith(ranges: [...day.windows, extra]));
  }

  void _remove(int index) {
    final ranges = [...day.windows]..removeAt(index);
    onChanged(
      ranges.length == 1
          ? day.copyWith(
              ranges: const [],
              startMinute: ranges.single.startMinute,
              endMinute: ranges.single.endMinute,
            )
          : day.copyWith(ranges: ranges),
    );
  }

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _WindowEditor extends StatelessWidget {
  const _WindowEditor({
    required this.range,
    required this.canRemove,
    required this.onStart,
    required this.onEnd,
    required this.onRemove,
  });

  final TimeRange range;
  final bool canRemove;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          const Text('Inicio'),
          TextButton(
            onPressed: onStart,
            child: Text(formatMinute(range.startMinute)),
          ),
          const Text('Fin'),
          TextButton(
            onPressed: onEnd,
            child: Text(formatMinute(range.endMinute)),
          ),
          if (canRemove)
            IconButton(
              tooltip: 'Quitar ventana',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

/// Siguiente hueco de al menos una hora, primero después de la última ventana.
TimeRange? suggestAdditionalWindow(
  List<TimeRange> current, {
  int openMinute = WorkerDayWindowsEditor._openMinute,
  int closeMinute = WorkerDayWindowsEditor._closeMinute,
}) {
  const span = 3 * 60;
  final sorted = [...current]
    ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
  if (sorted.isEmpty) {
    return const TimeRange(startMinute: 9 * 60, endMinute: 13 * 60);
  }
  final last = sorted.last;
  if (closeMinute - last.endMinute >= 60) {
    return TimeRange(
      startMinute: last.endMinute,
      endMinute: math.min(closeMinute, last.endMinute + span),
    );
  }
  var cursor = openMinute;
  for (final window in sorted) {
    if (window.startMinute - cursor >= 60) {
      final end = math.min(window.startMinute, cursor + span);
      if (end - cursor >= 60) {
        return TimeRange(startMinute: cursor, endMinute: end);
      }
    }
    if (window.endMinute > cursor) cursor = window.endMinute;
  }
  return null;
}

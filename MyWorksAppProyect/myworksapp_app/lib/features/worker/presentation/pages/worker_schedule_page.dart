import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/repositories/worker_schedule_repository.dart';
import '../../../../core/domain/weekly_schedule.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class WorkerSchedulePage extends ConsumerStatefulWidget {
  const WorkerSchedulePage({super.key});

  @override
  ConsumerState<WorkerSchedulePage> createState() => _WorkerSchedulePageState();
}

class _WorkerSchedulePageState extends ConsumerState<WorkerSchedulePage> {
  final _repo = WorkerScheduleRepository();
  WeeklySchedule _schedule = WeeklySchedule.weekdaysNineToSix();
  bool _loading = true;
  bool _saving = false;

  static const _names = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    try {
      final loaded = await _repo.load(user.id);
      if (!mounted) return;
      setState(() {
        _schedule = loaded.days.isEmpty
            ? WeeklySchedule.weekdaysNineToSix().copyEnabled(loaded.enabled)
            : loaded;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
      );
    }
  }

  Future<void> _save() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    for (final day in _schedule.days) {
      if (day.enabled && day.endMinute <= day.startMinute) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_names[day.weekday - 1]}: la hora de fin debe ser posterior',
            ),
          ),
        );
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await _repo.save(userId: user.id, schedule: _schedule);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horario guardado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pick(int index, {required bool start}) async {
    final day = _schedule.days[index];
    final current = TimeOfDay(
      hour: (start ? day.startMinute : day.endMinute) ~/ 60,
      minute: (start ? day.startMinute : day.endMinute) % 60,
    );
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) return;
    final minute = picked.hour * 60 + picked.minute;
    final next = day.copyWith(
      startMinute: start ? minute : null,
      endMinute: start ? null : minute,
    );
    setState(() {
      final days = [..._schedule.days];
      days[index] = next;
      _schedule = WeeklySchedule(enabled: _schedule.enabled, days: days);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Horario semanal')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Usar este horario'),
                  subtitle: const Text(
                    'Si está apagado, «Disponible ahora» sigue el interruptor del inicio. '
                    'Si está encendido, también hay que estar dentro del rango del día.',
                  ),
                  value: _schedule.enabled,
                  onChanged: (value) {
                    setState(() {
                      _schedule =
                          WeeklySchedule(enabled: value, days: _schedule.days);
                    });
                  },
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _schedule.days.length; i++)
                  _DayRow(
                    name: _names[_schedule.days[i].weekday - 1],
                    day: _schedule.days[i],
                    onToggle: (value) {
                      setState(() {
                        final days = [..._schedule.days];
                        days[i] = days[i].copyWith(enabled: value);
                        _schedule = WeeklySchedule(
                            enabled: _schedule.enabled, days: days);
                      });
                    },
                    onStart: () => _pick(i, start: true),
                    onEnd: () => _pick(i, start: false),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandOrange),
                  child: Text(_saving ? 'Guardando…' : 'Guardar horario'),
                ),
              ],
            ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.name,
    required this.day,
    required this.onToggle,
    required this.onStart,
    required this.onEnd,
  });

  final String name;
  final DayWindow day;
  final ValueChanged<bool> onToggle;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TextButton(
            onPressed: day.enabled ? onStart : null,
            child: Text(formatMinute(day.startMinute)),
          ),
          const Text('–'),
          TextButton(
            onPressed: day.enabled ? onEnd : null,
            child: Text(formatMinute(day.endMinute)),
          ),
          Switch(value: day.enabled, onChanged: onToggle),
        ],
      ),
    );
  }
}

extension on WeeklySchedule {
  WeeklySchedule copyEnabled(bool enabled) {
    return WeeklySchedule(enabled: enabled, days: days);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/repositories/worker_schedule_repository.dart';
import '../../../../core/domain/weekly_schedule.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/worker_day_windows_editor.dart';

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
      final days = loaded.days.isEmpty
          ? WeeklySchedule.weekdaysNineToSix().days
          : _fullWeek(loaded.days);
      setState(() {
        _schedule = WeeklySchedule(enabled: loaded.enabled, days: days);
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

  List<DayWindow> _fullWeek(List<DayWindow> days) {
    final byDay = {for (final day in days) day.weekday: day};
    return [
      for (var weekday = 1; weekday <= 7; weekday++)
        byDay[weekday] ??
            DayWindow(
              weekday: weekday,
              startMinute: 9 * 60,
              endMinute: weekday <= 5 ? 18 * 60 : 13 * 60,
              enabled: false,
            ),
    ];
  }

  Future<void> _save() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final overlap = overlappingWindowsMessage(_schedule.days);
    if (overlap != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(overlap)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.save(userId: user.id, schedule: _schedule);
      if (!mounted) return;
      final fresh = await _repo.load(user.id);
      if (!mounted) return;
      setState(() {
        _schedule = WeeklySchedule(
          enabled: fresh.enabled,
          days: _fullWeek(fresh.days),
        );
      });
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

  void _replaceDay(int index, DayWindow day) {
    final days = [..._schedule.days];
    days[index] = day;
    setState(() {
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
                    'Si está encendido, también hay que estar dentro de una ventana del día.',
                  ),
                  value: _schedule.enabled,
                  onChanged: (value) {
                    setState(() {
                      _schedule = WeeklySchedule(
                        enabled: value,
                        days: _schedule.days,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _schedule.days.length; i++)
                  WorkerDayWindowsEditor(
                    name: weekdayNamesEs[_schedule.days[i].weekday - 1],
                    day: _schedule.days[i],
                    onChanged: (day) => _replaceDay(i, day),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandOrange,
                  ),
                  child: Text(_saving ? 'Guardando…' : 'Guardar horario'),
                ),
              ],
            ),
    );
  }
}

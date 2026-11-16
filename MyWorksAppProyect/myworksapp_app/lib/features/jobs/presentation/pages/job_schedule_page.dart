import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/domain/worker_hours.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/job_status_copy.dart';
import '../../../../core/utils/mock_reserved_slots.dart';
import '../../../../core/utils/job_schedule_grouping.dart';
import '../../../../core/utils/santiago_time.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../worker/presentation/widgets/worker_hours_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JobSchedulePage extends ConsumerStatefulWidget {
  const JobSchedulePage({super.key});

  @override
  ConsumerState<JobSchedulePage> createState() => _JobSchedulePageState();
}

class _JobSchedulePageState extends ConsumerState<JobSchedulePage> {
  JobRepository get _jobRepository => ref.read(jobRepositoryProvider);
  final _workerRepository = WorkerRepository();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<JobModel>> _jobsByDate = {};
  List<WorkerHourSlot> _hours = [];
  int _selectedWeekday = DateTime.now().weekday;
  bool _savingHours = false;

  @override
  void initState() {
    super.initState();
    final today = SantiagoTime.day(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
    _loadJobs();
    _loadHours();
  }

  DateTime _dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<void> _loadHours() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final worker = await _workerRepository.getWorkerByUserId(user.id);
    if (!mounted || worker == null) return;
    setState(() => _hours = worker.availableHours);
  }

  Future<void> _persistHours(List<WorkerHourSlot> next) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() => _savingHours = true);
    try {
      await _workerRepository.updateAvailableHours(userId: user.id, hours: next);
      if (!mounted) return;
      setState(() => _hours = uniqueWorkerHours(next));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron guardar los horarios.')),
      );
    } finally {
      if (mounted) setState(() => _savingHours = false);
    }
  }

  Future<void> _addHour(TimeOfDay time) async {
    final slot = WorkerHourSlot(
      weekday: _selectedWeekday,
      time: MockReservedSlots.format(time),
    );
    final error = addWorkerHourError(_hours, slot);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await _persistHours([..._hours, slot]);
  }

  Future<void> _removeHour(WorkerHourSlot slot) async {
    await _persistHours(
      _hours
          .where(
            (item) => item.weekday != slot.weekday || item.time != slot.time,
          )
          .toList(),
    );
  }

  Future<void> _loadJobs() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      final jobs = await _jobRepository.getJobsByWorkerId(user.id);
      if (!mounted) return;
      setState(() {
        _jobsByDate = jobsBySantiagoDay(jobs);
      });
    } catch (e) {
      // Error al cargar trabajos
    }
  }

  List<JobModel> _getJobsForDay(DateTime day) {
    return _jobsByDate[_dayKey(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedJobs = _getJobsForDay(_selectedDay);

    return Scaffold(
      appBar: const AppGradientAppBar(
        title: Text('Calendario de Trabajos'),
      ),
      body: Column(
        children: [
          WorkerHoursEditor(
            hours: _hours,
            selectedWeekday: _selectedWeekday,
            onSelectWeekday: (day) => setState(() => _selectedWeekday = day),
            onAddHour: _addHour,
            onRemoveHour: _removeHour,
            saving: _savingHours,
          ),
          const Divider(),
          TableCalendar<JobModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getJobsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const Divider(),
          Expanded(
            child: selectedJobs.isEmpty
                ? const Center(
                    child: Text('No hay trabajos en esta fecha'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedJobs.length,
                    itemBuilder: (context, index) {
                      final job = selectedJobs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(job.description ?? 'Sin descripción'),
                          subtitle: Text(
                            '${_getStatusText(job.status)} - ${DateFormat('HH:mm').format(SantiagoTime.wall(scheduleInstant(job)))}',
                          ),
                          trailing: Icon(
                            _getStatusIcon(job.status),
                            color: _getStatusColor(job.status),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) => JobStatusCopy.color(status);

  IconData _getStatusIcon(String status) => JobStatusCopy.icon(status);

  String _getStatusText(String status) => JobStatusCopy.label(status);
}

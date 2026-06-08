import 'package:flutter/material.dart';
import 'package:myworksapp/core/theme/app_colors.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JobSchedulePage extends ConsumerStatefulWidget {
  const JobSchedulePage({super.key});

  @override
  ConsumerState<JobSchedulePage> createState() => _JobSchedulePageState();
}

class _JobSchedulePageState extends ConsumerState<JobSchedulePage> {
  final JobRepository _jobRepository = JobRepository();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<JobModel>> _jobsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      final jobs = await _jobRepository.getJobsByWorkerId(user.id);
      final jobsMap = <DateTime, List<JobModel>>{};

      for (var job in jobs) {
        final date = DateTime(
          job.createdAt.year,
          job.createdAt.month,
          job.createdAt.day,
        );
        if (jobsMap.containsKey(date)) {
          jobsMap[date]!.add(job);
        } else {
          jobsMap[date] = [job];
        }
      }

      setState(() {
        _jobsByDate = jobsMap;
      });
    } catch (e) {
      // Error al cargar trabajos
    }
  }

  List<JobModel> _getJobsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _jobsByDate[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedJobs = _getJobsForDay(_selectedDay);

    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Calendario de Trabajos'),
      ),
      body: Column(
        children: [
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
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
            headerStyle: HeaderStyle(
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
                            '${_getStatusText(job.status)} - ${DateFormat('HH:mm').format(job.createdAt)}',
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

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return Colors.orange;
      case AppConstants.jobStatusAccepted:
        return AppColors.brandOrange;
      case AppConstants.jobStatusInProgress:
        return AppColors.brandOrangeDark;
      case AppConstants.jobStatusCompleted:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return Icons.pending;
      case AppConstants.jobStatusAccepted:
        return Icons.check_circle_outline;
      case AppConstants.jobStatusInProgress:
        return Icons.work;
      case AppConstants.jobStatusCompleted:
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return 'Pendiente';
      case AppConstants.jobStatusAccepted:
        return 'Aceptado';
      case AppConstants.jobStatusInProgress:
        return 'En Curso';
      case AppConstants.jobStatusCompleted:
        return 'Completado';
      default:
        return status;
    }
  }
}


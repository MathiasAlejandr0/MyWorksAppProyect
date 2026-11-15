import '../database/models/job_model.dart';
import 'santiago_time.dart';

/// Día de agenda en America/Santiago y los trabajos de ese día, del más
/// temprano al más tarde.
class ScheduleDayGroup {
  const ScheduleDayGroup({required this.day, required this.jobs});

  /// Medianoche civil de Santiago (año, mes y día; sin hora).
  final DateTime day;
  final List<JobModel> jobs;
}

/// Instante que ordena el trabajo: la visita programada, o la creación si
/// todavía no hay hora.
DateTime scheduleInstant(JobModel job) => job.scheduledDate ?? job.createdAt;

/// Agrupa por el día civil de `fecha_programada` en America/Santiago.
/// Si esa fecha es nula, usa la creación. No usa la zona del dispositivo.
List<ScheduleDayGroup> groupJobsBySantiagoDay(List<JobModel> jobs) {
  final buckets = <DateTime, List<JobModel>>{};
  for (final job in jobs) {
    final day = SantiagoTime.day(scheduleInstant(job));
    buckets.putIfAbsent(day, () => []).add(job);
  }
  final days = buckets.keys.toList()..sort();
  return [
    for (final day in days)
      ScheduleDayGroup(
        day: day,
        jobs: [...buckets[day]!]..sort(
            (a, b) => scheduleInstant(a).compareTo(scheduleInstant(b)),
          ),
      ),
  ];
}

Map<DateTime, List<JobModel>> jobsBySantiagoDay(List<JobModel> jobs) {
  return {
    for (final group in groupJobsBySantiagoDay(jobs)) group.day: group.jobs,
  };
}

import '../supabase_db.dart';
import '../../domain/weekly_schedule.dart';

class WorkerScheduleRepository {
  Future<WeeklySchedule> load(String userId) async {
    final worker = await supabase
        .from('trabajadores')
        .select('usa_horario')
        .eq('id_usuario', userId)
        .maybeSingle();
    final enabled = worker?['usa_horario'] == true;
    final rows = await supabase
        .from('trabajador_horarios')
        .select('dia_semana, hora_inicio, hora_fin, activo')
        .eq('id_usuario', userId);
    final days = <DayWindow>[];
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final weekday = (map['dia_semana'] as num?)?.toInt();
      if (weekday == null || weekday < 1 || weekday > 7) continue;
      days.add(
        DayWindow(
          weekday: weekday,
          startMinute: _minutes(map['hora_inicio']),
          endMinute: _minutes(map['hora_fin']),
          enabled: map['activo'] != false,
        ),
      );
    }
    days.sort((a, b) => a.weekday.compareTo(b.weekday));
    return WeeklySchedule(enabled: enabled, days: days);
  }

  Future<Map<String, WeeklySchedule>> loadMany(List<String> userIds) async {
    final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};
    final flags = await supabase
        .from('trabajadores')
        .select('id_usuario, usa_horario')
        .inFilter('id_usuario', ids);
    final rows = await supabase
        .from('trabajador_horarios')
        .select('id_usuario, dia_semana, hora_inicio, hora_fin, activo')
        .inFilter('id_usuario', ids);
    final byUser = <String, List<DayWindow>>{};
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final userId = map['id_usuario'] as String?;
      final weekday = (map['dia_semana'] as num?)?.toInt();
      if (userId == null || weekday == null) continue;
      byUser.putIfAbsent(userId, () => []).add(
            DayWindow(
              weekday: weekday,
              startMinute: _minutes(map['hora_inicio']),
              endMinute: _minutes(map['hora_fin']),
              enabled: map['activo'] != false,
            ),
          );
    }
    final result = <String, WeeklySchedule>{};
    for (final row in flags as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final userId = map['id_usuario'] as String?;
      if (userId == null) continue;
      result[userId] = WeeklySchedule(
        enabled: map['usa_horario'] == true,
        days: byUser[userId] ?? const [],
      );
    }
    return result;
  }

  Future<void> save({
    required String userId,
    required WeeklySchedule schedule,
  }) async {
    await supabase
        .from('trabajadores')
        .update({'usa_horario': schedule.enabled}).eq('id_usuario', userId);
    final existing = await supabase
        .from('trabajador_horarios')
        .select('horarios')
        .eq('id_usuario', userId);
    Object horarios = const <Object>[];
    var best = -1;
    if (existing is List) {
      for (final raw in existing) {
        final value = (raw as Map)['horarios'];
        final length = value is List ? value.length : 0;
        if (length > best) {
          best = length;
          horarios = value ?? const <Object>[];
        }
      }
    }
    final rows = [
      for (final row in scheduleDayRows(
        userId: userId,
        days: schedule.days,
        updatedAt: DateTime.now(),
      ))
        {
          ...row,
          // Misma plantilla de horas publicadas en cada fila: el trigger
          // de reserva lee el jsonb, no el rango hora_inicio/hora_fin.
          'horarios': horarios,
        },
    ];
    if (rows.isEmpty) return;
    await supabase.from('trabajador_horarios').upsert(
          rows,
          onConflict: scheduleUpsertConflict,
        );
  }

  static int _minutes(Object? raw) {
    final text = raw?.toString() ?? '00:00';
    final parts = text.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return hour * 60 + minute;
  }
}

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
    final published = await _publishedSlots([userId]);
    return WeeklySchedule(
      enabled: enabled,
      days: daysFromScheduleRows(
        _withPublished(rows as List, published[userId] ?? const []),
      ),
    );
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
    final published = await _publishedSlots(ids);
    final byUser = <String, List<Map<String, dynamic>>>{};
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final userId = map['id_usuario'] as String?;
      if (userId == null) continue;
      byUser.putIfAbsent(userId, () => []).add(map);
    }
    final result = <String, WeeklySchedule>{};
    for (final row in flags as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final userId = map['id_usuario'] as String?;
      if (userId == null) continue;
      final dayRows = byUser[userId] ?? const <Map<String, dynamic>>[];
      final slots = published[userId] ?? const <Map<String, dynamic>>[];
      result[userId] = WeeklySchedule(
        enabled: map['usa_horario'] == true,
        days: daysFromScheduleRows(_withPublished(dayRows, slots)),
      );
    }
    return result;
  }

  /// Si el alta dejó las ventanas pero ninguna hora publicada, publica
  /// lunes a viernes 09:00–18:00 para que el cliente pueda agendar.
  Future<void> ensureDefault({required String userId}) async {
    final existing = await supabase
        .from('trabajador_horas_publicadas')
        .select('hora')
        .eq('id_usuario', userId)
        .limit(1);
    if ((existing as List).isNotEmpty) return;
    final current = await load(userId);
    await save(
      userId: userId,
      schedule: current.days.isEmpty
          ? WeeklySchedule.weekdaysNineToSix()
          : WeeklySchedule(enabled: true, days: current.days),
    );
  }

  Future<void> save({
    required String userId,
    required WeeklySchedule schedule,
  }) async {
    final overlap = overlappingWindowsMessage(schedule.days);
    if (overlap != null) {
      throw StateError(overlap);
    }
    await supabase
        .from('trabajadores')
        .update({'usa_horario': schedule.enabled}).eq('id_usuario', userId);
    final rows = scheduleDayRows(
      userId: userId,
      days: schedule.days,
      updatedAt: DateTime.now(),
    );
    if (rows.isNotEmpty) {
      await supabase.from('trabajador_horarios').upsert(
            rows,
            onConflict: scheduleUpsertConflict,
          );
    }
    final slots = publishedHourSlots(schedule.days);
    await supabase
        .from('trabajador_horas_publicadas')
        .delete()
        .eq('id_usuario', userId);
    if (slots.isEmpty) return;
    await supabase.from('trabajador_horas_publicadas').insert([
      for (final slot in slots)
        {
          'id_usuario': userId,
          'dia_semana': slot['dia'],
          'hora': slot['hora'],
        },
    ]);
  }

  Future<Map<String, List<Map<String, dynamic>>>> _publishedSlots(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    final rows = await supabase
        .from('trabajador_horas_publicadas')
        .select('id_usuario, dia_semana, hora')
        .inFilter('id_usuario', userIds);
    final byUser = <String, List<Map<String, dynamic>>>{};
    for (final raw in rows as List) {
      final map = Map<String, dynamic>.from(raw as Map);
      final userId = map['id_usuario'] as String?;
      final weekday = (map['dia_semana'] as num?)?.toInt();
      if (userId == null || weekday == null) continue;
      byUser.putIfAbsent(userId, () => []).add({
        'dia': weekday,
        'hora': formatMinute(parseClockMinute(map['hora'])),
      });
    }
    return byUser;
  }

  List<Map<String, dynamic>> _withPublished(
    List<dynamic> rows,
    List<Map<String, dynamic>> slots,
  ) {
    final maps = <Map<String, dynamic>>[
      for (final raw in rows)
        if (raw is Map) Map<String, dynamic>.from(raw),
    ];
    if (maps.isEmpty) {
      if (slots.isEmpty) return const [];
      return [
        {'horarios': slots},
      ];
    }
    return [
      for (var i = 0; i < maps.length; i++)
        {
          ...maps[i],
          if (i == 0) 'horarios': slots,
        },
    ];
  }
}

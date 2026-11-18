import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/supabase_db.dart';

/// Encuesta de testing (UAT), la misma que la web (`shared/src/survey`):
/// SUS de 10 afirmaciones (Brooke, 1996), satisfacción 1 a 5, si completó
/// la tarea y dos comentarios.
class TestingSurvey {
  TestingSurvey._();

  static const susItems = <String>[
    'Creo que me gustaría usar MyWorksApp con frecuencia.',
    'Encontré MyWorksApp innecesariamente complicada.',
    'Pensé que MyWorksApp era fácil de usar.',
    'Creo que necesitaría ayuda de una persona con conocimientos técnicos para usar MyWorksApp.',
    'Las funciones de MyWorksApp están bien integradas.',
    'Pensé que había demasiada inconsistencia en MyWorksApp.',
    'Imagino que la mayoría de las personas aprendería a usar MyWorksApp muy rápido.',
    'Encontré MyWorksApp muy difícil de usar.',
    'Me sentí muy seguro(a) usando MyWorksApp.',
    'Necesité aprender muchas cosas antes de poder usar MyWorksApp.',
  ];

  /// Puntaje SUS 0 a 100, o null si faltan respuestas.
  static double? susScore(List<int> answers) {
    if (answers.length != 10) return null;
    var sum = 0;
    for (var i = 0; i < 10; i++) {
      final value = answers[i];
      if (value < 1 || value > 5) return null;
      sum += i.isEven ? value - 1 : 5 - value;
    }
    return sum * 2.5;
  }
}

class TestingFeedbackDraft {
  const TestingFeedbackDraft({
    required this.score,
    required this.worked,
    required this.improve,
    this.sus = const [],
    this.role = 'cliente',
    this.taskCompleted = 'si',
  });

  /// Satisfacción general de 1 a 5.
  final int score;
  final String worked;
  final String improve;
  final List<int> sus;
  final String role;
  final String taskCompleted;

  int get susAnswered => sus.where((v) => v >= 1 && v <= 5).length;

  bool get isValid =>
      score >= 1 &&
      score <= 5 &&
      susAnswered == 10 &&
      improve.trim().length <= 1000 &&
      worked.trim().length <= 1000;

  Map<String, dynamic> toJson() => {
        'score': score,
        'worked': worked.trim(),
        'improve': improve.trim(),
        'sus': sus,
        'role': role,
        'task': taskCompleted,
        'at': DateTime.now().toUtc().toIso8601String(),
      };

  /// Parámetros de `enviar_encuesta_testing`. La base guarda las 10
  /// respuestas y calcula el puntaje SUS.
  Map<String, dynamic> toRpcParams({String? appVersion}) => {
        'p_plataforma': 'app',
        'p_rol': role,
        'p_tarea_completada': taskCompleted,
        'p_satisfaccion': score,
        'p_sus': sus,
        'p_que_funciono': worked.trim().isEmpty ? null : worked.trim(),
        'p_que_mejorar': improve.trim().isEmpty ? null : improve.trim(),
        'p_version_app': appVersion,
      };
}

/// Envía la encuesta a Supabase con la función enviar_encuesta_testing (solo
/// el administrador lee las respuestas). Si no hay red, queda una copia en el teléfono.
class TestingFeedbackStore {
  TestingFeedbackStore._();

  static const storageKey = 'testing_feedback_v1';

  static Future<void> save(TestingFeedbackDraft draft) async {
    try {
      String? appVersion;
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = 'app ${info.version}+${info.buildNumber}';
      } catch (_) {
        appVersion = 'app';
      }
      await supabase.rpc(
        'enviar_encuesta_testing',
        params: draft.toRpcParams(appVersion: appVersion),
      );
    } catch (_) {
      await saveLocal(draft);
      rethrow;
    }
  }

  static Future<void> saveLocal(TestingFeedbackDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(storageKey) ?? <String>[];
    current.add(jsonEncode(draft.toJson()));
    await prefs.setStringList(storageKey, current);
  }

  static Future<List<Map<String, dynamic>>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(storageKey) ?? const <String>[];
    return current
        .map((raw) {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
          return const <String, dynamic>{};
        })
        .where((row) => row.isNotEmpty)
        .toList();
  }
}

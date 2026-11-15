import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TestingFeedbackDraft {
  const TestingFeedbackDraft({
    required this.score,
    required this.worked,
    required this.improve,
  });

  final int score;
  final String worked;
  final String improve;

  bool get isValid =>
      score >= 1 && score <= 5 && improve.trim().length >= 8;

  Map<String, dynamic> toJson() => {
        'score': score,
        'worked': worked.trim(),
        'improve': improve.trim(),
        'at': DateTime.now().toIso8601String(),
      };
}

/// Opiniones de usabilidad de la etapa de pruebas. Quedan en el teléfono
/// para no depender de una tabla nueva ni de permisos de analítica.
class TestingFeedbackStore {
  TestingFeedbackStore._();

  static const storageKey = 'testing_feedback_v1';

  static Future<void> save(TestingFeedbackDraft draft) async {
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

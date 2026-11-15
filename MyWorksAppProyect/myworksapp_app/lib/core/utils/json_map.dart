import 'dart:convert';

/// Lee un objeto JSON tanto si PostgREST lo entrega como [Map] o como texto.
Map<String, dynamic>? decodeJsonMap(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }
  return null;
}

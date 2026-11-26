// Utilidades para probar modelos con datos variados sin reflexión.

/// Ejecuta [f] y devuelve su resultado; si lanza, devuelve null. Se usa solo
/// en variantes "de robustez" donde un error de tipo es un resultado válido
/// (la base devolvió algo que el modelo no acepta).
T? probe<T>(T Function() f) {
  try {
    return f();
  } catch (_) {
    return null;
  }
}

/// toString, == y hashCode de cualquier objeto.
void touchCommon(Object? o) {
  o.toString();
  // ignore: unrelated_type_equality_checks
  o == o;
  o.hashCode;
}

/// Variantes de un mapa de ejemplo: todo nulo salvo ids, números como texto,
/// números como double, booleanos como enteros y fechas en otro formato.
List<Map<String, dynamic>> variants(Map<String, dynamic> base) {
  Map<String, dynamic> map(Object? Function(String k, Object? v) f) =>
      {for (final e in base.entries) e.key: f(e.key, e.value)};
  bool keep(String k) => k == 'id' || k.startsWith('id_');
  return [
    map((k, v) => keep(k) ? v : null),
    map((k, v) => v is num ? '$v' : v),
    map((k, v) => v is int ? v.toDouble() : v),
    map((k, v) => v is bool ? (v ? 1 : 0) : (v is int ? 0 : v)),
    map((k, v) => v is bool ? 'true' : v),
    map((k, v) => v is String && v.startsWith('2026-') ? '2026-01-02' : v),
    map((k, v) => v is String && v.startsWith('v_') ? '' : v),
    map((k, v) => v is List ? [1, 'a', <String, dynamic>{}] : v),
    map((k, v) => v is Map ? {'a': 1} : v),
    <String, dynamic>{'id': base['id']},
  ];
}

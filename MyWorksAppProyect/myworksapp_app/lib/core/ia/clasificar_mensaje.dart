/// Misma prioridad que `clasificar_mensaje` en Postgres.
String clasificarMensaje(String texto) {
  final v = texto.trim();
  if (v.isEmpty) return 'limpio';
  if (RegExp(r'[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}', caseSensitive: false).hasMatch(v)) {
    return 'correo';
  }
  if (RegExp(r'(?:^|[^\d])(?:\+?56[\s.\-]*)?9(?:[\s.\-]?\d){8}(?!\d)').hasMatch(v)) {
    return 'telefono';
  }
  if (RegExp(r'cuenta\s+(corriente|vista|rut|de\s+ahorro)|n[uú]mero\s+de\s+cuenta', caseSensitive: false).hasMatch(v)) {
    return 'banco';
  }
  if (RegExp(r'p[aá]game\s+por\s+fuera|pago\s+por\s+fuera|por\s+fuera\s+de\s+la\s+app|sin\s+pasar\s+por\s+la\s+app', caseSensitive: false).hasMatch(v)) {
    return 'fuera';
  }
  if (RegExp(r'\b(weon|weón|aweonao|aweona|conchetumare|conchesumadre|ctm|qliao|imbecil|imbécil|idiota)\b|saco\s+de\s+wea', caseSensitive: false).hasMatch(v)) {
    return 'insulto';
  }
  if (RegExp(r'escribeme|mi\s+n[uú]mero|por\s+interno|te\s+paso\s+el\s+dato|[0-9]{5,7}', caseSensitive: false).hasMatch(v)) {
    return 'dudoso';
  }
  return 'limpio';
}

String avisoModeracion(String motivo) {
  if (motivo == 'limpio') return '';
  return 'Este mensaje quedó marcado para revisión. No se borra. Un administrador decide.';
}

/// Inferencia simple de comuna desde texto de dirección (Chile).
String inferComunaKey(String address) {
  final lower = address.toLowerCase();
  if (lower.contains('providencia')) return 'providencia';
  if (lower.contains('las condes')) return 'las_condes';
  if (lower.contains('maipú') || lower.contains('maipu')) return 'maipu';
  if (lower.contains('puente alto')) return 'puente_alto';
  if (lower.contains('ñuñoa') || lower.contains('nunoa')) return 'nunoa';
  if (lower.contains('la florida')) return 'la_florida';
  return 'santiago';
}

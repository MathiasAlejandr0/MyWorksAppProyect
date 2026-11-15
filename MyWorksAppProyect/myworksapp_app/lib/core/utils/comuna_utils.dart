/// Inferencia simple de comuna/ciudad desde texto de dirección (Chile).
///
/// La base de la demo es Puerto Montt. Solo se usa una comuna de Santiago
/// cuando la dirección la nombra.
String inferComunaKey(String address) {
  final lower = address.toLowerCase();
  if (lower.contains('puerto montt') ||
      lower.contains('angelmo') ||
      lower.contains('pelluco') ||
      lower.contains('alerce') ||
      lower.contains('cardonal') ||
      lower.contains('mirasol') ||
      lower.contains('chamiza')) {
    return 'puerto_montt';
  }
  if (lower.contains('puerto varas')) return 'puerto_varas';
  if (lower.contains('osorno')) return 'osorno';
  if (lower.contains('providencia')) return 'providencia';
  if (lower.contains('las condes')) return 'las_condes';
  if (lower.contains('maipú') || lower.contains('maipu')) return 'maipu';
  if (lower.contains('puente alto')) return 'puente_alto';
  if (lower.contains('ñuñoa') || lower.contains('nunoa')) return 'nunoa';
  if (lower.contains('la florida')) return 'la_florida';
  if (lower.contains('santiago')) return 'santiago';
  if (lower.contains('los lagos')) return 'puerto_montt';
  return 'puerto_montt';
}

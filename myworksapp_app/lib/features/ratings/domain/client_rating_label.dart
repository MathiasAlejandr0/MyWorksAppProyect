/// Texto que ve el profesional antes de aceptar o rechazar.
String clientRatingLabel(
    {double? average, required int count, bool known = true}) {
  if (!known) return 'Reputación no disponible';
  if (count <= 0 || average == null) return 'Cliente nuevo';
  final nota = average.toStringAsFixed(1);
  final palabra = count == 1 ? 'calificación' : 'calificaciones';
  return '$nota · $count $palabra';
}

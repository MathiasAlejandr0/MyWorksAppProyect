class SugerenciaSolicitud {
  const SugerenciaSolicitud({
    required this.categoria,
    required this.urgencia,
    required this.precioMinClp,
    required this.precioMaxClp,
    required this.preguntas,
  });

  final String categoria;
  final String urgencia;
  final int precioMinClp;
  final int precioMaxClp;
  final List<String> preguntas;

  static const aviso =
      'Sugerencia de la IA. No reserva ni cobra: tú confirmas el pedido.';
}

SugerenciaSolicitud? parsearSugerencia(Map<String, dynamic> raw) {
  const categorias = {
    'ensamblaje',
    'electricidad',
    'plomeria',
    'gasfiteria',
    'limpieza',
    'pintura',
    'jardineria',
    'cerrajeria',
    'construccion',
    'soporte_tecnico',
    'mudanza',
    'climatizacion',
  };
  final categoria = raw['categoria']?.toString() ?? '';
  final urgencia = raw['urgencia']?.toString() ?? '';
  final min = raw['precio_min_clp'];
  final max = raw['precio_max_clp'];
  if (!categorias.contains(categoria)) return null;
  if (urgencia != 'baja' && urgencia != 'media' && urgencia != 'alta') return null;
  if (min is! int || max is! int || min < 5000 || max > 500000 || min > max) return null;
  final preguntas = <String>[];
  final lista = raw['preguntas'];
  if (lista is List) {
    for (final item in lista) {
      final texto = item.toString().trim();
      if (texto.length >= 8 && texto.length <= 160) preguntas.add(texto);
    }
  }
  return SugerenciaSolicitud(
    categoria: categoria,
    urgencia: urgencia,
    precioMinClp: min,
    precioMaxClp: max,
    preguntas: preguntas.take(4).toList(),
  );
}

String redactarPerfil(String texto) {
  final base = enmascararParaExterno(texto).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (base.length < 8) return '';
  final cuerpo = base[0].toUpperCase() + base.substring(1);
  final cerrado = RegExp(r'[.!?]$').hasMatch(cuerpo) ? cuerpo : '$cuerpo.';
  return 'Trabajo con orden y dejo el lugar limpio. $cerrado';
}

String enmascararParaExterno(String texto) {
  return texto
      .replaceAll(RegExp(r'\b\d{1,2}\.\d{3}\.\d{3}-[\dkK]\b'), 'RUT oculto')
      .replaceAll(RegExp(r'\b\d{7,8}-[\dkK]\b'), 'RUT oculto')
      .replaceAll(RegExp(r'[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}', caseSensitive: false), 'correo oculto');
}

/// Largo máximo de `traza_pila` en `registros_error_app`.
const int kErrorStackMaxChars = 8000;

final _email = RegExp(
  r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
);
final _jwt = RegExp(
  r'\beyJ[A-Za-z0-9_\-]+=*\.[A-Za-z0-9_\-]+=*\.[A-Za-z0-9_\-]+=*',
);
final _bearer = RegExp(
  r'bearer\s+[A-Za-z0-9\-._~+/]+=*',
  caseSensitive: false,
);
final _secretQuery = RegExp(
  r'(access_token|refresh_token|id_token|apikey|api[_-]?key|token|authorization|password|secret|hottok)=([^&\s]+)',
  caseSensitive: false,
);
final _chilePhone = RegExp(
  r'\+?56[\s\-]?9[\s\-]?\d{4}[\s\-]?\d{4}',
);
final _helperFrame = RegExp(
  r'package:myworksapp/core/services/error_stack_sanitizer\.dart|'
  r'package:myworksapp/core/services/crash_reporting_service\.dart|'
  r'package:myworksapp/core/utils/app_logger\.dart|'
  r'package:myworksapp/core/utils/error_handler\.dart',
);

/// Stack que se guarda en el reporte: el que llegó, o el actual si no hubo.
String? stackForErrorLog(
  StackTrace? stackTrace, {
  int maxChars = kErrorStackMaxChars,
}) {
  return sanitizeErrorStack(
    (stackTrace ?? StackTrace.current).toString(),
    maxChars: maxChars,
  );
}

/// Recorta la traza, quita los frames del propio reporte y oculta datos
/// sensibles (correo, token, teléfono, secretos en la URL).
String? sanitizeErrorStack(
  String? raw, {
  int maxChars = kErrorStackMaxChars,
}) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final lines = trimmed.split(RegExp(r'\r?\n'));
  var i = 0;
  while (i < lines.length && _helperFrame.hasMatch(lines[i])) {
    i++;
  }
  var text = (i < lines.length ? lines.sublist(i) : lines).join('\n');

  text = text.replaceAll(_jwt, '[token]');
  text = text.replaceAll(_bearer, 'Bearer [token]');
  text = text.replaceAllMapped(
    _secretQuery,
    (m) => '${m[1]}=[redactado]',
  );
  text = text.replaceAll(_email, '[correo]');
  text = text.replaceAll(_chilePhone, '[telefono]');

  if (text.length > maxChars) {
    text = '${text.substring(0, maxChars)}\n… (traza recortada)';
  }
  final out = text.trim();
  return out.isEmpty ? null : out;
}

/// Canales de soporte. Se definen al compilar para no dejar un correo o un
/// número de ejemplo en la app publicada:
///
///   --dart-define=SUPPORT_EMAIL=soporte@tu-dominio.cl
///   --dart-define=SUPPORT_WHATSAPP=569XXXXXXXX   (sin + ni espacios)
///
/// Si un canal queda vacío, la app no lo muestra.
class SupportConfig {
  SupportConfig._();

  static const String email = String.fromEnvironment('SUPPORT_EMAIL');
  static const String whatsapp = String.fromEnvironment('SUPPORT_WHATSAPP');

  static bool get hasEmail => email.contains('@');
  static bool get hasWhatsapp => RegExp(r'^\d{8,15}$').hasMatch(whatsapp);

  /// «+56 9 1234 5678» para un número chileno; si no, el número con «+».
  static String get whatsappLabel {
    const n = whatsapp;
    if (n.length == 11 && n.startsWith('569')) {
      return '+56 9 ${n.substring(3, 7)} ${n.substring(7)}';
    }
    return '+$n';
  }

  static Uri emailUri({String subject = 'Soporte My Works App', String? body}) {
    final query = <String>[
      'subject=${Uri.encodeComponent(subject)}',
      if (body != null && body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
    ].join('&');
    return Uri.parse('mailto:$email?$query');
  }

  static Uri whatsappUri(String message) => Uri.parse(
        'https://wa.me/$whatsapp?text=${Uri.encodeComponent(message)}',
      );
}

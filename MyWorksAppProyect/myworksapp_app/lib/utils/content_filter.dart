import 'package:flutter/material.dart';
import 'package:myworksapp/core/theme/app_colors.dart';

/// Filtro local de datos de contacto.
/// La misma regla está en shared/src/chat/contactFilter.ts y en
/// texto_tiene_contacto. Los casos compartidos viven en contactCases.json.
///
/// WhatsApp, «llámame» y un enlace son contacto aunque no traigan usuario.
/// Facebook, TikTok, Instagram y el resto solo cuentan con usuario, enlace o @.
/// Un RUT, una medida o un monto no es un teléfono.
class ContentFilter {
  ContentFilter._();

  static const String blockedTitle = 'Mensaje no permitido';

  static const String blockedMessage =
      'Este tipo de mensaje no está permitido. Para proteger a ambas partes y conservar la garantía de pago, no se puede compartir teléfono, correo electrónico, enlaces ni datos de contacto externos. Continúe la conversación dentro de la aplicación.';

  static final RegExp _emailPattern = RegExp(
    r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp _spelledEmailPattern = RegExp(
    r'\b[a-zA-Z0-9._%+\-]+\s+arroba\s+(?:[a-zA-Z0-9.\-]+\.(?:cl|com|net|org)|gmail|hotmail|outlook|yahoo|icloud)\b',
    caseSensitive: false,
  );

  static final RegExp _spelledPhonePattern = RegExp(
    r'(?:cero|uno|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)(?:[\s,\-]+(?:cero|uno|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)){6,}',
    caseSensitive: false,
  );

  static final RegExp _channelPattern = RegExp(
    r'whats\s*app|w[aá]ts?a+p+|\bwsp\b|guasap|wasap|wa\.me|t\.me|ll[aá]mame|h[aá]blame\s+al',
    caseSensitive: false,
  );

  static const String _network =
      r'(?:facebook|\bfb\b|instagram|\binsta\b|\big\b|tik\s*tok|tiktok|snapchat|twitter|signal|discord|telegram)';

  static final RegExp _socialContactPattern = RegExp(
    '$_network'
    r'\s*[:：]\s*@?[a-z0-9._]{2,}'
    '|$_network'
    r'\s+@\s*[a-z0-9._]{2,}'
    r'|\b(?:mi|en)\s+'
    '$_network'
    r'\s+(?:es|de)\s+@?[a-z0-9._]{2,}'
    r'|(?:facebook|fb|instagram|tiktok|twitter|x|snapchat|t)\.(?:com|me)\/[a-z0-9._]{2,}'
    r'|fb\.me\/[a-z0-9._]{2,}'
    r'|m\.me\/[a-z0-9._]{2,}',
    caseSensitive: false,
  );

  static final RegExp _linkPattern = RegExp(
    r'(https?:\/\/|www\.|\b[\w\-]+\.(?:cl|com|net|org)\b)',
    caseSensitive: false,
  );

  static const String _areaCodes =
      '32|33|34|35|41|42|43|45|51|52|53|55|57|58|61|63|64|65|67|71|72|73|75';

  static final RegExp _phonePattern = RegExp(
    '(?:^|[^\\d])(?:\\+?56[\\s.\\-]*)?(?:9(?:[\\s.\\-]?\\d){8}|2(?:[\\s.\\-]?\\d){8}|(?:$_areaCodes)(?:[\\s.\\-]?\\d){7})(?!\\d)',
  );

  static final RegExp _rutPattern = RegExp(
    r'\brut\s*:?\s*\d{7,9}\b|\b\d{1,2}\.\d{3}\.\d{3}-[\dkK]\b|\b\d{7,8}-[\dkK]\b',
    caseSensitive: false,
  );

  static final RegExp _moneyPattern = RegExp(
    r'\$\s*\d{1,3}(?:\.\d{3})+|\b\d{1,3}(?:\.\d{3})+\b',
  );

  static final RegExp _measurePattern = RegExp(
    r'\b\d+(?:[.,]\d+)?\s*(?:cm|mm|km|kg|grs?|g|ml|lts?|lt|mts?|metros?|horas?|hrs?|min|años?)\b',
    caseSensitive: false,
  );

  static bool hasSensitiveData(String text) {
    final value = text.trim();
    if (value.isEmpty) return false;
    return _emailPattern.hasMatch(value) ||
        _spelledEmailPattern.hasMatch(value) ||
        _channelPattern.hasMatch(value) ||
        _socialContactPattern.hasMatch(value) ||
        _linkPattern.hasMatch(value) ||
        _spelledPhonePattern.hasMatch(value) ||
        _hasChileanPhone(value);
  }

  static bool _hasChileanPhone(String text) {
    final masked = text
        .replaceAll(_rutPattern, ' ')
        .replaceAll(_moneyPattern, ' ')
        .replaceAll(_measurePattern, ' ');
    for (final match in _phonePattern.allMatches(masked)) {
      final digits = match.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (!digits.endsWith('000')) return true;
    }
    return false;
  }

  /// Diálogo rojo. Cancela el envío en el llamador si [hasSensitiveData] es true.
  static Future<void> showBlockedDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.gpp_bad_outlined,
            color: AppColors.error, size: 36),
        title: const Text(
          blockedTitle,
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          blockedMessage,
          style: TextStyle(color: AppColors.error, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

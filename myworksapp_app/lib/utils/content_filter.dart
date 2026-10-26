import 'package:flutter/material.dart';
import 'package:myworksapp/core/theme/app_colors.dart';

/// Filtro local de datos de contacto y frases de evasión.
/// No envía el texto a ningún servicio remoto.
class ContentFilter {
  ContentFilter._();

  static const String blockedMessage =
      'Por seguridad y garantía de pago (Escrow), no se permite compartir datos de contacto directo.';

  /// Correos como `example@email.com`.
  static final RegExp emailPattern = RegExp(
    r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
  );

  /// Móviles chilenos: `+56912345678`, `912345678`, con espacios o puntos.
  static final RegExp chileanPhonePattern = RegExp(
    r'(?<!\d)(?:\+?56[\s.\-]*)?9(?:[\s.\-]?\d){8}(?!\d)',
  );

  /// Palabras usadas para sacar la conversación de la app.
  static final RegExp evasionKeywordsPattern = RegExp(
    r'(?:whats\s*app|\bwsp\b|ll[aá]mame|h[aá]blame\s+al|telegram|\binsta\b|instagram|wa\.me|t\.me)',
    caseSensitive: false,
  );

  /// Correo escrito con «arroba» para esquivar el @.
  static final RegExp spelledEmailPattern = RegExp(
    r'\barroba\b',
    caseSensitive: false,
  );

  /// Enlaces y dominios. El chat no es el canal para pasar una web.
  static final RegExp linkPattern = RegExp(
    r'(https?:\/\/|www\.|\b[\w\-]+\.(?:cl|com|net|org)\b)',
    caseSensitive: false,
  );

  static bool hasSensitiveData(String text) {
    final value = text.trim();
    if (value.isEmpty) return false;
    return emailPattern.hasMatch(value) ||
        spelledEmailPattern.hasMatch(value) ||
        chileanPhonePattern.hasMatch(value) ||
        evasionKeywordsPattern.hasMatch(value) ||
        linkPattern.hasMatch(value);
  }

  /// Diálogo rojo. Cancela el envío en el llamador si [hasSensitiveData] es true.
  static Future<void> showBlockedDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.gpp_bad_outlined, color: AppColors.error, size: 36),
        title: const Text(
          'Mensaje bloqueado',
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

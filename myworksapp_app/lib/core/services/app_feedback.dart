import 'package:flutter/services.dart';

/// Servicio centralizado de respuestas hápticas y táctiles estilo iOS/Android.
class AppFeedback {
  AppFeedback._();

  /// Vibración suave para toques de tarjetas, botones y pestañas
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Vibración media para selecciones de listas y switches
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Vibración pesada para acciones críticas (ej. confirmar pago u orden)
  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Vibración de selección rápida (sliders, pickers)
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}

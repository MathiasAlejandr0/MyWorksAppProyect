import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Servicio para accesibilidad
class AccessibilityService {
  static final AccessibilityService instance = AccessibilityService._();
  AccessibilityService._();

  static const String _keyTextScale = 'accessibility_text_scale';
  static const String _keyHighContrast = 'accessibility_high_contrast';

  /// Obtiene el factor de escala de texto
  Future<double> getTextScale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyTextScale) ?? 1.0;
    } catch (e) {
      AppLogger.e('Error al obtener text scale', e);
      return 1.0;
    }
  }

  /// Establece el factor de escala de texto
  Future<void> setTextScale(double scale) async {
    try {
      // Limitar entre 0.8 y 2.0 (rango razonable)
      final clampedScale = scale.clamp(0.8, 2.0);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyTextScale, clampedScale);
      AppLogger.i('Text scale actualizado: $clampedScale');
    } catch (e) {
      AppLogger.e('Error al establecer text scale', e);
    }
  }

  /// Verifica si el contraste alto está habilitado
  Future<bool> isHighContrastEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyHighContrast) ?? false;
    } catch (e) {
      AppLogger.e('Error al verificar high contrast', e);
      return false;
    }
  }

  /// Habilita/deshabilita contraste alto
  Future<void> setHighContrast(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHighContrast, enabled);
      AppLogger.i('High contrast ${enabled ? "habilitado" : "deshabilitado"}');
    } catch (e) {
      AppLogger.e('Error al establecer high contrast', e);
    }
  }

  /// Verifica si el contraste cumple con AA (mínimo)
  static bool meetsAAContrast(Color foreground, Color background) {
    // Fórmula de contraste WCAG
    final contrast = _calculateContrast(foreground, background);
    // AA requiere 4.5:1 para texto normal, 3:1 para texto grande
    return contrast >= 4.5;
  }

  /// Calcula el ratio de contraste
  static double _calculateContrast(Color foreground, Color background) {
    final fgLuminance = _getRelativeLuminance(foreground);
    final bgLuminance = _getRelativeLuminance(background);

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calcula la luminancia relativa
  static double _getRelativeLuminance(Color color) {
    final r = _linearize(color.r);
    final g = _linearize(color.g);
    final b = _linearize(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Lineariza un componente de color
  static double _linearize(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }
}


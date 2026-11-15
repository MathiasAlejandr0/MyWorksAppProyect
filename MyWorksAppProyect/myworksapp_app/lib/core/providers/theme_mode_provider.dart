import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preferencia de tema. Arranca en oscuro (mockups) y luego aplica SharedPreferences.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _prefKey = 'dark_mode';

  @override
  ThemeMode build() => ThemeMode.dark;

  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefKey) ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    state = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

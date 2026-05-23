import 'package:shared_preferences/shared_preferences.dart';

/// Tour guiado de 3 pasos en el home del usuario.
class DemoTourService {
  DemoTourService._();

  static const _key = 'demo_tour_v1_completed';

  static Future<bool> shouldShowTour() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  static Future<void> completeTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Guía interactiva por fases: inicio, lista de trabajadores y solicitud.
class DemoTourService {
  DemoTourService._();

  static const _homeKey = 'demo_tour_v2_home_completed';
  static const _workersKey = 'demo_tour_v2_workers_completed';
  static const _requestKey = 'demo_tour_v2_request_completed';

  static Future<bool> shouldShowHomeTour() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_homeKey) ?? false);
  }

  static Future<bool> shouldShowWorkersTour() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_workersKey) ?? false);
  }

  static Future<bool> shouldShowRequestTour() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_requestKey) ?? false);
  }

  static Future<void> completeHomeTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeKey, true);
  }

  static Future<void> completeWorkersTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_workersKey, true);
  }

  static Future<void> completeRequestTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_requestKey, true);
  }

  static Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_homeKey);
    await prefs.remove(_workersKey);
    await prefs.remove(_requestKey);
  }
}

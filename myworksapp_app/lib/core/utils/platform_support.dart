import 'package:flutter/foundation.dart';

/// Utilidades de plataforma para adaptar funcionalidades según el dispositivo.
class AppPlatform {
  AppPlatform._();

  static bool get isWeb => kIsWeb;

  static bool get isMobileNative =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isDesktopNative =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Google Maps embebido: Android, iOS y Web. En Windows/macOS/Linux usa fallback.
  static bool get supportsEmbeddedGoogleMap =>
      isMobileNative || isWeb;
}

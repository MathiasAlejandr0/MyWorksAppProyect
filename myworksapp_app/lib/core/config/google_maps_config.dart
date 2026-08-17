import 'package:flutter/foundation.dart';

/// Google Maps requiere `GOOGLE_MAPS_API_KEY` en `android/secrets.properties`.
/// Sin clave, los tiles no cargan (mapa gris). En debug usamos OpenStreetMap.
class GoogleMapsConfig {
  GoogleMapsConfig._();

  static const bool isConfigured = bool.fromEnvironment(
    'GOOGLE_MAPS_CONFIGURED',
    defaultValue: false,
  );

  static bool get useEmbeddedGoogleMap =>
      isConfigured && !kDebugMode;
}

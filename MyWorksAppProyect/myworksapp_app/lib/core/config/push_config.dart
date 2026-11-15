import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Push con Firebase Cloud Messaging (gratis). Se activa solo si la build
/// trae los 4 valores de la app Android del proyecto Firebase:
///
///   --dart-define=FCM_API_KEY=...
///   --dart-define=FCM_APP_ID=1:123456789:android:abc...
///   --dart-define=FCM_SENDER_ID=123456789
///   --dart-define=FCM_PROJECT_ID=myworksapp
///
/// No hace falta `google-services.json`: Firebase se inicializa con estas
/// opciones. Son identificadores públicos de la app, no secretos.
class PushConfig {
  PushConfig._();

  static const String apiKey = String.fromEnvironment('FCM_API_KEY');
  static const String appId = String.fromEnvironment('FCM_APP_ID');
  static const String senderId = String.fromEnvironment('FCM_SENDER_ID');
  static const String projectId = String.fromEnvironment('FCM_PROJECT_ID');

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      senderId.isNotEmpty &&
      projectId.isNotEmpty;

  /// Por ahora solo Android (iOS necesita además la clave APNs).
  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isEnabled => isConfigured && isSupportedPlatform;

  static FirebaseOptions get options => const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
      );
}

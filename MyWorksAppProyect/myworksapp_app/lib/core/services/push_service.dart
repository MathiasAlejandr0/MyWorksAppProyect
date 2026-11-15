import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/push_config.dart';
import '../database/supabase_db.dart';
import '../utils/app_logger.dart';

/// Registra el token FCM del equipo para el usuario con sesión.
///
/// Con la app abierta los avisos llegan por Realtime (NotificationService);
/// el push sirve para cuando la app está cerrada o en segundo plano, y ahí
/// Android muestra la notificación solo.
///
/// Sin la configuración FCM (ver [PushConfig]) todo esto es un no-op.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _firebaseReady = false;
  String? _token;
  StreamSubscription<String>? _refreshSub;

  Future<bool> _ensureFirebase() async {
    if (!PushConfig.isEnabled) return false;
    if (_firebaseReady) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: PushConfig.options);
      }
      _firebaseReady = true;
    } catch (e) {
      AppLogger.w('Firebase no se pudo inicializar; sin push', e);
    }
    return _firebaseReady;
  }

  /// Pide permiso (Android 13+), obtiene el token y lo guarda en Supabase.
  Future<void> register(String userId) async {
    if (!await _ensureFirebase()) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        AppLogger.i('Push: el usuario no dio permiso de notificaciones');
        return;
      }
      // register()/onRegistered (FID) es la API nueva de firebase_messaging 17;
      // se usa el token de registro clásico, que es el que acepta FCM HTTP v1
      // en `message.token` (ver supabase/functions/_shared/fcm.ts).
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await _save(token);
      await _refreshSub?.cancel();
      // ignore: deprecated_member_use
      _refreshSub = messaging.onTokenRefresh.listen((t) => unawaited(_save(t)));
    } catch (e) {
      AppLogger.w('Push: no se pudo registrar el equipo', e);
    }
  }

  /// Al cerrar sesión: este equipo deja de recibir los avisos de esa cuenta.
  /// Se llama antes de `signOut` (la RPC necesita la sesión).
  Future<void> unregister() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    final token = _token;
    _token = null;
    if (token == null || !_firebaseReady) return;
    try {
      await supabase.rpc('quitar_dispositivo_push', params: {'p_token': token});
    } catch (e) {
      AppLogger.w('Push: no se pudo quitar el token', e);
    }
  }

  Future<void> _save(String token) async {
    _token = token;
    try {
      await supabase.rpc('registrar_dispositivo_push', params: {
        'p_token': token,
        'p_plataforma': 'android',
      });
    } catch (e) {
      // Si la migración de push no está aplicada, la app sigue igual.
      AppLogger.w('Push: no se pudo guardar el token', e);
    }
  }
}

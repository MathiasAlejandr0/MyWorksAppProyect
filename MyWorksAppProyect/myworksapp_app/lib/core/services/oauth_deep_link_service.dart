import 'package:app_links/app_links.dart';

import '../config/oauth_config.dart';
import '../database/supabase_db.dart';
import '../utils/app_logger.dart';

typedef OAuthSessionCallback = Future<void> Function();

const _emailAuthTypes = {
  'recovery',
  'signup',
  'invite',
  'magiclink',
  'email',
  'email_change',
};

String? authLinkType(Uri uri) {
  final queryType = uri.queryParameters['type'];
  if (queryType != null && queryType.isNotEmpty) return queryType.toLowerCase();
  final fragment = Uri.splitQueryString(uri.fragment);
  final hashType = fragment['type'];
  if (hashType != null && hashType.isNotEmpty) return hashType.toLowerCase();
  return null;
}

/// True si el enlace no es el retorno de Google/Apple.
/// Un `?code=` de confirmación o recuperación lo intercambia supabase_flutter.
bool leaveAuthCodeToSupabase(Uri uri, {required bool expectingOAuth}) {
  if (!OAuthConfig.isOAuthCallback(uri)) return true;
  final type = authLinkType(uri);
  if (type != null && _emailAuthTypes.contains(type)) return true;
  final code = uri.queryParameters['code'];
  if (code != null && code.isNotEmpty && !expectingOAuth) return true;
  return false;
}

/// Escucha el deep link de retorno tras Google / Apple Sign-In.
class OAuthDeepLinkService {
  OAuthDeepLinkService._();

  static final OAuthDeepLinkService instance = OAuthDeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  OAuthSessionCallback? _onSessionReady;
  bool _started = false;
  bool _expectingOAuth = false;

  /// El navegador de Google o Apple está por volver con `?code=`.
  void expectOAuthCallback() {
    _expectingOAuth = true;
  }

  void cancelOAuthCallback() {
    _expectingOAuth = false;
  }

  Future<void> start(OAuthSessionCallback onSessionReady) async {
    if (_started) return;
    _started = true;
    _onSessionReady = onSessionReady;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handleUri(initial);
      }
    } catch (e, st) {
      AppLogger.w('OAuth: no se pudo leer deep link inicial', e, st);
    }

    _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (Object e, StackTrace st) {
        AppLogger.e('OAuth: error en uriLinkStream', e, st);
      },
    );
  }

  Future<void> _handleUri(Uri uri) async {
    if (!OAuthConfig.isOAuthCallback(uri)) return;
    if (leaveAuthCodeToSupabase(uri, expectingOAuth: _expectingOAuth)) return;
    _expectingOAuth = false;

    try {
      AppLogger.i('OAuth: procesando callback ${uri.toString()}');
      await supabase.auth.getSessionFromUrl(uri);
      await _onSessionReady?.call();
    } catch (e, st) {
      AppLogger.e('OAuth: fallo al recuperar sesión', e, st);
    }
  }
}

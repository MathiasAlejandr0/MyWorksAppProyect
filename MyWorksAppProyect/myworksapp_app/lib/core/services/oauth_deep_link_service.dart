import 'package:app_links/app_links.dart';

import '../config/oauth_config.dart';
import '../database/supabase_db.dart';
import '../utils/app_logger.dart';

typedef OAuthSessionCallback = Future<void> Function();

/// Escucha el deep link de retorno tras Google / Apple Sign-In.
class OAuthDeepLinkService {
  OAuthDeepLinkService._();

  static final OAuthDeepLinkService instance = OAuthDeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  OAuthSessionCallback? _onSessionReady;
  bool _started = false;

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

    try {
      AppLogger.i('OAuth: procesando callback ${uri.toString()}');
      await supabase.auth.getSessionFromUrl(uri);
      await _onSessionReady?.call();
    } catch (e, st) {
      AppLogger.e('OAuth: fallo al recuperar sesión', e, st);
    }
  }
}

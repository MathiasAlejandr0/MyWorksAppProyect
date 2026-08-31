/// Deep link de retorno OAuth (debe coincidir con Supabase → URL Configuration).
class OAuthConfig {
  OAuthConfig._();

  static const scheme = 'cl.myworksapp.auth';
  static const host = 'login-callback';
  static const redirectUrl = '$scheme://$host';

  static bool isOAuthCallback(Uri uri) =>
      uri.scheme == scheme && uri.host == host;
}

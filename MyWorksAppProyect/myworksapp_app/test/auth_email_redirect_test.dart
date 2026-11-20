import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/config/oauth_config.dart';
import 'package:myworksapp/core/router/auth_recovery_redirect.dart';
import 'package:myworksapp/core/services/oauth_deep_link_service.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/features/auth/presentation/pages/forgot_password_page.dart';

void main() {
  test('el alta y la recuperacion vuelven al deep link de la app', () {
    expect(OAuthConfig.redirectUrl, 'cl.myworksapp.auth://login-callback');
  });

  test('sendPasswordResetEmail normaliza el correo y usa ese redirect', () async {
    String? seen;
    String? redirect;
    await sendPasswordResetEmail(
      ' Ana@MyWorksApp.cl ',
      sender: (email, {required String redirectTo}) async {
        seen = email;
        redirect = redirectTo;
      },
    );
    expect(seen, 'ana@myworksapp.cl');
    expect(redirect, OAuthConfig.redirectUrl);
  });

  test('la recuperacion abre Nueva contrasena y no la deja si ya esta ahi', () {
    expect(
      authRecoveryRedirect(recovering: true, location: '/login'),
      AppConstants.routeResetPassword,
    );
    expect(
      authRecoveryRedirect(
        recovering: true,
        location: AppConstants.routeResetPassword,
      ),
      isNull,
    );
    expect(authRecoveryRedirect(recovering: false, location: '/login'), isNull);
  });

  test('un code que no es OAuth lo resuelve supabase_flutter', () {
    final uri = Uri.parse('cl.myworksapp.auth://login-callback?code=abc');
    expect(leaveAuthCodeToSupabase(uri, expectingOAuth: false), isTrue);
    expect(leaveAuthCodeToSupabase(uri, expectingOAuth: true), isFalse);
    final recovery = Uri.parse(
      'cl.myworksapp.auth://login-callback?code=abc&type=recovery',
    );
    expect(leaveAuthCodeToSupabase(recovery, expectingOAuth: true), isTrue);
    final other = Uri.parse('https://myworksapp.cl/?code=abc');
    expect(leaveAuthCodeToSupabase(other, expectingOAuth: true), isTrue);
  });

  testWidgets('ForgotPasswordPage envia el correo y confirma el aviso', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? sent;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ForgotPasswordPage(
            sendReset: (email) async {
              sent = email;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'ana@myworksapp.cl');
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();

    expect(sent, 'ana@myworksapp.cl');
    expect(find.textContaining('Si el correo está registrado'), findsOneWidget);
  });
}

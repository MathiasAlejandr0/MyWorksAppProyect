import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myworksapp/core/database/models/user_model.dart';
import 'package:myworksapp/core/domain/user_role.dart';
import 'package:myworksapp/core/providers/auth_provider.dart';
import 'package:myworksapp/core/services/auth_service.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/features/auth/presentation/pages/reset_password_new_page.dart';

class _FakeAuthService implements AuthService {
  int passwordChanges = 0;

  @override
  Stream<AuthSessionEvent> get sessionChanges => const Stream.empty();

  @override
  String? get currentUserId => null;

  @override
  Future<void> changePassword(String newPassword) async {
    passwordChanges += 1;
  }

  @override
  Future<UserModel> completeOAuthSession() => throw UnimplementedError();

  @override
  Future<UserModel?> loadUser(String userId) async => null;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> loginWithOAuth(SocialAuthProvider provider) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<AuthRegistrationResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserModel?> restoreSession() async => null;
}

void main() {
  testWidgets('Nueva contrasena valida y no guarda una clave debil', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = _FakeAuthService();
    final router = GoRouter(
      initialLocation: AppConstants.routeResetPassword,
      routes: [
        GoRoute(
          path: AppConstants.routeResetPassword,
          builder: (context, state) => const ResetPasswordNewPage(),
        ),
        GoRoute(
          path: AppConstants.routeLogin,
          builder: (context, state) => const Text('login'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(fake)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva contraseña'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(0), 'corta');
    await tester.enterText(find.byType(TextFormField).at(1), 'corta');
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();

    expect(find.text('La contraseña debe tener al menos 8 caracteres'), findsOneWidget);
    expect(fake.passwordChanges, 0);

    await tester.enterText(find.byType(TextFormField).at(0), 'clave1234');
    await tester.enterText(find.byType(TextFormField).at(1), 'otra12345');
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(fake.passwordChanges, 0);

    await tester.enterText(find.byType(TextFormField).at(0), 'clave1234');
    await tester.enterText(find.byType(TextFormField).at(1), 'clave1234');
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();

    expect(fake.passwordChanges, 1);
    expect(find.text('login'), findsOneWidget);
  });
}

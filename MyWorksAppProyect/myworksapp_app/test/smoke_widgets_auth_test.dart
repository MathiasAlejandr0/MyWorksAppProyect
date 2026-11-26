// GENERADO por scripts/cobertura/gen_widgets.py. No editar a mano.
// Tests de humo de widgets: montan cada widget contra el backend falso,
// tocan sus botones y escriben en sus campos (test/support/widget_harness.dart).
// ignore_for_file: prefer_const_constructors, deprecated_member_use, unused_import
// ignore_for_file: prefer_single_quotes, avoid_dynamic_calls
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:myworksapp/features/auth/presentation/pages/forgot_password_page.dart'
    as f0;
import 'package:myworksapp/features/auth/presentation/pages/login_page.dart'
    as f1;
import 'package:myworksapp/features/auth/presentation/pages/profile_page.dart'
    as f2;
import 'package:myworksapp/features/auth/presentation/pages/register_page.dart'
    as f3;
import 'package:myworksapp/features/auth/presentation/pages/reset_password_new_page.dart'
    as f4;
import 'package:myworksapp/features/auth/presentation/widgets/password_strength_meter.dart'
    as f5;
import 'package:myworksapp/features/auth/presentation/widgets/role_selector_chips.dart'
    as f6;
import 'package:myworksapp/core/domain/user_role.dart' as f7;
import 'package:myworksapp/features/auth/presentation/widgets/sign_out_button.dart'
    as f8;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void main() {
  testWidgets(
      'ForgotPasswordPage completo (features/auth/presentation/pages/forgot_password_page.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f0.ForgotPasswordPage(sendReset: (_) async {}),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'ForgotPasswordPage mínimo (features/auth/presentation/pages/forgot_password_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.ForgotPasswordPage(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'LoginPage completo (features/auth/presentation/pages/login_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.LoginPage(role: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'LoginPage mínimo (features/auth/presentation/pages/login_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.LoginPage(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ProfilePage completo (features/auth/presentation/pages/profile_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.ProfilePage(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'RegisterPage completo (features/auth/presentation/pages/register_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f3.RegisterPage(role: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'RegisterPage mínimo (features/auth/presentation/pages/register_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f3.RegisterPage(),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'ResetPasswordNewPage completo (features/auth/presentation/pages/reset_password_new_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.ResetPasswordNewPage(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'PasswordStrengthMeter completo (features/auth/presentation/widgets/password_strength_meter.dart)',
      (tester) async {
    await smokeWidget(tester, () => f5.PasswordStrengthMeter(value: 'valor-de-prueba'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'RoleSelectorChips completo (features/auth/presentation/widgets/role_selector_chips.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f6.RoleSelectorChips(
            selected: f7.UserRole.values.first,
            onChanged: (_) {},
            roles: [f7.UserRole.values.first]),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'RoleSelectorChips mínimo (features/auth/presentation/widgets/role_selector_chips.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f6.RoleSelectorChips(
            selected: f7.UserRole.values.first, onChanged: (_) {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'SignOutButton completo (features/auth/presentation/widgets/sign_out_button.dart)',
      (tester) async {
    await smokeWidget(tester, () => f8.SignOutButton(label: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'SignOutButton mínimo (features/auth/presentation/widgets/sign_out_button.dart)',
      (tester) async {
    await smokeWidget(tester, () => f8.SignOutButton(),
        seeded: false, role: 'usuario');
  });
}

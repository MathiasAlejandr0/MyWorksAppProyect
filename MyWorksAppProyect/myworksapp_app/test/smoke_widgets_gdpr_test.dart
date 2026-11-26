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
import 'package:myworksapp/features/gdpr/presentation/pages/privacy_policy_page.dart'
    as f0;
import 'package:myworksapp/features/gdpr/presentation/pages/terms_page.dart'
    as f1;
import 'package:myworksapp/features/gdpr/presentation/pages/user_rights_page.dart'
    as f2;
import 'package:myworksapp/features/gdpr/presentation/widgets/consent_checkbox.dart'
    as f3;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void main() {
  testWidgets(
      'PrivacyPolicyPage completo (features/gdpr/presentation/pages/privacy_policy_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.PrivacyPolicyPage(), seeded: true);
  });
  testWidgets(
      'TermsPage completo (features/gdpr/presentation/pages/terms_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.TermsPage(), seeded: true);
  });
  testWidgets(
      'UserRightsPage completo (features/gdpr/presentation/pages/user_rights_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.UserRightsPage(), seeded: true);
  });
  testWidgets(
      'ConsentCheckbox completo (features/gdpr/presentation/widgets/consent_checkbox.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.ConsentCheckbox(
            value: true, onChanged: (_) {}, consentVersion: 'id-1'),
        seeded: true);
  });
  testWidgets(
      'ConsentCheckbox mínimo (features/gdpr/presentation/widgets/consent_checkbox.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f3.ConsentCheckbox(value: true, onChanged: (_) {}),
        seeded: false);
  });
}

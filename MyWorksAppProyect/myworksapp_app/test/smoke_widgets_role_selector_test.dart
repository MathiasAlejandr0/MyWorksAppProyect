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
import 'package:myworksapp/features/role_selector/presentation/pages/role_selector_page.dart'
    as f0;
import 'package:myworksapp/features/role_selector/presentation/pages/welcome_page.dart'
    as f1;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void main() {
  testWidgets(
      'RoleSelectorPage completo (features/role_selector/presentation/pages/role_selector_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.RoleSelectorPage(), seeded: true);
  });
  testWidgets(
      'WelcomePage completo (features/role_selector/presentation/pages/welcome_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.WelcomePage(), seeded: true);
  });
}

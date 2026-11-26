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
import 'package:myworksapp/features/payments/presentation/pages/card_enrollment_page.dart'
    as f0;
import 'package:myworksapp/features/payments/presentation/pages/payment_methods_page.dart'
    as f1;
import 'package:myworksapp/features/payments/presentation/pages/payment_result_screen.dart'
    as f2;
import 'package:myworksapp/features/payments/presentation/pages/payment_screen.dart'
    as f3;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void main() {
  testWidgets(
      'CardEnrollmentPage completo (features/payments/presentation/pages/card_enrollment_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.CardEnrollmentPage(replacing: true),
        seeded: true);
  });
  testWidgets(
      'CardEnrollmentPage mínimo (features/payments/presentation/pages/card_enrollment_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.CardEnrollmentPage(), seeded: false);
  });
  testWidgets(
      'PaymentMethodsPage completo (features/payments/presentation/pages/payment_methods_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.PaymentMethodsPage(), seeded: true);
  });
  testWidgets(
      'PaymentMethodsBody completo (features/payments/presentation/pages/payment_methods_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f1.PaymentMethodsBody(
            loading: true,
            busy: true,
            cardLabel: 'id-1',
            onAdd: () {},
            onRemove: () {},
            onRetry: () {},
            error: 'id-1'),
        seeded: true);
  });
  testWidgets(
      'PaymentMethodsBody mínimo (features/payments/presentation/pages/payment_methods_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f1.PaymentMethodsBody(
            loading: true, busy: true, cardLabel: 'id-1', onAdd: () {}),
        seeded: false);
  });
  testWidgets(
      'PaymentResultScreen completo (features/payments/presentation/pages/payment_result_screen.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.PaymentResultScreen(token: 'id-1'),
        seeded: true);
  });
  testWidgets(
      'PaymentScreen completo (features/payments/presentation/pages/payment_screen.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.PaymentScreen(
            jobId: 'id-1',
            amount: 1.0,
            serviceName: 'id-1',
            specialistName: 'id-1'),
        seeded: true);
  });
  testWidgets(
      'PaymentScreen mínimo (features/payments/presentation/pages/payment_screen.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f3.PaymentScreen(jobId: 'id-1', amount: 1.0),
        seeded: false);
  });
}

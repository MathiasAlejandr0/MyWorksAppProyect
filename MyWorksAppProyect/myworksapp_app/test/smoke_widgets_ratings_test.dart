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
import 'package:myworksapp/features/ratings/presentation/pages/rating_page.dart'
    as f0;
import 'package:myworksapp/features/ratings/presentation/widgets/client_rating_badge.dart'
    as f1;
import 'package:myworksapp/features/ratings/presentation/widgets/client_reputation_card.dart'
    as f2;
import 'package:myworksapp/features/ratings/presentation/widgets/rate_client_button.dart'
    as f3;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void main() {
  testWidgets(
      'RatingPage completo (features/ratings/presentation/pages/rating_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.RatingPage(jobId: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'ClientRatingBadge completo (features/ratings/presentation/widgets/client_rating_badge.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.ClientRatingBadge(label: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'ClientReputationCard completo (features/ratings/presentation/widgets/client_reputation_card.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.ClientReputationCard(clientId: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'RateClientButton completo (features/ratings/presentation/widgets/rate_client_button.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f3.RateClientButton(jobId: 'id-1', onSaved: () {}),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'RateClientButton mínimo (features/ratings/presentation/widgets/rate_client_button.dart)',
      (tester) async {
    await smokeWidget(tester, () => f3.RateClientButton(jobId: 'id-1'),
        seeded: false, role: 'usuario');
  });
}

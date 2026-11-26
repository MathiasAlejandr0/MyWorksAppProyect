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
import 'package:myworksapp/features/admin/presentation/pages/admin_dashboard_page.dart'
    as f0;
import 'package:myworksapp/features/admin/presentation/pages/admin_desktop_management_page.dart'
    as f1;
import 'package:myworksapp/features/admin/presentation/pages/admin_disputes_page.dart'
    as f2;
import 'package:myworksapp/features/admin/presentation/pages/admin_errors_page.dart'
    as f3;
import 'package:myworksapp/features/admin/presentation/pages/admin_feature_flags_page.dart'
    as f4;
import 'package:myworksapp/features/admin/presentation/pages/admin_job_detail_page.dart'
    as f5;
import 'package:myworksapp/features/admin/presentation/pages/admin_jobs_page.dart'
    as f6;
import 'package:myworksapp/features/admin/presentation/pages/admin_payouts_page.dart'
    as f7;
import 'package:myworksapp/features/admin/presentation/pages/admin_ranking_page.dart'
    as f8;
import 'package:myworksapp/features/admin/presentation/pages/admin_reports_page.dart'
    as f9;
import 'package:myworksapp/features/admin/presentation/pages/admin_services_page.dart'
    as f10;
import 'package:myworksapp/features/admin/presentation/pages/admin_users_page.dart'
    as f11;
import 'package:myworksapp/features/admin/presentation/pages/admin_workers_page.dart'
    as f12;
import 'package:myworksapp/features/admin/presentation/widgets/admin_nav_tile.dart'
    as f13;
import 'package:myworksapp/features/admin/presentation/widgets/admin_search_field.dart'
    as f14;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void main() {
  testWidgets(
      'AdminDashboardPage completo (features/admin/presentation/pages/admin_dashboard_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.AdminDashboardPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminDesktopManagementPage completo (features/admin/presentation/pages/admin_desktop_management_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.AdminDesktopManagementPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminDisputesPage completo (features/admin/presentation/pages/admin_disputes_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.AdminDisputesPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminErrorsPage completo (features/admin/presentation/pages/admin_errors_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f3.AdminErrorsPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminFeatureFlagsPage completo (features/admin/presentation/pages/admin_feature_flags_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.AdminFeatureFlagsPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminJobDetailPage completo (features/admin/presentation/pages/admin_job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f5.AdminJobDetailPage(jobId: 'id-1'),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminJobsPage completo (features/admin/presentation/pages/admin_jobs_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f6.AdminJobsPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminPayoutsPage completo (features/admin/presentation/pages/admin_payouts_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f7.AdminPayoutsPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminRankingPage completo (features/admin/presentation/pages/admin_ranking_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f8.AdminRankingPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminReportsPage completo (features/admin/presentation/pages/admin_reports_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f9.AdminReportsPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminServicesPage completo (features/admin/presentation/pages/admin_services_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f10.AdminServicesPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminUsersPage completo (features/admin/presentation/pages/admin_users_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f11.AdminUsersPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminWorkersPage completo (features/admin/presentation/pages/admin_workers_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f12.AdminWorkersPage(),
        seeded: true, role: 'administrador');
  });
  testWidgets(
      'AdminNavTile completo (features/admin/presentation/widgets/admin_nav_tile.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.AdminNavTile(
            icon: Icons.star,
            title: 'id-1',
            subtitle: 'id-1',
            onTap: () {},
            badge: 1),
        seeded: true,
        role: 'administrador');
  });
  testWidgets(
      'AdminNavTile mínimo (features/admin/presentation/widgets/admin_nav_tile.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.AdminNavTile(
            icon: Icons.star, title: 'id-1', subtitle: 'id-1', onTap: () {}),
        seeded: false,
        role: 'administrador');
  });
  testWidgets(
      'AdminSearchField completo (features/admin/presentation/widgets/admin_search_field.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () =>
            f14.AdminSearchField(hint: 'id-1', onSearch: (_) {}, debounceMs: 1),
        seeded: true,
        role: 'administrador');
  });
  testWidgets(
      'AdminSearchField mínimo (features/admin/presentation/widgets/admin_search_field.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f14.AdminSearchField(hint: 'id-1', onSearch: (_) {}),
        seeded: false, role: 'administrador');
  });
}

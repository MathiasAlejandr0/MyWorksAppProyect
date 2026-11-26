// Recorre todas las rutas del router real de la app (routerProvider) con
// cada rol y sin sesión, contra el backend Supabase falso. Cubre los
// redirects (onboarding, bienvenida, rol, rutas de administración) y los
// builders de cada ruta. No sale a la red.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/constants.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

const _id = '00000000-0000-4000-8000-0000000000aa';

const _routes = [
  AppConstants.routeWelcome,
  AppConstants.routeOnboarding,
  AppConstants.routeRoleSelector,
  AppConstants.routeLogin,
  AppConstants.routeRegister,
  AppConstants.routeForgotPassword,
  AppConstants.routeResetPassword,
  AppConstants.routeUserHome,
  AppConstants.routeWorkerHome,
  AppConstants.routeProfile,
  AppConstants.routeUserProfile,
  AppConstants.routeUserProfileEdit,
  AppConstants.routeWorkerProfile,
  AppConstants.routeWorkerProfileManage,
  AppConstants.routeWorkerRegister,
  AppConstants.routeWorkerPricingSetup,
  '${AppConstants.routeWorkerPricingSetup}?edit=1',
  AppConstants.routeServiceRequest,
  AppConstants.routeWorkerList,
  '${AppConstants.routeWorkerDetail}/$_id',
  AppConstants.routeQuickBooking,
  '${AppConstants.routeJobDetail}/$_id',
  AppConstants.routeJobHistory,
  '${AppConstants.routeRating}/$_id',
  '${AppConstants.routeChat}/$_id',
  AppConstants.routeMessages,
  AppConstants.routeNotifications,
  '${AppConstants.routeJobPhotos}/$_id',
  AppConstants.routeStatistics,
  AppConstants.routeSettings,
  AppConstants.routeJobSchedule,
  AppConstants.routeWorkerPayouts,
  AppConstants.routeWorkerSchedule,
  AppConstants.routeMyRatings,
  AppConstants.routeMyDisputes,
  AppConstants.routePrivacyPolicy,
  AppConstants.routeTerms,
  AppConstants.routeUserRights,
  AppConstants.routeMaintenance,
  AppConstants.routeHelpCenter,
  AppConstants.routeAdminDashboard,
  AppConstants.routeAdminUsers,
  AppConstants.routeAdminWorkers,
  AppConstants.routeAdminJobs,
  '${AppConstants.routeAdminJobDetail}/$_id',
  AppConstants.routeAdminReports,
  AppConstants.routeAdminDisputes,
  AppConstants.routeAdminErrors,
  AppConstants.routeAdminServices,
  AppConstants.routeAdminFeatureFlags,
  AppConstants.routeAdminRanking,
  AppConstants.routeAdminDesktopHub,
  AppConstants.routeAdminPayouts,
  '/ruta-que-no-existe',
];

void main() {
  tearDown(() => fakePrefs = {});
  for (final role in ['usuario', 'trabajador', 'administrador']) {
    for (final route in _routes) {
      testWidgets('ruta $route con rol $role', (tester) async {
        fakePrefs = {'onboarding_completed': true};
        await smokeWidget(
          tester,
          () => const SizedBox(),
          role: role,
          interact: false,
          appRoute: route,
        );
      });
    }
  }
  for (final onboarded in [true, false]) {
    for (final route in _routes) {
      testWidgets('ruta $route sin sesión (onboarding $onboarded)',
          (tester) async {
        fakePrefs = {'onboarding_completed': onboarded};
        await smokeWidget(
          tester,
          () => const SizedBox(),
          signedIn: false,
          interact: false,
          appRoute: route,
        );
      });
    }
  }
}

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/role_selector/presentation/pages/welcome_page.dart';
import '../../features/role_selector/presentation/pages/role_selector_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/user/presentation/pages/user_home_page.dart';
import '../../features/user/presentation/pages/user_profile_page.dart';
import '../../features/worker/presentation/pages/worker_home_page.dart';
import '../../features/worker/presentation/pages/worker_profile_page.dart';
import '../../features/worker/presentation/pages/worker_register_page.dart';
import '../../features/user/presentation/pages/service_request_page.dart';
import '../../features/user/presentation/pages/worker_list_page.dart';
import '../../features/user/presentation/pages/worker_detail_page.dart';
import '../../features/user/presentation/pages/quick_booking_page.dart';
import '../../features/jobs/presentation/pages/job_detail_page.dart';
import '../../features/jobs/presentation/pages/job_history_page.dart';
import '../../features/ratings/presentation/pages/rating_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/jobs/presentation/pages/job_photos_page.dart';
import '../../features/worker/presentation/pages/statistics_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/jobs/presentation/pages/job_schedule_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/reset_password_code_page.dart';
import '../../features/auth/presentation/pages/reset_password_new_page.dart';
import '../../features/gdpr/presentation/pages/privacy_policy_page.dart';
import '../../features/gdpr/presentation/pages/terms_page.dart';
import '../../features/gdpr/presentation/pages/user_rights_page.dart';
import '../../core/presentation/pages/maintenance_page.dart';
import '../../core/presentation/pages/help_center_page.dart';
import '../../core/utils/constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Solo reaccionar a login/logout, no a isLoading (evita resetear la pila al abrir perfil).
  final authUser = ref.watch(authProvider.select((s) => s.user));

  return GoRouter(
    initialLocation: AppConstants.routeWelcome,
    redirect: (context, state) async {
      try {
        final isLoggedIn = authUser != null;
        
        // Verificar si es la primera vez (onboarding)
        if (!isLoggedIn && 
            (state.matchedLocation == AppConstants.routeWelcome ||
             state.matchedLocation == '/')) {
          final prefs = await SharedPreferences.getInstance();
          final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
          if (!onboardingCompleted) {
            return AppConstants.routeOnboarding;
          }
        }
        
        final isOnWelcome = state.matchedLocation == AppConstants.routeWelcome ||
            state.matchedLocation == AppConstants.routeOnboarding;
        final isOnAuth = state.matchedLocation == AppConstants.routeLogin ||
            state.matchedLocation == AppConstants.routeRegister ||
            state.matchedLocation == AppConstants.routeForgotPassword;

        // Rutas legales accesibles sin login (GDPR compliance)
        final isLegalRoute = state.matchedLocation == AppConstants.routePrivacyPolicy ||
            state.matchedLocation == AppConstants.routeTerms ||
            state.matchedLocation == AppConstants.routeUserRights;

        // Si no está logueado y no está en welcome/auth/legal, redirigir a welcome
        if (!isLoggedIn && !isOnWelcome && !isOnAuth && !isLegalRoute) {
          return AppConstants.routeWelcome;
        }

        // Si está logueado y está en welcome/auth/onboarding, redirigir según rol
        if (isLoggedIn && (isOnWelcome || isOnAuth)) {
          if (authUser.role == AppConstants.roleUser) {
            return AppConstants.routeUserHome;
          } else {
            return AppConstants.routeWorkerHome;
          }
        }
      } catch (e) {
        // Si hay error, continuar sin redirección
        // Error silenciado para evitar crashes en producción
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeWelcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppConstants.routeOnboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppConstants.routeRoleSelector,
        builder: (context, state) => const RoleSelectorPage(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) {
          final role = state.extra as Map<String, dynamic>?;
          return LoginPage(role: role?['role'] as String?);
        },
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        builder: (context, state) {
          final role = state.extra as Map<String, dynamic>?;
          return RegisterPage(role: role?['role'] as String?);
        },
      ),
      GoRoute(
        path: AppConstants.routeForgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppConstants.routeResetPasswordCode,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return ResetPasswordCodePage(email: args?['email'] ?? '');
        },
      ),
      GoRoute(
        path: '${AppConstants.routeResetPassword}/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ResetPasswordNewPage(userId: userId);
        },
      ),
      GoRoute(
        path: AppConstants.routeUserHome,
        builder: (context, state) => const UserHomePage(),
      ),
      GoRoute(
        path: AppConstants.routeWorkerHome,
        builder: (context, state) => const WorkerHomePage(),
      ),
      GoRoute(
        path: AppConstants.routeUserProfile,
        builder: (context, state) => const UserProfilePage(),
      ),
      GoRoute(
        path: AppConstants.routeWorkerProfile,
        builder: (context, state) => const WorkerProfilePage(),
      ),
      GoRoute(
        path: AppConstants.routeWorkerRegister,
        builder: (context, state) => const WorkerRegisterPage(),
      ),
      GoRoute(
        path: AppConstants.routeServiceRequest,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return ServiceRequestPage(
            serviceId: args?['serviceId'] as String?,
            workerId: args?['workerId'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeWorkerList,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return WorkerListPage(
            serviceId: args?['serviceId'] as String?,
            jobId: args?['jobId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '${AppConstants.routeWorkerDetail}/:workerId',
        builder: (context, state) {
          final workerId = state.pathParameters['workerId']!;
          final args = state.extra as Map<String, dynamic>?;
          return WorkerDetailPage(
            workerId: workerId,
            serviceId: args?['serviceId'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeQuickBooking,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return QuickBookingPage(
            workerId: args?['workerId'] as String? ?? '',
            serviceId: args?['serviceId'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '${AppConstants.routeJobDetail}/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return JobDetailPage(jobId: jobId);
        },
      ),
      GoRoute(
        path: AppConstants.routeJobHistory,
        builder: (context, state) => const JobHistoryPage(),
      ),
      GoRoute(
        path: '${AppConstants.routeRating}/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return RatingPage(jobId: jobId);
        },
      ),
      GoRoute(
        path: '${AppConstants.routeChat}/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return ChatPage(jobId: jobId);
        },
      ),
      GoRoute(
        path: AppConstants.routeNotifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '${AppConstants.routeJobPhotos}/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return JobPhotosPage(jobId: jobId);
        },
      ),
      GoRoute(
        path: AppConstants.routeStatistics,
        builder: (context, state) => const StatisticsPage(),
      ),
      GoRoute(
        path: AppConstants.routeSettings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppConstants.routeJobSchedule,
        builder: (context, state) => const JobSchedulePage(),
      ),
      // Rutas GDPR
      GoRoute(
        path: AppConstants.routePrivacyPolicy,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppConstants.routeTerms,
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: AppConstants.routeUserRights,
        builder: (context, state) => const UserRightsPage(),
      ),
      // Rutas nuevas
      GoRoute(
        path: AppConstants.routeMaintenance,
        builder: (context, state) => const MaintenancePage(),
      ),
      GoRoute(
        path: AppConstants.routeHelpCenter,
        builder: (context, state) {
          final role = state.extra as String?;
          return HelpCenterPage(userRole: role);
        },
      ),
    ],
  );
});


class AppConstants {
  /// Nombre de marca en logos, launcher y textos de la UI.
  static const String appBrandDisplayName = 'My Works App';

  // Roles
  static const String roleUser = 'user';
  static const String roleWorker = 'worker';

  // Estados de trabajo
  static const String jobStatusPending = 'pending';
  static const String jobStatusAccepted = 'accepted';
  static const String jobStatusInProgress = 'in_progress';
  static const String jobStatusCompleted = 'completed';
  static const String jobStatusCancelled = 'cancelled';
  // Estados avanzados (preparación futura)
  static const String jobStatusExpired = 'expired'; // No aceptado en X tiempo
  static const String jobStatusNoShow = 'no_show'; // Una parte no se presentó

  // Rutas
  static const String routeWelcome = '/welcome';
  static const String routeRoleSelector = '/role-selector';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeUserHome = '/user/home';
  static const String routeWorkerHome = '/worker/home';
  static const String routeUserProfile = '/user/profile';
  static const String routeWorkerProfile = '/worker/profile';
  static const String routeWorkerRegister = '/worker/register';
  static const String routeWorkerPricingSetup = '/worker/pricing-setup';
  static const String routeServiceRequest = '/user/service-request';
  static const String routeWorkerList = '/user/worker-list';
  static const String routeWorkerDetail = '/user/worker-detail';
  static const String routeQuickBooking = '/user/quick-booking';
  static const String routeJobDetail = '/job/detail';
  static const String routeJobHistory = '/job/history';
  static const String routeRating = '/rating';
  static const String routeChat = '/chat';
  static const String routeNotifications = '/notifications';
  static const String routeSettings = '/settings';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeResetPasswordCode = '/reset-password-code';
  static const String routeResetPassword = '/reset-password';
  static const String routeStatistics = '/statistics';
  static const String routeJobPhotos = '/job/photos';
  static const String routeJobSchedule = '/job/schedule';
  static const String routeOnboarding = '/onboarding';
  
  // Rutas GDPR
  static const String routePrivacyPolicy = '/privacy-policy';
  static const String routeTerms = '/terms';
  static const String routeUserRights = '/user-rights';
  
  // Rutas nuevas
  static const String routeMaintenance = '/maintenance';
  static const String routeHelpCenter = '/help-center';
}


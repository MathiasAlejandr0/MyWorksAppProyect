class AppConstants {
  /// Nombre de marca en logos, launcher y textos de la UI.
  static const String appBrandDisplayName = 'My Works App';

  // Roles (códigos BD en español). Preferir [UserRole] en código nuevo.
  // Cliente → usuario, Especialista → trabajador.
  static const String roleUser = 'usuario';
  static const String roleWorker = 'trabajador';
  static const String roleAdmin = 'administrador';

  // Estados de trabajo
  static const String jobStatusPending = 'pendiente';
  static const String jobStatusAccepted = 'aceptado';
  static const String jobStatusInProgress = 'en_curso';
  static const String jobStatusCompleted = 'completado';
  static const String jobStatusCancelled = 'cancelado';
  static const String jobStatusExpired = 'expirado';
  static const String jobStatusNoShow = 'no_asistio';

  // Estados de disputa
  static const String disputeStatusOpen = 'abierta';
  static const String disputeStatusUnderReview = 'en_revision';
  static const String disputeStatusResolved = 'resuelta';

  // Estados de reporte / reclamo
  static const String reportStatusPending = 'pendiente';
  static const String reportStatusReviewed = 'revisado';
  static const String reportStatusResolved = 'resuelto';
  static const String reportStatusDismissed = 'descartado';

  // Estados de registro de error de app
  static const String errorStatusNew = 'nuevo';
  static const String errorStatusAcknowledged = 'reconocido';
  static const String errorStatusResolved = 'resuelto';
  static const String errorStatusIgnored = 'ignorado';

  // Estados de cuenta
  static const String accountStatusActive = 'activo';
  static const String accountStatusSuspended = 'suspendido';
  static const String accountStatusBlocked = 'bloqueado';
  static const String accountStatusDeleted = 'eliminado';

  // Estados de sync offline
  static const String syncStatusPending = 'pendiente_sync';
  static const String syncStatusFailed = 'fallido';

  // Motivos de disputa
  static const String disputeReasonQuality = 'calidad';
  static const String disputeReasonPayment = 'pago';
  static const String disputeReasonBehavior = 'conducta';
  static const String disputeReasonOther = 'otro';

  // Rutas
  static const String routeWelcome = '/welcome';
  static const String routeRoleSelector = '/role-selector';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeUserHome = '/user/home';
  static const String routeWorkerHome = '/worker/home';
  static const String routeProfile = '/profile';
  static const String routeUserProfile = '/user/profile';
  static const String routeUserProfileEdit = '/user/profile/edit';
  static const String routeWorkerProfile = '/worker/profile';
  static const String routeWorkerProfileManage = '/worker/profile/manage';
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

  // Admin
  static const String routeAdminDashboard = '/admin';
  static const String routeAdminUsers = '/admin/users';
  static const String routeAdminWorkers = '/admin/workers';
  static const String routeAdminJobs = '/admin/jobs';
  static const String routeAdminJobDetail = '/admin/jobs/detail';
  static const String routeAdminReports = '/admin/reports';
  static const String routeAdminDisputes = '/admin/disputes';
  static const String routeAdminErrors = '/admin/errors';
  static const String routeAdminServices = '/admin/services';
  static const String routeAdminFeatureFlags = '/admin/feature-flags';
  static const String routeAdminDesktopHub = '/admin/desktop-hub';
}

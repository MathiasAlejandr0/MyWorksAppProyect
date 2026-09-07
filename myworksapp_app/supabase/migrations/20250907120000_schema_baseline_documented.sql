-- =============================================================================
-- Schema baseline DOCUMENTADO (idempotente / seguro)
-- =============================================================================
-- Origen: reconstruido desde modelos Dart en
--   myworksapp_app/lib/core/database/models/
-- y nombres REALES de tablas en repositorios (*.from / _table).
--
-- IMPORTANTE:
-- - El proyecto Supabase YA existe. Esta migración NO borra datos.
-- - NO DROP TABLE. Solo CREATE TABLE IF NOT EXISTS.
-- - Columnas en camelCase entre comillas dobles (como usa el código:
--   "userId", "createdAt", "accountStatus", etc.).
-- - Flags booleanos del cliente se persisten como integer 0/1.
-- - Fechas/horas se modelan como text ISO-8601 (toIso8601String / DateTime.parse),
--   coherente con triggers existentes (p.ej. handle_new_user).
-- - Maps/listas nativas del cliente → jsonb; JSON serializado en Dart → text.
-- - Si una tabla ya existe, este script no altera su definición.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- profiles (UserModel / user_repository → 'profiles')
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY,
  name text NOT NULL DEFAULT '',
  email text NOT NULL DEFAULT '',
  password text,
  role text NOT NULL DEFAULT 'user',
  "accountStatus" text NOT NULL DEFAULT 'active',
  "profilePhotoPath" text,
  "createdAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- workers (WorkerModel / worker_repository → 'workers')
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.workers (
  "userId" uuid PRIMARY KEY,
  profession text NOT NULL DEFAULT '',
  description text,
  rating double precision NOT NULL DEFAULT 0,
  "isAvailable" integer NOT NULL DEFAULT 1,
  "visitFee" double precision NOT NULL DEFAULT 15000,
  "serviceCategory" text NOT NULL DEFAULT 'general',
  "pricingTiers" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "customServices" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "pricingConfigured" integer NOT NULL DEFAULT 0,
  "workZone" text,
  "rejectionCount" integer NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- services (ServiceModel / service_repository → 'services')
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.services (
  id text PRIMARY KEY,
  name text NOT NULL,
  description text,
  category text NOT NULL DEFAULT 'general',
  "isActive" integer NOT NULL DEFAULT 1,
  "requiresCertification" integer NOT NULL DEFAULT 0,
  "pricingModel" text NOT NULL DEFAULT 'hourly',
  "legalDisclaimer" text,
  "createdAt" text NOT NULL,
  "updatedAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- worker_services (N:M worker ↔ categoría; worker_service_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.worker_services (
  "workerId" uuid NOT NULL,
  "serviceCategory" text NOT NULL,
  PRIMARY KEY ("workerId", "serviceCategory")
);

-- ---------------------------------------------------------------------------
-- service_configs (ServiceConfigModel / service_config_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.service_configs (
  id text PRIMARY KEY,
  "serviceId" text NOT NULL,
  "configSchema" text NOT NULL DEFAULT '{}',
  "createdAt" text NOT NULL,
  "updatedAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- service_pricing (ServicePricingModel; documentado — aún no hay repo dedicado)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.service_pricing (
  id text PRIMARY KEY,
  "serviceId" text NOT NULL,
  "basePrice" double precision NOT NULL DEFAULT 0,
  "minimumFee" double precision NOT NULL DEFAULT 0,
  "hourlyRate" double precision NOT NULL DEFAULT 0,
  currency text DEFAULT 'USD',
  "createdAt" text NOT NULL,
  "updatedAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- jobs (JobModel / job_repository → 'jobs')
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.jobs (
  id text PRIMARY KEY,
  "userId" uuid NOT NULL,
  "workerId" uuid,
  "serviceId" text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  address text NOT NULL DEFAULT '',
  latitude double precision,
  longitude double precision,
  description text,
  "scheduledDate" text,
  "serviceMetadata" text,
  "pricingMode" text NOT NULL DEFAULT 'legacy',
  "paymentStatus" text NOT NULL DEFAULT 'none',
  "comunaId" text,
  "pricingSnapshot" text,
  "serviceSkuId" text,
  "hourlyBlockHours" integer,
  "selectedQuoteId" text,
  "createdAt" text NOT NULL,
  "updatedAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- payments (PaymentModel / payment_repository → 'payments')
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payments (
  id text PRIMARY KEY,
  "jobId" text NOT NULL,
  "changeOrderId" text,
  "paymentType" text NOT NULL DEFAULT 'primary',
  amount double precision NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'CLP',
  status text NOT NULL DEFAULT 'pending',
  "paymentMethod" text,
  "transactionId" text,
  "authorizedAt" text,
  "releasedAt" text,
  "refundedAt" text,
  "createdAt" text NOT NULL,
  "updatedAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- messages (MessageModel / message_repository → 'messages')
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.messages (
  id text PRIMARY KEY,
  "jobId" text NOT NULL,
  "senderId" uuid NOT NULL,
  "receiverId" uuid NOT NULL,
  content text NOT NULL DEFAULT '',
  type text NOT NULL DEFAULT 'text',
  "imagePath" text,
  "isRead" integer NOT NULL DEFAULT 0,
  "createdAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- notifications (NotificationModel / notification_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
  id text PRIMARY KEY,
  "userId" uuid NOT NULL,
  type text NOT NULL,
  title text NOT NULL DEFAULT '',
  body text NOT NULL DEFAULT '',
  "relatedId" text,
  "isRead" integer NOT NULL DEFAULT 0,
  "createdAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- ratings (RatingModel / rating_repository → 'ratings')
-- WorkerReviewModel es un DTO de presentación; no hay tabla worker_reviews.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ratings (
  id text PRIMARY KEY,
  "jobId" text NOT NULL,
  "userId" uuid,
  score integer NOT NULL,
  comment text,
  "createdAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- disputes (DisputeModel / dispute_repository → 'disputes')
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.disputes (
  id text PRIMARY KEY,
  "jobId" text NOT NULL,
  "openedBy" uuid NOT NULL,
  reason text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'open',
  resolution text,
  "resolvedBy" uuid,
  "resolvedAt" text,
  "createdAt" text NOT NULL,
  "updatedAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- change_orders (ChangeOrderModel / change_order_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.change_orders (
  id text PRIMARY KEY,
  "jobId" text NOT NULL,
  "workerId" uuid NOT NULL,
  tipo text NOT NULL,
  titulo text NOT NULL DEFAULT '',
  descripcion text NOT NULL DEFAULT '',
  "montoClp" integer NOT NULL DEFAULT 0,
  estado text NOT NULL DEFAULT 'pending_client',
  "paymentId" text,
  "createdAt" text NOT NULL,
  "respondedAt" text
);

-- ---------------------------------------------------------------------------
-- quote_proposals (QuoteProposalModel / quote_proposal_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.quote_proposals (
  id text PRIMARY KEY,
  "jobId" text NOT NULL,
  "workerId" uuid NOT NULL,
  "montoTotalClp" integer NOT NULL DEFAULT 0,
  descripcion text NOT NULL DEFAULT '',
  "validezHasta" text,
  desglose text,
  estado text NOT NULL DEFAULT 'submitted',
  "createdAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- job_photos (JobPhotoModel / job_photo_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.job_photos (
  id text PRIMARY KEY,
  "jobId" text NOT NULL,
  "photoPath" text NOT NULL,
  "mediaType" text NOT NULL DEFAULT 'photo',
  "createdAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- worker_portfolio (PortfolioModel / portfolio_repository → 'worker_portfolio')
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.worker_portfolio (
  id text PRIMARY KEY,
  "workerId" uuid NOT NULL,
  "photoPath" text NOT NULL,
  description text,
  "createdAt" text NOT NULL,
  "mediaType" text NOT NULL DEFAULT 'photo'
);

-- ---------------------------------------------------------------------------
-- feature_flags (FeatureFlagModel / feature_flag_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.feature_flags (
  id text PRIMARY KEY,
  "flagName" text NOT NULL,
  "isEnabled" integer NOT NULL DEFAULT 0,
  "appVersion" text,
  role text,
  "userId" uuid,
  "createdAt" text NOT NULL,
  "updatedAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- reports (ReportModel / report_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reports (
  id text PRIMARY KEY,
  "reporterId" uuid NOT NULL,
  "reportedUserId" uuid NOT NULL,
  reason text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'pending',
  "createdAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- app_error_logs (AppErrorLogModel / app_error_log_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_error_logs (
  id text PRIMARY KEY,
  "userId" uuid,
  "errorType" text NOT NULL DEFAULT 'error',
  message text NOT NULL,
  "stackTrace" text,
  metadata jsonb,
  status text NOT NULL DEFAULT 'new',
  "appVersion" text,
  platform text,
  "createdAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- abuse_events (AbuseEventModel / abuse_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.abuse_events (
  id text PRIMARY KEY,
  "userId" uuid NOT NULL,
  "abuseType" text NOT NULL,
  count integer NOT NULL DEFAULT 0,
  "detectedAt" text NOT NULL,
  "actionTaken" text,
  "actionTakenAt" text,
  "isResolved" integer NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- subscriptions (SubscriptionModel / subscription_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id text PRIMARY KEY,
  "userId" uuid NOT NULL,
  "planType" text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  "startDate" text NOT NULL,
  "endDate" text,
  "createdAt" text NOT NULL,
  "updatedAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- boosts (BoostModel / boost_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.boosts (
  id text PRIMARY KEY,
  "workerId" uuid NOT NULL,
  "boostType" text NOT NULL,
  "startDate" text NOT NULL,
  "endDate" text NOT NULL,
  "createdAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- user_consents (UserConsentModel / user_consent_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_consents (
  id text PRIMARY KEY,
  "userId" uuid NOT NULL,
  "consentVersion" text NOT NULL,
  accepted integer NOT NULL DEFAULT 0,
  "acceptedAt" text NOT NULL,
  "ipAddress" text,
  "userAgent" text
);

-- ---------------------------------------------------------------------------
-- user_blocks (UserBlockModel / user_block_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_blocks (
  id text PRIMARY KEY,
  "blockerId" uuid NOT NULL,
  "blockedUserId" uuid NOT NULL,
  "createdAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- pending_actions (PendingActionModel / pending_action_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pending_actions (
  id text PRIMARY KEY,
  "userId" uuid NOT NULL,
  "actionType" text NOT NULL,
  "entityType" text NOT NULL,
  "entityId" text,
  data text NOT NULL,
  status text NOT NULL DEFAULT 'pending_sync',
  "retryCount" integer NOT NULL DEFAULT 0,
  "errorMessage" text,
  "createdAt" text NOT NULL,
  "updatedAt" text NOT NULL
);

-- ---------------------------------------------------------------------------
-- analytics_events (AnalyticsEventModel / analytics_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.analytics_events (
  id text PRIMARY KEY,
  "eventName" text NOT NULL,
  "userId" uuid,
  role text,
  "timestamp" text NOT NULL,
  metadata text NOT NULL DEFAULT '{}'
);

-- ---------------------------------------------------------------------------
-- job_cancellations (JobCancellationModel / job_cancellation_repository)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.job_cancellations (
  id text PRIMARY KEY,
  "jobId" text NOT NULL,
  "cancelledBy" uuid NOT NULL,
  reason text NOT NULL,
  "cancelledAt" text NOT NULL
);

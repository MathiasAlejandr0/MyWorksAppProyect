


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  requested_role text;
  safe_role text;
  display_name text;
BEGIN
  requested_role := lower(trim(coalesce(new.raw_user_meta_data->>'role', 'user')));
  IF requested_role = 'worker' THEN
    safe_role := 'worker';
  ELSE
    safe_role := 'user';
  END IF;

  display_name := trim(
    coalesce(
      nullif(new.raw_user_meta_data->>'name', ''),
      nullif(new.raw_user_meta_data->>'full_name', ''),
      nullif(new.raw_user_meta_data->>'given_name', ''),
      split_part(coalesce(new.email, ''), '@', 1)
    )
  );

  INSERT INTO public.profiles (id, name, email, role, "accountStatus", "createdAt")
  VALUES (
    new.id,
    display_name,
    new.email,
    safe_role,
    'active',
    to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."protect_profile_sensitive_fields"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF NOT public.is_admin() THEN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'No puedes cambiar tu rol';
    END IF;
    IF NEW."accountStatus" IS DISTINCT FROM OLD."accountStatus" THEN
      RAISE EXCEPTION 'No puedes cambiar el estado de tu cuenta';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."protect_profile_sensitive_fields"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."abuse_events" (
    "id" "text" NOT NULL,
    "userId" "uuid" NOT NULL,
    "abuseType" "text" NOT NULL,
    "count" integer NOT NULL,
    "detectedAt" "text" NOT NULL,
    "actionTaken" "text",
    "actionTakenAt" "text",
    "isResolved" integer DEFAULT 0
);


ALTER TABLE "public"."abuse_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."analytics_events" (
    "id" "text" NOT NULL,
    "eventName" "text" NOT NULL,
    "userId" "uuid",
    "role" "text",
    "timestamp" "text" NOT NULL,
    "metadata" "text"
);


ALTER TABLE "public"."analytics_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_error_logs" (
    "id" "text" NOT NULL,
    "userId" "uuid",
    "errorType" "text" DEFAULT 'error'::"text" NOT NULL,
    "message" "text" NOT NULL,
    "stackTrace" "text",
    "metadata" "jsonb",
    "status" "text" DEFAULT 'new'::"text" NOT NULL,
    "appVersion" "text",
    "platform" "text",
    "createdAt" "text" DEFAULT "to_char"(("now"() AT TIME ZONE 'utc'::"text"), 'YYYY-MM-DD"T"HH24:MI:SS.US'::"text") NOT NULL
);


ALTER TABLE "public"."app_error_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."boosts" (
    "id" "text" NOT NULL,
    "workerId" "uuid" NOT NULL,
    "boostType" "text" NOT NULL,
    "startDate" "text" NOT NULL,
    "endDate" "text" NOT NULL,
    "createdAt" "text" NOT NULL
);


ALTER TABLE "public"."boosts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."change_orders" (
    "id" "text" NOT NULL,
    "jobId" "text" NOT NULL,
    "workerId" "uuid" NOT NULL,
    "tipo" "text" NOT NULL,
    "titulo" "text" NOT NULL,
    "descripcion" "text" NOT NULL,
    "montoClp" integer NOT NULL,
    "estado" "text" DEFAULT 'pending_client'::"text" NOT NULL,
    "paymentId" "text",
    "createdAt" "text" NOT NULL,
    "respondedAt" "text"
);


ALTER TABLE "public"."change_orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."disputes" (
    "id" "text" NOT NULL,
    "jobId" "text" NOT NULL,
    "openedBy" "uuid" NOT NULL,
    "reason" "text" NOT NULL,
    "description" "text",
    "status" "text" NOT NULL,
    "resolution" "text",
    "resolvedBy" "uuid",
    "resolvedAt" "text",
    "createdAt" "text" NOT NULL,
    "updatedAt" "text" NOT NULL
);


ALTER TABLE "public"."disputes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feature_flags" (
    "id" "text" NOT NULL,
    "flagName" "text" NOT NULL,
    "isEnabled" integer DEFAULT 0 NOT NULL,
    "appVersion" "text",
    "role" "text",
    "userId" "uuid",
    "createdAt" "text" NOT NULL,
    "updatedAt" "text" NOT NULL
);


ALTER TABLE "public"."feature_flags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."job_cancellations" (
    "id" "text" NOT NULL,
    "jobId" "text" NOT NULL,
    "cancelledBy" "uuid" NOT NULL,
    "reason" "text" NOT NULL,
    "cancelledAt" "text" NOT NULL
);


ALTER TABLE "public"."job_cancellations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."job_photos" (
    "id" "text" NOT NULL,
    "jobId" "text" NOT NULL,
    "photoPath" "text" NOT NULL,
    "createdAt" "text" NOT NULL,
    "mediaType" "text" DEFAULT 'photo'::"text" NOT NULL
);


ALTER TABLE "public"."job_photos" OWNER TO "postgres";


COMMENT ON COLUMN "public"."job_photos"."mediaType" IS 'photo or video evidence';



CREATE TABLE IF NOT EXISTS "public"."jobs" (
    "id" "text" NOT NULL,
    "userId" "uuid" NOT NULL,
    "workerId" "uuid",
    "serviceId" "text",
    "status" "text" NOT NULL,
    "address" "text" DEFAULT ''::"text" NOT NULL,
    "latitude" double precision,
    "longitude" double precision,
    "description" "text",
    "scheduledDate" "text",
    "serviceMetadata" "text",
    "pricingMode" "text",
    "paymentStatus" "text",
    "comunaId" "text",
    "pricingSnapshot" "text",
    "serviceSkuId" "text",
    "hourlyBlockHours" integer,
    "selectedQuoteId" "text",
    "createdAt" "text" NOT NULL,
    "updatedAt" "text" NOT NULL
);


ALTER TABLE "public"."jobs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" "text" NOT NULL,
    "jobId" "text" NOT NULL,
    "senderId" "uuid" NOT NULL,
    "receiverId" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "type" "text" DEFAULT 'text'::"text" NOT NULL,
    "imagePath" "text",
    "isRead" integer DEFAULT 0 NOT NULL,
    "createdAt" "text" NOT NULL
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "text" NOT NULL,
    "userId" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "title" "text" NOT NULL,
    "body" "text" NOT NULL,
    "relatedId" "text",
    "isRead" integer DEFAULT 0 NOT NULL,
    "createdAt" "text" NOT NULL
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."password_reset_codes" (
    "id" "text" NOT NULL,
    "userId" "uuid" NOT NULL,
    "code" "text" NOT NULL,
    "email" "text" NOT NULL,
    "expiresAt" "text" NOT NULL,
    "isUsed" integer DEFAULT 0,
    "createdAt" "text" NOT NULL
);


ALTER TABLE "public"."password_reset_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payments" (
    "id" "text" NOT NULL,
    "jobId" "text" NOT NULL,
    "changeOrderId" "text",
    "paymentType" "text" DEFAULT 'primary'::"text" NOT NULL,
    "amount" double precision NOT NULL,
    "currency" "text" DEFAULT 'CLP'::"text" NOT NULL,
    "status" "text" NOT NULL,
    "paymentMethod" "text",
    "transactionId" "text",
    "authorizedAt" "text",
    "releasedAt" "text",
    "refundedAt" "text",
    "createdAt" "text" NOT NULL,
    "updatedAt" "text" NOT NULL
);


ALTER TABLE "public"."payments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pending_actions" (
    "id" "text" NOT NULL,
    "userId" "uuid" NOT NULL,
    "actionType" "text" NOT NULL,
    "entityType" "text" NOT NULL,
    "entityId" "text",
    "data" "text" NOT NULL,
    "status" "text" DEFAULT 'pending_sync'::"text" NOT NULL,
    "retryCount" integer DEFAULT 0,
    "errorMessage" "text",
    "createdAt" "text" NOT NULL,
    "updatedAt" "text" NOT NULL
);


ALTER TABLE "public"."pending_actions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "email" "text",
    "role" "text" DEFAULT 'user'::"text" NOT NULL,
    "accountStatus" "text" DEFAULT 'active'::"text" NOT NULL,
    "profilePhotoPath" "text",
    "createdAt" "text" DEFAULT "to_char"(("now"() AT TIME ZONE 'utc'::"text"), 'YYYY-MM-DD"T"HH24:MI:SS.US'::"text") NOT NULL
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."quote_proposals" (
    "id" "text" NOT NULL,
    "jobId" "text" NOT NULL,
    "workerId" "uuid" NOT NULL,
    "montoTotalClp" integer NOT NULL,
    "descripcion" "text" NOT NULL,
    "validezHasta" "text",
    "desglose" "text",
    "estado" "text" NOT NULL,
    "createdAt" "text" NOT NULL
);


ALTER TABLE "public"."quote_proposals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ratings" (
    "id" "text" NOT NULL,
    "jobId" "text" NOT NULL,
    "userId" "uuid",
    "score" integer NOT NULL,
    "comment" "text",
    "createdAt" "text" NOT NULL
);


ALTER TABLE "public"."ratings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reports" (
    "id" "text" NOT NULL,
    "reporterId" "uuid" NOT NULL,
    "reportedUserId" "uuid" NOT NULL,
    "reason" "text" NOT NULL,
    "description" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "createdAt" "text" NOT NULL
);


ALTER TABLE "public"."reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."service_configs" (
    "id" "text" NOT NULL,
    "serviceId" "text" NOT NULL,
    "configSchema" "text" NOT NULL,
    "createdAt" "text" NOT NULL,
    "updatedAt" "text" NOT NULL
);


ALTER TABLE "public"."service_configs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."services" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "category" "text" DEFAULT 'general'::"text" NOT NULL,
    "isActive" integer DEFAULT 1 NOT NULL,
    "requiresCertification" integer DEFAULT 0 NOT NULL,
    "pricingModel" "text" DEFAULT 'hourly'::"text" NOT NULL,
    "legalDisclaimer" "text",
    "createdAt" "text",
    "updatedAt" "text"
);


ALTER TABLE "public"."services" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "text" NOT NULL,
    "userId" "uuid" NOT NULL,
    "planType" "text" NOT NULL,
    "status" "text" NOT NULL,
    "startDate" "text" NOT NULL,
    "endDate" "text",
    "createdAt" "text" NOT NULL,
    "updatedAt" "text" NOT NULL
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tickets" (
    "id" "text" DEFAULT ("gen_random_uuid"())::"text" NOT NULL,
    "job_id" "text",
    "client_name" "text" NOT NULL,
    "worker_name" "text" NOT NULL,
    "issue" "text" NOT NULL,
    "escrow_amount" integer NOT NULL,
    "status" "text" DEFAULT 'Pending'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "tickets_status_check" CHECK (("status" = ANY (ARRAY['Pending'::"text", 'Resolved'::"text"])))
);


ALTER TABLE "public"."tickets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_blocks" (
    "id" "text" NOT NULL,
    "blockerId" "uuid" NOT NULL,
    "blockedUserId" "uuid" NOT NULL,
    "createdAt" "text" NOT NULL
);


ALTER TABLE "public"."user_blocks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_consents" (
    "id" "text" NOT NULL,
    "userId" "uuid" NOT NULL,
    "consentVersion" "text" NOT NULL,
    "accepted" integer DEFAULT 0 NOT NULL,
    "acceptedAt" "text" NOT NULL,
    "ipAddress" "text",
    "userAgent" "text"
);


ALTER TABLE "public"."user_consents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."worker_portfolio" (
    "id" "text" NOT NULL,
    "workerId" "uuid" NOT NULL,
    "photoPath" "text" NOT NULL,
    "description" "text",
    "createdAt" "text" NOT NULL,
    "mediaType" "text" DEFAULT 'photo'::"text"
);


ALTER TABLE "public"."worker_portfolio" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."worker_services" (
    "workerId" "uuid" NOT NULL,
    "serviceCategory" "text" NOT NULL
);


ALTER TABLE "public"."worker_services" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."workers" (
    "userId" "uuid" NOT NULL,
    "profession" "text" DEFAULT ''::"text" NOT NULL,
    "description" "text",
    "rating" double precision DEFAULT 0 NOT NULL,
    "isAvailable" integer DEFAULT 1 NOT NULL,
    "visitFee" double precision DEFAULT 15000 NOT NULL,
    "serviceCategory" "text" DEFAULT 'general'::"text" NOT NULL,
    "pricingTiers" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "rejectionCount" integer DEFAULT 0 NOT NULL,
    "customServices" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "pricingConfigured" integer DEFAULT 0 NOT NULL,
    "workZone" "text"
);


ALTER TABLE "public"."workers" OWNER TO "postgres";


COMMENT ON COLUMN "public"."workers"."rejectionCount" IS 'Rechazos de invitaciones; penaliza orden en listados (no visible en UI)';



COMMENT ON COLUMN "public"."workers"."customServices" IS 'Servicios adicionales definidos por el trabajador (JSON array)';



COMMENT ON COLUMN "public"."workers"."pricingConfigured" IS '1 si el trabajador completó la guía de configuración de precios';



COMMENT ON COLUMN "public"."workers"."workZone" IS 'Comuna o zona donde atiende el trabajador';



ALTER TABLE ONLY "public"."abuse_events"
    ADD CONSTRAINT "abuse_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."analytics_events"
    ADD CONSTRAINT "analytics_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_error_logs"
    ADD CONSTRAINT "app_error_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."boosts"
    ADD CONSTRAINT "boosts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."change_orders"
    ADD CONSTRAINT "change_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."disputes"
    ADD CONSTRAINT "disputes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feature_flags"
    ADD CONSTRAINT "feature_flags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."job_cancellations"
    ADD CONSTRAINT "job_cancellations_jobId_key" UNIQUE ("jobId");



ALTER TABLE ONLY "public"."job_cancellations"
    ADD CONSTRAINT "job_cancellations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."job_photos"
    ADD CONSTRAINT "job_photos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."jobs"
    ADD CONSTRAINT "jobs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."password_reset_codes"
    ADD CONSTRAINT "password_reset_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pending_actions"
    ADD CONSTRAINT "pending_actions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quote_proposals"
    ADD CONSTRAINT "quote_proposals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ratings"
    ADD CONSTRAINT "ratings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."service_configs"
    ADD CONSTRAINT "service_configs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."service_configs"
    ADD CONSTRAINT "service_configs_serviceId_key" UNIQUE ("serviceId");



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tickets"
    ADD CONSTRAINT "tickets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_blocks"
    ADD CONSTRAINT "user_blocks_blockerId_blockedUserId_key" UNIQUE ("blockerId", "blockedUserId");



ALTER TABLE ONLY "public"."user_blocks"
    ADD CONSTRAINT "user_blocks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_consents"
    ADD CONSTRAINT "user_consents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."worker_portfolio"
    ADD CONSTRAINT "worker_portfolio_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."worker_services"
    ADD CONSTRAINT "worker_services_pkey" PRIMARY KEY ("workerId", "serviceCategory");



ALTER TABLE ONLY "public"."workers"
    ADD CONSTRAINT "workers_pkey" PRIMARY KEY ("userId");



CREATE INDEX "idx_change_orders_job" ON "public"."change_orders" USING "btree" ("jobId");



CREATE INDEX "idx_disputes_job" ON "public"."disputes" USING "btree" ("jobId");



CREATE INDEX "idx_job_photos_job" ON "public"."job_photos" USING "btree" ("jobId");



CREATE INDEX "idx_jobs_user" ON "public"."jobs" USING "btree" ("userId");



CREATE INDEX "idx_jobs_worker" ON "public"."jobs" USING "btree" ("workerId");



CREATE INDEX "idx_messages_job" ON "public"."messages" USING "btree" ("jobId");



CREATE INDEX "idx_messages_receiver" ON "public"."messages" USING "btree" ("receiverId");



CREATE INDEX "idx_notifications_user" ON "public"."notifications" USING "btree" ("userId");



CREATE INDEX "idx_payments_job" ON "public"."payments" USING "btree" ("jobId");



CREATE INDEX "idx_portfolio_worker" ON "public"."worker_portfolio" USING "btree" ("workerId");



CREATE INDEX "idx_quotes_job" ON "public"."quote_proposals" USING "btree" ("jobId");



CREATE INDEX "idx_quotes_worker" ON "public"."quote_proposals" USING "btree" ("workerId");



CREATE OR REPLACE TRIGGER "protect_profiles_sensitive" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."protect_profile_sensitive_fields"();



ALTER TABLE ONLY "public"."abuse_events"
    ADD CONSTRAINT "abuse_events_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."app_error_logs"
    ADD CONSTRAINT "app_error_logs_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."boosts"
    ADD CONSTRAINT "boosts_workerId_fkey" FOREIGN KEY ("workerId") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."change_orders"
    ADD CONSTRAINT "change_orders_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "public"."jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."disputes"
    ADD CONSTRAINT "disputes_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "public"."jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."job_cancellations"
    ADD CONSTRAINT "job_cancellations_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "public"."jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."job_photos"
    ADD CONSTRAINT "job_photos_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "public"."jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."jobs"
    ADD CONSTRAINT "jobs_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "public"."services"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."jobs"
    ADD CONSTRAINT "jobs_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."jobs"
    ADD CONSTRAINT "jobs_workerId_fkey" FOREIGN KEY ("workerId") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "public"."jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "public"."jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pending_actions"
    ADD CONSTRAINT "pending_actions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."quote_proposals"
    ADD CONSTRAINT "quote_proposals_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "public"."jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."quote_proposals"
    ADD CONSTRAINT "quote_proposals_workerId_fkey" FOREIGN KEY ("workerId") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ratings"
    ADD CONSTRAINT "ratings_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "public"."jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."service_configs"
    ADD CONSTRAINT "service_configs_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "public"."services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_consents"
    ADD CONSTRAINT "user_consents_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."worker_portfolio"
    ADD CONSTRAINT "worker_portfolio_workerId_fkey" FOREIGN KEY ("workerId") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."worker_services"
    ADD CONSTRAINT "worker_services_workerId_fkey" FOREIGN KEY ("workerId") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."workers"
    ADD CONSTRAINT "workers_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



CREATE POLICY "abuse_admin_select" ON "public"."abuse_events" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "abuse_admin_update" ON "public"."abuse_events" FOR UPDATE USING ("public"."is_admin"());



CREATE POLICY "abuse_all" ON "public"."abuse_events" TO "authenticated" USING (("userId" = "auth"."uid"())) WITH CHECK (("userId" = "auth"."uid"()));



ALTER TABLE "public"."abuse_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."analytics_events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "analytics_insert" ON "public"."analytics_events" FOR INSERT TO "authenticated" WITH CHECK ((("userId" = "auth"."uid"()) OR ("userId" IS NULL)));



CREATE POLICY "analytics_select" ON "public"."analytics_events" FOR SELECT TO "authenticated" USING (("userId" = "auth"."uid"()));



ALTER TABLE "public"."app_error_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "app_error_logs_admin_select" ON "public"."app_error_logs" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "app_error_logs_admin_update" ON "public"."app_error_logs" FOR UPDATE USING ("public"."is_admin"());



CREATE POLICY "app_error_logs_insert" ON "public"."app_error_logs" FOR INSERT TO "authenticated" WITH CHECK ((("userId" IS NULL) OR ("userId" = "auth"."uid"())));



CREATE POLICY "blocks_all" ON "public"."user_blocks" TO "authenticated" USING (("blockerId" = "auth"."uid"())) WITH CHECK (("blockerId" = "auth"."uid"()));



ALTER TABLE "public"."boosts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "boosts_select" ON "public"."boosts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "boosts_write" ON "public"."boosts" TO "authenticated" USING (("workerId" = "auth"."uid"())) WITH CHECK (("workerId" = "auth"."uid"()));



ALTER TABLE "public"."change_orders" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "co_all" ON "public"."change_orders" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "change_orders"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"())))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "change_orders"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"()))))));



CREATE POLICY "consents_all" ON "public"."user_consents" TO "authenticated" USING (("userId" = "auth"."uid"())) WITH CHECK (("userId" = "auth"."uid"()));



ALTER TABLE "public"."disputes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "disputes_admin_select" ON "public"."disputes" FOR SELECT TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "disputes_admin_update" ON "public"."disputes" FOR UPDATE TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "disputes_all" ON "public"."disputes" TO "authenticated" USING ((("openedBy" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "disputes"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"()))))))) WITH CHECK ((("openedBy" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "disputes"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"())))))));



ALTER TABLE "public"."feature_flags" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "ff_admin_delete" ON "public"."feature_flags" FOR DELETE USING ("public"."is_admin"());



CREATE POLICY "ff_admin_insert" ON "public"."feature_flags" FOR INSERT WITH CHECK ("public"."is_admin"());



CREATE POLICY "ff_admin_update" ON "public"."feature_flags" FOR UPDATE USING ("public"."is_admin"());



CREATE POLICY "ff_select" ON "public"."feature_flags" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "jc_all" ON "public"."job_cancellations" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "job_cancellations"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"())))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "job_cancellations"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"()))))));



ALTER TABLE "public"."job_cancellations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "job_cancellations_admin_select" ON "public"."job_cancellations" FOR SELECT USING ("public"."is_admin"());



ALTER TABLE "public"."job_photos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."jobs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "jobs_admin_select" ON "public"."jobs" FOR SELECT TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "jobs_admin_update" ON "public"."jobs" FOR UPDATE USING ("public"."is_admin"());



CREATE POLICY "jobs_delete" ON "public"."jobs" FOR DELETE TO "authenticated" USING (("userId" = "auth"."uid"()));



CREATE POLICY "jobs_insert" ON "public"."jobs" FOR INSERT TO "authenticated" WITH CHECK (("userId" = "auth"."uid"()));



CREATE POLICY "jobs_select" ON "public"."jobs" FOR SELECT TO "authenticated" USING ((("userId" = "auth"."uid"()) OR ("workerId" = "auth"."uid"())));



CREATE POLICY "jobs_select_completed_for_profiles" ON "public"."jobs" FOR SELECT TO "authenticated" USING ((("status" = 'completed'::"text") AND ("workerId" IS NOT NULL)));



CREATE POLICY "jobs_update" ON "public"."jobs" FOR UPDATE TO "authenticated" USING ((("userId" = "auth"."uid"()) OR ("workerId" = "auth"."uid"()))) WITH CHECK ((("userId" = "auth"."uid"()) OR ("workerId" = "auth"."uid"())));



CREATE POLICY "jp_all" ON "public"."job_photos" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "job_photos"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"())))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "job_photos"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"()))))));



ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "messages_admin_select" ON "public"."messages" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "msg_insert" ON "public"."messages" FOR INSERT TO "authenticated" WITH CHECK (("senderId" = "auth"."uid"()));



CREATE POLICY "msg_select" ON "public"."messages" FOR SELECT TO "authenticated" USING ((("senderId" = "auth"."uid"()) OR ("receiverId" = "auth"."uid"())));



CREATE POLICY "msg_update" ON "public"."messages" FOR UPDATE TO "authenticated" USING ((("senderId" = "auth"."uid"()) OR ("receiverId" = "auth"."uid"()))) WITH CHECK ((("senderId" = "auth"."uid"()) OR ("receiverId" = "auth"."uid"())));



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notifications_admin_select" ON "public"."notifications" FOR SELECT TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "notifications_delete_own" ON "public"."notifications" FOR DELETE TO "authenticated" USING (("userId" = "auth"."uid"()));



CREATE POLICY "notifications_insert_participants" ON "public"."notifications" FOR INSERT TO "authenticated" WITH CHECK ((("auth"."uid"() IS NOT NULL) AND (("userId" = "auth"."uid"()) OR (("relatedId" IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "notifications"."relatedId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"())))))))));



CREATE POLICY "notifications_select_own" ON "public"."notifications" FOR SELECT TO "authenticated" USING (("userId" = "auth"."uid"()));



CREATE POLICY "notifications_update_own" ON "public"."notifications" FOR UPDATE TO "authenticated" USING (("userId" = "auth"."uid"())) WITH CHECK (("userId" = "auth"."uid"()));



ALTER TABLE "public"."password_reset_codes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."payments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "payments_admin_select" ON "public"."payments" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "payments_insert" ON "public"."payments" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "payments"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"()))))));



CREATE POLICY "payments_select" ON "public"."payments" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "payments"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"()))))));



CREATE POLICY "payments_update" ON "public"."payments" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "payments"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"())))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "payments"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"()))))));



ALTER TABLE "public"."pending_actions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "pending_admin_select" ON "public"."pending_actions" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "pending_all" ON "public"."pending_actions" TO "authenticated" USING (("userId" = "auth"."uid"())) WITH CHECK (("userId" = "auth"."uid"()));



CREATE POLICY "portfolio_select" ON "public"."worker_portfolio" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "portfolio_write" ON "public"."worker_portfolio" TO "authenticated" USING (("workerId" = "auth"."uid"())) WITH CHECK (("workerId" = "auth"."uid"()));



CREATE POLICY "prc_all" ON "public"."password_reset_codes" TO "authenticated" USING (("userId" = "auth"."uid"())) WITH CHECK (("userId" = "auth"."uid"()));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_admin_select" ON "public"."profiles" FOR SELECT TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "profiles_admin_update" ON "public"."profiles" FOR UPDATE TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "profiles_insert" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "profiles_select" ON "public"."profiles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "profiles_select_anon_workers" ON "public"."profiles" FOR SELECT TO "anon" USING (("role" = 'worker'::"text"));



CREATE POLICY "profiles_update" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



ALTER TABLE "public"."quote_proposals" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "quotes_insert" ON "public"."quote_proposals" FOR INSERT TO "authenticated" WITH CHECK (("workerId" = "auth"."uid"()));



CREATE POLICY "quotes_select" ON "public"."quote_proposals" FOR SELECT TO "authenticated" USING ((("workerId" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "quote_proposals"."jobId") AND ("j"."userId" = "auth"."uid"()))))));



CREATE POLICY "quotes_update" ON "public"."quote_proposals" FOR UPDATE TO "authenticated" USING ((("workerId" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "quote_proposals"."jobId") AND ("j"."userId" = "auth"."uid"())))))) WITH CHECK ((("workerId" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "quote_proposals"."jobId") AND ("j"."userId" = "auth"."uid"()))))));



ALTER TABLE "public"."ratings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "ratings_insert" ON "public"."ratings" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."jobs" "j"
  WHERE (("j"."id" = "ratings"."jobId") AND (("j"."userId" = "auth"."uid"()) OR ("j"."workerId" = "auth"."uid"()))))));



CREATE POLICY "ratings_select" ON "public"."ratings" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."reports" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "reports_admin_select" ON "public"."reports" FOR SELECT TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "reports_admin_update" ON "public"."reports" FOR UPDATE USING ("public"."is_admin"());



CREATE POLICY "reports_insert" ON "public"."reports" FOR INSERT TO "authenticated" WITH CHECK (("reporterId" = "auth"."uid"()));



CREATE POLICY "reports_select" ON "public"."reports" FOR SELECT TO "authenticated" USING (("reporterId" = "auth"."uid"()));



CREATE POLICY "sc_select" ON "public"."service_configs" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."service_configs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."services" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "services_admin_update" ON "public"."services" FOR UPDATE USING ("public"."is_admin"());



CREATE POLICY "services_select" ON "public"."services" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "subs_all" ON "public"."subscriptions" TO "authenticated" USING (("userId" = "auth"."uid"())) WITH CHECK (("userId" = "auth"."uid"()));



ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tickets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_blocks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_consents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."worker_portfolio" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."worker_services" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."workers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "workers_admin_update" ON "public"."workers" FOR UPDATE USING ("public"."is_admin"());



CREATE POLICY "workers_delete" ON "public"."workers" FOR DELETE TO "authenticated" USING (("userId" = "auth"."uid"()));



CREATE POLICY "workers_insert" ON "public"."workers" FOR INSERT TO "authenticated" WITH CHECK (("userId" = "auth"."uid"()));



CREATE POLICY "workers_select" ON "public"."workers" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "workers_select_anon" ON "public"."workers" FOR SELECT TO "anon" USING (true);



CREATE POLICY "workers_update" ON "public"."workers" FOR UPDATE TO "authenticated" USING (("userId" = "auth"."uid"())) WITH CHECK (("userId" = "auth"."uid"()));



CREATE POLICY "ws_select" ON "public"."worker_services" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "ws_write" ON "public"."worker_services" TO "authenticated" USING (("workerId" = "auth"."uid"())) WITH CHECK (("workerId" = "auth"."uid"()));



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



REVOKE ALL ON FUNCTION "public"."handle_new_user"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_admin"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";



REVOKE ALL ON FUNCTION "public"."protect_profile_sensitive_fields"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."protect_profile_sensitive_fields"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."rls_auto_enable"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON TABLE "public"."abuse_events" TO "anon";
GRANT ALL ON TABLE "public"."abuse_events" TO "authenticated";
GRANT ALL ON TABLE "public"."abuse_events" TO "service_role";



GRANT ALL ON TABLE "public"."analytics_events" TO "anon";
GRANT ALL ON TABLE "public"."analytics_events" TO "authenticated";
GRANT ALL ON TABLE "public"."analytics_events" TO "service_role";



GRANT ALL ON TABLE "public"."app_error_logs" TO "anon";
GRANT ALL ON TABLE "public"."app_error_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."app_error_logs" TO "service_role";



GRANT ALL ON TABLE "public"."boosts" TO "anon";
GRANT ALL ON TABLE "public"."boosts" TO "authenticated";
GRANT ALL ON TABLE "public"."boosts" TO "service_role";



GRANT ALL ON TABLE "public"."change_orders" TO "anon";
GRANT ALL ON TABLE "public"."change_orders" TO "authenticated";
GRANT ALL ON TABLE "public"."change_orders" TO "service_role";



GRANT ALL ON TABLE "public"."disputes" TO "anon";
GRANT ALL ON TABLE "public"."disputes" TO "authenticated";
GRANT ALL ON TABLE "public"."disputes" TO "service_role";



GRANT ALL ON TABLE "public"."feature_flags" TO "anon";
GRANT ALL ON TABLE "public"."feature_flags" TO "authenticated";
GRANT ALL ON TABLE "public"."feature_flags" TO "service_role";



GRANT ALL ON TABLE "public"."job_cancellations" TO "anon";
GRANT ALL ON TABLE "public"."job_cancellations" TO "authenticated";
GRANT ALL ON TABLE "public"."job_cancellations" TO "service_role";



GRANT ALL ON TABLE "public"."job_photos" TO "anon";
GRANT ALL ON TABLE "public"."job_photos" TO "authenticated";
GRANT ALL ON TABLE "public"."job_photos" TO "service_role";



GRANT ALL ON TABLE "public"."jobs" TO "anon";
GRANT ALL ON TABLE "public"."jobs" TO "authenticated";
GRANT ALL ON TABLE "public"."jobs" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."password_reset_codes" TO "anon";
GRANT ALL ON TABLE "public"."password_reset_codes" TO "authenticated";
GRANT ALL ON TABLE "public"."password_reset_codes" TO "service_role";



GRANT ALL ON TABLE "public"."payments" TO "anon";
GRANT ALL ON TABLE "public"."payments" TO "authenticated";
GRANT ALL ON TABLE "public"."payments" TO "service_role";



GRANT ALL ON TABLE "public"."pending_actions" TO "anon";
GRANT ALL ON TABLE "public"."pending_actions" TO "authenticated";
GRANT ALL ON TABLE "public"."pending_actions" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."quote_proposals" TO "anon";
GRANT ALL ON TABLE "public"."quote_proposals" TO "authenticated";
GRANT ALL ON TABLE "public"."quote_proposals" TO "service_role";



GRANT ALL ON TABLE "public"."ratings" TO "anon";
GRANT ALL ON TABLE "public"."ratings" TO "authenticated";
GRANT ALL ON TABLE "public"."ratings" TO "service_role";



GRANT ALL ON TABLE "public"."reports" TO "anon";
GRANT ALL ON TABLE "public"."reports" TO "authenticated";
GRANT ALL ON TABLE "public"."reports" TO "service_role";



GRANT ALL ON TABLE "public"."service_configs" TO "anon";
GRANT ALL ON TABLE "public"."service_configs" TO "authenticated";
GRANT ALL ON TABLE "public"."service_configs" TO "service_role";



GRANT ALL ON TABLE "public"."services" TO "anon";
GRANT ALL ON TABLE "public"."services" TO "authenticated";
GRANT ALL ON TABLE "public"."services" TO "service_role";



GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";



GRANT ALL ON TABLE "public"."tickets" TO "anon";
GRANT ALL ON TABLE "public"."tickets" TO "authenticated";
GRANT ALL ON TABLE "public"."tickets" TO "service_role";



GRANT ALL ON TABLE "public"."user_blocks" TO "anon";
GRANT ALL ON TABLE "public"."user_blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."user_blocks" TO "service_role";



GRANT ALL ON TABLE "public"."user_consents" TO "anon";
GRANT ALL ON TABLE "public"."user_consents" TO "authenticated";
GRANT ALL ON TABLE "public"."user_consents" TO "service_role";



GRANT ALL ON TABLE "public"."worker_portfolio" TO "anon";
GRANT ALL ON TABLE "public"."worker_portfolio" TO "authenticated";
GRANT ALL ON TABLE "public"."worker_portfolio" TO "service_role";



GRANT ALL ON TABLE "public"."worker_services" TO "anon";
GRANT ALL ON TABLE "public"."worker_services" TO "authenticated";
GRANT ALL ON TABLE "public"."worker_services" TO "service_role";



GRANT ALL ON TABLE "public"."workers" TO "anon";
GRANT ALL ON TABLE "public"."workers" TO "authenticated";
GRANT ALL ON TABLE "public"."workers" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";








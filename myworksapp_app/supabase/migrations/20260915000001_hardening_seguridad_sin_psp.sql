-- =============================================================================
-- Hardening seguridad (sin PSP real)
-- Sprint 7: limpia políticas EN legacy, endurece pagos/mensajes/trabajos,
-- mock escrow vía RPC, abuso self-report. Empresa aún sin gateway real.
-- Idempotente. Aplicar tras 20260914000005 / 000006.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) Drop políticas legacy EN (y nombres cortos del dump) si aún existen
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND (
        policyname ~* '^(profiles_|jobs_|payments_|msg_|messages_|notifications_|workers_|services_|ratings_|reports_|disputes_|quotes_|jp_all|jc_all|co_all|prc_all|pending_|blocks_|consents_|boosts_|portfolio_|ws_|sc_select|ff_|abuse_|analytics_|app_error_logs_|subs_all)'
        OR policyname IN (
          'profiles_select','profiles_update','profiles_insert',
          'profiles_admin_select','profiles_admin_update','profiles_select_anon_workers',
          'jobs_select','jobs_insert','jobs_update','jobs_delete',
          'jobs_admin_select','jobs_admin_update','jobs_select_completed_for_profiles',
          'payments_select','payments_insert','payments_update','payments_admin_select',
          'msg_select','msg_insert','msg_update','messages_admin_select',
          'notifications_select_own','notifications_update_own','notifications_delete_own',
          'notifications_insert_participants','notifications_admin_select',
          'workers_select','workers_insert','workers_update','workers_delete',
          'workers_select_anon','workers_admin_update',
          'services_select','services_admin_update',
          'ratings_select','ratings_insert',
          'reports_select','reports_insert','reports_admin_select','reports_admin_update',
          'disputes_all','disputes_admin_select','disputes_admin_update',
          'quotes_select','quotes_insert','quotes_update',
          'jp_all','jc_all','co_all','prc_all',
          'pending_all','pending_admin_select',
          'blocks_all','consents_all',
          'boosts_select','boosts_write',
          'portfolio_select','portfolio_write',
          'ws_select','ws_write','sc_select',
          'ff_select','ff_admin_insert','ff_admin_update','ff_admin_delete',
          'abuse_all','abuse_admin_select','abuse_admin_update',
          'analytics_insert','analytics_select',
          'app_error_logs_insert','app_error_logs_admin_select','app_error_logs_admin_update',
          'subs_all','job_cancellations_admin_select'
        )
      )
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I.%I',
      r.policyname, r.schemaname, r.tablename
    );
  END LOOP;
END $$;

-- Drops explícitos por si tablas EN y ES coexisten temporalmente
DO $$
DECLARE
  pname text;
  t_en text;
  t_es text;
  i int;
  legacy_names text[] := ARRAY[
    'profiles_select','profiles_update','profiles_insert',
    'profiles_admin_select','profiles_admin_update','profiles_select_anon_workers',
    'jobs_select','jobs_insert','jobs_update','jobs_delete',
    'jobs_admin_select','jobs_admin_update','jobs_select_completed_for_profiles',
    'payments_select','payments_insert','payments_update','payments_admin_select',
    'msg_select','msg_insert','msg_update','messages_admin_select',
    'notifications_select_own','notifications_update_own','notifications_delete_own',
    'notifications_insert_participants','notifications_admin_select',
    'workers_select','workers_insert','workers_update','workers_delete',
    'workers_select_anon','workers_admin_update',
    'services_select','services_admin_update',
    'ratings_select','ratings_insert',
    'reports_select','reports_insert','reports_admin_select','reports_admin_update',
    'disputes_all','disputes_admin_select','disputes_admin_update',
    'quotes_select','quotes_insert','quotes_update',
    'jp_all','jc_all','co_all','prc_all',
    'pending_all','pending_admin_select','blocks_all','consents_all',
    'boosts_select','boosts_write','portfolio_select','portfolio_write',
    'ws_select','ws_write','sc_select',
    'ff_select','ff_admin_insert','ff_admin_update','ff_admin_delete',
    'abuse_all','abuse_admin_select','abuse_admin_update',
    'analytics_insert','analytics_select',
    'app_error_logs_insert','app_error_logs_admin_select','app_error_logs_admin_update',
    'subs_all','job_cancellations_admin_select'
  ];
  table_pairs text[][] := ARRAY[
    ARRAY['profiles','perfiles'],
    ARRAY['jobs','trabajos'],
    ARRAY['payments','pagos'],
    ARRAY['messages','mensajes'],
    ARRAY['notifications','notificaciones'],
    ARRAY['workers','trabajadores'],
    ARRAY['services','servicios'],
    ARRAY['ratings','calificaciones'],
    ARRAY['reports','reportes'],
    ARRAY['disputes','disputas'],
    ARRAY['quote_proposals','propuestas_cotizacion'],
    ARRAY['job_photos','fotos_trabajo'],
    ARRAY['job_cancellations','cancelaciones_trabajo'],
    ARRAY['change_orders','ordenes_cambio'],
    ARRAY['pending_actions','acciones_pendientes'],
    ARRAY['user_blocks','bloqueos_usuario'],
    ARRAY['user_consents','consentimientos_usuario'],
    ARRAY['boosts','impulsos'],
    ARRAY['worker_portfolio','portafolio_trabajador'],
    ARRAY['worker_services','trabajador_servicios'],
    ARRAY['service_configs','configuraciones_servicio'],
    ARRAY['feature_flags','banderas_funcionalidad'],
    ARRAY['abuse_events','eventos_abuso'],
    ARRAY['analytics_events','eventos_analitica'],
    ARRAY['app_error_logs','registros_error_app'],
    ARRAY['subscriptions','suscripciones'],
    ARRAY['password_reset_codes','codigos_restablecimiento']
  ];
BEGIN
  FOREACH pname IN ARRAY legacy_names
  LOOP
    FOR i IN 1 .. array_length(table_pairs, 1)
    LOOP
      t_en := table_pairs[i][1];
      t_es := table_pairs[i][2];
      IF to_regclass('public.' || t_en) IS NOT NULL THEN
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pname, t_en);
      END IF;
      IF to_regclass('public.' || t_es) IS NOT NULL THEN
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pname, t_es);
      END IF;
    END LOOP;
  END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- 2) Grants: anon solo marketplace de lectura
-- -----------------------------------------------------------------------------
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;

DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'servicios','trabajadores','portafolio_trabajador',
    'trabajador_servicios','banderas_funcionalidad'
  ]
  LOOP
    IF to_regclass('public.' || t) IS NOT NULL THEN
      EXECUTE format('GRANT SELECT ON TABLE public.%I TO anon', t);
    END IF;
  END LOOP;
END $$;

-- authenticated: quitar UPDATE/DELETE directo en pagos y UPDATE en trabajos
-- (transiciones vía RPC SECURITY DEFINER)
DO $$
BEGIN
  IF to_regclass('public.pagos') IS NOT NULL THEN
    REVOKE ALL ON TABLE public.pagos FROM authenticated;
    GRANT SELECT, INSERT ON TABLE public.pagos TO authenticated;
  END IF;
  IF to_regclass('public.trabajos') IS NOT NULL THEN
    REVOKE UPDATE, DELETE ON TABLE public.trabajos FROM authenticated;
    GRANT SELECT, INSERT ON TABLE public.trabajos TO authenticated;
  END IF;
  IF to_regclass('public.mensajes') IS NOT NULL THEN
    GRANT SELECT, INSERT, UPDATE ON TABLE public.mensajes TO authenticated;
  END IF;
  IF to_regclass('public.eventos_abuso') IS NOT NULL THEN
    GRANT SELECT, INSERT ON TABLE public.eventos_abuso TO authenticated;
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 3) pagos: sin UPDATE/DELETE directo; solo SELECT + INSERT pendiente
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS pagos_all ON public.pagos;
DROP POLICY IF EXISTS pagos_select ON public.pagos;
DROP POLICY IF EXISTS pagos_insert ON public.pagos;
DROP POLICY IF EXISTS pagos_update ON public.pagos;
DROP POLICY IF EXISTS pagos_delete ON public.pagos;

CREATE POLICY pagos_select ON public.pagos
  FOR SELECT TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

CREATE POLICY pagos_insert ON public.pagos
  FOR INSERT TO authenticated
  WITH CHECK (
    (
      public.es_parte_trabajo(id_trabajo::text)
      AND estado IN ('pendiente', 'ninguno')
    )
    OR public.is_admin()
  );

-- Sin políticas UPDATE/DELETE para authenticated: solo RPC / service role.

-- -----------------------------------------------------------------------------
-- 4) mensajes: SELECT partes; INSERT remitente=uid; UPDATE leído solo destinatario
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS mensajes_all ON public.mensajes;
DROP POLICY IF EXISTS mensajes_select ON public.mensajes;
DROP POLICY IF EXISTS mensajes_insert ON public.mensajes;
DROP POLICY IF EXISTS mensajes_update ON public.mensajes;

CREATE POLICY mensajes_select ON public.mensajes
  FOR SELECT TO authenticated
  USING (
    id_remitente::text = auth.uid()::text
    OR id_destinatario::text = auth.uid()::text
    OR public.es_parte_trabajo(id_trabajo::text)
    OR public.is_admin()
  );

CREATE POLICY mensajes_insert ON public.mensajes
  FOR INSERT TO authenticated
  WITH CHECK (
    id_remitente::text = auth.uid()::text
    AND (
      public.es_parte_trabajo(id_trabajo::text)
      OR public.is_admin()
    )
  );

CREATE POLICY mensajes_update ON public.mensajes
  FOR UPDATE TO authenticated
  USING (
    id_destinatario::text = auth.uid()::text
    OR public.is_admin()
  )
  WITH CHECK (
    id_destinatario::text = auth.uid()::text
    OR public.is_admin()
  );

-- -----------------------------------------------------------------------------
-- 5) trabajos: quitar UPDATE amplio de partes; admin sí; INSERT/SELECT intactos
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS trabajos_update ON public.trabajos;
DROP POLICY IF EXISTS trabajos_admin_update ON public.trabajos;

CREATE POLICY trabajos_admin_update ON public.trabajos
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- -----------------------------------------------------------------------------
-- Helper: ¿transición de trabajo permitida? (matriz ES unificada / práctica)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.transicion_trabajo_permitida(
  p_desde text,
  p_hacia text,
  p_modalidad text DEFAULT 'legado'
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $$
DECLARE
  v_mode text := COALESCE(NULLIF(trim(p_modalidad), ''), 'legado');
BEGIN
  IF p_desde IS NULL OR p_hacia IS NULL THEN
    RETURN false;
  END IF;
  IF p_desde = p_hacia THEN
    RETURN false;
  END IF;

  -- Terminales
  IF p_desde IN ('completado', 'cancelado', 'expirado', 'no_asistio') THEN
    RETURN false;
  END IF;

  -- Cancelar desde la mayoría de estados activos
  IF p_hacia = 'cancelado' AND p_desde NOT IN ('completado', 'cancelado') THEN
    RETURN true;
  END IF;

  CASE v_mode
    WHEN 'precio_fijo', 'bloque_horas' THEN
      RETURN (p_desde, p_hacia) IN (
        ('esperando_pago', 'aceptado'),
        ('aceptado', 'en_curso'),
        ('en_curso', 'completado'),
        ('en_curso', 'no_asistio'),
        ('en_curso', 'pausado_orden_cambio'),
        ('pausado_orden_cambio', 'en_curso')
      );
    WHEN 'cotizacion_abierta' THEN
      RETURN (p_desde, p_hacia) IN (
        ('esperando_cotizaciones', 'cotizacion_seleccionada'),
        ('esperando_cotizaciones', 'expirado'),
        ('cotizacion_seleccionada', 'esperando_pago'),
        ('esperando_pago', 'aceptado'),
        ('aceptado', 'en_curso'),
        ('en_curso', 'completado'),
        ('en_curso', 'no_asistio'),
        ('en_curso', 'pausado_orden_cambio'),
        ('pausado_orden_cambio', 'en_curso')
      );
    ELSE -- legado
      RETURN (p_desde, p_hacia) IN (
        ('pendiente', 'aceptado'),
        ('pendiente', 'expirado'),
        ('aceptado', 'en_curso'),
        ('aceptado', 'pendiente'),
        ('en_curso', 'completado'),
        ('en_curso', 'esperando_aprobacion_cliente'),
        ('en_curso', 'no_asistio'),
        ('en_curso', 'pausado_orden_cambio'),
        ('esperando_aprobacion_cliente', 'completado'),
        ('esperando_aprobacion_cliente', 'en_curso'),
        ('pausado_orden_cambio', 'en_curso')
      );
  END CASE;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6) RPC transicionar_trabajo
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.transicionar_trabajo(
  p_trabajo_id text,
  p_nuevo_estado text,
  p_pin text DEFAULT NULL
)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
  v_expected_pin text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row
  FROM public.trabajos
  WHERE id::text = p_trabajo_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;

  IF NOT (
    public.is_admin()
    OR v_row.id_usuario::text = auth.uid()::text
    OR v_row.id_trabajador::text = auth.uid()::text
  ) THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;

  IF NOT public.is_admin() THEN
    IF NOT public.transicion_trabajo_permitida(
      v_row.estado,
      p_nuevo_estado,
      COALESCE(v_row.modalidad_cobro, 'legado')
    ) THEN
      RAISE EXCEPTION 'transicion no permitida: % -> %', v_row.estado, p_nuevo_estado;
    END IF;
  END IF;

  -- PIN opcional: si se envía, debe coincidir con pin en metadatos_servicio
  IF p_pin IS NOT NULL AND length(trim(p_pin)) > 0 THEN
    BEGIN
      v_expected_pin := NULLIF(trim(v_row.metadatos_servicio::jsonb ->> 'pin'), '');
    EXCEPTION WHEN others THEN
      v_expected_pin := NULL;
    END;
    IF v_expected_pin IS NULL OR v_expected_pin = '' THEN
      RAISE EXCEPTION 'pin requerido pero no configurado en el trabajo';
    END IF;
    IF p_pin <> v_expected_pin THEN
      RAISE EXCEPTION 'pin incorrecto';
    END IF;
  END IF;

  UPDATE public.trabajos
  SET
    estado = p_nuevo_estado,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

COMMENT ON FUNCTION public.transicionar_trabajo(text, text, text) IS
  'Transición de estado de trabajo validada (matriz ES). Partes vía RPC; sin UPDATE directo RLS.';

GRANT EXECUTE ON FUNCTION public.transicionar_trabajo(text, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.transicionar_trabajo(text, text, text) FROM anon;

-- -----------------------------------------------------------------------------
-- 7) RPC simular_transicion_pago (mock escrow hasta PSP real)
-- Real Webpay/MP reemplazará esta función; NO integrar PSP aún.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.simular_transicion_pago(
  p_pago_id text,
  p_nuevo_estado text
)
RETURNS public.pagos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.pagos;
  v_ok boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id::text = p_pago_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'pago no encontrado';
  END IF;

  IF NOT (public.es_parte_trabajo(v_row.id_trabajo::text) OR public.is_admin()) THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;

  -- Matriz mock: pendiente→autorizado→retenido→liberado | reembolsado desde pendiente/autorizado/retenido
  IF public.is_admin() THEN
    v_ok := true;
  ELSIF v_row.estado = 'pendiente' AND p_nuevo_estado IN ('autorizado', 'reembolsado') THEN
    v_ok := true;
  ELSIF v_row.estado = 'autorizado' AND p_nuevo_estado IN ('retenido', 'liberado', 'reembolsado') THEN
    v_ok := true;
  ELSIF v_row.estado = 'retenido' AND p_nuevo_estado IN ('liberado', 'reembolsado') THEN
    v_ok := true;
  END IF;

  IF NOT v_ok THEN
    RAISE EXCEPTION 'transicion de pago no permitida: % -> %', v_row.estado, p_nuevo_estado;
  END IF;

  UPDATE public.pagos
  SET
    estado = p_nuevo_estado,
    autorizado_en = CASE
      WHEN p_nuevo_estado = 'autorizado' THEN to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
      ELSE autorizado_en
    END,
    liberado_en = CASE
      WHEN p_nuevo_estado = 'liberado' THEN to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
      ELSE liberado_en
    END,
    reembolsado_en = CASE
      WHEN p_nuevo_estado = 'reembolsado' THEN to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
      ELSE reembolsado_en
    END,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_pago_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

COMMENT ON FUNCTION public.simular_transicion_pago(text, text) IS
  'MOCK escrow: transiciones de pago en servidor hasta integrar PSP real (Webpay/MP). No es cobro real.';

GRANT EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) FROM anon;

-- -----------------------------------------------------------------------------
-- 8) eventos_abuso: self-report + RPC
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS eventos_abuso_all ON public.eventos_abuso;
DROP POLICY IF EXISTS eventos_abuso_select ON public.eventos_abuso;
DROP POLICY IF EXISTS eventos_abuso_insert ON public.eventos_abuso;
DROP POLICY IF EXISTS eventos_abuso_update ON public.eventos_abuso;

CREATE POLICY eventos_abuso_select ON public.eventos_abuso
  FOR SELECT TO authenticated
  USING (id_usuario::text = auth.uid()::text OR public.is_admin());

CREATE POLICY eventos_abuso_insert ON public.eventos_abuso
  FOR INSERT TO authenticated
  WITH CHECK (id_usuario::text = auth.uid()::text OR public.is_admin());

CREATE POLICY eventos_abuso_update ON public.eventos_abuso
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE OR REPLACE FUNCTION public.registrar_evento_abuso(
  p_id text,
  p_tipo_abuso text,
  p_conteo integer DEFAULT 1,
  p_accion_tomada text DEFAULT NULL
)
RETURNS public.eventos_abuso
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.eventos_abuso;
  v_id text := COALESCE(NULLIF(trim(p_id), ''), gen_random_uuid()::text);
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF p_tipo_abuso IS NULL OR length(trim(p_tipo_abuso)) = 0 THEN
    RAISE EXCEPTION 'tipo_abuso requerido';
  END IF;

  INSERT INTO public.eventos_abuso (
    id, id_usuario, tipo_abuso, conteo, detectado_en, accion_tomada, resuelto
  ) VALUES (
    v_id,
    auth.uid(),
    trim(p_tipo_abuso),
    COALESCE(p_conteo, 1),
    to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US'),
    p_accion_tomada,
    0
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

COMMENT ON FUNCTION public.registrar_evento_abuso(text, text, integer, text) IS
  'Inserta evento de abuso para el usuario autenticado (self).';

GRANT EXECUTE ON FUNCTION public.registrar_evento_abuso(text, text, integer, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.registrar_evento_abuso(text, text, integer, text) FROM anon;

-- -----------------------------------------------------------------------------
-- 9) Asignar / rechazar trabajo (sustituye UPDATE directo post-hardening)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.asignar_trabajador_trabajo(
  p_trabajo_id text,
  p_trabajador_id text
)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF p_trabajador_id IS NULL OR length(trim(p_trabajador_id)) = 0 THEN
    RAISE EXCEPTION 'trabajador requerido';
  END IF;
  IF NOT (public.is_admin() OR auth.uid()::text = p_trabajador_id) THEN
    RAISE EXCEPTION 'solo el trabajador asignado o admin puede aceptar';
  END IF;

  SELECT * INTO v_row FROM public.trabajos WHERE id::text = p_trabajo_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;
  IF v_row.estado NOT IN ('pendiente', 'esperando_pago', 'cotizacion_seleccionada') THEN
    RAISE EXCEPTION 'estado no permite asignacion: %', v_row.estado;
  END IF;
  IF v_row.id_trabajador IS NOT NULL
     AND v_row.id_trabajador::text <> p_trabajador_id
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'trabajo ya asignado a otro trabajador';
  END IF;

  UPDATE public.trabajos
  SET
    id_trabajador = p_trabajador_id,
    estado = 'aceptado',
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.asignar_trabajador_trabajo(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.asignar_trabajador_trabajo(text, text) FROM anon;

CREATE OR REPLACE FUNCTION public.rechazar_trabajo_pendiente(
  p_trabajo_id text,
  p_metadatos text DEFAULT NULL
)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row FROM public.trabajos WHERE id::text = p_trabajo_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;
  IF NOT (
    public.is_admin()
    OR v_row.id_trabajador::text = auth.uid()::text
  ) THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;
  IF v_row.estado <> 'pendiente' THEN
    RAISE EXCEPTION 'solo se rechazan trabajos pendientes';
  END IF;

  UPDATE public.trabajos
  SET
    estado = 'cancelado',
    metadatos_servicio = COALESCE(p_metadatos, metadatos_servicio),
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.rechazar_trabajo_pendiente(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.rechazar_trabajo_pendiente(text, text) FROM anon;

COMMIT;

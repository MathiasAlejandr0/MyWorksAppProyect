-- =============================================================================
-- RLS de negocio + RPC admin (SECURITY DEFINER)
-- Aplicar COMPLETO en Supabase SQL Editor tras el rename ES (migracion 04).
-- Idempotente: DROP POLICY IF EXISTS / CREATE OR REPLACE.
--
-- IMPORTANTE: el esquema mezcla uuid y text en IDs.
-- Todas las comparaciones usan ::text en AMBOS lados para evitar 42883.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.perfiles
    WHERE id::text = auth.uid()::text
      AND rol IN ('admin', 'administrador')
      AND estado_cuenta IN ('activo', 'active')
  );
$$;

DROP FUNCTION IF EXISTS public.es_parte_trabajo(uuid);
DROP FUNCTION IF EXISTS public.es_parte_trabajo(text);

CREATE OR REPLACE FUNCTION public.es_parte_trabajo(p_trabajo_id text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.trabajos t
    WHERE t.id::text = p_trabajo_id
      AND (
        t.id_usuario::text = auth.uid()::text
        OR t.id_trabajador::text = auth.uid()::text
      )
  ) OR public.is_admin();
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.es_parte_trabajo(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_admin() FROM anon;
REVOKE EXECUTE ON FUNCTION public.es_parte_trabajo(text) FROM anon;

-- -----------------------------------------------------------------------------
-- Enable RLS
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'perfiles','trabajadores','servicios','trabajos','pagos','mensajes','disputas',
    'notificaciones','calificaciones','reportes','propuestas_cotizacion','ordenes_cambio',
    'fotos_trabajo','portafolio_trabajador','trabajador_servicios','cancelaciones_trabajo',
    'registros_error_app','eventos_abuso','acciones_pendientes','bloqueos_usuario',
    'consentimientos_usuario','banderas_funcionalidad','suscripciones','impulsos',
    'eventos_analitica','configuraciones_servicio','codigos_restablecimiento','tickets_soporte'
  ]
  LOOP
    IF to_regclass('public.' || t) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    END IF;
  END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- perfiles
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS perfiles_select ON public.perfiles;
DROP POLICY IF EXISTS perfiles_update ON public.perfiles;
DROP POLICY IF EXISTS perfiles_insert ON public.perfiles;

CREATE POLICY perfiles_select ON public.perfiles
  FOR SELECT TO authenticated
  USING (id::text = auth.uid()::text OR public.is_admin());

CREATE POLICY perfiles_update ON public.perfiles
  FOR UPDATE TO authenticated
  USING (id::text = auth.uid()::text OR public.is_admin())
  WITH CHECK (id::text = auth.uid()::text OR public.is_admin());

CREATE POLICY perfiles_insert ON public.perfiles
  FOR INSERT TO authenticated
  WITH CHECK (id::text = auth.uid()::text OR public.is_admin());

-- -----------------------------------------------------------------------------
-- trabajadores
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS trabajadores_select ON public.trabajadores;
DROP POLICY IF EXISTS trabajadores_insert ON public.trabajadores;
DROP POLICY IF EXISTS trabajadores_update ON public.trabajadores;

CREATE POLICY trabajadores_select ON public.trabajadores
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY trabajadores_insert ON public.trabajadores
  FOR INSERT TO authenticated
  WITH CHECK (id_usuario::text = auth.uid()::text OR public.is_admin());

CREATE POLICY trabajadores_update ON public.trabajadores
  FOR UPDATE TO authenticated
  USING (id_usuario::text = auth.uid()::text OR public.is_admin())
  WITH CHECK (id_usuario::text = auth.uid()::text OR public.is_admin());

-- -----------------------------------------------------------------------------
-- servicios
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS servicios_select ON public.servicios;
DROP POLICY IF EXISTS servicios_write ON public.servicios;

CREATE POLICY servicios_select ON public.servicios
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY servicios_write ON public.servicios
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- -----------------------------------------------------------------------------
-- trabajos
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS trabajos_select ON public.trabajos;
DROP POLICY IF EXISTS trabajos_insert ON public.trabajos;
DROP POLICY IF EXISTS trabajos_update ON public.trabajos;

CREATE POLICY trabajos_select ON public.trabajos
  FOR SELECT TO authenticated
  USING (
    id_usuario::text = auth.uid()::text
    OR id_trabajador::text = auth.uid()::text
    OR public.is_admin()
    OR (
      id_trabajador IS NULL
      AND estado IN ('pendiente', 'esperando_cotizaciones', 'esperando_pago')
    )
  );

CREATE POLICY trabajos_insert ON public.trabajos
  FOR INSERT TO authenticated
  WITH CHECK (id_usuario::text = auth.uid()::text OR public.is_admin());

CREATE POLICY trabajos_update ON public.trabajos
  FOR UPDATE TO authenticated
  USING (
    id_usuario::text = auth.uid()::text
    OR id_trabajador::text = auth.uid()::text
    OR public.is_admin()
  )
  WITH CHECK (
    id_usuario::text = auth.uid()::text
    OR id_trabajador::text = auth.uid()::text
    OR public.is_admin()
  );

-- -----------------------------------------------------------------------------
-- pagos / mensajes / disputas / fotos / cancelaciones / cotizaciones / ordenes
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS pagos_all ON public.pagos;
CREATE POLICY pagos_all ON public.pagos
  FOR ALL TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin())
  WITH CHECK (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

DROP POLICY IF EXISTS mensajes_all ON public.mensajes;
CREATE POLICY mensajes_all ON public.mensajes
  FOR ALL TO authenticated
  USING (
    id_remitente::text = auth.uid()::text
    OR id_destinatario::text = auth.uid()::text
    OR public.es_parte_trabajo(id_trabajo::text)
    OR public.is_admin()
  )
  WITH CHECK (
    id_remitente::text = auth.uid()::text
    OR public.es_parte_trabajo(id_trabajo::text)
    OR public.is_admin()
  );

DROP POLICY IF EXISTS disputas_select ON public.disputas;
DROP POLICY IF EXISTS disputas_insert ON public.disputas;
DROP POLICY IF EXISTS disputas_update ON public.disputas;

CREATE POLICY disputas_select ON public.disputas
  FOR SELECT TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

CREATE POLICY disputas_insert ON public.disputas
  FOR INSERT TO authenticated
  WITH CHECK (
    abierta_por::text = auth.uid()::text
    AND public.es_parte_trabajo(id_trabajo::text)
  );

CREATE POLICY disputas_update ON public.disputas
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS fotos_trabajo_all ON public.fotos_trabajo;
CREATE POLICY fotos_trabajo_all ON public.fotos_trabajo
  FOR ALL TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin())
  WITH CHECK (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

DROP POLICY IF EXISTS cancelaciones_all ON public.cancelaciones_trabajo;
CREATE POLICY cancelaciones_all ON public.cancelaciones_trabajo
  FOR ALL TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin())
  WITH CHECK (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

DROP POLICY IF EXISTS propuestas_all ON public.propuestas_cotizacion;
CREATE POLICY propuestas_all ON public.propuestas_cotizacion
  FOR ALL TO authenticated
  USING (
    id_trabajador::text = auth.uid()::text
    OR public.es_parte_trabajo(id_trabajo::text)
    OR public.is_admin()
  )
  WITH CHECK (
    id_trabajador::text = auth.uid()::text OR public.is_admin()
  );

DROP POLICY IF EXISTS ordenes_cambio_all ON public.ordenes_cambio;
CREATE POLICY ordenes_cambio_all ON public.ordenes_cambio
  FOR ALL TO authenticated
  USING (
    id_trabajador::text = auth.uid()::text
    OR public.es_parte_trabajo(id_trabajo::text)
    OR public.is_admin()
  )
  WITH CHECK (
    id_trabajador::text = auth.uid()::text
    OR public.es_parte_trabajo(id_trabajo::text)
    OR public.is_admin()
  );

-- -----------------------------------------------------------------------------
-- notificaciones / calificaciones / reportes / portafolio / N:M
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS notificaciones_all ON public.notificaciones;
CREATE POLICY notificaciones_all ON public.notificaciones
  FOR ALL TO authenticated
  USING (id_usuario::text = auth.uid()::text OR public.is_admin())
  WITH CHECK (id_usuario::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS calificaciones_select ON public.calificaciones;
DROP POLICY IF EXISTS calificaciones_insert ON public.calificaciones;
CREATE POLICY calificaciones_select ON public.calificaciones
  FOR SELECT TO authenticated
  USING (true);
CREATE POLICY calificaciones_insert ON public.calificaciones
  FOR INSERT TO authenticated
  WITH CHECK (id_usuario::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS reportes_all ON public.reportes;
CREATE POLICY reportes_all ON public.reportes
  FOR ALL TO authenticated
  USING (
    id_reportante::text = auth.uid()::text
    OR public.is_admin()
  )
  WITH CHECK (id_reportante::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS portafolio_select ON public.portafolio_trabajador;
DROP POLICY IF EXISTS portafolio_write ON public.portafolio_trabajador;
CREATE POLICY portafolio_select ON public.portafolio_trabajador
  FOR SELECT TO authenticated USING (true);
CREATE POLICY portafolio_write ON public.portafolio_trabajador
  FOR ALL TO authenticated
  USING (id_trabajador::text = auth.uid()::text OR public.is_admin())
  WITH CHECK (id_trabajador::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS trabajador_servicios_select ON public.trabajador_servicios;
DROP POLICY IF EXISTS trabajador_servicios_write ON public.trabajador_servicios;
CREATE POLICY trabajador_servicios_select ON public.trabajador_servicios
  FOR SELECT TO authenticated USING (true);
CREATE POLICY trabajador_servicios_write ON public.trabajador_servicios
  FOR ALL TO authenticated
  USING (id_trabajador::text = auth.uid()::text OR public.is_admin())
  WITH CHECK (id_trabajador::text = auth.uid()::text OR public.is_admin());

-- -----------------------------------------------------------------------------
-- Operacion / telemetria
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS registros_error_app_insert ON public.registros_error_app;
DROP POLICY IF EXISTS app_error_logs_insert ON public.registros_error_app;
DROP POLICY IF EXISTS registros_error_app_select ON public.registros_error_app;

CREATE POLICY registros_error_app_insert ON public.registros_error_app
  FOR INSERT TO authenticated
  WITH CHECK (id_usuario IS NULL OR id_usuario::text = auth.uid()::text);

CREATE POLICY registros_error_app_select ON public.registros_error_app
  FOR SELECT TO authenticated
  USING (public.is_admin() OR id_usuario::text = auth.uid()::text);

DROP POLICY IF EXISTS eventos_abuso_all ON public.eventos_abuso;
CREATE POLICY eventos_abuso_all ON public.eventos_abuso
  FOR ALL TO authenticated
  USING (public.is_admin() OR id_usuario::text = auth.uid()::text)
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS acciones_pendientes_all ON public.acciones_pendientes;
CREATE POLICY acciones_pendientes_all ON public.acciones_pendientes
  FOR ALL TO authenticated
  USING (id_usuario::text = auth.uid()::text OR public.is_admin())
  WITH CHECK (id_usuario::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS bloqueos_all ON public.bloqueos_usuario;
CREATE POLICY bloqueos_all ON public.bloqueos_usuario
  FOR ALL TO authenticated
  USING (
    id_bloqueador::text = auth.uid()::text
    OR id_bloqueado::text = auth.uid()::text
    OR public.is_admin()
  )
  WITH CHECK (id_bloqueador::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS consentimientos_all ON public.consentimientos_usuario;
CREATE POLICY consentimientos_all ON public.consentimientos_usuario
  FOR ALL TO authenticated
  USING (id_usuario::text = auth.uid()::text OR public.is_admin())
  WITH CHECK (id_usuario::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS banderas_select ON public.banderas_funcionalidad;
DROP POLICY IF EXISTS banderas_write ON public.banderas_funcionalidad;
CREATE POLICY banderas_select ON public.banderas_funcionalidad
  FOR SELECT TO authenticated USING (true);
CREATE POLICY banderas_write ON public.banderas_funcionalidad
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS suscripciones_all ON public.suscripciones;
CREATE POLICY suscripciones_all ON public.suscripciones
  FOR ALL TO authenticated
  USING (id_usuario::text = auth.uid()::text OR public.is_admin())
  WITH CHECK (id_usuario::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS impulsos_select ON public.impulsos;
DROP POLICY IF EXISTS impulsos_write ON public.impulsos;
CREATE POLICY impulsos_select ON public.impulsos
  FOR SELECT TO authenticated USING (true);
CREATE POLICY impulsos_write ON public.impulsos
  FOR ALL TO authenticated
  USING (id_trabajador::text = auth.uid()::text OR public.is_admin())
  WITH CHECK (id_trabajador::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS analitica_insert ON public.eventos_analitica;
DROP POLICY IF EXISTS analitica_select ON public.eventos_analitica;
CREATE POLICY analitica_insert ON public.eventos_analitica
  FOR INSERT TO authenticated
  WITH CHECK (
    id_usuario IS NULL
    OR id_usuario::text = auth.uid()::text
    OR public.is_admin()
  );
CREATE POLICY analitica_select ON public.eventos_analitica
  FOR SELECT TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS config_servicio_select ON public.configuraciones_servicio;
DROP POLICY IF EXISTS config_servicio_write ON public.configuraciones_servicio;
CREATE POLICY config_servicio_select ON public.configuraciones_servicio
  FOR SELECT TO authenticated USING (true);
CREATE POLICY config_servicio_write ON public.configuraciones_servicio
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS codigos_reset_all ON public.codigos_restablecimiento;
CREATE POLICY codigos_reset_all ON public.codigos_restablecimiento
  FOR ALL TO authenticated
  USING (id_usuario::text = auth.uid()::text OR public.is_admin())
  WITH CHECK (id_usuario::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS tickets_soporte_all ON public.tickets_soporte;
CREATE POLICY tickets_soporte_all ON public.tickets_soporte
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- -----------------------------------------------------------------------------
-- RPC admin
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.admin_actualizar_estado_disputa(text, text, text);
DROP FUNCTION IF EXISTS public.admin_actualizar_estado_disputa(uuid, text, text);

CREATE OR REPLACE FUNCTION public.admin_actualizar_estado_disputa(
  p_id text,
  p_estado text,
  p_resolucion text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo administradores';
  END IF;
  UPDATE public.disputas
  SET
    estado = p_estado,
    resolucion = COALESCE(p_resolucion, resolucion),
    resuelta_por = CASE
      WHEN p_estado = 'resuelta' THEN auth.uid()
      ELSE resuelta_por
    END,
    resuelta_en = CASE
      WHEN p_estado = 'resuelta' THEN to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
      ELSE resuelta_en
    END,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_metricas_resumen()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  result json;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo administradores';
  END IF;

  SELECT json_build_object(
    'usuarios', (SELECT count(*) FROM public.perfiles),
    'trabajadores', (SELECT count(*) FROM public.trabajadores),
    'trabajos', (SELECT count(*) FROM public.trabajos),
    'disputas_abiertas', (SELECT count(*) FROM public.disputas WHERE estado = 'abierta'),
    'disputas_en_revision', (SELECT count(*) FROM public.disputas WHERE estado = 'en_revision'),
    'reportes_pendientes', (SELECT count(*) FROM public.reportes WHERE estado = 'pendiente'),
    'trabajos_activos', (
      SELECT count(*) FROM public.trabajos
      WHERE estado IN ('pendiente','aceptado','en_curso')
    ),
    'errores_nuevos', (SELECT count(*) FROM public.registros_error_app WHERE estado = 'nuevo'),
    'abusos_abiertos', (SELECT count(*) FROM public.eventos_abuso WHERE resuelto = 0),
    'sync_fallidos', (SELECT count(*) FROM public.acciones_pendientes WHERE estado = 'fallido')
  ) INTO result;

  RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_actualizar_estado_disputa(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_metricas_resumen() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_actualizar_estado_disputa(text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_metricas_resumen() FROM anon;

COMMIT;

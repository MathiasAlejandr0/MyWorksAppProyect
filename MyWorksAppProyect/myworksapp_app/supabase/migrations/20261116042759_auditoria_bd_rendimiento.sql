-- Auditoría de base de datos 2026-11-16 (3/5): rendimiento de RLS e índices.
--
-- Detalle y mediciones en docs/pruebas/rendimiento_base_datos.md.
--
--   R1. is_admin() comparaba p.id::text = auth.uid()::text: el cast a texto
--       impide usar la clave primaria de perfiles. Se compara uuid con uuid.
--   R2. 20 políticas comparaban columnas uuid como texto
--       ((col)::text = (SELECT auth.uid())::text), lo que anula los índices
--       sobre id_usuario / id_trabajador, y llamaban is_admin() por fila. Se
--       reescriben como col = (SELECT auth.uid()) y (SELECT is_admin()), que
--       Postgres evalúa una sola vez por consulta (InitPlan).
--   R3. Tablas con una política FOR ALL de escritura y otra FOR SELECT tenían
--       dos políticas permisivas para SELECT (el linter de Supabase lo marca:
--       ambas se evalúan en cada lectura). Se separa la escritura en
--       INSERT/UPDATE/DELETE para que cada operación tenga una sola política.
--   R4. Índices que faltaban para consultas reales de la app (ganancias del
--       profesional, reseñas de un profesional, chat de un trabajo, campana
--       de notificaciones) y tres índices duplicados o cubiertos por otro.

-- R1 ------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.perfiles p
    WHERE p.id = auth.uid()
      AND p.rol = 'administrador'
      AND p.estado_cuenta IN ('activo', 'active')
      AND (
        COALESCE(
          (SELECT c.valor FROM public.app_config c WHERE c.clave = 'admin_requiere_aal2'),
          '0'
        ) IS DISTINCT FROM '1'
        OR COALESCE(auth.jwt()->>'aal', '') = 'aal2'
      )
  );
$function$;

-- R2 ------------------------------------------------------------------------
ALTER POLICY acciones_pendientes_all ON public.acciones_pendientes
  USING (((id_usuario = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)))
  WITH CHECK (((id_usuario = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY bloqueos_all ON public.bloqueos_usuario
  USING (((id_bloqueador = ( SELECT auth.uid() AS uid)) OR (id_bloqueado = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)))
  WITH CHECK (((id_bloqueador = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY calificaciones_cliente_select ON public.calificaciones_cliente
  USING (((id_cliente = ( SELECT auth.uid() AS uid)) OR (id_trabajador = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY codigos_reset_all ON public.codigos_restablecimiento
  USING (((id_usuario = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)))
  WITH CHECK (((id_usuario = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY consentimientos_all ON public.consentimientos_usuario
  USING (((id_usuario = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)))
  WITH CHECK (((id_usuario = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY disputas_insert ON public.disputas
  WITH CHECK (((abierta_por = ( SELECT auth.uid() AS uid)) AND es_parte_trabajo(id_trabajo) AND (estado = 'abierta'::text) AND (resolucion IS NULL) AND (resuelta_por IS NULL)));
ALTER POLICY eventos_abuso_all ON public.eventos_abuso
  USING ((( SELECT is_admin() AS is_admin) OR (id_usuario = ( SELECT auth.uid() AS uid))))
  WITH CHECK (( SELECT is_admin() AS is_admin));
ALTER POLICY analitica_insert ON public.eventos_analitica
  WITH CHECK (((id_usuario IS NULL) OR (id_usuario = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY mensajes_insert ON public.mensajes
  WITH CHECK (((es_parte_trabajo(id_trabajo) OR ( SELECT is_admin() AS is_admin)) AND (id_remitente = ( SELECT auth.uid() AS uid))));
ALTER POLICY ordenes_cambio_all ON public.ordenes_cambio
  USING (((id_trabajador = ( SELECT auth.uid() AS uid)) OR es_parte_trabajo(id_trabajo) OR ( SELECT is_admin() AS is_admin)))
  WITH CHECK (((id_trabajador = ( SELECT auth.uid() AS uid)) OR es_parte_trabajo(id_trabajo) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY perfiles_insert ON public.perfiles
  WITH CHECK (((id = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY perfiles_update ON public.perfiles
  USING (((id = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)))
  WITH CHECK (((id = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY pines_inicio_select_cliente ON public.pines_inicio_trabajo
  USING ((( SELECT is_admin() AS is_admin) OR (EXISTS ( SELECT 1
   FROM trabajos t
  WHERE ((t.id = pines_inicio_trabajo.id_trabajo) AND (t.id_usuario = ( SELECT auth.uid() AS uid)))))));
ALTER POLICY registros_error_app_insert ON public.registros_error_app
  WITH CHECK (((id_usuario IS NULL) OR (id_usuario = ( SELECT auth.uid() AS uid))));
ALTER POLICY registros_error_app_select ON public.registros_error_app
  USING ((( SELECT is_admin() AS is_admin) OR (id_usuario = ( SELECT auth.uid() AS uid))));
ALTER POLICY reportes_all ON public.reportes
  USING (((id_reportante = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)))
  WITH CHECK (((id_reportante = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY trabajadores_insert ON public.trabajadores
  WITH CHECK (((id_usuario = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY trabajadores_update ON public.trabajadores
  USING (((id_usuario = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)))
  WITH CHECK (((id_usuario = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY trabajos_select ON public.trabajos
  USING (((id_usuario = ( SELECT auth.uid() AS uid)) OR (id_trabajador = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));
ALTER POLICY trabajos_update ON public.trabajos
  USING (((id_usuario = ( SELECT auth.uid() AS uid)) OR (id_trabajador = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)))
  WITH CHECK (((id_usuario = ( SELECT auth.uid() AS uid)) OR (id_trabajador = ( SELECT auth.uid() AS uid)) OR ( SELECT is_admin() AS is_admin)));

-- R3 ------------------------------------------------------------------------
DROP POLICY IF EXISTS banderas_write ON public.banderas_funcionalidad;
CREATE POLICY banderas_funcionalidad_admin_insert ON public.banderas_funcionalidad FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY banderas_funcionalidad_admin_update ON public.banderas_funcionalidad FOR UPDATE TO authenticated USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY banderas_funcionalidad_admin_delete ON public.banderas_funcionalidad FOR DELETE TO authenticated USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS comunas_admin_write ON public.comunas;
CREATE POLICY comunas_admin_insert ON public.comunas FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY comunas_admin_update ON public.comunas FOR UPDATE TO authenticated USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY comunas_admin_delete ON public.comunas FOR DELETE TO authenticated USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS config_servicio_write ON public.configuraciones_servicio;
CREATE POLICY configuraciones_servicio_admin_insert ON public.configuraciones_servicio FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY configuraciones_servicio_admin_update ON public.configuraciones_servicio FOR UPDATE TO authenticated USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY configuraciones_servicio_admin_delete ON public.configuraciones_servicio FOR DELETE TO authenticated USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS paises_admin_write ON public.paises;
CREATE POLICY paises_admin_insert ON public.paises FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY paises_admin_update ON public.paises FOR UPDATE TO authenticated USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY paises_admin_delete ON public.paises FOR DELETE TO authenticated USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS regiones_admin_write ON public.regiones;
CREATE POLICY regiones_admin_insert ON public.regiones FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY regiones_admin_update ON public.regiones FOR UPDATE TO authenticated USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY regiones_admin_delete ON public.regiones FOR DELETE TO authenticated USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS servicios_write ON public.servicios;
CREATE POLICY servicios_admin_insert ON public.servicios FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY servicios_admin_update ON public.servicios FOR UPDATE TO authenticated USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY servicios_admin_delete ON public.servicios FOR DELETE TO authenticated USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS portafolio_write ON public.portafolio_trabajador;
CREATE POLICY portafolio_insert ON public.portafolio_trabajador FOR INSERT TO authenticated WITH CHECK (id_trabajador = (SELECT auth.uid()) OR (SELECT public.is_admin()));
CREATE POLICY portafolio_update ON public.portafolio_trabajador FOR UPDATE TO authenticated USING (id_trabajador = (SELECT auth.uid()) OR (SELECT public.is_admin())) WITH CHECK (id_trabajador = (SELECT auth.uid()) OR (SELECT public.is_admin()));
CREATE POLICY portafolio_delete ON public.portafolio_trabajador FOR DELETE TO authenticated USING (id_trabajador = (SELECT auth.uid()) OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS trabajador_servicios_write ON public.trabajador_servicios;
CREATE POLICY trabajador_servicios_insert ON public.trabajador_servicios FOR INSERT TO authenticated WITH CHECK (id_trabajador = (SELECT auth.uid()) OR (SELECT public.is_admin()));
CREATE POLICY trabajador_servicios_update ON public.trabajador_servicios FOR UPDATE TO authenticated USING (id_trabajador = (SELECT auth.uid()) OR (SELECT public.is_admin())) WITH CHECK (id_trabajador = (SELECT auth.uid()) OR (SELECT public.is_admin()));
CREATE POLICY trabajador_servicios_delete ON public.trabajador_servicios FOR DELETE TO authenticated USING (id_trabajador = (SELECT auth.uid()) OR (SELECT public.is_admin()));

-- notificaciones: el INSERT ya lo cubre notificaciones_insert_participantes.
DROP POLICY IF EXISTS notificaciones_all ON public.notificaciones;
CREATE POLICY notificaciones_select ON public.notificaciones FOR SELECT TO authenticated
  USING (id_usuario = (SELECT auth.uid()) OR (SELECT public.is_admin()));
CREATE POLICY notificaciones_update ON public.notificaciones FOR UPDATE TO authenticated
  USING (id_usuario = (SELECT auth.uid()) OR (SELECT public.is_admin()))
  WITH CHECK (id_usuario = (SELECT auth.uid()) OR (SELECT public.is_admin()));
CREATE POLICY notificaciones_delete ON public.notificaciones FOR DELETE TO authenticated
  USING (id_usuario = (SELECT auth.uid()) OR (SELECT public.is_admin()));

-- R4 ------------------------------------------------------------------------
-- Ganancias / liquidaciones del profesional (filtra por id_trabajador, ordena por fecha).
CREATE INDEX IF NOT EXISTS liquidaciones_trabajador_creado_idx
  ON public.liquidaciones (id_trabajador, creado_en DESC);
-- Reseñas recibidas por un profesional o cliente.
CREATE INDEX IF NOT EXISTS calificaciones_calificado_idx
  ON public.calificaciones (id_calificado, direccion, creado_en DESC);
-- Chat de un trabajo ordenado por fecha (reemplaza al índice simple).
CREATE INDEX IF NOT EXISTS mensajes_trabajo_creado_idx
  ON public.mensajes (id_trabajo, creado_en);
DROP INDEX IF EXISTS public.idx_mensajes_id_trabajo;
-- Campana de notificaciones (reemplaza al índice simple).
CREATE INDEX IF NOT EXISTS notificaciones_usuario_creado_idx
  ON public.notificaciones (id_usuario, creado_en DESC);
DROP INDEX IF EXISTS public.idx_notificaciones_id_usuario;
-- Duplicados: mismo contenido que un índice único o prefijo de un compuesto.
DROP INDEX IF EXISTS public.trabajador_horarios_usuario_idx;  -- = trabajador_horarios_usuario_dia_uidx
DROP INDEX IF EXISTS public.idx_trabajos_id_usuario;          -- prefijo de trabajos_usuario_creado_idx
DROP INDEX IF EXISTS public.idx_pagos_id_trabajo;             -- prefijo de pagos_trabajo_estado_idx

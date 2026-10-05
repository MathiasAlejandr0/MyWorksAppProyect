-- Cierra escrituras de pagos y de estado hechas por el cliente, deja de
-- exponer el correo de todos los perfiles y, recién entonces, bota las
-- políticas inglesas que duplicaban a las españolas.
-- Idempotente. Las RPC SECURITY DEFINER corren como postgres y siguen
-- pudiendo cambiar estado, profesional y pago.
-- Aplicar después de 20261007000004. Pruebas: docs/PRUEBAS_RLS_20261008.sql

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) pagos: el cliente solo lee. Escribe el service role o una RPC.
-- -----------------------------------------------------------------------------
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.pagos FROM anon, authenticated;
GRANT SELECT ON TABLE public.pagos TO authenticated;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT p.polname
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'pagos'
      AND p.polcmd IN ('a', 'w', 'd', '*')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.pagos', r.polname);
  END LOOP;
END $$;

DROP POLICY IF EXISTS pagos_select ON public.pagos;
CREATE POLICY pagos_select ON public.pagos
  FOR SELECT TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

-- -----------------------------------------------------------------------------
-- 2) trabajos: estado, profesional y pago no se escriben por PostgREST.
--    Las RPC (dueño postgres/supabase_admin), service_role, admin y el SQL
--    sin JWT siguen pasando. Un GUC de transacción también, por si una RPC
--    lo enciende; PostgREST no deja al cliente hacer SET.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.proteger_campos_trabajo()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP <> 'UPDATE' THEN
    RETURN NEW;
  END IF;

  IF NEW.estado IS NOT DISTINCT FROM OLD.estado
     AND NEW.id_trabajador IS NOT DISTINCT FROM OLD.id_trabajador
     AND NEW.id_usuario IS NOT DISTINCT FROM OLD.id_usuario
     AND NEW.estado_pago IS NOT DISTINCT FROM OLD.estado_pago
     AND NEW.modalidad_cobro IS NOT DISTINCT FROM OLD.modalidad_cobro
     AND NEW.instantanea_precio IS NOT DISTINCT FROM OLD.instantanea_precio
  THEN
    RETURN NEW;
  END IF;

  IF COALESCE(current_setting('mwa.rpc_trabajo', true), '') = '1'
     OR COALESCE(auth.role(), '') = 'service_role'
     OR public.is_admin()
     OR (auth.role() IS NULL AND auth.uid() IS NULL)
     OR current_user IN ('postgres', 'supabase_admin')
  THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'estado, profesional y pago solo cambian por los procedimientos del trabajo';
END;
$$;

REVOKE ALL ON FUNCTION public.proteger_campos_trabajo() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trabajos_proteger_campos ON public.trabajos;
CREATE TRIGGER trabajos_proteger_campos
  BEFORE UPDATE ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.proteger_campos_trabajo();

-- La web crea el pedido ya con el profesional elegido.
DROP POLICY IF EXISTS trabajos_insert ON public.trabajos;
CREATE POLICY trabajos_insert ON public.trabajos
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR (
      id_usuario = (SELECT auth.uid())
      AND estado IN ('pendiente', 'esperando_cotizaciones', 'esperando_pago')
    )
  );

-- -----------------------------------------------------------------------------
-- 3) perfiles: fila completa propia, de admin o de la contraparte de un
--    trabajo (Flutter getUserById en chat, detalle y conformidad).
--    Nombre y foto del resto van por la vista, solo para autenticados.
--    El correo de contacto fuera de esa fila, por RPC, y solo con trabajo activo.
--    El selector de la demo solo ve correos @demo.myworksapp.cl.
--    anon conserva listar_cuentas_demo_acceso: el login de la app llama
--    esa RPC antes de tener sesión.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS perfiles_select ON public.perfiles;
CREATE POLICY perfiles_select ON public.perfiles
  FOR SELECT TO authenticated
  USING (
    id = (SELECT auth.uid())
    OR public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.trabajos t
      WHERE (t.id_usuario = (SELECT auth.uid()) AND t.id_trabajador = perfiles.id)
         OR (t.id_trabajador = (SELECT auth.uid()) AND t.id_usuario = perfiles.id)
    )
  );

DROP VIEW IF EXISTS public.perfiles_publicos;
CREATE VIEW public.perfiles_publicos
WITH (security_invoker = false) AS
SELECT id, nombre, rol, ruta_foto_perfil
FROM public.perfiles;

-- La vista con security_invoker = false es actualizable y heredaba
-- UPDATE/DELETE de PUBLIC. Solo lectura, y solo con sesión.
REVOKE ALL ON public.perfiles_publicos FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.perfiles_publicos TO authenticated;

CREATE OR REPLACE FUNCTION public.perfil_contacto_si_trabajo_activo(p_perfil_id uuid)
RETURNS TABLE (id uuid, nombre text, correo text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT p.id, p.nombre, p.correo
  FROM public.perfiles p
  WHERE p.id = p_perfil_id
    AND auth.uid() IS NOT NULL
    AND (
      p.id = (SELECT auth.uid())
      OR public.is_admin()
      OR EXISTS (
        SELECT 1
        FROM public.trabajos t
        WHERE t.estado NOT IN ('completado', 'cancelado', 'expirado', 'no_asistio')
          AND (
            (t.id_usuario = (SELECT auth.uid()) AND t.id_trabajador = p.id)
            OR (t.id_trabajador = (SELECT auth.uid()) AND t.id_usuario = p.id)
          )
      )
    );
$$;

REVOKE ALL ON FUNCTION public.perfil_contacto_si_trabajo_activo(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.perfil_contacto_si_trabajo_activo(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.listar_cuentas_demo_acceso()
RETURNS TABLE (
  id uuid,
  nombre text,
  correo text,
  rol text,
  profesion text,
  categoria_servicio text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT p.id, p.nombre, p.correo, p.rol, t.profesion, t.categoria_servicio
  FROM public.perfiles p
  JOIN public.trabajadores t ON t.id_usuario = p.id
  WHERE p.rol = 'trabajador'
    AND p.correo ILIKE '%@demo.myworksapp.cl';
$$;

REVOKE ALL ON FUNCTION public.listar_cuentas_demo_acceso() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_cuentas_demo_acceso() TO anon, authenticated;

-- -----------------------------------------------------------------------------
-- 4) Lo que las políticas inglesas daban de más, ahora en español.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS notificaciones_insert_participantes ON public.notificaciones;
CREATE POLICY notificaciones_insert_participantes ON public.notificaciones
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      id_usuario = (SELECT auth.uid())
      OR public.is_admin()
      OR (
        id_relacionado IS NOT NULL
        AND EXISTS (
          SELECT 1
          FROM public.trabajos j
          WHERE j.id::text = notificaciones.id_relacionado
            AND (
              j.id_usuario = (SELECT auth.uid())
              OR j.id_trabajador = (SELECT auth.uid())
            )
        )
      )
    )
  );

DROP POLICY IF EXISTS propuestas_all ON public.propuestas_cotizacion;
CREATE POLICY propuestas_all ON public.propuestas_cotizacion
  FOR ALL TO authenticated
  USING (
    id_trabajador = (SELECT auth.uid())
    OR public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.trabajos j
      WHERE j.id = propuestas_cotizacion.id_trabajo
        AND j.id_usuario = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    id_trabajador = (SELECT auth.uid())
    OR public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.trabajos j
      WHERE j.id = propuestas_cotizacion.id_trabajo
        AND j.id_usuario = (SELECT auth.uid())
    )
  );

-- El cliente ve la ficha del profesional de su trabajo aunque ya no esté
-- disponible en el catálogo. El catálogo público sigue en las otras políticas.
DROP POLICY IF EXISTS trabajadores_select_contraparte ON public.trabajadores;
CREATE POLICY trabajadores_select_contraparte ON public.trabajadores
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.trabajos t
      WHERE t.id_trabajador = trabajadores.id_usuario
        AND t.id_usuario = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS impulsos_select ON public.impulsos;
CREATE POLICY impulsos_select ON public.impulsos
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS registros_error_app_update_admin ON public.registros_error_app;
CREATE POLICY registros_error_app_update_admin ON public.registros_error_app
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Nombres ingleses. Las españolas ya cubren el permiso que hacía falta.
DO $$
DECLARE
  r record;
  legacy_re text := '^(profiles_|jobs_|payments_|msg_|messages_|notifications_|workers_|services_|ratings_|reports_|disputes_|quotes_|jp_all$|jc_all$|co_all$|prc_all$|pending_|blocks_|consents_|boosts_|portfolio_|ws_select$|ws_write$|sc_select$|ff_|abuse_|analytics_|app_error_logs_|subs_all$|job_cancellations_)';
BEGIN
  FOR r IN
    SELECT n.nspname AS schema_name, c.relname AS table_name, p.polname
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND p.polname ~* legacy_re
      AND EXISTS (
        SELECT 1
        FROM pg_policy q
        WHERE q.polrelid = p.polrelid
          AND q.polname <> p.polname
          AND q.polname !~* legacy_re
      )
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I.%I',
      r.polname, r.schema_name, r.table_name
    );
  END LOOP;
END $$;

COMMIT;

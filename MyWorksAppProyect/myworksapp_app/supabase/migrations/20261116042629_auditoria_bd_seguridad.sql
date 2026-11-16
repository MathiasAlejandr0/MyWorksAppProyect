-- Auditoría de base de datos 2026-11-16 (2/5): seguridad.
--
-- Hallazgos de las pruebas de seguridad (docs/pruebas/seguridad_base_datos.md):
--   S1. Un usuario podía editar en su propio perfil los agregados de reputación
--       (reputacion_cliente, calificaciones_cliente) que solo debe calcular el
--       servidor. Prueba V-perfil-calificaciones_cliente: PATCH respondió 200.
--   S2. Un profesional podía crearse un "impulso" (destacado pagado) sin pagar:
--       la política impulsos_write permitía INSERT del dueño, y el trigger
--       refresca su ranking. Prueba V-impulso-gratis: 201 Created.
--   S3. Un usuario podía activarse una suscripción premium (suscripciones_all
--       permitía INSERT/UPDATE del dueño). Prueba V-suscripcion-gratis: 201.
--   S4. anon y authenticated tenían TRUNCATE, TRIGGER y REFERENCES en todas las
--       tablas (grant por defecto de Supabase). TRUNCATE ignora RLS; aunque la
--       API REST no lo expone, se retira (mínimo privilegio, defensa en
--       profundidad). Tampoco hay política de escritura para anon en ninguna
--       tabla, así que se retiran INSERT/UPDATE/DELETE de anon.
--   S5. listar_trabajos_marketplace (SECURITY DEFINER) devolvía las solicitudes
--       abiertas a cualquier usuario autenticado; solo la usa el profesional.
--   S6. bloqueos_pin_inicio e intentos_pin_inicio tenían RLS sin políticas
--       (correcto para el cliente, pero el linter lo marca y el admin no podía
--       auditar los intentos). Se agrega lectura solo para administración.

-- S1 ------------------------------------------------------------------------
-- Pasa a SECURITY INVOKER para que current_user refleje quién escribe
-- (authenticated por la API, postgres dentro de funciones del servidor).
CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT (public.is_admin() OR COALESCE(auth.role(), '') = 'service_role') THEN
    IF NEW.rol IS DISTINCT FROM OLD.rol THEN
      RAISE EXCEPTION 'No puedes cambiar tu rol';
    END IF;
    IF NEW.estado_cuenta IS DISTINCT FROM OLD.estado_cuenta THEN
      RAISE EXCEPTION 'No puedes cambiar el estado de tu cuenta';
    END IF;
  END IF;
  -- Los agregados de reputación los calcula el servidor (funciones SECURITY
  -- DEFINER, donde current_user es el dueño de la función). Un cliente que
  -- escribe directo por la API llega como authenticated/anon y se rechaza.
  IF current_user IN ('authenticated', 'anon')
     AND NOT public.is_admin()
     AND (NEW.reputacion_cliente IS DISTINCT FROM OLD.reputacion_cliente
          OR NEW.calificaciones_cliente IS DISTINCT FROM OLD.calificaciones_cliente) THEN
    RAISE EXCEPTION 'La reputación la calcula el sistema';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.perfiles_reputacion_inicial_segura()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
BEGIN
  IF current_user IN ('authenticated', 'anon') AND NOT public.is_admin() THEN
    NEW.reputacion_cliente := NULL;
    NEW.calificaciones_cliente := 0;
  END IF;
  RETURN NEW;
END;
$function$;
DROP TRIGGER IF EXISTS perfiles_reputacion_inicial_segura ON public.perfiles;
CREATE TRIGGER perfiles_reputacion_inicial_segura
  BEFORE INSERT ON public.perfiles
  FOR EACH ROW EXECUTE FUNCTION public.perfiles_reputacion_inicial_segura();

-- S2 ------------------------------------------------------------------------
DROP POLICY IF EXISTS impulsos_write ON public.impulsos;
CREATE POLICY impulsos_admin_insert ON public.impulsos FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());
CREATE POLICY impulsos_admin_update ON public.impulsos FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY impulsos_admin_delete ON public.impulsos FOR DELETE TO authenticated
  USING (public.is_admin());

-- S3 ------------------------------------------------------------------------
DROP POLICY IF EXISTS suscripciones_all ON public.suscripciones;
CREATE POLICY suscripciones_select ON public.suscripciones FOR SELECT TO authenticated
  USING (id_usuario = (SELECT auth.uid()) OR public.is_admin());
CREATE POLICY suscripciones_admin_insert ON public.suscripciones FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());
CREATE POLICY suscripciones_admin_update ON public.suscripciones FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY suscripciones_admin_delete ON public.suscripciones FOR DELETE TO authenticated
  USING (public.is_admin());

-- S4 ------------------------------------------------------------------------
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT c.relname
    FROM pg_class c
    WHERE c.relnamespace = 'public'::regnamespace AND c.relkind IN ('r', 'p')
  LOOP
    EXECUTE format('REVOKE TRUNCATE, TRIGGER, REFERENCES ON public.%I FROM anon, authenticated', r.relname);
    EXECUTE format('REVOKE INSERT, UPDATE, DELETE ON public.%I FROM anon', r.relname);
  END LOOP;
END $$;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE TRUNCATE, TRIGGER, REFERENCES ON TABLES FROM anon, authenticated;

-- S5 ------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.listar_trabajos_marketplace(p_limite integer DEFAULT 50)
RETURNS TABLE(id text, estado text, descripcion text, creado_en text, actualizado_en text,
              id_servicio text, modalidad_cobro text, metadatos_servicio text)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT t.id::text,
         t.estado::text,
         t.descripcion::text,
         t.creado_en::text,
         t.actualizado_en::text,
         t.id_servicio::text,
         COALESCE(t.modalidad_cobro::text, 'legado'),
         public.metadatos_sin_pin(t.metadatos_servicio::text)
  FROM public.trabajos t
  WHERE t.id_trabajador IS NULL
    AND t.estado IN ('pendiente', 'esperando_cotizaciones', 'esperando_pago')
    AND (public.es_rol_trabajador((SELECT auth.uid())::text) OR public.is_admin())
  ORDER BY t.creado_en DESC
  LIMIT GREATEST(1, LEAST(COALESCE(p_limite, 50), 100));
$function$;

-- S6 ------------------------------------------------------------------------
DROP POLICY IF EXISTS bloqueos_pin_inicio_admin_select ON public.bloqueos_pin_inicio;
CREATE POLICY bloqueos_pin_inicio_admin_select ON public.bloqueos_pin_inicio
  FOR SELECT TO authenticated USING (public.is_admin());
DROP POLICY IF EXISTS intentos_pin_inicio_admin_select ON public.intentos_pin_inicio;
CREATE POLICY intentos_pin_inicio_admin_select ON public.intentos_pin_inicio
  FOR SELECT TO authenticated USING (public.is_admin());

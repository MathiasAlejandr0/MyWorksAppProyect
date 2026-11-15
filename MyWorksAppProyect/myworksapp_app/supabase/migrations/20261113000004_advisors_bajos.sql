-- Avisos «bajos» de los advisors de Supabase (auditoría 12 nov 2026).
--
-- 1. vincular_trabajador_solicitud no revisaba trabajador_reservable: un
--    cliente podía pedir a un profesional sin verificar o suspendido (el
--    cobro igual lo rechazaba, pero el trabajo quedaba asignado).
-- 2. Políticas permisivas duplicadas para el mismo rol y comando
--    (servicios y trabajadores, SELECT authenticated): se unen en una sola
--    con OR. Mismas filas visibles, una evaluación menos por fila.
-- 3. eventos_ranking tiene RLS sin políticas: queda explícito que solo un
--    admin lo puede leer (escriben las funciones SECURITY DEFINER).
--
-- No cambia: listar_cuentas_demo_acceso sigue ejecutable por anon (el
-- selector demo corre antes del login) y devuelve vacío con demo_modo = 0.
-- search_path de km_entre_puntos/recargo_traslado_clp ya va en 20261113000001.
--
-- Idempotente.

BEGIN;

-- 1 ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.vincular_trabajador_solicitud(p_trabajo_id text, p_trabajador_id text)
 RETURNS trabajos
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_row public.trabajos;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF p_trabajador_id IS NULL OR length(trim(p_trabajador_id)) = 0 THEN
    RAISE EXCEPTION 'trabajador requerido';
  END IF;
  IF NOT public.es_rol_trabajador(p_trabajador_id) THEN
    RAISE EXCEPTION 'el usuario no es trabajador';
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
  ) THEN
    RAISE EXCEPTION 'solo el cliente puede pedir a este profesional';
  END IF;
  IF v_row.estado NOT IN ('esperando_pago', 'pendiente') THEN
    RAISE EXCEPTION 'estado no permite pedir profesional: %', v_row.estado;
  END IF;
  IF v_row.id_trabajador IS NOT NULL
     AND v_row.id_trabajador::text <> p_trabajador_id THEN
    RAISE EXCEPTION 'el trabajo ya tiene otro profesional';
  END IF;
  -- Mismo criterio que el cobro: solo profesionales verificados, activos,
  -- disponibles y con precios publicados.
  IF v_row.id_trabajador IS NULL
     AND NOT public.trabajador_reservable(p_trabajador_id::uuid) THEN
    RAISE EXCEPTION 'Este profesional no está disponible para reservar';
  END IF;

  UPDATE public.trabajos
  SET
    id_trabajador = p_trabajador_id::uuid,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$function$;

REVOKE ALL ON FUNCTION public.vincular_trabajador_solicitud(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.vincular_trabajador_solicitud(text, text) TO authenticated, service_role;

-- 2 ---------------------------------------------------------------------
ALTER POLICY servicios_select ON public.servicios TO anon;
DROP POLICY IF EXISTS servicios_select_admin ON public.servicios;
DROP POLICY IF EXISTS servicios_select_authenticated ON public.servicios;
CREATE POLICY servicios_select_authenticated ON public.servicios
  FOR SELECT TO authenticated
  USING (COALESCE(activo, 1) = 1 OR public.is_admin());

DROP POLICY IF EXISTS trabajadores_select_contraparte ON public.trabajadores;
DROP POLICY IF EXISTS trabajadores_select_authenticated ON public.trabajadores;
CREATE POLICY trabajadores_select_authenticated ON public.trabajadores
  FOR SELECT TO authenticated
  USING (
    (COALESCE(disponible, 0) = 1 AND COALESCE(precios_configurados, 0) = 1)
    OR id_usuario = (SELECT auth.uid())
    OR public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.trabajos t
      WHERE t.id_trabajador = trabajadores.id_usuario
        AND t.id_usuario = (SELECT auth.uid())
    )
  );

-- 3 ---------------------------------------------------------------------
DROP POLICY IF EXISTS eventos_ranking_select_admin ON public.eventos_ranking;
CREATE POLICY eventos_ranking_select_admin ON public.eventos_ranking
  FOR SELECT TO authenticated
  USING (public.is_admin());

COMMIT;

-- Reafirma harden Webpay DESPUÉS de migraciones 20260919*
-- (evita que grants viejos de simular_transicion_pago queden vigentes).

-- Columnas PSP (idempotente)
ALTER TABLE public.pagos
  ADD COLUMN IF NOT EXISTS ambiente text,
  ADD COLUMN IF NOT EXISTS token_tbk text,
  ADD COLUMN IF NOT EXISTS url_tbk text,
  ADD COLUMN IF NOT EXISTS buy_order text;

-- RLS pagos: sin INSERT/UPDATE de clientes
DROP POLICY IF EXISTS pagos_all ON public.pagos;
DROP POLICY IF EXISTS pagos_insert ON public.pagos;
DROP POLICY IF EXISTS pagos_update ON public.pagos;
DROP POLICY IF EXISTS pagos_select ON public.pagos;
DROP POLICY IF EXISTS pagos_admin_write ON public.pagos;

CREATE POLICY pagos_select ON public.pagos
  FOR SELECT TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

CREATE POLICY pagos_admin_write ON public.pagos
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Revocar simulación a clientes (otra vez, post-20260919)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'simular_transicion_pago'
  ) THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) FROM authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) FROM anon';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) FROM PUBLIC';
  END IF;
END $$;

-- trabajos: solo partes + admin
DROP POLICY IF EXISTS trabajos_select ON public.trabajos;
CREATE POLICY trabajos_select ON public.trabajos
  FOR SELECT TO authenticated
  USING (
    id_usuario::text = auth.uid()::text
    OR id_trabajador::text = auth.uid()::text
    OR public.is_admin()
  );

-- Monto: sin fallback al monto del cliente si hay tarifa/cotización
CREATE OR REPLACE FUNCTION public.crear_intencion_pago(
  p_id_trabajo text,
  p_monto numeric,
  p_buy_order text DEFAULT NULL
)
RETURNS public.pagos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text := auth.uid()::text;
  v_job public.trabajos%ROWTYPE;
  v_expected numeric;
  v_row public.pagos%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'No autenticado';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id::text = p_id_trabajo;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trabajo no encontrado';
  END IF;

  IF v_job.id_usuario::text <> v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo el cliente del trabajo puede crear la intención de pago';
  END IF;

  SELECT COALESCE(
    (SELECT c.monto_total_clp FROM public.propuestas_cotizacion c
      WHERE c.id_trabajo = v_job.id AND c.estado = 'seleccionada'
      ORDER BY c.creado_en DESC LIMIT 1),
    (SELECT w.tarifa_visita FROM public.trabajadores w
      WHERE w.id_usuario = v_job.id_trabajador)
  ) INTO v_expected;

  IF v_expected IS NULL OR v_expected <= 0 THEN
    RAISE EXCEPTION 'No hay tarifa/cotización para validar el monto';
  END IF;

  IF p_monto IS NULL OR abs(p_monto - v_expected) > 1 THEN
    RAISE EXCEPTION 'Monto % no coincide con tarifa/cotización %', p_monto, v_expected;
  END IF;

  INSERT INTO public.pagos (
    id, id_trabajo, monto, moneda, estado, tipo_pago, metodo_pago,
    creado_en, actualizado_en, buy_order, ambiente
  ) VALUES (
    gen_random_uuid()::text,
    v_job.id,
    v_expected,
    'CLP',
    'pendiente',
    'principal',
    'webpay',
    now(),
    now(),
    p_buy_order,
    'integration'
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.crear_intencion_pago(text, numeric, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crear_intencion_pago(text, numeric, text) TO authenticated;

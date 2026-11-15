-- Webpay escrow hardening: PII, intención de pago, RPCs solo admin/sistema.
-- Aplica en staging/prod antes de activar Edge Functions.

-- -----------------------------------------------------------------------------
-- 1) Columnas PSP en pagos
-- -----------------------------------------------------------------------------
ALTER TABLE public.pagos
  ADD COLUMN IF NOT EXISTS ambiente text,
  ADD COLUMN IF NOT EXISTS token_tbk text,
  ADD COLUMN IF NOT EXISTS url_tbk text,
  ADD COLUMN IF NOT EXISTS buy_order text;

COMMENT ON COLUMN public.pagos.ambiente IS 'integration | production';
COMMENT ON COLUMN public.pagos.token_tbk IS 'token_ws Transbank (intención)';
COMMENT ON COLUMN public.pagos.buy_order IS 'buy_order Webpay';

-- -----------------------------------------------------------------------------
-- 2) trabajos_select: sin PII a cualquiera authenticated en jobs abiertos
--    Marketplace usa RPC listar_trabajos_marketplace (sin dirección/coords).
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS trabajos_select ON public.trabajos;

CREATE POLICY trabajos_select ON public.trabajos
  FOR SELECT TO authenticated
  USING (
    id_usuario::text = auth.uid()::text
    OR id_trabajador::text = auth.uid()::text
    OR public.is_admin()
  );

DROP FUNCTION IF EXISTS public.listar_trabajos_marketplace(integer);

CREATE OR REPLACE FUNCTION public.listar_trabajos_marketplace(
  p_limite integer DEFAULT 50
)
RETURNS TABLE (
  id text,
  estado text,
  descripcion text,
  creado_en text,
  id_servicio text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT t.id::text,
         t.estado::text,
         t.descripcion::text,
         t.creado_en::text,
         t.id_servicio::text
  FROM public.trabajos t
  WHERE t.id_trabajador IS NULL
    AND t.estado IN ('pendiente', 'esperando_cotizaciones', 'esperando_pago')
  ORDER BY t.creado_en DESC
  LIMIT GREATEST(1, LEAST(COALESCE(p_limite, 50), 100));
$$;

REVOKE ALL ON FUNCTION public.listar_trabajos_marketplace(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_trabajos_marketplace(integer) TO authenticated;

-- -----------------------------------------------------------------------------
-- 3) pagos: clientes no INSERT arbitrario — solo vía RPC / service_role
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS pagos_insert ON public.pagos;
DROP POLICY IF EXISTS pagos_all ON public.pagos;
DROP POLICY IF EXISTS pagos_select ON public.pagos;
DROP POLICY IF EXISTS pagos_update ON public.pagos;

CREATE POLICY pagos_select ON public.pagos
  FOR SELECT TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

-- Sin INSERT/UPDATE para authenticated (Edge usa service_role).
CREATE POLICY pagos_admin_write ON public.pagos
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- -----------------------------------------------------------------------------
-- 4) crear_intencion_pago — valida monto vs trabajo / cotización
-- -----------------------------------------------------------------------------
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

  -- Monto esperado: cotización seleccionada o tarifa del trabajador
  SELECT COALESCE(
    (SELECT c.monto_total_clp FROM public.propuestas_cotizacion c
      WHERE c.id_trabajo = v_job.id AND c.estado = 'seleccionada'
      ORDER BY c.creado_en DESC LIMIT 1),
    (SELECT w.tarifa_visita FROM public.trabajadores w
      WHERE w.id_usuario = v_job.id_trabajador),
    p_monto
  ) INTO v_expected;

  IF p_monto IS NULL OR p_monto <= 0 THEN
    RAISE EXCEPTION 'Monto inválido';
  END IF;

  IF v_expected IS NOT NULL AND abs(p_monto - v_expected) > 1 THEN
    RAISE EXCEPTION 'Monto % no coincide con tarifa/cotización esperada %', p_monto, v_expected;
  END IF;

  INSERT INTO public.pagos (
    id, id_trabajo, monto, moneda, estado, tipo_pago, metodo_pago,
    creado_en, actualizado_en, buy_order, ambiente
  ) VALUES (
    gen_random_uuid()::text,
    v_job.id,
    p_monto,
    'CLP',
    'pendiente',
    'principal',
    'webpay',
    now(),
    now(),
    p_buy_order,
    coalesce(nullif(current_setting('app.tbk_env', true), ''), 'integration')
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.crear_intencion_pago(text, numeric, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crear_intencion_pago(text, numeric, text) TO authenticated;

-- -----------------------------------------------------------------------------
-- 5) Liberar / reembolsar solo admin (o service_role vía Edge)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.liberar_escrow(p_id_pago text)
RETURNS public.pagos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.pagos%ROWTYPE;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo administrador puede liberar escrow';
  END IF;

  UPDATE public.pagos
  SET estado = 'liberado',
      liberado_en = now(),
      actualizado_en = now()
  WHERE id::text = p_id_pago
    AND estado IN ('autorizado', 'retenido')
  RETURNING * INTO v_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pago no liberable';
  END IF;
  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.reembolsar_escrow(p_id_pago text)
RETURNS public.pagos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.pagos%ROWTYPE;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo administrador puede reembolsar escrow';
  END IF;

  UPDATE public.pagos
  SET estado = 'reembolsado',
      reembolsado_en = now(),
      actualizado_en = now()
  WHERE id::text = p_id_pago
    AND estado IN ('autorizado', 'retenido', 'pendiente')
  RETURNING * INTO v_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pago no reembolsable';
  END IF;
  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.liberar_escrow(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reembolsar_escrow(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.liberar_escrow(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reembolsar_escrow(text) TO authenticated;

-- -----------------------------------------------------------------------------
-- 6) Revocar simular_transicion_pago a clientes (solo service_role)
-- -----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) FROM PUBLIC;

COMMENT ON FUNCTION public.simular_transicion_pago(text, text) IS
  'LEGACY — no usar desde clientes. Transiciones PSP vía Edge webpay-commit / liberar_escrow.';

-- -----------------------------------------------------------------------------
-- 7) mensajes: UPDATE solo leído (política restrictiva)
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS mensajes_all ON public.mensajes;
DROP POLICY IF EXISTS mensajes_select ON public.mensajes;
DROP POLICY IF EXISTS mensajes_insert ON public.mensajes;
DROP POLICY IF EXISTS mensajes_update ON public.mensajes;

CREATE POLICY mensajes_select ON public.mensajes
  FOR SELECT TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

CREATE POLICY mensajes_insert ON public.mensajes
  FOR INSERT TO authenticated
  WITH CHECK (
    (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin())
    AND id_remitente::text = auth.uid()::text
  );

CREATE POLICY mensajes_update_leido ON public.mensajes
  FOR UPDATE TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin())
  WITH CHECK (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

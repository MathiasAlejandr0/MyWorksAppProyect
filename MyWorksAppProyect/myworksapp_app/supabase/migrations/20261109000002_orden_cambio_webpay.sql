-- Intención de pago Webpay para órdenes de cambio (tomado de PR #46, d05d64a).
-- Solo la parte de órdenes de cambio: las evidencias ya van en WebP (20261108000001).
BEGIN;
-- -----------------------------------------------------------------------------
-- 2) Intención de pago para una orden de cambio pendiente
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crear_intencion_pago_orden_cambio(
  p_id_trabajo text,
  p_id_orden_cambio text,
  p_monto numeric,
  p_buy_order text DEFAULT NULL
)
RETURNS public.pagos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid text := auth.uid()::text;
  v_job public.trabajos;
  v_order public.ordenes_cambio;
  v_expected numeric;
  v_row public.pagos;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = p_id_trabajo
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trabajo no encontrado';
  END IF;

  IF v_job.id_usuario::text <> v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo el cliente del trabajo puede pagar la orden de cambio';
  END IF;

  IF v_job.estado IS DISTINCT FROM 'pausado_orden_cambio' THEN
    RAISE EXCEPTION 'El trabajo no está pausado por orden de cambio';
  END IF;

  SELECT * INTO v_order
  FROM public.ordenes_cambio
  WHERE id::text = p_id_orden_cambio
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Orden de cambio no encontrada';
  END IF;

  IF v_order.id_trabajo::text <> v_job.id::text THEN
    RAISE EXCEPTION 'La orden de cambio no pertenece a este trabajo';
  END IF;

  IF v_order.estado IS DISTINCT FROM 'pendiente_cliente' THEN
    RAISE EXCEPTION 'La orden de cambio ya fue respondida';
  END IF;

  v_expected := COALESCE(v_order.monto_clp, 0)::numeric
    + round(COALESCE(v_order.monto_clp, 0)::numeric * 0.08);

  IF p_monto IS NULL OR abs(p_monto - v_expected) > 1 THEN
    RAISE EXCEPTION 'Monto % no coincide con la orden de cambio %', p_monto, v_expected;
  END IF;

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id_orden_cambio::text = v_order.id::text
    AND tipo_pago = 'orden_cambio'
    AND estado IN ('retenido', 'autorizado', 'liberado')
  LIMIT 1;
  IF FOUND THEN
    RAISE EXCEPTION 'esta orden de cambio ya tiene un pago en garantia';
  END IF;

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id_orden_cambio::text = v_order.id::text
    AND tipo_pago = 'orden_cambio'
    AND estado = 'pendiente'
  ORDER BY creado_en DESC
  LIMIT 1;
  IF FOUND THEN
    IF v_row.token_tbk IS NOT NULL AND length(trim(v_row.token_tbk)) > 0 THEN
      RAISE EXCEPTION 'ya hay un cobro en curso para esta orden de cambio';
    END IF;
    UPDATE public.pagos
      SET monto = v_expected,
          actualizado_en = now()
      WHERE id = v_row.id
      RETURNING * INTO v_row;
    RETURN v_row;
  END IF;

  INSERT INTO public.pagos (
    id, id_trabajo, monto, moneda, estado, tipo_pago, metodo_pago,
    id_orden_cambio, creado_en, actualizado_en, buy_order, ambiente
  ) VALUES (
    gen_random_uuid()::text,
    v_job.id,
    v_expected,
    'CLP',
    'pendiente',
    'orden_cambio',
    'webpay',
    v_order.id,
    now(),
    now(),
    p_buy_order,
    'integration'
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.crear_intencion_pago_orden_cambio(text, text, numeric, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.crear_intencion_pago_orden_cambio(text, text, numeric, text)
  TO authenticated, service_role;

-- Tras retener el cobro extra, marcar la orden pagada y reanudar el trabajo.
-- service_role (webpay-commit) puede llamarla sin JWT de cliente.
CREATE OR REPLACE FUNCTION public.marcar_orden_cambio_pagada(
  p_id_orden_cambio text,
  p_id_pago text
)
RETURNS public.ordenes_cambio
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid text := auth.uid()::text;
  v_role text := coalesce(auth.role(), '');
  v_order public.ordenes_cambio;
  v_job public.trabajos;
  v_pago public.pagos;
BEGIN
  SELECT * INTO v_order
  FROM public.ordenes_cambio
  WHERE id::text = p_id_orden_cambio
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Orden de cambio no encontrada';
  END IF;

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = v_order.id_trabajo::text
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trabajo no encontrado';
  END IF;

  IF v_role <> 'service_role'
     AND v_uid IS DISTINCT FROM v_job.id_usuario::text
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo el cliente puede confirmar el cobro adicional';
  END IF;

  SELECT * INTO v_pago
  FROM public.pagos
  WHERE id::text = p_id_pago;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pago no encontrado';
  END IF;

  IF v_pago.id_orden_cambio::text IS DISTINCT FROM v_order.id::text THEN
    RAISE EXCEPTION 'El pago no corresponde a esta orden de cambio';
  END IF;

  IF v_pago.estado NOT IN ('retenido', 'autorizado', 'liberado') THEN
    RAISE EXCEPTION 'El cobro adicional aún no está retenido';
  END IF;

  UPDATE public.ordenes_cambio
  SET
    estado = 'pagada',
    id_pago = v_pago.id,
    respondido_en = COALESCE(respondido_en, now())
  WHERE id = v_order.id
  RETURNING * INTO v_order;

  IF v_job.estado = 'pausado_orden_cambio' THEN
    UPDATE public.trabajos
    SET
      estado = 'en_curso',
      actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
    WHERE id = v_job.id;
  END IF;

  RETURN v_order;
END;
$$;

REVOKE ALL ON FUNCTION public.marcar_orden_cambio_pagada(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.marcar_orden_cambio_pagada(text, text)
  TO authenticated, service_role;
COMMIT;

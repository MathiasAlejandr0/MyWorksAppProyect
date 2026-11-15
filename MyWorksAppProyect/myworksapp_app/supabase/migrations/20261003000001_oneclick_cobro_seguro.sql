-- Oneclick: el token Webpay no se mezcla con la orden de detalle,
-- un cobro en curso no se pisa, y el monto pendiente se actualiza
-- a la tarifa vigente antes de autorizar.

ALTER TABLE public.pagos
  ADD COLUMN IF NOT EXISTS orden_detalle_oneclick text,
  ADD COLUMN IF NOT EXISTS cobro_reclamado_en timestamptz;

COMMENT ON COLUMN public.pagos.token_tbk IS
  'token_ws de Webpay Plus. No guardar aquí la orden Oneclick.';
COMMENT ON COLUMN public.pagos.orden_detalle_oneclick IS
  'buy_order de detalle de Oneclick Mall, para el reembolso.';
COMMENT ON COLUMN public.pagos.cobro_reclamado_en IS
  'Marca exclusiva de una autorización Oneclick en curso.';

ALTER TABLE public.metodos_pago_oneclick
  ADD COLUMN IF NOT EXISTS url_inscripcion text,
  ADD COLUMN IF NOT EXISTS ticket_handoff text;

CREATE UNIQUE INDEX IF NOT EXISTS metodos_pago_oneclick_ticket_handoff_uidx
  ON public.metodos_pago_oneclick (ticket_handoff)
  WHERE ticket_handoff IS NOT NULL;

REVOKE ALL ON TABLE public.metodos_pago_oneclick FROM PUBLIC, anon, authenticated;
GRANT ALL ON TABLE public.metodos_pago_oneclick TO service_role;

-- -----------------------------------------------------------------------------
-- Intención del cliente (JWT). Si ya hay token Webpay, no se reutiliza la fila.
-- Si el pendiente no tiene token, el monto pasa a ser la tarifa vigente.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crear_intencion_pago(
  p_id_trabajo text,
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
  v_expected numeric;
  v_row public.pagos;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
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
      WHERE c.id_trabajo = v_job.id AND c.estado IN ('seleccionada', 'aceptada')
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

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
    AND estado IN ('retenido', 'autorizado')
  LIMIT 1;
  IF FOUND THEN
    RAISE EXCEPTION 'este trabajo ya tiene un pago en garantia';
  END IF;

  IF v_job.estado IS DISTINCT FROM 'esperando_pago' THEN
    RAISE EXCEPTION 'El trabajo ya no está pendiente de pago';
  END IF;

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
    AND estado = 'pendiente'
  ORDER BY creado_en DESC
  LIMIT 1;
  IF FOUND THEN
    IF v_row.token_tbk IS NOT NULL AND length(trim(v_row.token_tbk)) > 0
       AND COALESCE(v_row.metodo_pago, 'webpay') IS DISTINCT FROM 'oneclick' THEN
      RAISE EXCEPTION 'ya hay un cobro en curso para este trabajo';
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

REVOKE ALL ON FUNCTION public.crear_intencion_pago(text, numeric, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.crear_intencion_pago(text, numeric, text) TO authenticated;

-- -----------------------------------------------------------------------------
-- Misma validación, sin JWT. Solo el retorno de Transbank (service_role).
-- Los privilegios por defecto de Supabase dan EXECUTE a anon y authenticated;
-- REVOKE FROM PUBLIC no los quita.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crear_intencion_pago_servicio(
  p_id_usuario text,
  p_id_trabajo text,
  p_monto numeric
)
RETURNS public.pagos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_job public.trabajos;
  v_expected numeric;
  v_row public.pagos;
BEGIN
  IF p_id_usuario IS NULL OR length(trim(p_id_usuario)) = 0 THEN
    RAISE EXCEPTION 'usuario requerido';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id::text = p_id_trabajo;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trabajo no encontrado';
  END IF;

  IF v_job.id_usuario::text <> p_id_usuario THEN
    RAISE EXCEPTION 'Solo el cliente del trabajo puede crear la intención de pago';
  END IF;

  SELECT COALESCE(
    (SELECT c.monto_total_clp FROM public.propuestas_cotizacion c
      WHERE c.id_trabajo = v_job.id AND c.estado IN ('seleccionada', 'aceptada')
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

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
    AND estado IN ('retenido', 'autorizado')
  LIMIT 1;
  IF FOUND THEN
    RETURN v_row;
  END IF;

  IF v_job.estado IS DISTINCT FROM 'esperando_pago' THEN
    RAISE EXCEPTION 'El trabajo ya no está pendiente de pago';
  END IF;

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
    AND estado = 'pendiente'
  ORDER BY creado_en DESC
  LIMIT 1;
  IF FOUND THEN
    IF v_row.token_tbk IS NOT NULL AND length(trim(v_row.token_tbk)) > 0
       AND COALESCE(v_row.metodo_pago, 'webpay') IS DISTINCT FROM 'oneclick' THEN
      RAISE EXCEPTION 'ya hay un cobro en curso para este trabajo';
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
    creado_en, actualizado_en, ambiente
  ) VALUES (
    gen_random_uuid()::text,
    v_job.id,
    v_expected,
    'CLP',
    'pendiente',
    'principal',
    'oneclick',
    now(),
    now(),
    'integration'
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.crear_intencion_pago_servicio(text, text, numeric) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.crear_intencion_pago_servicio(text, text, numeric) FROM anon;
REVOKE ALL ON FUNCTION public.crear_intencion_pago_servicio(text, text, numeric) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.crear_intencion_pago_servicio(text, text, numeric) TO service_role;

-- Una sola autorización Oneclick por pago. El perdedor recibe en_curso.
CREATE OR REPLACE FUNCTION public.reclamar_cobro_oneclick(
  p_id_pago text,
  p_buy_order text,
  p_monto numeric
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.pagos;
BEGIN
  IF p_buy_order IS NULL OR length(trim(p_buy_order)) = 0 THEN
    RAISE EXCEPTION 'orden de cobro requerida';
  END IF;
  IF p_monto IS NULL OR p_monto <= 0 THEN
    RAISE EXCEPTION 'monto de cobro inválido';
  END IF;

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id::text = p_id_pago
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pago no encontrado';
  END IF;

  IF v_row.estado IN ('retenido', 'autorizado', 'liberado') THEN
    RETURN 'listo';
  END IF;

  IF v_row.estado <> 'pendiente' THEN
    RAISE EXCEPTION 'El pago no está pendiente';
  END IF;

  IF v_row.token_tbk IS NOT NULL AND length(trim(v_row.token_tbk)) > 0
     AND COALESCE(v_row.metodo_pago, 'webpay') IS DISTINCT FROM 'oneclick' THEN
    RAISE EXCEPTION 'ya hay un cobro en curso para este trabajo';
  END IF;

  IF v_row.cobro_reclamado_en IS NOT NULL
     AND v_row.cobro_reclamado_en > now() - interval '90 seconds'
     AND v_row.metodo_pago = 'oneclick'
     AND v_row.buy_order IS NOT NULL THEN
    RETURN 'en_curso';
  END IF;

  UPDATE public.pagos
    SET buy_order = p_buy_order,
        metodo_pago = 'oneclick',
        monto = p_monto,
        cobro_reclamado_en = now(),
        actualizado_en = now()
    WHERE id = v_row.id;

  RETURN 'reclamado';
END;
$$;

REVOKE ALL ON FUNCTION public.reclamar_cobro_oneclick(text, text, numeric) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reclamar_cobro_oneclick(text, text, numeric) FROM anon;
REVOKE ALL ON FUNCTION public.reclamar_cobro_oneclick(text, text, numeric) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.reclamar_cobro_oneclick(text, text, numeric) TO service_role;

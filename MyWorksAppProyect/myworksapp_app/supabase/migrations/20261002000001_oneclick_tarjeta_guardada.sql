-- Tarjeta Oneclick (Transbank). El tbk_user no sale al cliente.
CREATE TABLE IF NOT EXISTS public.metodos_pago_oneclick (
  id_usuario text PRIMARY KEY,
  username text NOT NULL,
  tbk_user text,
  tipo_tarjeta text,
  ultimos4 text,
  estado text NOT NULL DEFAULT 'pendiente',
  token_inscripcion text,
  id_trabajo_pendiente text,
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT metodos_pago_oneclick_estado_chk
    CHECK (estado IN ('pendiente', 'activa', 'rechazada'))
);

ALTER TABLE public.metodos_pago_oneclick ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.metodos_pago_oneclick FROM PUBLIC, anon, authenticated;
GRANT ALL ON TABLE public.metodos_pago_oneclick TO service_role;

-- Misma validación que crear_intencion_pago, para el retorno de Transbank
-- (ahí no hay JWT del cliente). Solo service_role.
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

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
    AND estado = 'pendiente'
  ORDER BY creado_en DESC
  LIMIT 1;
  IF FOUND THEN
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

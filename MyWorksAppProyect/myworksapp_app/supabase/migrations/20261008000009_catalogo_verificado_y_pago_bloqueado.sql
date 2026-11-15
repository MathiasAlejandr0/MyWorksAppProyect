-- El catálogo solo lista profesionales verificados.
-- crear_intencion_pago bloquea la fila del trabajo para cerrar la carrera
-- de dos cobros pendientes a la vez.

BEGIN;

CREATE OR REPLACE FUNCTION public.listar_profesionales_catalogo(
  p_categoria text DEFAULT NULL,
  p_zona text DEFAULT NULL,
  p_cursor_calificacion numeric DEFAULT NULL,
  p_cursor_id uuid DEFAULT NULL,
  p_limit integer DEFAULT 20
)
RETURNS TABLE (
  id_usuario uuid,
  profesion text,
  descripcion text,
  calificacion numeric,
  tarifa_visita numeric,
  categoria_servicio text,
  zona_trabajo text,
  nombre text,
  ruta_foto_perfil text,
  latitud_base double precision,
  longitud_base double precision,
  radio_servicio_km numeric,
  origen_base text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    t.id_usuario,
    t.profesion,
    t.descripcion,
    t.calificacion,
    t.tarifa_visita,
    t.categoria_servicio,
    t.zona_trabajo,
    p.nombre,
    p.ruta_foto_perfil,
    round(t.latitud_base::numeric, 3)::double precision,
    round(t.longitud_base::numeric, 3)::double precision,
    t.radio_servicio_km,
    t.origen_base
  FROM public.trabajadores t
  LEFT JOIN public.perfiles p ON p.id = t.id_usuario
  WHERE COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
    AND t.estado_verificacion = 'verificado'
    AND (
      p_categoria IS NULL
      OR btrim(p_categoria) = ''
      OR t.categoria_servicio = p_categoria
    )
    AND (
      p_zona IS NULL
      OR btrim(p_zona) = ''
      OR t.zona_trabajo ILIKE
        ('%' || replace(replace(btrim(p_zona), '%', ''), '_', '') || '%')
    )
    AND (
      p_cursor_id IS NULL
      OR COALESCE(t.calificacion, 0) < COALESCE(p_cursor_calificacion, 0)
      OR (
        COALESCE(t.calificacion, 0) = COALESCE(p_cursor_calificacion, 0)
        AND t.id_usuario > p_cursor_id
      )
    )
  ORDER BY COALESCE(t.calificacion, 0) DESC, t.id_usuario ASC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 40);
$$;

REVOKE ALL ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.categorias_con_disponibles()
RETURNS SETOF text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT t.categoria_servicio
  FROM public.trabajadores t
  WHERE COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
    AND t.estado_verificacion = 'verificado'
    AND t.categoria_servicio IS NOT NULL
    AND length(btrim(t.categoria_servicio)) > 0;
$$;

REVOKE ALL ON FUNCTION public.categorias_con_disponibles() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.categorias_con_disponibles() TO anon, authenticated;

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

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = p_id_trabajo
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trabajo no encontrado';
  END IF;

  IF v_job.id_usuario::text <> v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo el cliente del trabajo puede crear la intención de pago';
  END IF;

  v_expected := public.monto_esperado_trabajo(v_job);

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

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = p_id_trabajo
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trabajo no encontrado';
  END IF;

  IF v_job.id_usuario::text <> p_id_usuario THEN
    RAISE EXCEPTION 'Solo el cliente del trabajo puede crear la intención de pago';
  END IF;

  v_expected := public.monto_esperado_trabajo(v_job);

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

COMMIT;

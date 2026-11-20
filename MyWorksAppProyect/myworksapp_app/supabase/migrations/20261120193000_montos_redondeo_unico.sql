-- Un solo entero en CLP para el cobro.
-- El km del traslado se fija a 3 decimales antes de pasar el umbral de $0 / $3.000
-- y el de 30 km, así asin y atan2 no mueven el peso.
-- La tarifa se redondea a pesos y después se suma el traslado, para que
-- «tarifa + traslado» sea el total y la línea de tarifa sea el precio publicado.

CREATE OR REPLACE FUNCTION public.recargo_traslado_clp(
  p_lat_trabajador double precision,
  p_lng_trabajador double precision,
  p_lat_trabajo double precision,
  p_lng_trabajo double precision,
  p_radio_km numeric
) RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $$
DECLARE
  v_radius numeric;
  v_km numeric;
  v_extra numeric;
  v_raw integer;
BEGIN
  IF p_lat_trabajador IS NULL OR p_lng_trabajador IS NULL
     OR p_lat_trabajo IS NULL OR p_lng_trabajo IS NULL THEN
    RETURN 0;
  END IF;
  v_radius := CASE
    WHEN p_radio_km IS NULL OR p_radio_km <= 0 THEN 7
    ELSE p_radio_km
  END;
  v_km := round((public.km_entre_puntos(
    p_lat_trabajador, p_lng_trabajador, p_lat_trabajo, p_lng_trabajo
  ))::numeric, 3);
  IF v_km IS NULL THEN
    RETURN 0;
  END IF;
  IF v_km > 30 THEN
    RAISE EXCEPTION 'El trabajo queda a más de 30 km del profesional';
  END IF;
  v_extra := v_km - v_radius;
  IF v_extra <= 0 THEN
    RETURN 0;
  END IF;
  v_raw := round(v_extra * 1200)::integer;
  IF v_raw < 3000 THEN
    RETURN 3000;
  END IF;
  IF v_raw > 18000 THEN
    RETURN 18000;
  END IF;
  RETURN v_raw;
END;
$$;

-- 8 % en enteros. Para un monto entero coincide con round(numeric * 0.08)
-- y no depende del 0.08 binario.
CREATE OR REPLACE FUNCTION public.comision_orden_cambio_clp(p_monto integer)
RETURNS integer
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT CASE
    WHEN p_monto IS NULL OR p_monto <= 0 THEN 0
    ELSE (p_monto * 8 + 50) / 100
  END;
$$;

REVOKE ALL ON FUNCTION public.comision_orden_cambio_clp(integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.comision_orden_cambio_clp(integer) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.monto_esperado_trabajo(p_job trabajos)
 RETURNS numeric
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_expected numeric;
  v_worker public.trabajadores%ROWTYPE;
  v_rol text;
  v_estado text;
  v_meta jsonb;
  v_tier text;
  v_rate numeric;
  v_m2 numeric;
  v_unit text;
  v_service integer;
  v_hour integer;
  v_traslado integer;
BEGIN
  IF p_job.id_cotizacion_seleccionada IS NOT NULL
     OR COALESCE(p_job.modalidad_cobro, '') IN ('cotizacion_abierta', 'cotizacion') THEN
    IF p_job.id_cotizacion_seleccionada IS NULL OR p_job.id_trabajador IS NULL THEN
      RAISE EXCEPTION 'No hay cotizacion seleccionada para este trabajo';
    END IF;
    SELECT c.monto_total_clp INTO v_expected
    FROM public.propuestas_cotizacion c
    WHERE c.id::text = p_job.id_cotizacion_seleccionada::text
      AND c.id_trabajador::text = p_job.id_trabajador::text
      AND c.id_trabajo::text = p_job.id::text
      AND c.estado IN ('seleccionada', 'aceptada');
  ELSE
    SELECT w.* INTO v_worker FROM public.trabajadores w
    WHERE w.id_usuario::text = p_job.id_trabajador::text;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'No hay tarifa/cotizacion para validar el monto';
    END IF;
    IF COALESCE(v_worker.estado_verificacion, '') <> 'verificado' THEN
      RAISE EXCEPTION 'Este profesional todavia no esta verificado para cobrar';
    END IF;
    SELECT p.rol, p.estado_cuenta INTO v_rol, v_estado
    FROM public.perfiles p WHERE p.id = v_worker.id_usuario;
    IF COALESCE(v_worker.disponible, 0) <> 1
       OR COALESCE(v_worker.precios_configurados, 0) <> 1
       OR v_rol IS DISTINCT FROM 'trabajador'
       OR v_estado NOT IN ('activo', 'active') THEN
      RAISE EXCEPTION 'Este profesional no esta disponible para cobrar';
    END IF;
    BEGIN
      IF p_job.metadatos_servicio IS NOT NULL AND btrim(p_job.metadatos_servicio) <> '' THEN
        v_meta := p_job.metadatos_servicio::jsonb;
      END IF;
    EXCEPTION WHEN others THEN v_meta := NULL;
    END;
    IF v_meta IS NOT NULL AND v_meta->>'request_type' = 'worker_tier_invitation' THEN
      v_tier := v_meta->>'worker_tier_id';
      v_unit := COALESCE(v_meta->>'worker_tier_unit', '');
      IF v_tier = 'visita' THEN
        v_rate := v_worker.tarifa_visita;
        v_unit := 'fixed';
      ELSE
        SELECT pr.monto_clp INTO v_rate
        FROM public.trabajador_precios pr
        WHERE pr.id_usuario = v_worker.id_usuario AND pr.codigo = v_tier;
      END IF;
      IF v_rate IS NULL AND v_tier = 'construction_large_project' THEN
        SELECT pr.monto_clp INTO v_rate FROM public.trabajador_precios pr
        WHERE pr.id_usuario = v_worker.id_usuario AND pr.codigo = 'construction_per_sqm';
      ELSIF v_rate IS NULL AND v_tier = 'electrical_large_project' THEN
        SELECT pr.monto_clp INTO v_rate FROM public.trabajador_precios pr
        WHERE pr.id_usuario = v_worker.id_usuario AND pr.codigo = 'electrical_per_sqm';
      END IF;
      IF v_rate IS NULL THEN
        SELECT ex.monto_clp INTO v_rate
        FROM public.trabajador_servicios_extra ex
        WHERE ex.id_usuario = v_worker.id_usuario AND ex.id = v_tier
        LIMIT 1;
      END IF;
      IF v_rate IS NULL OR v_rate <= 0 THEN
        RAISE EXCEPTION 'Este profesional no publico esa tarifa';
      END IF;
      v_m2 := NULLIF(v_meta->>'worker_tier_square_meters', '')::numeric;
      IF v_unit = 'perSqm' AND COALESCE(v_m2, 0) > 0 THEN
        v_service := round(v_rate)::integer * round(v_m2)::integer;
      ELSE
        v_service := round(v_rate)::integer;
      END IF;
    ELSIF COALESCE(p_job.modalidad_cobro, '') = 'bloque_horas'
       AND COALESCE(p_job.horas_bloque, 0) IN (2, 4, 8) THEN
      -- Misma cuenta que la app: visita en pesos × 2,5, tope $15.000–$120.000,
      -- por las horas del bloque. Sin factor de comuna: el servidor no lo publica.
      v_hour := round(round(v_worker.tarifa_visita)::numeric * 2.5)::integer;
      IF v_hour < 15000 THEN
        v_hour := 15000;
      ELSIF v_hour > 120000 THEN
        v_hour := 120000;
      END IF;
      v_service := v_hour * p_job.horas_bloque::integer;
    ELSE
      v_service := round(v_worker.tarifa_visita)::integer;
    END IF;
    v_traslado := public.recargo_traslado_clp(
      v_worker.latitud_base, v_worker.longitud_base,
      p_job.latitud, p_job.longitud, v_worker.radio_servicio_km);
    v_expected := v_service + COALESCE(v_traslado, 0);
  END IF;
  IF v_expected IS NULL OR v_expected <= 0 THEN
    RAISE EXCEPTION 'No hay tarifa/cotizacion para validar el monto';
  END IF;
  RETURN v_expected;
END;
$function$;

CREATE OR REPLACE FUNCTION public.monto_esperado_trabajo_id(p_id text)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_job public.trabajos;
BEGIN
  SELECT * INTO v_job FROM public.trabajos WHERE id::text = p_id;
  IF NOT FOUND THEN
    RETURN 0;
  END IF;
  RETURN round(public.monto_esperado_trabajo(v_job))::integer;
END;
$$;

REVOKE ALL ON FUNCTION public.monto_esperado_trabajo_id(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.monto_esperado_trabajo_id(text) TO service_role;

-- Cotización de visita con la base real, sin devolver la coordenada.
CREATE OR REPLACE FUNCTION public.cotizar_visita_publica(
  p_trabajador uuid,
  p_lat double precision,
  p_lng double precision
) RETURNS TABLE (
  tarifa_clp integer,
  traslado_clp integer,
  total_clp integer,
  distancia_km numeric,
  fuera_de_alcance boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_worker public.trabajadores%ROWTYPE;
  v_tarifa integer;
  v_km numeric;
  v_traslado integer := 0;
BEGIN
  SELECT * INTO v_worker FROM public.trabajadores WHERE id_usuario = p_trabajador;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profesional no encontrado';
  END IF;
  IF COALESCE(v_worker.estado_verificacion, '') <> 'verificado'
     OR COALESCE(v_worker.disponible, 0) <> 1
     OR COALESCE(v_worker.precios_configurados, 0) <> 1 THEN
    RAISE EXCEPTION 'Este profesional no esta disponible para cobrar';
  END IF;
  v_tarifa := round(v_worker.tarifa_visita)::integer;
  IF v_tarifa IS NULL OR v_tarifa <= 0 THEN
    RAISE EXCEPTION 'El profesional no tiene tarifa de visita';
  END IF;
  v_km := round((public.km_entre_puntos(
    v_worker.latitud_base, v_worker.longitud_base, p_lat, p_lng
  ))::numeric, 3);
  IF v_km IS NOT NULL AND v_km > 30 THEN
    RETURN QUERY SELECT v_tarifa, 0, v_tarifa, v_km, true;
    RETURN;
  END IF;
  v_traslado := COALESCE(public.recargo_traslado_clp(
    v_worker.latitud_base, v_worker.longitud_base, p_lat, p_lng, v_worker.radio_servicio_km
  ), 0);
  RETURN QUERY SELECT v_tarifa, v_traslado, v_tarifa + v_traslado, v_km, false;
END;
$$;

REVOKE ALL ON FUNCTION public.cotizar_visita_publica(uuid, double precision, double precision)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cotizar_visita_publica(uuid, double precision, double precision)
  TO service_role;

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
  v_base integer;
  v_expected integer;
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

  v_base := round(COALESCE(v_order.monto_clp, 0))::integer;
  v_expected := v_base + public.comision_orden_cambio_clp(v_base);

  IF p_monto IS NULL OR p_monto <> v_expected THEN
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

CREATE OR REPLACE FUNCTION public.monto_a_cobrar_orden_cambio(p_id text)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_order public.ordenes_cambio;
  v_job public.trabajos;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_order FROM public.ordenes_cambio WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Orden de cambio no encontrada';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id = v_order.id_trabajo;
  IF NOT FOUND OR v_job.id_usuario IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Solo el cliente del trabajo puede ver este cobro';
  END IF;

  RETURN round(COALESCE(v_order.monto_clp, 0))::integer
    + public.comision_orden_cambio_clp(round(COALESCE(v_order.monto_clp, 0))::integer);
END;
$$;

COMMENT ON FUNCTION public.resumen_cobro_trabajo(text) IS
  'Total, tarifa, traslado, comisión y neto en CLP enteros. La tarifa ya está redondeada antes de sumar el traslado, así que tarifa + traslado = total.';

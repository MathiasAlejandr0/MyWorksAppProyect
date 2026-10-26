-- Recargo de traslado si el trabajo queda fuera del radar cercano del profesional.
-- Dentro del radio no se suma nada. Misma regla que shared/src/geo/transport.ts.

BEGIN;

CREATE OR REPLACE FUNCTION public.km_entre_puntos(
  p_lat1 double precision,
  p_lng1 double precision,
  p_lat2 double precision,
  p_lng2 double precision
) RETURNS double precision
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_lat1 IS NULL OR p_lng1 IS NULL OR p_lat2 IS NULL OR p_lng2 IS NULL
      THEN NULL
    ELSE
      6371 * 2 * asin(sqrt(
        power(sin(radians((p_lat2 - p_lat1) / 2)), 2) +
        cos(radians(p_lat1)) * cos(radians(p_lat2)) *
        power(sin(radians((p_lng2 - p_lng1) / 2)), 2)
      ))
  END;
$$;

CREATE OR REPLACE FUNCTION public.recargo_traslado_clp(
  p_lat_trabajador double precision,
  p_lng_trabajador double precision,
  p_lat_trabajo double precision,
  p_lng_trabajo double precision,
  p_radio_km numeric
) RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_radius numeric;
  v_km double precision;
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
  v_km := public.km_entre_puntos(
    p_lat_trabajador, p_lng_trabajador, p_lat_trabajo, p_lng_trabajo
  );
  IF v_km IS NULL THEN
    RETURN 0;
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

COMMENT ON FUNCTION public.recargo_traslado_clp(double precision, double precision, double precision, double precision, numeric) IS
  'CLP extra si el trabajo queda fuera del radio cercano. 0 si está dentro.';

CREATE OR REPLACE FUNCTION public.monto_esperado_trabajo(p_job public.trabajos)
RETURNS numeric
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
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
  v_tiers jsonb;
  v_custom jsonb;
  v_traslado integer;
BEGIN
  IF p_job.id_cotizacion_seleccionada IS NOT NULL
     OR COALESCE(p_job.modalidad_cobro, '') IN ('cotizacion_abierta', 'cotizacion') THEN
    IF p_job.id_cotizacion_seleccionada IS NULL OR p_job.id_trabajador IS NULL THEN
      RAISE EXCEPTION 'No hay cotización seleccionada para este trabajo';
    END IF;
    SELECT c.monto_total_clp INTO v_expected
    FROM public.propuestas_cotizacion c
    WHERE c.id::text = p_job.id_cotizacion_seleccionada::text
      AND c.id_trabajador::text = p_job.id_trabajador::text
      AND c.id_trabajo::text = p_job.id::text
      AND c.estado IN ('seleccionada', 'aceptada');
  ELSE
    SELECT w.* INTO v_worker
    FROM public.trabajadores w
    WHERE w.id_usuario::text = p_job.id_trabajador::text;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'No hay tarifa/cotización para validar el monto';
    END IF;

    IF COALESCE(v_worker.estado_verificacion, '') <> 'verificado' THEN
      RAISE EXCEPTION 'Este profesional todavía no está verificado para cobrar';
    END IF;

    SELECT p.rol, p.estado_cuenta INTO v_rol, v_estado
    FROM public.perfiles p
    WHERE p.id = v_worker.id_usuario;

    IF COALESCE(v_worker.disponible, 0) <> 1
       OR COALESCE(v_worker.precios_configurados, 0) <> 1
       OR v_rol IS DISTINCT FROM 'trabajador'
       OR v_estado NOT IN ('activo', 'active') THEN
      RAISE EXCEPTION 'Este profesional no está disponible para cobrar';
    END IF;

    BEGIN
      IF p_job.metadatos_servicio IS NOT NULL AND btrim(p_job.metadatos_servicio) <> '' THEN
        v_meta := p_job.metadatos_servicio::jsonb;
      END IF;
    EXCEPTION
      WHEN others THEN
        v_meta := NULL;
    END;

    IF v_meta IS NOT NULL AND v_meta->>'request_type' = 'worker_tier_invitation' THEN
      v_tier := v_meta->>'worker_tier_id';
      v_unit := COALESCE(v_meta->>'worker_tier_unit', '');
      v_tiers := COALESCE(v_worker.niveles_precio::jsonb, '{}'::jsonb);
      v_rate := NULLIF(v_tiers ->> v_tier, '')::numeric;
      IF v_rate IS NULL AND v_tier = 'construction_large_project' THEN
        v_rate := NULLIF(v_tiers ->> 'construction_per_sqm', '')::numeric;
      ELSIF v_rate IS NULL AND v_tier = 'electrical_large_project' THEN
        v_rate := NULLIF(v_tiers ->> 'electrical_per_sqm', '')::numeric;
      END IF;
      IF v_rate IS NULL THEN
        v_custom := COALESCE(v_worker.servicios_personalizados::jsonb, '[]'::jsonb);
        IF jsonb_typeof(v_custom) = 'array' THEN
          SELECT NULLIF(elem->>'priceClp', '')::numeric INTO v_rate
          FROM jsonb_array_elements(v_custom) elem
          WHERE elem->>'id' = v_tier
          LIMIT 1;
        END IF;
      END IF;
      IF v_rate IS NULL OR v_rate <= 0 THEN
        RAISE EXCEPTION 'Este profesional no publicó esa tarifa';
      END IF;
      v_m2 := NULLIF(v_meta->>'worker_tier_square_meters', '')::numeric;
      IF v_unit = 'perSqm' AND COALESCE(v_m2, 0) > 0 THEN
        v_expected := v_rate * v_m2;
      ELSE
        v_expected := v_rate;
      END IF;
    ELSE
      v_expected := v_worker.tarifa_visita;
    END IF;

    v_traslado := public.recargo_traslado_clp(
      v_worker.latitud_base,
      v_worker.longitud_base,
      p_job.latitud,
      p_job.longitud,
      v_worker.radio_servicio_km
    );
    v_expected := v_expected + COALESCE(v_traslado, 0);
  END IF;

  IF v_expected IS NULL OR v_expected <= 0 THEN
    RAISE EXCEPTION 'No hay tarifa/cotización para validar el monto';
  END IF;
  RETURN v_expected;
END;
$$;

REVOKE ALL ON FUNCTION public.km_entre_puntos(double precision, double precision, double precision, double precision) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.km_entre_puntos(double precision, double precision, double precision, double precision) TO postgres, service_role;

REVOKE ALL ON FUNCTION public.recargo_traslado_clp(double precision, double precision, double precision, double precision, numeric) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.recargo_traslado_clp(double precision, double precision, double precision, double precision, numeric) TO postgres, service_role;

REVOKE ALL ON FUNCTION public.monto_esperado_trabajo(public.trabajos) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.monto_esperado_trabajo(public.trabajos) TO postgres, service_role;

COMMIT;

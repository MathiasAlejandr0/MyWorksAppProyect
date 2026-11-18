-- Monto esperado de una invitación por tarifa (worker_tier_invitation).
-- El precio de cada variante sale de trabajador_precios (o de
-- trabajador_servicios_extra). La opción «visita» cobra la tarifa de visita del
-- profesional (trabajadores.tarifa_visita), la misma que cobra la web; la app la
-- ofrece cuando el profesional no publicó variantes ni servicios extra.

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
        -- Visita del profesional: su tarifa de visita publicada.
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
        v_expected := v_rate * v_m2;
      ELSE
        v_expected := v_rate;
      END IF;
    ELSE
      v_expected := v_worker.tarifa_visita;
    END IF;
    v_traslado := public.recargo_traslado_clp(
      v_worker.latitud_base, v_worker.longitud_base,
      p_job.latitud, p_job.longitud, v_worker.radio_servicio_km);
    v_expected := v_expected + COALESCE(v_traslado, 0);
  END IF;
  IF v_expected IS NULL OR v_expected <= 0 THEN
    RAISE EXCEPTION 'No hay tarifa/cotizacion para validar el monto';
  END IF;
  RETURN v_expected;
END;
$function$;

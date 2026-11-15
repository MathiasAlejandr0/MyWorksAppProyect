-- anon no conserva REFERENCES ni TRIGGER sobre trabajadores.
-- El catálogo cuenta trabajos completados.
-- monto_esperado distingue un profesional sin verificar y cobra la tarifa
-- publicada en niveles_precio cuando el pedido es una invitación por tarifa.

BEGIN;

REVOKE REFERENCES, TRIGGER ON TABLE public.trabajadores FROM anon;

DROP FUNCTION IF EXISTS public.listar_profesionales_catalogo(text, text, numeric, uuid, integer);

CREATE FUNCTION public.listar_profesionales_catalogo(
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
  origen_base text,
  trabajos_completados integer
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
    t.origen_base,
    (
      SELECT count(*)::integer
      FROM public.trabajos j
      WHERE j.id_trabajador = t.id_usuario
        AND j.estado = 'completado'
    ) AS trabajos_completados
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
  END IF;

  IF v_expected IS NULL OR v_expected <= 0 THEN
    RAISE EXCEPTION 'No hay tarifa/cotización para validar el monto';
  END IF;
  RETURN v_expected;
END;
$$;

REVOKE ALL ON FUNCTION public.monto_esperado_trabajo(public.trabajos) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.monto_esperado_trabajo(public.trabajos) TO postgres, service_role;

COMMIT;

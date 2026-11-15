-- El catálogo publicaba lat/lng redondeadas a ~100 m. El cobro usa la base
-- real, así que el extra de la web no coincidía (±1 CLP) y a veces cruzaba
-- el radar. Más de 30 km no se ofrece, ni con recargo.

BEGIN;

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
  trabajos_completados integer,
  score_listado numeric,
  prioridad_manual integer
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
    t.latitud_base,
    t.longitud_base,
    t.radio_servicio_km,
    t.origen_base,
    (
      SELECT count(*)::integer
      FROM public.trabajos j
      WHERE j.id_trabajador = t.id_usuario
        AND j.estado = 'completado'
    ) AS trabajos_completados,
    t.score_listado,
    t.prioridad_manual
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
      OR COALESCE(t.score_listado, 0) < COALESCE(p_cursor_calificacion, 0)
      OR (
        COALESCE(t.score_listado, 0) = COALESCE(p_cursor_calificacion, 0)
        AND t.id_usuario > p_cursor_id
      )
    )
  ORDER BY COALESCE(t.score_listado, 0) DESC, t.id_usuario ASC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 40);
$$;

REVOKE ALL ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) TO anon, authenticated;

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

COMMIT;

-- Orden único del catálogo: cercanía, luego calificación, luego precio.
--
-- La web, la app y cualquier otro cliente reciben a los profesionales en el
-- mismo orden porque el orden vive aquí, en listar_profesionales_catalogo.
-- Los clientes lo replican con el mismo comparador (shared/src/catalogOrder.ts
-- y lib/core/domain/catalog_order.dart) solo para reordenar sin volver a
-- pedir la lista cuando el cliente cambia su ubicación en pantalla.
--
-- Algoritmo (de mayor a menor prioridad):
--   1. banda_km ASC  = floor(distancia en km) entre la ubicación del cliente
--      (p_latitud, p_longitud: GPS, dirección o comuna) y la base pública del
--      profesional (coordenadas redondeadas a 2 decimales, ~1 km, las mismas
--      que ve el cliente). Distancia con haversine, radio 6371 km. Sin
--      ubicación del cliente o sin base del profesional, la banda es NULL y
--      va al final.
--   2. nota DESC     = promedio público de stats_profesional; 0 si todavía no
--      tiene reseñas.
--   3. tarifa_visita ASC (NULL al final).
--   4. id_usuario ASC, desempate estable para paginar.
-- Se usa la banda de 1 km y no la distancia exacta: la base pública ya está
-- redondeada a ~1 km, así que una diferencia menor es ruido, y con la
-- distancia exacta la nota y el precio casi nunca desempatarían.
-- El score_listado (rechazos, prioridad manual) ya no ordena el catálogo;
-- se sigue devolviendo para el panel de administración.
--
-- Paginación por desplazamiento (p_offset). p_cursor_calificacion y
-- p_cursor_id se aceptan solo para no romper clientes antiguos y se ignoran.

BEGIN;

DROP FUNCTION IF EXISTS public.listar_profesionales_catalogo(text, text, numeric, uuid, integer);

CREATE FUNCTION public.listar_profesionales_catalogo(
  p_categoria text DEFAULT NULL,
  p_zona text DEFAULT NULL,
  p_cursor_calificacion numeric DEFAULT NULL,
  p_cursor_id uuid DEFAULT NULL,
  p_limit integer DEFAULT 20,
  p_latitud double precision DEFAULT NULL,
  p_longitud double precision DEFAULT NULL,
  p_offset integer DEFAULT 0
)
RETURNS TABLE(
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
  prioridad_manual integer,
  radio_urbano_km numeric,
  tarifa_fuera_radio_clp integer,
  es_elite boolean,
  distancia_km double precision
)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT
    t.id_usuario,
    t.profesion,
    t.descripcion,
    s.calificacion,
    t.tarifa_visita,
    c.categoria,
    t.zona_trabajo,
    p.nombre,
    p.ruta_foto_perfil,
    CASE
      WHEN auth.uid() IS NOT NULL AND auth.uid() = t.id_usuario
        THEN t.latitud_base
      ELSE g.lat_pub
    END AS latitud_base,
    CASE
      WHEN auth.uid() IS NOT NULL AND auth.uid() = t.id_usuario
        THEN t.longitud_base
      ELSE g.lng_pub
    END AS longitud_base,
    t.radio_servicio_km,
    t.origen_base,
    s.trabajos_completados,
    t.score_listado,
    t.prioridad_manual,
    t.radio_urbano_km,
    t.tarifa_fuera_radio_clp,
    s.es_elite,
    d.km AS distancia_km
  FROM public.trabajadores t
  LEFT JOIN public.perfiles p ON p.id = t.id_usuario
  JOIN LATERAL public.stats_profesional(t.id_usuario) AS s ON true
  LEFT JOIN LATERAL (
    SELECT min(ts.categoria_servicio) AS categoria
    FROM public.trabajador_servicios ts
    WHERE ts.id_trabajador = t.id_usuario
      AND (p_categoria IS NULL OR btrim(p_categoria) = '' OR ts.categoria_servicio = p_categoria)
  ) c ON true
  CROSS JOIN LATERAL (
    SELECT
      round(t.latitud_base::numeric, 2)::double precision AS lat_pub,
      round(t.longitud_base::numeric, 2)::double precision AS lng_pub
  ) g
  CROSS JOIN LATERAL (
    SELECT CASE
      WHEN p_latitud IS NULL OR p_longitud IS NULL
        OR g.lat_pub IS NULL OR g.lng_pub IS NULL
        THEN NULL::double precision
      ELSE 6371 * 2 * atan2(
        sqrt(h.a), sqrt(1 - h.a)
      )
    END AS km
    FROM (
      SELECT
        power(sin(radians(g.lat_pub - p_latitud) / 2), 2)
        + cos(radians(p_latitud)) * cos(radians(g.lat_pub))
          * power(sin(radians(g.lng_pub - p_longitud) / 2), 2) AS a
    ) h
  ) d
  WHERE COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
    AND t.estado_verificacion = 'verificado'
    AND (s.n_calificaciones = 0 OR COALESCE(s.calificacion, 0) >= 3)
    AND (
      p_categoria IS NULL
      OR btrim(p_categoria) = ''
      OR c.categoria IS NOT NULL
    )
    AND (
      p_zona IS NULL
      OR btrim(p_zona) = ''
      OR t.zona_trabajo ILIKE
        ('%' || replace(replace(btrim(p_zona), '%', ''), '_', '') || '%')
    )
  ORDER BY
    floor(d.km) ASC NULLS LAST,
    CASE WHEN COALESCE(s.n_calificaciones, 0) > 0 THEN COALESCE(s.calificacion, 0) ELSE 0 END DESC,
    t.tarifa_visita ASC NULLS LAST,
    t.id_usuario ASC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 40)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
$function$;

COMMENT ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) IS
  'Catálogo público. Orden único: banda de 1 km de cercanía ASC (NULL al final), nota pública DESC (0 sin reseñas), tarifa_visita ASC, id_usuario ASC. p_cursor_* se ignoran; paginar con p_offset.';

REVOKE ALL ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) TO anon, authenticated;

COMMIT;

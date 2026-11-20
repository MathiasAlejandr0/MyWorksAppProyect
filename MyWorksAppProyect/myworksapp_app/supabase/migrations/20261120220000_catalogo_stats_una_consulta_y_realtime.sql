-- Capacidad: las cifras públicas del catálogo se calculan una sola vez,
-- con la misma definición que privado.stats_profesional, y Realtime deja
-- de replicar tablas a las que ni la web ni la app se suscriben.
-- No cambia comisiones, demo_modo, pagos ni la forma de las respuestas.

BEGIN;

-- Misma fórmula que privado.stats_profesional (20261116044049), en dos
-- agregados para todo el lote. Una fila por elemento de p_ids, en ese
-- orden, también si el id viene repetido o es NULL.
CREATE OR REPLACE FUNCTION privado.stats_profesionales(p_ids uuid[])
RETURNS TABLE (
  id_usuario uuid,
  calificacion numeric,
  n_calificaciones integer,
  trabajos_completados integer,
  es_elite boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  WITH ids AS (
    SELECT u.id, u.ord
    FROM unnest(COALESCE(p_ids, ARRAY[]::uuid[])) WITH ORDINALITY AS u(id, ord)
  ),
  jobs AS (
    SELECT
      t.id_trabajador AS id,
      count(*) FILTER (WHERE t.estado = 'completado')::integer AS n
    FROM public.trabajos t
    WHERE t.id_trabajador IN (SELECT i.id FROM ids i WHERE i.id IS NOT NULL)
    GROUP BY t.id_trabajador
  ),
  reviews AS (
    SELECT
      tr.id_trabajador AS id,
      round(avg(c.puntaje)::numeric, 2) AS promedio,
      count(*)::integer AS n
    FROM public.trabajos tr
    JOIN public.calificaciones c ON tr.id::text = c.id_trabajo::text
    WHERE tr.id_trabajador IN (SELECT i.id FROM ids i WHERE i.id IS NOT NULL)
      AND COALESCE(c.direccion, 'cliente_a_trabajador') = 'cliente_a_trabajador'
      AND c.estado_revision IS DISTINCT FROM 'excluida'
    GROUP BY tr.id_trabajador
  )
  SELECT
    ids.id,
    reviews.promedio,
    COALESCE(reviews.n, 0),
    COALESCE(jobs.n, 0),
    (COALESCE(reviews.promedio, 0) >= 4.7 AND COALESCE(jobs.n, 0) >= 5)
  FROM ids
  LEFT JOIN jobs ON jobs.id = ids.id
  LEFT JOIN reviews ON reviews.id = ids.id
  ORDER BY ids.ord;
$$;

REVOKE ALL ON FUNCTION privado.stats_profesionales(uuid[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION privado.stats_profesionales(uuid[]) TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION privado.stats_profesional(p_id uuid)
RETURNS TABLE (
  id_usuario uuid,
  calificacion numeric,
  n_calificaciones integer,
  trabajos_completados integer,
  es_elite boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    s.id_usuario,
    s.calificacion,
    s.n_calificaciones,
    s.trabajos_completados,
    s.es_elite
  FROM privado.stats_profesionales(ARRAY[p_id]) AS s;
$$;

CREATE OR REPLACE FUNCTION public.stats_profesionales(p_ids uuid[])
RETURNS TABLE (
  id_usuario uuid,
  calificacion numeric,
  n_calificaciones integer,
  trabajos_completados integer,
  es_elite boolean
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path TO 'public'
AS $$
  SELECT
    s.id_usuario,
    s.calificacion,
    s.n_calificaciones,
    s.trabajos_completados,
    s.es_elite
  FROM privado.stats_profesionales(p_ids) AS s;
$$;

REVOKE ALL ON FUNCTION public.stats_profesionales(uuid[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.stats_profesionales(uuid[]) TO anon, authenticated, service_role;

-- Misma firma, filtros, redondeo y orden que 20261120140000.
-- Las cifras salen del lote, no de una llamada por profesional.
CREATE OR REPLACE FUNCTION public.listar_profesionales_catalogo(
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
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  WITH base AS (
    SELECT
      t.id_usuario,
      t.profesion,
      t.descripcion,
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
      t.score_listado,
      t.prioridad_manual,
      t.radio_urbano_km,
      t.tarifa_fuera_radio_clp,
      d.km AS distancia_km
    FROM public.trabajadores t
    LEFT JOIN public.perfiles p ON p.id = t.id_usuario
    CROSS JOIN LATERAL (
      SELECT public.catalogo_muestra_profesional(t.es_demo) AS visible
    ) vis
    LEFT JOIN LATERAL (
      SELECT min(ts.categoria_servicio) AS categoria
      FROM public.trabajador_servicios ts
      WHERE ts.id_trabajador = t.id_usuario
        AND (
          p_categoria IS NULL
          OR btrim(p_categoria) = ''
          OR ts.categoria_servicio = p_categoria
        )
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
    WHERE vis.visible
      AND COALESCE(t.disponible, 0) = 1
      AND COALESCE(t.precios_configurados, 0) = 1
      AND t.estado_verificacion = 'verificado'
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
  ),
  cifras AS (
    SELECT s.*
    FROM privado.stats_profesionales(
      COALESCE((SELECT array_agg(b.id_usuario) FROM base b), ARRAY[]::uuid[])
    ) AS s
  )
  SELECT
    b.id_usuario,
    b.profesion,
    b.descripcion,
    s.calificacion,
    b.tarifa_visita,
    b.categoria,
    b.zona_trabajo,
    b.nombre,
    b.ruta_foto_perfil,
    b.latitud_base,
    b.longitud_base,
    b.radio_servicio_km,
    b.origen_base,
    s.trabajos_completados,
    b.score_listado,
    b.prioridad_manual,
    b.radio_urbano_km,
    b.tarifa_fuera_radio_clp,
    s.es_elite,
    b.distancia_km
  FROM base b
  JOIN cifras s ON s.id_usuario = b.id_usuario
  WHERE s.n_calificaciones = 0 OR COALESCE(s.calificacion, 0) >= 3
  ORDER BY
    floor(b.distancia_km) ASC NULLS LAST,
    CASE
      WHEN COALESCE(s.n_calificaciones, 0) > 0 THEN COALESCE(s.calificacion, 0)
      ELSE 0
    END DESC,
    NULLIF(b.tarifa_visita, 0) ASC NULLS LAST,
    b.id_usuario ASC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 40)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
$function$;

COMMENT ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) IS
  'Catálogo público. Con demo_modo distinto de 1 omite es_demo. Orden único: banda de 1 km, nota, tarifa (0 o NULL al final), id. p_cursor_* se ignoran; paginar con p_offset. Las cifras salen de un solo agregado.';

REVOKE ALL ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) TO anon, authenticated;

-- Suscripciones encontradas en web y Flutter:
--   mensajes (chat), ubicacion_en_vivo (mapa), notificaciones (campana).
-- La consola de escritorio no abre canales. Lo demás sale de la publicación
-- para que el WAL de Realtime no lo decodifique. No se agrega ninguna tabla.
DO $realtime$
DECLARE
  r record;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    RETURN;
  END IF;

  FOR r IN
    SELECT schemaname, tablename
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND NOT (
        schemaname = 'public'
        AND tablename IN ('mensajes', 'ubicacion_en_vivo', 'notificaciones')
      )
  LOOP
    EXECUTE format(
      'ALTER PUBLICATION supabase_realtime DROP TABLE %I.%I',
      r.schemaname,
      r.tablename
    );
  END LOOP;
END;
$realtime$;

COMMIT;

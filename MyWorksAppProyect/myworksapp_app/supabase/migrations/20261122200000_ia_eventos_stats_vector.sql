-- Fase 0 de IA: eventos de uso, vista de estadísticas y extensión vector.
-- No aplicar en el proyecto remoto wxqrfcqifkfgawrnqmnj (plan gratis, sin OK).
-- La vista reemplaza la llamada a stats_profesional por cada profesional
-- dentro de listar_profesionales_catalogo. Se refresca cada hora.

BEGIN;

CREATE SCHEMA IF NOT EXISTS extensions;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'vector'
  ) THEN
    CREATE EXTENSION vector WITH SCHEMA extensions;
  END IF;
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'vector no se pudo crear: %', SQLERRM;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'vector' AND n.nspname = 'public'
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'vector' AND n.nspname = 'extensions'
  ) THEN
    ALTER EXTENSION vector SET SCHEMA extensions;
  END IF;
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'vector sigue fuera de extensions: %', SQLERRM;
END $$;

CREATE TABLE IF NOT EXISTS public.eventos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.perfiles (id) ON DELETE CASCADE,
  tipo text NOT NULL CHECK (
    tipo IN (
      'busqueda',
      'vista_perfil',
      'click',
      'contratacion',
      'cancelacion',
      'disputa',
      'resena'
    )
  ),
  entidad_id text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  comuna text,
  categoria text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS eventos_usuario_creado_idx
  ON public.eventos (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS eventos_tipo_creado_idx
  ON public.eventos (tipo, created_at DESC);
CREATE INDEX IF NOT EXISTS eventos_categoria_idx
  ON public.eventos (categoria, created_at DESC)
  WHERE categoria IS NOT NULL;
CREATE INDEX IF NOT EXISTS eventos_entidad_idx
  ON public.eventos (entidad_id)
  WHERE entidad_id IS NOT NULL;

ALTER TABLE public.eventos ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.eventos FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT ON public.eventos TO authenticated;
GRANT SELECT, INSERT ON public.eventos TO service_role;

DROP POLICY IF EXISTS eventos_insert_propio ON public.eventos;
CREATE POLICY eventos_insert_propio
  ON public.eventos
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS eventos_select_propio_o_admin ON public.eventos;
CREATE POLICY eventos_select_propio_o_admin
  ON public.eventos
  FOR SELECT
  TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR (SELECT public.is_admin())
  );

CREATE OR REPLACE FUNCTION public.eventos_sanitizar()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    NEW.user_id := auth.uid();
  END IF;
  NEW.metadata := COALESCE(NEW.metadata, '{}'::jsonb)
    - 'rut' - 'correo' - 'email' - 'telefono' - 'password' - 'clave'
    - 'numero_cuenta' - 'rut_titular' - 'nombre_titular';
  IF octet_length(NEW.metadata::text) > 2000 THEN
    NEW.metadata := jsonb_build_object('recortado', true);
  END IF;
  NEW.entidad_id := NULLIF(left(btrim(COALESCE(NEW.entidad_id, '')), 80), '');
  NEW.comuna := NULLIF(left(btrim(COALESCE(NEW.comuna, '')), 80), '');
  NEW.categoria := NULLIF(left(btrim(COALESCE(NEW.categoria, '')), 40), '');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS eventos_sanitizar ON public.eventos;
CREATE TRIGGER eventos_sanitizar
  BEFORE INSERT ON public.eventos
  FOR EACH ROW
  EXECUTE FUNCTION public.eventos_sanitizar();

CREATE OR REPLACE FUNCTION public.registrar_evento(
  p_tipo text,
  p_entidad_id text DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb,
  p_comuna text DEFAULT NULL,
  p_categoria text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN;
  END IF;
  IF btrim(COALESCE(p_tipo, '')) NOT IN (
    'busqueda', 'vista_perfil', 'click', 'contratacion',
    'cancelacion', 'disputa', 'resena'
  ) THEN
    RETURN;
  END IF;
  INSERT INTO public.eventos (user_id, tipo, entidad_id, metadata, comuna, categoria)
  VALUES (
    auth.uid(),
    btrim(p_tipo),
    p_entidad_id,
    COALESCE(p_metadata, '{}'::jsonb),
    p_comuna,
    p_categoria
  );
EXCEPTION
  WHEN others THEN
    RETURN;
END;
$$;

REVOKE ALL ON FUNCTION public.registrar_evento(text, text, jsonb, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_evento(text, text, jsonb, text, text) TO authenticated;

COMMENT ON FUNCTION public.registrar_evento(text, text, jsonb, text, text) IS
  'Registra un evento del usuario actual. Un tipo inválido o un fallo no interrumpe la app.';

CREATE SCHEMA IF NOT EXISTS privado;
REVOKE ALL ON SCHEMA privado FROM PUBLIC;
GRANT USAGE ON SCHEMA privado TO service_role;

CREATE OR REPLACE FUNCTION privado.texto_a_timestamptz(p_valor text)
RETURNS timestamptz
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $$
BEGIN
  IF p_valor IS NULL OR p_valor !~ '^\d{4}-\d{2}-\d{2}' THEN
    RETURN NULL;
  END IF;
  RETURN p_valor::timestamptz;
EXCEPTION
  WHEN others THEN
    RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION privado.texto_a_timestamptz(text) FROM PUBLIC;

CREATE MATERIALIZED VIEW public.mv_stats_profesional AS
WITH trabajos_agg AS (
  SELECT
    t.id_trabajador AS id_usuario,
    count(*) FILTER (WHERE t.estado = 'completado')::integer AS trabajos_completados,
    count(*) FILTER (WHERE t.estado = 'cancelado')::integer AS cancelados,
    count(*) FILTER (WHERE t.estado IN ('completado', 'cancelado'))::integer AS cerrados
  FROM public.trabajos t
  WHERE t.id_trabajador IS NOT NULL
  GROUP BY t.id_trabajador
),
resenas AS (
  SELECT
    t.id_trabajador AS id_usuario,
    round(avg(c.puntaje)::numeric, 2) AS calificacion,
    count(*)::integer AS n_calificaciones
  FROM public.calificaciones c
  JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
  WHERE t.id_trabajador IS NOT NULL
    AND COALESCE(c.direccion, 'cliente_a_trabajador') = 'cliente_a_trabajador'
    AND c.estado_revision IS DISTINCT FROM 'excluida'
  GROUP BY t.id_trabajador
),
disputas_agg AS (
  SELECT t.id_trabajador AS id_usuario, count(*)::integer AS disputas
  FROM public.disputas d
  JOIN public.trabajos t ON t.id::text = d.id_trabajo::text
  WHERE t.id_trabajador IS NOT NULL
  GROUP BY t.id_trabajador
),
respuesta AS (
  SELECT
    t.id_trabajador AS id_usuario,
    round(avg(
      EXTRACT(EPOCH FROM (
        privado.texto_a_timestamptz(m.creado_en) - privado.texto_a_timestamptz(t.creado_en)
      )) / 3600.0
    )::numeric, 2) AS tiempo_respuesta_horas
  FROM public.trabajos t
  JOIN LATERAL (
    SELECT m.creado_en
    FROM public.mensajes m
    WHERE m.id_trabajo = t.id
      AND m.id_remitente = t.id_trabajador
    ORDER BY m.creado_en ASC
    LIMIT 1
  ) m ON true
  WHERE privado.texto_a_timestamptz(t.creado_en) IS NOT NULL
    AND privado.texto_a_timestamptz(m.creado_en) IS NOT NULL
  GROUP BY t.id_trabajador
)
SELECT
  w.id_usuario,
  r.calificacion,
  COALESCE(r.n_calificaciones, 0) AS n_calificaciones,
  COALESCE(j.trabajos_completados, 0) AS trabajos_completados,
  (COALESCE(r.calificacion, 0) >= 4.7 AND COALESCE(j.trabajos_completados, 0) >= 5) AS es_elite,
  CASE
    WHEN COALESCE(j.cerrados, 0) = 0 THEN 0::numeric
    ELSE round(COALESCE(j.cancelados, 0)::numeric / j.cerrados, 4)
  END AS tasa_cancelacion,
  resp.tiempo_respuesta_horas,
  COALESCE(d.disputas, 0) AS disputas
FROM public.trabajadores w
LEFT JOIN trabajos_agg j ON j.id_usuario = w.id_usuario
LEFT JOIN resenas r ON r.id_usuario = w.id_usuario
LEFT JOIN disputas_agg d ON d.id_usuario = w.id_usuario
LEFT JOIN respuesta resp ON resp.id_usuario = w.id_usuario
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS mv_stats_profesional_id_idx
  ON public.mv_stats_profesional (id_usuario);

REVOKE ALL ON public.mv_stats_profesional FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.mv_stats_profesional TO service_role;

COMMENT ON MATERIALIZED VIEW public.mv_stats_profesional IS
  'Cifras públicas del profesional en un solo pase. La refresca pg_cron cada hora. No es una API.';

CREATE OR REPLACE FUNCTION public.refrescar_mv_stats_profesional()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_stats_profesional;
  EXCEPTION
    WHEN others THEN
      REFRESH MATERIALIZED VIEW public.mv_stats_profesional;
  END;
END;
$$;

REVOKE ALL ON FUNCTION public.refrescar_mv_stats_profesional() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.refrescar_mv_stats_profesional() TO service_role;

-- Misma firma y el mismo orden que 20261120140000. Las cifras salen de la vista.
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
  LEFT JOIN public.mv_stats_profesional mv ON mv.id_usuario = t.id_usuario
  CROSS JOIN LATERAL (
    SELECT
      mv.calificacion AS calificacion,
      COALESCE(mv.n_calificaciones, 0) AS n_calificaciones,
      COALESCE(mv.trabajos_completados, 0) AS trabajos_completados,
      COALESCE(mv.es_elite, false) AS es_elite
  ) s
  CROSS JOIN LATERAL (
    SELECT public.catalogo_muestra_profesional(t.es_demo) AS visible
  ) vis
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
  WHERE vis.visible
    AND COALESCE(t.disponible, 0) = 1
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
    NULLIF(t.tarifa_visita, 0) ASC NULLS LAST,
    t.id_usuario ASC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 40)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
$function$;

COMMENT ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) IS
  'Catálogo público. Lee mv_stats_profesional (refresco horario) en vez de stats_profesional por fila. Orden: banda de 1 km, nota, tarifa, id.';

REVOKE ALL ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) TO anon, authenticated;

DO $cron$
BEGIN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
  EXCEPTION
    WHEN others THEN
      RAISE NOTICE 'pg_cron no se pudo crear: %', SQLERRM;
  END;

  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'ia_refrescar_mv_stats') THEN
      PERFORM cron.unschedule('ia_refrescar_mv_stats');
    END IF;
    PERFORM cron.schedule(
      'ia_refrescar_mv_stats',
      '0 * * * *',
      'SELECT public.refrescar_mv_stats_profesional();'
    );
  ELSE
    RAISE NOTICE 'pg_cron no está instalado. Programa SELECT public.refrescar_mv_stats_profesional(); cada hora.';
  END IF;
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'No se programó el refresco de stats: %', SQLERRM;
END;
$cron$;

COMMIT;

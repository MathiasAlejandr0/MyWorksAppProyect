-- Fase 1: embeddings de 384 dimensiones y búsqueda híbrida.
-- No aplicar en wxqrfcqifkfgawrnqmnj sin el OK de Mathias.
-- El vector provisional es un hash local. gte-small (función embed) lo reemplaza.
-- trabajos es la solicitud del cliente: no existe una tabla solicitudes.

BEGIN;

CREATE TABLE IF NOT EXISTS public.ia_pesos_busqueda (
  clave text PRIMARY KEY CHECK (clave IN ('similitud', 'cercania', 'nota', 'confiabilidad')),
  peso numeric NOT NULL CHECK (peso >= 0 AND peso <= 1),
  descripcion text NOT NULL
);

ALTER TABLE public.ia_pesos_busqueda ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ia_pesos_busqueda FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.ia_pesos_busqueda TO authenticated;

DROP POLICY IF EXISTS ia_pesos_select_admin ON public.ia_pesos_busqueda;
CREATE POLICY ia_pesos_select_admin
  ON public.ia_pesos_busqueda
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_admin()));

INSERT INTO public.ia_pesos_busqueda (clave, peso, descripcion)
VALUES
  ('similitud', 0.45, 'Coseno del embedding, o parecido del texto si aún no hay gte-small'),
  ('cercania', 0.25, 'Qué tan cerca está la base del cliente'),
  ('nota', 0.20, 'Nota pública de mv_stats_profesional'),
  ('confiabilidad', 0.10, 'Menos cancelaciones, disputas y demora en responder')
ON CONFLICT (clave) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.ia_cola_embeddings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tabla text NOT NULL CHECK (tabla IN ('trabajadores', 'trabajos')),
  entidad_id text NOT NULL,
  texto text NOT NULL,
  estado text NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'listo', 'error')),
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ia_cola_embeddings_pendiente_idx
  ON public.ia_cola_embeddings (creado_en)
  WHERE estado = 'pendiente';

ALTER TABLE public.ia_cola_embeddings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ia_cola_embeddings FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.ia_cola_embeddings TO service_role;

ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS embedding extensions.vector(384),
  ADD COLUMN IF NOT EXISTS embedding_origen text;

ALTER TABLE public.trabajadores
  DROP CONSTRAINT IF EXISTS trabajadores_embedding_origen_chk;
ALTER TABLE public.trabajadores
  ADD CONSTRAINT trabajadores_embedding_origen_chk
  CHECK (embedding_origen IS NULL OR embedding_origen IN ('hash', 'gte-small'));

ALTER TABLE public.trabajos
  ADD COLUMN IF NOT EXISTS embedding extensions.vector(384),
  ADD COLUMN IF NOT EXISTS embedding_origen text;

ALTER TABLE public.trabajos
  DROP CONSTRAINT IF EXISTS trabajos_embedding_origen_chk;
ALTER TABLE public.trabajos
  ADD CONSTRAINT trabajos_embedding_origen_chk
  CHECK (embedding_origen IS NULL OR embedding_origen IN ('hash', 'gte-small'));

CREATE INDEX IF NOT EXISTS trabajadores_embedding_hnsw
  ON public.trabajadores
  USING hnsw (embedding extensions.vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

CREATE INDEX IF NOT EXISTS trabajos_embedding_hnsw
  ON public.trabajos
  USING hnsw (embedding extensions.vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

CREATE OR REPLACE FUNCTION privado.embedding_hash(p_texto text)
RETURNS extensions.vector
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_nums float8[] := ARRAY[]::float8[];
  i integer;
  h text;
  n float8;
  norma float8 := 0;
  v_txt text;
BEGIN
  FOR i IN 0..383 LOOP
    h := md5(coalesce(p_texto, '') || ':' || i::text);
    n := (((('x' || substr(h, 1, 8))::bit(32)::bigint) % 2000000) - 1000000)::float8 / 1000000.0;
    v_nums := v_nums || n;
    norma := norma + (n * n);
  END LOOP;
  norma := sqrt(GREATEST(norma, 1e-12));
  SELECT string_agg(trim(to_char(x / norma, 'FM999990.000000')), ',')
    INTO v_txt
  FROM unnest(v_nums) AS x;
  RETURN ('[' || v_txt || ']')::extensions.vector;
END;
$$;

REVOKE ALL ON FUNCTION privado.embedding_hash(text) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.trabajadores_preparar_embedding()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_texto text;
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.profesion IS NOT DISTINCT FROM OLD.profesion
     AND NEW.descripcion IS NOT DISTINCT FROM OLD.descripcion
     AND NEW.embedding IS NOT NULL THEN
    RETURN NEW;
  END IF;
  v_texto := left(btrim(coalesce(NEW.profesion, '') || ' ' || coalesce(NEW.descripcion, '')), 2000);
  NEW.embedding := privado.embedding_hash(v_texto);
  NEW.embedding_origen := 'hash';
  INSERT INTO public.ia_cola_embeddings (tabla, entidad_id, texto)
  VALUES ('trabajadores', NEW.id_usuario::text, v_texto);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajadores_preparar_embedding ON public.trabajadores;
CREATE TRIGGER trabajadores_preparar_embedding
  BEFORE INSERT OR UPDATE OF profesion, descripcion ON public.trabajadores
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajadores_preparar_embedding();

CREATE OR REPLACE FUNCTION public.trabajos_preparar_embedding()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_texto text;
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.descripcion IS NOT DISTINCT FROM OLD.descripcion
     AND NEW.embedding IS NOT NULL THEN
    RETURN NEW;
  END IF;
  v_texto := left(btrim(coalesce(NEW.descripcion, '')), 2000);
  NEW.embedding := privado.embedding_hash(v_texto);
  NEW.embedding_origen := 'hash';
  INSERT INTO public.ia_cola_embeddings (tabla, entidad_id, texto)
  VALUES ('trabajos', NEW.id::text, v_texto);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajos_preparar_embedding ON public.trabajos;
CREATE TRIGGER trabajos_preparar_embedding
  BEFORE INSERT OR UPDATE OF descripcion ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_preparar_embedding();

CREATE OR REPLACE FUNCTION public.ia_guardar_embedding(
  p_tabla text,
  p_id text,
  p_vector text,
  p_origen text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v extensions.vector;
BEGIN
  IF coalesce(auth.role(), '') IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_tabla NOT IN ('trabajadores', 'trabajos') THEN
    RAISE EXCEPTION 'tabla no permitida';
  END IF;
  IF p_origen NOT IN ('hash', 'gte-small') THEN
    RAISE EXCEPTION 'origen no permitido';
  END IF;
  v := p_vector::extensions.vector;
  IF vector_dims(v) <> 384 THEN
    RAISE EXCEPTION 'el embedding tiene que tener 384 dimensiones';
  END IF;
  IF p_tabla = 'trabajadores' THEN
    UPDATE public.trabajadores
    SET embedding = v, embedding_origen = p_origen
    WHERE id_usuario::text = btrim(p_id);
  ELSE
    UPDATE public.trabajos
    SET embedding = v, embedding_origen = p_origen
    WHERE id::text = btrim(p_id);
  END IF;
  UPDATE public.ia_cola_embeddings
  SET estado = 'listo'
  WHERE tabla = p_tabla AND entidad_id = btrim(p_id) AND estado = 'pendiente';
END;
$$;

REVOKE ALL ON FUNCTION public.ia_guardar_embedding(text, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.ia_guardar_embedding(text, text, text, text) TO service_role;

CREATE OR REPLACE FUNCTION public.buscar_profesionales_hibrido(
  p_q text DEFAULT NULL,
  p_lat double precision DEFAULT NULL,
  p_lng double precision DEFAULT NULL,
  p_categoria text DEFAULT NULL,
  p_embedding extensions.vector DEFAULT NULL,
  p_limit integer DEFAULT 20
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
  distancia_km double precision,
  similitud numeric,
  puntaje numeric,
  modo text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_q text := left(replace(replace(btrim(coalesce(p_q, '')), '%', ''), '_', ''), 80);
  v_lim integer := LEAST(GREATEST(coalesce(p_limit, 20), 1), 40);
  w_sim numeric := 0.45;
  w_cerca numeric := 0.25;
  w_nota numeric := 0.20;
  w_conf numeric := 0.10;
BEGIN
  SELECT peso INTO w_sim FROM public.ia_pesos_busqueda WHERE clave = 'similitud';
  SELECT peso INTO w_cerca FROM public.ia_pesos_busqueda WHERE clave = 'cercania';
  SELECT peso INTO w_nota FROM public.ia_pesos_busqueda WHERE clave = 'nota';
  SELECT peso INTO w_conf FROM public.ia_pesos_busqueda WHERE clave = 'confiabilidad';
  w_sim := coalesce(w_sim, 0.45);
  w_cerca := coalesce(w_cerca, 0.25);
  w_nota := coalesce(w_nota, 0.20);
  w_conf := coalesce(w_conf, 0.10);

  RETURN QUERY
  WITH base AS (
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
        WHEN auth.uid() IS NOT NULL AND auth.uid() = t.id_usuario THEN t.latitud_base
        ELSE round(t.latitud_base::numeric, 2)::double precision
      END AS latitud_base,
      CASE
        WHEN auth.uid() IS NOT NULL AND auth.uid() = t.id_usuario THEN t.longitud_base
        ELSE round(t.longitud_base::numeric, 2)::double precision
      END AS longitud_base,
      t.radio_servicio_km,
      t.origen_base,
      s.trabajos_completados,
      t.score_listado,
      t.prioridad_manual,
      t.radio_urbano_km,
      t.tarifa_fuera_radio_clp,
      s.es_elite,
      t.embedding,
      t.embedding_origen,
      s.tasa_cancelacion,
      s.tiempo_respuesta_horas,
      s.disputas,
      s.n_calificaciones
    FROM public.trabajadores t
    LEFT JOIN public.perfiles p ON p.id = t.id_usuario
    LEFT JOIN public.mv_stats_profesional mv ON mv.id_usuario = t.id_usuario
    CROSS JOIN LATERAL (
      SELECT
        mv.calificacion AS calificacion,
        COALESCE(mv.n_calificaciones, 0) AS n_calificaciones,
        COALESCE(mv.trabajos_completados, 0) AS trabajos_completados,
        COALESCE(mv.es_elite, false) AS es_elite,
        COALESCE(mv.tasa_cancelacion, 0) AS tasa_cancelacion,
        mv.tiempo_respuesta_horas,
        COALESCE(mv.disputas, 0) AS disputas
    ) s
    CROSS JOIN LATERAL (
      SELECT public.catalogo_muestra_profesional(t.es_demo) AS visible
    ) vis
    LEFT JOIN LATERAL (
      SELECT min(ts.categoria_servicio) AS categoria
      FROM public.trabajador_servicios ts
      WHERE ts.id_trabajador = t.id_usuario
        AND (
          p_categoria IS NULL OR btrim(p_categoria) = ''
          OR ts.categoria_servicio = p_categoria
        )
    ) c ON true
    WHERE vis.visible
      AND COALESCE(t.disponible, 0) = 1
      AND COALESCE(t.precios_configurados, 0) = 1
      AND t.estado_verificacion = 'verificado'
      AND (s.n_calificaciones = 0 OR COALESCE(s.calificacion, 0) >= 3)
      AND (
        p_categoria IS NULL OR btrim(p_categoria) = '' OR c.categoria IS NOT NULL
      )
  ),
  puntuado AS (
    SELECT
      b.*,
      CASE
        WHEN p_lat IS NULL OR p_lng IS NULL OR b.latitud_base IS NULL OR b.longitud_base IS NULL
          THEN NULL::double precision
        ELSE 6371 * 2 * atan2(
          sqrt(h.a), sqrt(1 - h.a)
        )
      END AS km,
      CASE
        WHEN p_embedding IS NOT NULL
             AND b.embedding IS NOT NULL
             AND b.embedding_origen = 'gte-small'
          THEN greatest(0, least(1, 1 - (b.embedding <=> p_embedding)))
        WHEN v_q = '' THEN 0.40
        WHEN b.profesion ILIKE '%' || v_q || '%'
          OR coalesce(b.descripcion, '') ILIKE '%' || v_q || '%'
          OR coalesce(b.categoria, '') ILIKE '%' || v_q || '%'
          THEN 0.62
        ELSE 0.12
      END AS sim
    FROM base b
    CROSS JOIN LATERAL (
      SELECT power(sin(radians(b.latitud_base - p_lat) / 2), 2)
        + cos(radians(p_lat)) * cos(radians(b.latitud_base))
          * power(sin(radians(b.longitud_base - p_lng) / 2), 2) AS a
    ) h
  )
  SELECT
    u.id_usuario,
    u.profesion,
    u.descripcion,
    u.calificacion,
    u.tarifa_visita,
    u.categoria,
    u.zona_trabajo,
    u.nombre,
    u.ruta_foto_perfil,
    u.latitud_base,
    u.longitud_base,
    u.radio_servicio_km,
    u.origen_base,
    u.trabajos_completados,
    u.score_listado,
    u.prioridad_manual,
    u.radio_urbano_km,
    u.tarifa_fuera_radio_clp,
    u.es_elite,
    u.km,
    round(u.sim::numeric, 4),
    round((
      w_sim * u.sim
      + w_cerca * CASE WHEN u.km IS NULL THEN 0.50 ELSE 1.0 / (1.0 + u.km / 5.0) END
      + w_nota * CASE
          WHEN coalesce(u.n_calificaciones, 0) = 0 THEN 0.40
          ELSE least(coalesce(u.calificacion, 0), 5) / 5.0
        END
      + w_conf * greatest(
          0,
          1
          - least(coalesce(u.tasa_cancelacion, 0), 1) * 0.50
          - least(coalesce(u.disputas, 0), 5) * 0.05
          - CASE WHEN coalesce(u.tiempo_respuesta_horas, 0) > 24 THEN 0.10 ELSE 0 END
        )
    )::numeric, 4),
    CASE
      WHEN p_embedding IS NOT NULL THEN 'semantico'
      ELSE 'lexico'
    END
  FROM puntuado u
  WHERE v_q = '' OR u.sim >= 0.20 OR p_embedding IS NOT NULL
  ORDER BY 22 DESC, u.id_usuario ASC
  LIMIT v_lim;
END;
$$;

REVOKE ALL ON FUNCTION public.buscar_profesionales_hibrido(text, double precision, double precision, text, extensions.vector, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.buscar_profesionales_hibrido(text, double precision, double precision, text, extensions.vector, integer) TO anon, authenticated;

COMMENT ON FUNCTION public.buscar_profesionales_hibrido(text, double precision, double precision, text, extensions.vector, integer) IS
  'Mezcla similitud, cercanía, nota y la vista de stats. Sin embedding de gte-small usa el texto. La app vuelve al catálogo si esta RPC falla.';

CREATE OR REPLACE FUNCTION public.profesionales_parecidos(
  p_id uuid,
  p_limite integer DEFAULT 4
)
RETURNS TABLE(
  id_usuario uuid,
  profesion text,
  nombre text,
  calificacion numeric,
  categoria_servicio text,
  similitud numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_lim integer := LEAST(GREATEST(coalesce(p_limite, 4), 1), 8);
  v_origen text;
  v_vec extensions.vector;
  v_cat text;
BEGIN
  SELECT t.embedding_origen, t.embedding
    INTO v_origen, v_vec
  FROM public.trabajadores t
  WHERE t.id_usuario = p_id;

  SELECT min(ts.categoria_servicio) INTO v_cat
  FROM public.trabajador_servicios ts
  WHERE ts.id_trabajador = p_id;

  RETURN QUERY
  SELECT
    t.id_usuario,
    t.profesion,
    p.nombre,
    mv.calificacion,
    c.categoria,
    CASE
      WHEN v_origen = 'gte-small' AND v_vec IS NOT NULL AND t.embedding_origen = 'gte-small' AND t.embedding IS NOT NULL
        THEN round((1 - (t.embedding <=> v_vec))::numeric, 4)
      ELSE NULL
    END
  FROM public.trabajadores t
  LEFT JOIN public.perfiles p ON p.id = t.id_usuario
  LEFT JOIN public.mv_stats_profesional mv ON mv.id_usuario = t.id_usuario
  LEFT JOIN LATERAL (
    SELECT min(ts.categoria_servicio) AS categoria
    FROM public.trabajador_servicios ts
    WHERE ts.id_trabajador = t.id_usuario
  ) c ON true
  WHERE t.id_usuario <> p_id
    AND public.catalogo_muestra_profesional(t.es_demo)
    AND COALESCE(t.disponible, 0) = 1
    AND t.estado_verificacion = 'verificado'
    AND (
      v_cat IS NULL
      OR c.categoria = v_cat
      OR (v_origen = 'gte-small' AND t.embedding_origen = 'gte-small')
    )
  ORDER BY
    CASE
      WHEN v_origen = 'gte-small' AND v_vec IS NOT NULL AND t.embedding IS NOT NULL AND t.embedding_origen = 'gte-small'
        THEN t.embedding <=> v_vec
      ELSE 1
    END ASC,
    COALESCE(mv.calificacion, 0) DESC,
    t.id_usuario ASC
  LIMIT v_lim;
END;
$$;

REVOKE ALL ON FUNCTION public.profesionales_parecidos(uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.profesionales_parecidos(uuid, integer) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.consola_editar_peso_busqueda(
  p_clave text,
  p_peso numeric,
  p_motivo text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes numeric;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_peso IS NULL OR p_peso < 0 OR p_peso > 1 THEN
    RAISE EXCEPTION 'Peso no permitido';
  END IF;
  IF char_length(btrim(coalesce(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT peso INTO v_antes
  FROM public.ia_pesos_busqueda
  WHERE clave = btrim(p_clave)
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Peso no encontrado';
  END IF;
  UPDATE public.ia_pesos_busqueda
  SET peso = round(p_peso, 2)
  WHERE clave = btrim(p_clave);
  PERFORM public.registrar_auditoria(
    'editar_ajuste', 'ia_pesos_busqueda', btrim(p_clave),
    jsonb_build_object('peso', v_antes),
    jsonb_build_object('peso', round(p_peso, 2)),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;

REVOKE ALL ON FUNCTION public.consola_editar_peso_busqueda(text, numeric, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_editar_peso_busqueda(text, numeric, text) TO authenticated;

COMMIT;

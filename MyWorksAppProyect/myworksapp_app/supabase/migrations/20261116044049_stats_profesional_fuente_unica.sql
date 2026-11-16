-- Fuente única de las cifras públicas del profesional.
--
-- La nota, el recuento de trabajos y la insignia élite salen de las filas
-- reales (calificaciones + trabajos completados), no de valores sembrados
-- en las columnas de la ficha. El catálogo, stats_profesional y un
-- recálculo de columnas usan la misma definición:
--   * calificacion = promedio simple de reseñas cliente→profesional
--     no excluidas (NULL/0 si no hay reseñas)
--   * trabajos_completados = trabajos en estado completado
--   * es_elite = nota >= 4.7 y al menos 5 trabajos completados
--
-- El score de ranking sigue usando el promedio ponderado y Bayes; eso
-- no se muestra como la estrella pública.
--
-- Este archivo también RECALCULA las columnas cacheadas a partir de las
-- filas reales (no inventa reseñas ni trabajos). Aplicada en producción el
-- 16-nov-2026 con el OK de Mathias (versión registrada 20261116044049).

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) Cálculo canónico
-- -----------------------------------------------------------------------------
-- El cálculo necesita leer trabajos y reseñas saltándose RLS (el visitante
-- anónimo no ve esas filas), así que vive como SECURITY DEFINER en el
-- esquema privado, que la API REST no expone. Las RPC públicas son
-- SECURITY INVOKER y solo lo envuelven: así el linter de Supabase no marca
-- una función definer invocable por anon/authenticated.
CREATE SCHEMA IF NOT EXISTS privado;
REVOKE ALL ON SCHEMA privado FROM PUBLIC;
GRANT USAGE ON SCHEMA privado TO anon, authenticated, service_role;

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
  WITH jobs AS (
    SELECT count(*) FILTER (WHERE estado = 'completado')::integer AS n
    FROM public.trabajos
    WHERE id_trabajador = p_id
  ),
  reviews AS (
    SELECT
      round(avg(c.puntaje)::numeric, 2) AS promedio,
      count(*)::integer AS n
    FROM public.calificaciones c
    JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
    WHERE t.id_trabajador = p_id
      AND COALESCE(c.direccion, 'cliente_a_trabajador') = 'cliente_a_trabajador'
      AND c.estado_revision IS DISTINCT FROM 'excluida'
  )
  SELECT
    p_id,
    reviews.promedio,
    COALESCE(reviews.n, 0),
    COALESCE(jobs.n, 0),
    (COALESCE(reviews.promedio, 0) >= 4.7 AND COALESCE(jobs.n, 0) >= 5)
  FROM jobs, reviews;
$$;

REVOKE ALL ON FUNCTION privado.stats_profesional(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION privado.stats_profesional(uuid) TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.stats_profesional(p_id uuid)
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
  SELECT * FROM privado.stats_profesional(p_id);
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
  SELECT s.*
  FROM unnest(COALESCE(p_ids, ARRAY[]::uuid[])) AS u(id)
  JOIN LATERAL privado.stats_profesional(u.id) AS s ON true;
$$;

REVOKE ALL ON FUNCTION public.stats_profesional(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.stats_profesional(uuid) TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.stats_profesionales(uuid[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.stats_profesionales(uuid[]) TO anon, authenticated, service_role;

COMMENT ON FUNCTION public.stats_profesional(uuid) IS
  'Nota, reseñas y trabajos completados reales de un profesional. Fuente única para app, web y panel.';

-- -----------------------------------------------------------------------------
-- 2) Recálculo de columnas cacheadas (datos derivados, no inventados)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.recomputar_agregados_profesional(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_avg numeric;
  v_jobs integer;
BEGIN
  IF p_id IS NULL THEN
    RETURN;
  END IF;

  SELECT s.calificacion, s.trabajos_completados
  INTO v_avg, v_jobs
  FROM public.stats_profesional(p_id) AS s;

  UPDATE public.trabajadores
  SET
    calificacion = COALESCE(v_avg, 0),
    trabajos_completados = COALESCE(v_jobs, 0)
  WHERE id_usuario = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.recomputar_agregados_profesionales()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_id uuid;
  v_n int := 0;
BEGIN
  FOR v_id IN SELECT id_usuario FROM public.trabajadores LOOP
    PERFORM public.recomputar_agregados_profesional(v_id);
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$$;

REVOKE ALL ON FUNCTION public.recomputar_agregados_profesional(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.recomputar_agregados_profesionales() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.recomputar_agregados_profesionales() TO service_role;

-- -----------------------------------------------------------------------------
-- 3) Triggers: el recuento se recalcula, no se incrementa (evita deriva)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trabajos_contar_completados()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.recomputar_agregados_profesional(OLD.id_trabajador);
    RETURN OLD;
  END IF;

  IF TG_OP = 'UPDATE'
     AND OLD.estado IS NOT DISTINCT FROM NEW.estado
     AND OLD.id_trabajador IS NOT DISTINCT FROM NEW.id_trabajador THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE'
     AND OLD.id_trabajador IS DISTINCT FROM NEW.id_trabajador THEN
    PERFORM public.recomputar_agregados_profesional(OLD.id_trabajador);
  END IF;

  PERFORM public.recomputar_agregados_profesional(NEW.id_trabajador);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajos_contar_completados ON public.trabajos;
CREATE TRIGGER trabajos_contar_completados
  AFTER INSERT OR UPDATE OF estado, id_trabajador OR DELETE ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_contar_completados();

CREATE OR REPLACE FUNCTION public._recomputar_agregados_por_calificacion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_job text;
  v_worker uuid;
BEGIN
  v_job := COALESCE(NEW.id_trabajo, OLD.id_trabajo)::text;
  IF v_job IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT t.id_trabajador INTO v_worker
  FROM public.trabajos t
  WHERE t.id::text = v_job;

  PERFORM public.recomputar_agregados_profesional(v_worker);
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS calificaciones_recomputar_agregados ON public.calificaciones;
CREATE TRIGGER calificaciones_recomputar_agregados
  AFTER INSERT OR UPDATE OF puntaje, direccion, estado_revision, id_trabajo
  OR DELETE ON public.calificaciones
  FOR EACH ROW
  EXECUTE FUNCTION public._recomputar_agregados_por_calificacion();

REVOKE ALL ON FUNCTION public._recomputar_agregados_por_calificacion() FROM PUBLIC, anon, authenticated;

-- El trigger antiguo calificaciones_refrescar_trabajador corre DESPUÉS del
-- nuevo (orden alfabético) y recalculaba la nota sin descartar reseñas
-- excluidas ni reseñas sin dirección, pisando la cifra canónica. Ahora
-- delega en el mismo cálculo para que ambos dejen el mismo valor.
CREATE OR REPLACE FUNCTION public.refrescar_calificacion_trabajador()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_worker uuid;
BEGIN
  SELECT t.id_trabajador INTO v_worker
  FROM public.trabajos t
  WHERE t.id::text = COALESCE(NEW.id_trabajo, OLD.id_trabajo)::text;

  PERFORM public.recomputar_agregados_profesional(v_worker);
  RETURN COALESCE(NEW, OLD);
END;
$$;

REVOKE ALL ON FUNCTION public.refrescar_calificacion_trabajador() FROM PUBLIC, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 4) Ranking: la estrella pública ya no usa el promedio ponderado
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.refrescar_ranking_trabajador(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_cfg public.ranking_config;
  v_w numeric[];
  v_worker public.trabajadores%ROWTYPE;
  v_n numeric;
  v_avg numeric;
  v_bayes numeric;
  v_conf numeric;
  v_completados int;
  v_simple_avg numeric;
  v_simple_n int;
  v_impulso int;
  v_dias numeric;
  f_cal numeric;
  f_comp numeric;
  f_rech numeric;
  f_ver numeric;
  f_imp numeric;
  f_rec numeric;
  f_conf numeric;
  v_score numeric;
BEGIN
  IF p_id IS NULL THEN
    RETURN;
  END IF;

  SELECT * INTO v_worker FROM public.trabajadores WHERE id_usuario = p_id;
  IF NOT FOUND THEN
    RETURN;
  END IF;

  v_cfg := public._ranking_cfg();
  v_w := public._normalizar_pesos_ranking(
    v_cfg.peso_calificacion,
    v_cfg.peso_completados,
    v_cfg.peso_rechazos,
    v_cfg.peso_verificacion,
    v_cfg.peso_impulso,
    v_cfg.peso_recencia,
    v_cfg.peso_confianza
  );

  SELECT
    COALESCE(SUM(c.peso_confianza) FILTER (WHERE c.estado_revision IS DISTINCT FROM 'excluida'), 0),
    CASE
      WHEN COALESCE(SUM(c.peso_confianza) FILTER (WHERE c.estado_revision IS DISTINCT FROM 'excluida'), 0) > 0
      THEN SUM(c.puntaje * c.peso_confianza) FILTER (WHERE c.estado_revision IS DISTINCT FROM 'excluida')
           / SUM(c.peso_confianza) FILTER (WHERE c.estado_revision IS DISTINCT FROM 'excluida')
      ELSE NULL
    END,
    COALESCE(AVG(c.peso_confianza) FILTER (WHERE c.estado_revision IS DISTINCT FROM 'excluida'), 0.50)
  INTO v_n, v_avg, v_conf
  FROM public.calificaciones c
  JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
  WHERE t.id_trabajador = p_id;

  IF COALESCE(v_n, 0) <= 0 THEN
    v_bayes := v_cfg.prior_bayes * 0.55;
  ELSE
    v_bayes := (v_cfg.n_bayes * v_cfg.prior_bayes + v_n * v_avg)
               / (v_cfg.n_bayes + v_n);
  END IF;

  SELECT count(*)::int INTO v_completados
  FROM public.trabajos
  WHERE id_trabajador = p_id AND estado = 'completado';

  -- Nota pública: promedio simple de reseñas reales del cliente, no el
  -- promedio ponderado que usa el score de ranking (v_avg / Bayes).
  SELECT
    round(avg(c.puntaje)::numeric, 2),
    count(*)::int
  INTO v_simple_avg, v_simple_n
  FROM public.calificaciones c
  JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
  WHERE t.id_trabajador = p_id
    AND COALESCE(c.direccion, 'cliente_a_trabajador') = 'cliente_a_trabajador'
    AND c.estado_revision IS DISTINCT FROM 'excluida';

  BEGIN
    SELECT CASE WHEN EXISTS (
      SELECT 1 FROM public.impulsos i
      WHERE i.id_trabajador = p_id
        AND i.fecha_inicio::timestamptz <= now()
        AND i.fecha_fin::timestamptz >= now()
    ) THEN 1 ELSE 0 END INTO v_impulso;
  EXCEPTION WHEN others THEN
    v_impulso := 0;
  END;

  BEGIN
    SELECT EXTRACT(EPOCH FROM (
      now() - COALESCE(MAX(j.actualizado_en::timestamptz), now() - interval '90 days')
    )) / 86400.0
    INTO v_dias
    FROM public.trabajos j
    WHERE j.id_trabajador = p_id AND j.estado = 'completado';
  EXCEPTION WHEN others THEN
    v_dias := 90;
  END;

  f_cal := LEAST(GREATEST(v_bayes / 5.0, 0), 1);
  f_comp := tanh(v_completados / 12.0);
  f_rech := 1 - LEAST(COALESCE(v_worker.conteo_rechazos, 0) * 0.12, 1);
  f_ver := CASE COALESCE(v_worker.estado_verificacion, 'pendiente')
    WHEN 'verificado' THEN 1
    WHEN 'en_revision' THEN 0.55
    ELSE 0.35
  END;
  f_imp := v_impulso;
  f_rec := EXP(-GREATEST(COALESCE(v_dias, 90), 0) / 45.0);
  f_conf := LEAST(GREATEST(COALESCE(v_conf, 0.50), 0), 1);

  v_score := 100 * (
        v_w[1] * f_cal
      + v_w[2] * f_comp
      + v_w[3] * f_rech
      + v_w[4] * f_ver
      + v_w[5] * f_imp
      + v_w[6] * f_rec
      + v_w[7] * f_conf
  ) + COALESCE(v_worker.prioridad_manual, 0) * 2.0;

  UPDATE public.trabajadores
  SET
    calificacion = round(COALESCE(v_simple_avg, 0)::numeric, 2),
    trabajos_completados = COALESCE(v_completados, 0),
    score_listado = round(v_score::numeric, 4),
    score_desglose = jsonb_build_object(
      'f_calificacion', round(f_cal::numeric, 4),
      'f_completados', round(f_comp::numeric, 4),
      'f_rechazos', round(f_rech::numeric, 4),
      'f_verificacion', round(f_ver::numeric, 4),
      'f_impulso', round(f_imp::numeric, 4),
      'f_recencia', round(f_rec::numeric, 4),
      'f_confianza', round(f_conf::numeric, 4),
      'bayes', round(v_bayes::numeric, 4),
      'n_efectivo', round(COALESCE(v_n, 0)::numeric, 3),
      'prioridad_manual', COALESCE(v_worker.prioridad_manual, 0)
    ),
    ranking_actualizado_en = now()
  WHERE id_usuario = p_id;
END;
$$;

REVOKE ALL ON FUNCTION public.refrescar_ranking_trabajador(uuid) FROM PUBLIC, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 5) Catálogo: entrega las cifras en vivo, aunque las columnas estén desfasadas
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.listar_profesionales_catalogo(
  p_categoria text DEFAULT NULL::text,
  p_zona text DEFAULT NULL::text,
  p_cursor_calificacion numeric DEFAULT NULL::numeric,
  p_cursor_id uuid DEFAULT NULL::uuid,
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
  prioridad_manual integer,
  radio_urbano_km numeric,
  tarifa_fuera_radio_clp integer,
  es_elite boolean
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
    t.categoria_servicio,
    t.zona_trabajo,
    p.nombre,
    p.ruta_foto_perfil,
    CASE
      WHEN auth.uid() IS NOT NULL AND auth.uid() = t.id_usuario
        THEN t.latitud_base
      ELSE round(t.latitud_base::numeric, 2)::double precision
    END AS latitud_base,
    CASE
      WHEN auth.uid() IS NOT NULL AND auth.uid() = t.id_usuario
        THEN t.longitud_base
      ELSE round(t.longitud_base::numeric, 2)::double precision
    END AS longitud_base,
    t.radio_servicio_km,
    t.origen_base,
    s.trabajos_completados,
    t.score_listado,
    t.prioridad_manual,
    t.radio_urbano_km,
    t.tarifa_fuera_radio_clp,
    s.es_elite
  FROM public.trabajadores t
  LEFT JOIN public.perfiles p ON p.id = t.id_usuario
  JOIN LATERAL public.stats_profesional(t.id_usuario) AS s ON true
  WHERE COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
    AND t.estado_verificacion = 'verificado'
    AND (s.n_calificaciones = 0 OR COALESCE(s.calificacion, 0) >= 3)
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
$function$;

REVOKE ALL ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) TO anon, authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 6) Recalcular columnas cacheadas desde las filas reales
-- -----------------------------------------------------------------------------
SELECT public.recomputar_agregados_profesionales();

COMMIT;

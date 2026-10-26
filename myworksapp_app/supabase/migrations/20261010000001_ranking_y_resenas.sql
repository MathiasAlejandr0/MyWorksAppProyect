-- Ranking configurable, aprendizaje por resultados y revisión de reseñas.
-- La nota pública sigue saliendo de calificaciones; el orden del listado
-- usa score_listado. Las reseñas dudosas bajan de peso; no se ocultan hasta
-- confirmar fraude (evita falsos positivos).

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) Columnas en ficha y reseña
-- -----------------------------------------------------------------------------
ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS score_listado numeric(8,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS prioridad_manual integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS score_desglose jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS ranking_actualizado_en timestamptz;

ALTER TABLE public.trabajadores
  DROP CONSTRAINT IF EXISTS trabajadores_prioridad_manual_chk;
ALTER TABLE public.trabajadores
  ADD CONSTRAINT trabajadores_prioridad_manual_chk
  CHECK (prioridad_manual BETWEEN -50 AND 50);

ALTER TABLE public.calificaciones
  ADD COLUMN IF NOT EXISTS peso_confianza numeric(4,3) NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS estado_revision text NOT NULL DEFAULT 'vigente',
  ADD COLUMN IF NOT EXISTS motivo_revision text;

ALTER TABLE public.calificaciones
  DROP CONSTRAINT IF EXISTS calificaciones_peso_confianza_chk;
ALTER TABLE public.calificaciones
  ADD CONSTRAINT calificaciones_peso_confianza_chk
  CHECK (peso_confianza BETWEEN 0 AND 1);

ALTER TABLE public.calificaciones
  DROP CONSTRAINT IF EXISTS calificaciones_estado_revision_chk;
ALTER TABLE public.calificaciones
  ADD CONSTRAINT calificaciones_estado_revision_chk
  CHECK (estado_revision IN ('vigente', 'en_revision', 'excluida'));

CREATE INDEX IF NOT EXISTS trabajadores_score_listado_idx
  ON public.trabajadores (score_listado DESC, id_usuario ASC);

CREATE INDEX IF NOT EXISTS calificaciones_estado_revision_idx
  ON public.calificaciones (estado_revision);

-- -----------------------------------------------------------------------------
-- 2) Tablas de ranking y señales
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ranking_config (
  id text PRIMARY KEY DEFAULT 'default',
  peso_calificacion numeric NOT NULL DEFAULT 0.32,
  peso_completados numeric NOT NULL DEFAULT 0.18,
  peso_rechazos numeric NOT NULL DEFAULT 0.12,
  peso_verificacion numeric NOT NULL DEFAULT 0.10,
  peso_impulso numeric NOT NULL DEFAULT 0.08,
  peso_recencia numeric NOT NULL DEFAULT 0.08,
  peso_confianza numeric NOT NULL DEFAULT 0.12,
  prior_bayes numeric NOT NULL DEFAULT 3.80,
  n_bayes numeric NOT NULL DEFAULT 8,
  umbral_revision numeric NOT NULL DEFAULT 0.55,
  umbral_auto_excluir numeric NOT NULL DEFAULT 0.90,
  aprendizaje_activo integer NOT NULL DEFAULT 1,
  tasa_aprendizaje numeric NOT NULL DEFAULT 0.15,
  pesos_senal jsonb NOT NULL DEFAULT '{
    "auto_resena": 1.00,
    "sin_trabajo_valido": 0.95,
    "rafaga": 0.45,
    "cuenta_nueva": 0.25,
    "texto_vacio_extremo": 0.20,
    "duplicado_texto": 0.40,
    "outlier": 0.22,
    "granja_cinco_estrellas": 0.50
  }'::jsonb,
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ranking_config_unica CHECK (id = 'default')
);

INSERT INTO public.ranking_config (id) VALUES ('default')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.senales_resena (
  id text PRIMARY KEY,
  id_calificacion text NOT NULL REFERENCES public.calificaciones(id) ON DELETE CASCADE,
  tipo_senal text NOT NULL,
  puntaje numeric NOT NULL,
  detalle text,
  estado text NOT NULL DEFAULT 'pendiente',
  resuelto_por uuid,
  resuelto_en timestamptz,
  creado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT senales_resena_unica UNIQUE (id_calificacion, tipo_senal),
  CONSTRAINT senales_resena_estado_chk CHECK (
    estado IN ('pendiente', 'fraude_confirmado', 'falso_positivo', 'descartada')
  )
);

CREATE INDEX IF NOT EXISTS senales_resena_estado_idx
  ON public.senales_resena (estado, creado_en DESC);

CREATE TABLE IF NOT EXISTS public.ranking_aprendizaje (
  id text PRIMARY KEY,
  motivo text NOT NULL,
  pesos_antes jsonb NOT NULL,
  pesos_despues jsonb NOT NULL,
  metricas jsonb,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.eventos_ranking (
  id text PRIMARY KEY,
  id_trabajador uuid NOT NULL,
  id_trabajo text,
  tipo_evento text NOT NULL,
  factores jsonb NOT NULL DEFAULT '{}'::jsonb,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS eventos_ranking_trabajador_idx
  ON public.eventos_ranking (id_trabajador, tipo_evento);

ALTER TABLE public.ranking_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.senales_resena ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ranking_aprendizaje ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eventos_ranking ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.ranking_config FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.senales_resena FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.ranking_aprendizaje FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.eventos_ranking FROM PUBLIC, anon, authenticated;

DROP POLICY IF EXISTS ranking_config_admin ON public.ranking_config;
CREATE POLICY ranking_config_admin ON public.ranking_config
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS senales_resena_admin ON public.senales_resena;
CREATE POLICY senales_resena_admin ON public.senales_resena
  FOR SELECT TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS ranking_aprendizaje_admin ON public.ranking_aprendizaje;
CREATE POLICY ranking_aprendizaje_admin ON public.ranking_aprendizaje
  FOR SELECT TO authenticated
  USING (public.is_admin());

GRANT SELECT ON TABLE public.ranking_config TO authenticated;
GRANT SELECT ON TABLE public.senales_resena TO authenticated;
GRANT SELECT ON TABLE public.ranking_aprendizaje TO authenticated;

-- El profesional no escribe el score ni la prioridad.
REVOKE UPDATE (
  score_listado,
  prioridad_manual,
  score_desglose,
  ranking_actualizado_en
) ON TABLE public.trabajadores FROM anon, authenticated;

-- -----------------------------------------------------------------------------
-- 3) Helpers
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._ranking_cfg()
RETURNS public.ranking_config
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT * FROM public.ranking_config WHERE id = 'default';
$$;

REVOKE ALL ON FUNCTION public._ranking_cfg() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public._normalizar_pesos_ranking(
  p_cal numeric,
  p_comp numeric,
  p_rech numeric,
  p_ver numeric,
  p_imp numeric,
  p_rec numeric,
  p_conf numeric
)
RETURNS numeric[]
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $$
DECLARE
  v_raw numeric[] := ARRAY[
    GREATEST(COALESCE(p_cal, 0), 0.03),
    GREATEST(COALESCE(p_comp, 0), 0.03),
    GREATEST(COALESCE(p_rech, 0), 0.03),
    GREATEST(COALESCE(p_ver, 0), 0.03),
    GREATEST(COALESCE(p_imp, 0), 0.03),
    GREATEST(COALESCE(p_rec, 0), 0.03),
    GREATEST(COALESCE(p_conf, 0), 0.03)
  ];
  v_sum numeric := 0;
  i int;
BEGIN
  FOR i IN 1..7 LOOP
    v_raw[i] := LEAST(v_raw[i], 0.50);
    v_sum := v_sum + v_raw[i];
  END LOOP;
  IF v_sum <= 0 THEN
    RETURN ARRAY[0.32, 0.18, 0.12, 0.10, 0.08, 0.08, 0.12];
  END IF;
  FOR i IN 1..7 LOOP
    v_raw[i] := round((v_raw[i] / v_sum)::numeric, 4);
  END LOOP;
  RETURN v_raw;
END;
$$;

REVOKE ALL ON FUNCTION public._normalizar_pesos_ranking(numeric, numeric, numeric, numeric, numeric, numeric, numeric)
  FROM PUBLIC, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 4) Score de un profesional
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
    calificacion = round(COALESCE(v_avg, 0)::numeric, 2),
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

CREATE OR REPLACE FUNCTION public.refrescar_ranking_todos()
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
    PERFORM public.refrescar_ranking_trabajador(v_id);
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$$;

REVOKE ALL ON FUNCTION public.refrescar_ranking_todos() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.refrescar_ranking_todos_admin()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'solo administrador';
  END IF;
  RETURN public.refrescar_ranking_todos();
END;
$$;

REVOKE ALL ON FUNCTION public.refrescar_ranking_todos_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.refrescar_ranking_todos_admin() TO authenticated;

-- -----------------------------------------------------------------------------
-- 5) Evaluación de reseñas (falsos positivos vs fraude)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.evaluar_resena(p_id text)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_c public.calificaciones%ROWTYPE;
  v_job public.trabajos%ROWTYPE;
  v_cfg public.ranking_config;
  v_pesos jsonb;
  v_risk numeric := 0;
  v_factor numeric;
  v_tipo text;
  v_w numeric;
  v_cuenta timestamptz;
  v_n int;
  v_mean numeric;
  v_std numeric;
  v_norm text;
  v_estado text;
  v_peso numeric;
  v_motivo text := '';
BEGIN
  SELECT * INTO v_c FROM public.calificaciones WHERE id::text = p_id;
  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id::text = v_c.id_trabajo::text;
  v_cfg := public._ranking_cfg();
  v_pesos := v_cfg.pesos_senal;

  DELETE FROM public.senales_resena
  WHERE id_calificacion = v_c.id::text
    AND estado = 'pendiente';

  IF v_job.id_trabajador IS NOT NULL
     AND v_c.id_usuario IS NOT NULL
     AND v_c.id_usuario::text = v_job.id_trabajador::text THEN
    INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
    VALUES (gen_random_uuid()::text, v_c.id::text, 'auto_resena', 1,
            'El profesional calificó su propio trabajo')
    ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
      SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
  END IF;

  IF v_job.id IS NULL
     OR v_job.estado IS DISTINCT FROM 'completado'
     OR v_c.id_usuario IS DISTINCT FROM v_job.id_usuario THEN
    INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
    VALUES (gen_random_uuid()::text, v_c.id::text, 'sin_trabajo_valido', 0.95,
            'La reseña no corresponde a un trabajo completado del cliente')
    ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
      SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
  END IF;

  BEGIN
    SELECT p.creado_en::timestamptz INTO v_cuenta
    FROM public.perfiles p
    WHERE p.id = v_c.id_usuario;
  EXCEPTION WHEN others THEN
    v_cuenta := NULL;
  END;

  IF v_cuenta IS NOT NULL AND v_cuenta > now() - interval '48 hours'
     AND v_c.puntaje IN (1, 5) THEN
    INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
    VALUES (gen_random_uuid()::text, v_c.id::text, 'cuenta_nueva', 0.25,
            'Cuenta con menos de 48 horas y nota extrema')
    ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
      SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
  END IF;

  IF v_c.puntaje IN (1, 5)
     AND length(btrim(COALESCE(v_c.comentario, ''))) < 8 THEN
    INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
    VALUES (gen_random_uuid()::text, v_c.id::text, 'texto_vacio_extremo', 0.20,
            'Nota extrema sin texto suficiente')
    ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
      SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
  END IF;

  SELECT count(*)::int INTO v_n
  FROM public.calificaciones c
  JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
  WHERE t.id_trabajador = v_job.id_trabajador
    AND c.id::text <> v_c.id::text
    AND c.creado_en > now() - interval '6 hours';
  IF v_n >= 3 THEN
    INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
    VALUES (gen_random_uuid()::text, v_c.id::text, 'rafaga', 0.45,
            'Tres o más reseñas extra al mismo profesional en 6 h')
    ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
      SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
  END IF;

  v_norm := lower(regexp_replace(btrim(COALESCE(v_c.comentario, '')), '\s+', ' ', 'g'));
  IF length(v_norm) >= 12 THEN
    IF EXISTS (
      SELECT 1 FROM public.calificaciones c
      WHERE c.id::text <> v_c.id::text
        AND lower(regexp_replace(btrim(COALESCE(c.comentario, '')), '\s+', ' ', 'g')) = v_norm
    ) THEN
      INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
      VALUES (gen_random_uuid()::text, v_c.id::text, 'duplicado_texto', 0.40,
              'El mismo texto aparece en otra reseña')
      ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
        SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
    END IF;
  END IF;

  SELECT count(*)::int, avg(c.puntaje), stddev_pop(c.puntaje)
  INTO v_n, v_mean, v_std
  FROM public.calificaciones c
  JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
  WHERE t.id_trabajador = v_job.id_trabajador
    AND c.estado_revision IS DISTINCT FROM 'excluida'
    AND c.id::text <> v_c.id::text;
  IF v_n >= 5 AND v_std IS NOT NULL AND v_std > 0
     AND abs(v_c.puntaje - v_mean) > 2 * v_std THEN
    INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
    VALUES (gen_random_uuid()::text, v_c.id::text, 'outlier', 0.22,
            'Se aleja más de 2σ de la media del profesional')
    ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
      SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
  END IF;

  IF v_c.puntaje = 5 AND v_c.id_usuario IS NOT NULL THEN
    SELECT count(*)::int INTO v_n
    FROM public.calificaciones c
    JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
    WHERE c.id_usuario = v_c.id_usuario
      AND c.puntaje = 5
      AND c.creado_en > now() - interval '24 hours'
      AND t.id_trabajador IS DISTINCT FROM v_job.id_trabajador;
    IF v_n >= 3 THEN
      INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
      VALUES (gen_random_uuid()::text, v_c.id::text, 'granja_cinco_estrellas', 0.50,
              'El mismo cliente dio 5★ a 3 o más profesionales en 24 h')
      ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
        SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
    END IF;
  END IF;

  v_risk := 0;
  FOR v_tipo, v_factor IN
    SELECT s.tipo_senal, s.puntaje
    FROM public.senales_resena s
    WHERE s.id_calificacion = v_c.id::text
      AND s.estado IN ('pendiente', 'fraude_confirmado')
  LOOP
    v_w := COALESCE((v_pesos ->> v_tipo)::numeric, v_factor);
    v_risk := 1 - (1 - v_risk) * (1 - LEAST(GREATEST(v_w, 0), 1));
    IF v_motivo = '' THEN
      v_motivo := v_tipo;
    ELSE
      v_motivo := v_motivo || ',' || v_tipo;
    END IF;
  END LOOP;

  IF EXISTS (
    SELECT 1 FROM public.senales_resena s
    WHERE s.id_calificacion = v_c.id::text
      AND s.tipo_senal IN ('auto_resena', 'sin_trabajo_valido')
      AND s.estado IN ('pendiente', 'fraude_confirmado')
  ) OR v_risk >= v_cfg.umbral_auto_excluir THEN
    v_estado := 'excluida';
    v_peso := 0;
  ELSIF v_risk >= v_cfg.umbral_revision THEN
    v_estado := 'en_revision';
    v_peso := GREATEST(1 - v_risk, 0.15);
  ELSE
    v_estado := 'vigente';
    v_peso := GREATEST(1 - v_risk, 0.35);
  END IF;

  PERFORM set_config('mwa.skip_eval_resena', '1', true);
  UPDATE public.calificaciones
  SET peso_confianza = round(v_peso::numeric, 3),
      estado_revision = v_estado,
      motivo_revision = NULLIF(btrim(v_motivo), '')
  WHERE id::text = v_c.id::text;
  RETURN round(v_risk::numeric, 4);
END;
$$;

REVOKE ALL ON FUNCTION public.evaluar_resena(text) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public._evaluar_resena_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_worker uuid;
BEGIN
  IF COALESCE(current_setting('mwa.skip_eval_resena', true), '') = '1' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE'
     AND NEW.puntaje IS NOT DISTINCT FROM OLD.puntaje
     AND NEW.comentario IS NOT DISTINCT FROM OLD.comentario THEN
    RETURN NEW;
  END IF;
  PERFORM public.evaluar_resena(NEW.id::text);
  SELECT t.id_trabajador INTO v_worker
  FROM public.trabajos t
  WHERE t.id::text = NEW.id_trabajo::text;
  IF v_worker IS NOT NULL THEN
    PERFORM public.refrescar_ranking_trabajador(v_worker);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS calificaciones_evaluar_resena ON public.calificaciones;
CREATE TRIGGER calificaciones_evaluar_resena
  AFTER INSERT OR UPDATE OF puntaje, comentario ON public.calificaciones
  FOR EACH ROW
  EXECUTE FUNCTION public._evaluar_resena_trigger();

REVOKE ALL ON FUNCTION public._evaluar_resena_trigger() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public._registrar_evento_ranking(
  p_trabajador uuid,
  p_trabajo text,
  p_tipo text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_factores jsonb := '{}'::jsonb;
  v_n int;
BEGIN
  IF p_trabajador IS NULL THEN
    RETURN;
  END IF;
  PERFORM public.refrescar_ranking_trabajador(p_trabajador);
  SELECT score_desglose INTO v_factores
  FROM public.trabajadores
  WHERE id_usuario = p_trabajador;
  INSERT INTO public.eventos_ranking (id, id_trabajador, id_trabajo, tipo_evento, factores)
  VALUES (gen_random_uuid()::text, p_trabajador, p_trabajo, p_tipo, COALESCE(v_factores, '{}'::jsonb));

  IF p_tipo IN ('completado_ok', 'disputado', 'cancelado_trabajador') THEN
    SELECT count(*)::int INTO v_n
    FROM public.eventos_ranking
    WHERE tipo_evento IN ('completado_ok', 'disputado', 'cancelado_trabajador')
      AND creado_en > now() - interval '120 days';
    IF v_n >= 12 AND v_n % 8 = 0 THEN
      PERFORM public.aprender_pesos_ranking();
    END IF;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public._registrar_evento_ranking(uuid, text, text) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.aprender_pesos_ranking()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_cfg public.ranking_config;
  v_lr numeric;
  v_pos int;
  v_neg int;
  v_ok numeric[];
  v_bad numeric[];
  v_new numeric[];
  v_delta numeric[];
  v_sum numeric := 0;
  v_antes jsonb;
  v_despues jsonb;
  v_keys text[] := ARRAY['f_calificacion','f_completados','f_rechazos','f_verificacion','f_impulso','f_recencia','f_confianza'];
  i int;
BEGIN
  v_cfg := public._ranking_cfg();
  IF COALESCE(v_cfg.aprendizaje_activo, 1) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'motivo', 'aprendizaje_inactivo');
  END IF;
  v_lr := COALESCE(v_cfg.tasa_aprendizaje, 0.15);

  SELECT
    count(*) FILTER (WHERE tipo_evento = 'completado_ok'),
    count(*) FILTER (WHERE tipo_evento IN ('disputado', 'cancelado_trabajador'))
  INTO v_pos, v_neg
  FROM public.eventos_ranking
  WHERE creado_en > now() - interval '120 days';

  IF COALESCE(v_pos, 0) + COALESCE(v_neg, 0) < 12 THEN
    RETURN jsonb_build_object('ok', false, 'motivo', 'muestra_insuficiente', 'positivos', v_pos, 'negativos', v_neg);
  END IF;

  v_antes := jsonb_build_object(
    'peso_calificacion', v_cfg.peso_calificacion,
    'peso_completados', v_cfg.peso_completados,
    'peso_rechazos', v_cfg.peso_rechazos,
    'peso_verificacion', v_cfg.peso_verificacion,
    'peso_impulso', v_cfg.peso_impulso,
    'peso_recencia', v_cfg.peso_recencia,
    'peso_confianza', v_cfg.peso_confianza
  );

  SELECT ARRAY[
    COALESCE(avg((factores->>'f_calificacion')::numeric) FILTER (WHERE tipo_evento = 'completado_ok'), 0),
    COALESCE(avg((factores->>'f_completados')::numeric) FILTER (WHERE tipo_evento = 'completado_ok'), 0),
    COALESCE(avg((factores->>'f_rechazos')::numeric) FILTER (WHERE tipo_evento = 'completado_ok'), 0),
    COALESCE(avg((factores->>'f_verificacion')::numeric) FILTER (WHERE tipo_evento = 'completado_ok'), 0),
    COALESCE(avg((factores->>'f_impulso')::numeric) FILTER (WHERE tipo_evento = 'completado_ok'), 0),
    COALESCE(avg((factores->>'f_recencia')::numeric) FILTER (WHERE tipo_evento = 'completado_ok'), 0),
    COALESCE(avg((factores->>'f_confianza')::numeric) FILTER (WHERE tipo_evento = 'completado_ok'), 0)
  ] INTO v_ok
  FROM public.eventos_ranking
  WHERE creado_en > now() - interval '120 days';

  SELECT ARRAY[
    COALESCE(avg((factores->>'f_calificacion')::numeric) FILTER (WHERE tipo_evento IN ('disputado','cancelado_trabajador')), 0),
    COALESCE(avg((factores->>'f_completados')::numeric) FILTER (WHERE tipo_evento IN ('disputado','cancelado_trabajador')), 0),
    COALESCE(avg((factores->>'f_rechazos')::numeric) FILTER (WHERE tipo_evento IN ('disputado','cancelado_trabajador')), 0),
    COALESCE(avg((factores->>'f_verificacion')::numeric) FILTER (WHERE tipo_evento IN ('disputado','cancelado_trabajador')), 0),
    COALESCE(avg((factores->>'f_impulso')::numeric) FILTER (WHERE tipo_evento IN ('disputado','cancelado_trabajador')), 0),
    COALESCE(avg((factores->>'f_recencia')::numeric) FILTER (WHERE tipo_evento IN ('disputado','cancelado_trabajador')), 0),
    COALESCE(avg((factores->>'f_confianza')::numeric) FILTER (WHERE tipo_evento IN ('disputado','cancelado_trabajador')), 0)
  ] INTO v_bad
  FROM public.eventos_ranking
  WHERE creado_en > now() - interval '120 days';

  v_new := ARRAY[
    v_cfg.peso_calificacion, v_cfg.peso_completados, v_cfg.peso_rechazos,
    v_cfg.peso_verificacion, v_cfg.peso_impulso, v_cfg.peso_recencia,
    v_cfg.peso_confianza
  ];
  v_delta := ARRAY[0,0,0,0,0,0,0];
  FOR i IN 1..7 LOOP
    v_delta[i] := GREATEST((COALESCE(v_ok[i], 0) - COALESCE(v_bad[i], 0)) + 0.08, 0.03);
    v_sum := v_sum + v_delta[i];
  END LOOP;
  IF v_sum <= 0 THEN
    RETURN jsonb_build_object('ok', false, 'motivo', 'sin_delta');
  END IF;
  FOR i IN 1..7 LOOP
    v_delta[i] := v_delta[i] / v_sum;
    v_new[i] := (1 - v_lr) * v_new[i] + v_lr * v_delta[i];
  END LOOP;
  v_new := public._normalizar_pesos_ranking(
    v_new[1], v_new[2], v_new[3], v_new[4], v_new[5], v_new[6], v_new[7]
  );

  UPDATE public.ranking_config
  SET
    peso_calificacion = v_new[1],
    peso_completados = v_new[2],
    peso_rechazos = v_new[3],
    peso_verificacion = v_new[4],
    peso_impulso = v_new[5],
    peso_recencia = v_new[6],
    peso_confianza = v_new[7],
    actualizado_en = now()
  WHERE id = 'default';

  v_despues := jsonb_build_object(
    'peso_calificacion', v_new[1],
    'peso_completados', v_new[2],
    'peso_rechazos', v_new[3],
    'peso_verificacion', v_new[4],
    'peso_impulso', v_new[5],
    'peso_recencia', v_new[6],
    'peso_confianza', v_new[7]
  );

  INSERT INTO public.ranking_aprendizaje (id, motivo, pesos_antes, pesos_despues, metricas)
  VALUES (
    gen_random_uuid()::text,
    'ciclo_trabajos',
    v_antes,
    v_despues,
    jsonb_build_object('positivos', v_pos, 'negativos', v_neg, 'tasa', v_lr, 'factores', v_keys)
  );

  PERFORM public.refrescar_ranking_todos();
  RETURN jsonb_build_object('ok', true, 'pesos', v_despues, 'positivos', v_pos, 'negativos', v_neg);
END;
$$;

CREATE OR REPLACE FUNCTION public.aprender_pesos_ranking_admin()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'solo administrador';
  END IF;
  RETURN public.aprender_pesos_ranking();
END;
$$;

REVOKE ALL ON FUNCTION public.aprender_pesos_ranking() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.aprender_pesos_ranking_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.aprender_pesos_ranking_admin() TO authenticated;

CREATE OR REPLACE FUNCTION public.registrar_resultado_trabajo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_por uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.id_trabajador IS NOT NULL
     AND OLD.id_trabajador IS DISTINCT FROM NEW.id_trabajador THEN
    PERFORM public._registrar_evento_ranking(NEW.id_trabajador, NEW.id::text, 'contratado');
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.estado IS DISTINCT FROM OLD.estado THEN
    IF NEW.estado = 'completado' AND NEW.id_trabajador IS NOT NULL THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.disputas d
        WHERE d.id_trabajo::text = NEW.id::text
          AND d.estado IN ('abierta', 'en_revision')
      ) THEN
        PERFORM public._registrar_evento_ranking(NEW.id_trabajador, NEW.id::text, 'completado_ok');
      END IF;
    ELSIF NEW.estado = 'cancelado' AND NEW.id_trabajador IS NOT NULL THEN
      SELECT cancelado_por INTO v_por
      FROM public.cancelaciones_trabajo
      WHERE id_trabajo::text = NEW.id::text;
      IF v_por IS NOT NULL AND v_por = NEW.id_trabajador THEN
        PERFORM public._registrar_evento_ranking(NEW.id_trabajador, NEW.id::text, 'cancelado_trabajador');
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajos_eventos_ranking ON public.trabajos;
CREATE TRIGGER trabajos_eventos_ranking
  AFTER UPDATE OF estado, id_trabajador ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.registrar_resultado_trabajo();

REVOKE ALL ON FUNCTION public.registrar_resultado_trabajo() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.registrar_disputa_ranking()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_worker uuid;
BEGIN
  SELECT id_trabajador INTO v_worker
  FROM public.trabajos
  WHERE id::text = NEW.id_trabajo::text;
  IF v_worker IS NOT NULL THEN
    PERFORM public._registrar_evento_ranking(v_worker, NEW.id_trabajo::text, 'disputado');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS disputas_eventos_ranking ON public.disputas;
CREATE TRIGGER disputas_eventos_ranking
  AFTER INSERT ON public.disputas
  FOR EACH ROW
  EXECUTE FUNCTION public.registrar_disputa_ranking();

REVOKE ALL ON FUNCTION public.registrar_disputa_ranking() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.refrescar_ranking_por_impulso()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  PERFORM public.refrescar_ranking_trabajador(COALESCE(NEW.id_trabajador, OLD.id_trabajador));
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS impulsos_refrescar_ranking ON public.impulsos;
CREATE TRIGGER impulsos_refrescar_ranking
  AFTER INSERT OR UPDATE OR DELETE ON public.impulsos
  FOR EACH ROW
  EXECUTE FUNCTION public.refrescar_ranking_por_impulso();

REVOKE ALL ON FUNCTION public.refrescar_ranking_por_impulso() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.refrescar_ranking_ficha()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.conteo_rechazos IS NOT DISTINCT FROM OLD.conteo_rechazos
     AND NEW.estado_verificacion IS NOT DISTINCT FROM OLD.estado_verificacion
     AND NEW.prioridad_manual IS NOT DISTINCT FROM OLD.prioridad_manual THEN
    RETURN NEW;
  END IF;
  PERFORM public.refrescar_ranking_trabajador(NEW.id_usuario);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajadores_refrescar_ranking ON public.trabajadores;
CREATE TRIGGER trabajadores_refrescar_ranking
  AFTER UPDATE OF conteo_rechazos, estado_verificacion, prioridad_manual
  ON public.trabajadores
  FOR EACH ROW
  EXECUTE FUNCTION public.refrescar_ranking_ficha();

REVOKE ALL ON FUNCTION public.refrescar_ranking_ficha() FROM PUBLIC, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 7) RPCs de administración
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.proteger_campos_trabajador()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.calificacion IS NOT DISTINCT FROM OLD.calificacion
     AND NEW.conteo_rechazos IS NOT DISTINCT FROM OLD.conteo_rechazos
     AND NEW.estado_verificacion IS NOT DISTINCT FROM OLD.estado_verificacion
     AND NEW.nota_verificacion IS NOT DISTINCT FROM OLD.nota_verificacion
     AND NEW.score_listado IS NOT DISTINCT FROM OLD.score_listado
     AND NEW.prioridad_manual IS NOT DISTINCT FROM OLD.prioridad_manual
     AND NEW.score_desglose IS NOT DISTINCT FROM OLD.score_desglose
     AND NEW.ranking_actualizado_en IS NOT DISTINCT FROM OLD.ranking_actualizado_en
  THEN
    RETURN NEW;
  END IF;

  IF COALESCE(current_setting('mwa.rpc_trabajador', true), '') = '1'
     OR COALESCE(auth.role(), '') = 'service_role'
     OR public.is_admin()
     OR (auth.role() IS NULL AND auth.uid() IS NULL)
     OR current_user IN ('postgres', 'supabase_admin')
  THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'calificación, ranking y verificación no los edita el profesional';
END;
$$;

CREATE OR REPLACE FUNCTION public.obtener_config_ranking()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'solo administrador';
  END IF;
  RETURN (
    SELECT to_jsonb(c.*)
    FROM public.ranking_config c
    WHERE c.id = 'default'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.obtener_config_ranking() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.obtener_config_ranking() TO authenticated;

CREATE OR REPLACE FUNCTION public.guardar_config_ranking(p_cfg jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_w numeric[];
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'solo administrador';
  END IF;
  v_w := public._normalizar_pesos_ranking(
    (p_cfg->>'peso_calificacion')::numeric,
    (p_cfg->>'peso_completados')::numeric,
    (p_cfg->>'peso_rechazos')::numeric,
    (p_cfg->>'peso_verificacion')::numeric,
    (p_cfg->>'peso_impulso')::numeric,
    (p_cfg->>'peso_recencia')::numeric,
    (p_cfg->>'peso_confianza')::numeric
  );
  UPDATE public.ranking_config
  SET
    peso_calificacion = v_w[1],
    peso_completados = v_w[2],
    peso_rechazos = v_w[3],
    peso_verificacion = v_w[4],
    peso_impulso = v_w[5],
    peso_recencia = v_w[6],
    peso_confianza = v_w[7],
    prior_bayes = COALESCE((p_cfg->>'prior_bayes')::numeric, prior_bayes),
    n_bayes = COALESCE((p_cfg->>'n_bayes')::numeric, n_bayes),
    umbral_revision = COALESCE((p_cfg->>'umbral_revision')::numeric, umbral_revision),
    umbral_auto_excluir = COALESCE((p_cfg->>'umbral_auto_excluir')::numeric, umbral_auto_excluir),
    aprendizaje_activo = CASE
      WHEN COALESCE(p_cfg->>'aprendizaje_activo', '1') IN ('0', 'false', 'f') THEN 0
      ELSE 1
    END,
    tasa_aprendizaje = COALESCE((p_cfg->>'tasa_aprendizaje')::numeric, tasa_aprendizaje),
    pesos_senal = CASE
      WHEN p_cfg->'pesos_senal' IS NULL
        OR p_cfg->'pesos_senal' = '{}'::jsonb
      THEN pesos_senal
      ELSE p_cfg->'pesos_senal'
    END,
    actualizado_en = now()
  WHERE id = 'default';

  PERFORM public.refrescar_ranking_todos();
  RETURN public.obtener_config_ranking();
END;
$$;

REVOKE ALL ON FUNCTION public.guardar_config_ranking(jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.guardar_config_ranking(jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION public.fijar_prioridad_trabajador(
  p_id uuid,
  p_prioridad integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'solo administrador';
  END IF;
  IF p_prioridad < -50 OR p_prioridad > 50 THEN
    RAISE EXCEPTION 'prioridad fuera de rango (-50 a 50)';
  END IF;
  PERFORM set_config('mwa.rpc_trabajador', '1', true);
  UPDATE public.trabajadores
  SET prioridad_manual = p_prioridad
  WHERE id_usuario = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajador no encontrado';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.fijar_prioridad_trabajador(uuid, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fijar_prioridad_trabajador(uuid, integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.listar_senales_resena(
  p_estado text DEFAULT 'pendiente',
  p_limit integer DEFAULT 80
)
RETURNS TABLE (
  id text,
  id_calificacion text,
  tipo_senal text,
  puntaje numeric,
  detalle text,
  estado text,
  creado_en timestamptz,
  puntaje_resena integer,
  comentario text,
  estado_revision text,
  peso_confianza numeric,
  id_trabajo text,
  id_trabajador uuid,
  nombre_trabajador text,
  nombre_cliente text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'solo administrador';
  END IF;
  RETURN QUERY
  SELECT
    s.id,
    s.id_calificacion,
    s.tipo_senal,
    s.puntaje,
    s.detalle,
    s.estado,
    s.creado_en,
    c.puntaje,
    c.comentario,
    c.estado_revision,
    c.peso_confianza,
    c.id_trabajo::text,
    t.id_trabajador,
    tw.nombre,
    cl.nombre
  FROM public.senales_resena s
  JOIN public.calificaciones c ON c.id::text = s.id_calificacion
  LEFT JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
  LEFT JOIN public.perfiles tw ON tw.id = t.id_trabajador
  LEFT JOIN public.perfiles cl ON cl.id = c.id_usuario
  WHERE (p_estado IS NULL OR btrim(p_estado) = '' OR p_estado = 'all'
         OR s.estado = p_estado)
  ORDER BY s.creado_en DESC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 80), 1), 200);
END;
$$;

REVOKE ALL ON FUNCTION public.listar_senales_resena(text, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.listar_senales_resena(text, integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.resolver_senal_resena(
  p_id text,
  p_estado text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.senales_resena%ROWTYPE;
  v_cfg public.ranking_config;
  v_w numeric;
  v_pesos jsonb;
  v_worker uuid;
  v_risk numeric;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'solo administrador';
  END IF;
  IF p_estado NOT IN ('fraude_confirmado', 'falso_positivo', 'descartada') THEN
    RAISE EXCEPTION 'estado de resolución inválido';
  END IF;

  SELECT * INTO v_row FROM public.senales_resena WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'señal no encontrada';
  END IF;

  UPDATE public.senales_resena
  SET estado = p_estado,
      resuelto_por = auth.uid(),
      resuelto_en = now()
  WHERE id = p_id;

  v_cfg := public._ranking_cfg();
  v_pesos := v_cfg.pesos_senal;
  v_w := COALESCE((v_pesos ->> v_row.tipo_senal)::numeric, 0.3);
  IF v_row.tipo_senal NOT IN ('auto_resena', 'sin_trabajo_valido') THEN
    IF p_estado = 'falso_positivo' THEN
      v_w := GREATEST(v_w * 0.85, 0.05);
    ELSIF p_estado = 'fraude_confirmado' THEN
      v_w := LEAST(v_w * 1.12 + 0.02, 0.90);
    END IF;
    v_pesos := jsonb_set(v_pesos, ARRAY[v_row.tipo_senal], to_jsonb(round(v_w, 4)));
    UPDATE public.ranking_config
    SET pesos_senal = v_pesos, actualizado_en = now()
    WHERE id = 'default';

    INSERT INTO public.ranking_aprendizaje (id, motivo, pesos_antes, pesos_despues, metricas)
    VALUES (
      gen_random_uuid()::text,
      'resolucion_senal',
      jsonb_build_object(v_row.tipo_senal, (v_cfg.pesos_senal ->> v_row.tipo_senal)::numeric),
      jsonb_build_object(v_row.tipo_senal, v_w),
      jsonb_build_object('id_senal', p_id, 'estado', p_estado)
    );
  END IF;

  PERFORM set_config('mwa.skip_eval_resena', '1', true);

  IF EXISTS (
    SELECT 1 FROM public.senales_resena
    WHERE id_calificacion = v_row.id_calificacion
      AND estado = 'fraude_confirmado'
  ) THEN
    UPDATE public.calificaciones
    SET estado_revision = 'excluida', peso_confianza = 0,
        motivo_revision = 'fraude_confirmado'
    WHERE id::text = v_row.id_calificacion;
  ELSIF NOT EXISTS (
    SELECT 1 FROM public.senales_resena
    WHERE id_calificacion = v_row.id_calificacion
      AND estado IN ('pendiente', 'fraude_confirmado')
  ) THEN
    UPDATE public.calificaciones
    SET estado_revision = 'vigente', peso_confianza = 1,
        motivo_revision = NULL
    WHERE id::text = v_row.id_calificacion;
  ELSE
    v_risk := public.evaluar_resena(v_row.id_calificacion);
  END IF;

  SELECT t.id_trabajador INTO v_worker
  FROM public.calificaciones c
  JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
  WHERE c.id::text = v_row.id_calificacion;
  IF v_worker IS NOT NULL THEN
    PERFORM public.refrescar_ranking_trabajador(v_worker);
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.resolver_senal_resena(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resolver_senal_resena(text, text) TO authenticated;

-- -----------------------------------------------------------------------------
-- 8) Catálogo ordenado por ranking
-- -----------------------------------------------------------------------------
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
    round(t.latitud_base::numeric, 3)::double precision,
    round(t.longitud_base::numeric, 3)::double precision,
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

COMMENT ON COLUMN public.trabajadores.score_listado IS
  'Orden de marketplace. Incluye pesos configurables + prioridad_manual*2.';
COMMENT ON COLUMN public.trabajadores.prioridad_manual IS
  'Override de admin (-50..50) para mostrar un profesional antes o después.';
COMMENT ON TABLE public.senales_resena IS
  'Señales de reseña dudosa. Falso positivo baja el peso de esa señal.';

-- Score inicial (nota vigente, sin re-evaluar historial para no inundar la cola).
SELECT public.refrescar_ranking_todos();

COMMIT;

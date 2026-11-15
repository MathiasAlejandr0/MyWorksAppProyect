-- Reconcilia el repo con lo que corre en producción (wxqrfcqifkfgawrnqmnj).
--
-- Contexto (auditoría 12 nov 2026): varias funciones se corrigieron a mano
-- en el SQL Editor y nunca volvieron al repo, y el trigger de reseñas de
-- 20261010000001 no quedó creado en producción.
--
-- 1. evaluar_resena, _registrar_evento_ranking y aprender_pesos_ranking:
--    se copian las versiones de PRODUCCIÓN (sin cambio de comportamiento
--    allá). La versión del repo comparaba calificaciones.creado_en (text)
--    contra timestamptz y fallaba en tiempo de ejecución.
-- 2. _evaluar_resena_trigger + trigger calificaciones_evaluar_resena: se
--    crean. A diferencia de 20261010000001, un error al evaluar la reseña
--    solo deja un WARNING: nunca bloquea que el cliente califique.
-- 3. recargo_traslado_clp: se aplica la versión del repo (tope de 30 km,
--    igual que la regla que ya aplican app y web) y se fija search_path.
--    km_entre_puntos también fija search_path (aviso del linter).
--
-- Idempotente: se puede correr más de una vez.

BEGIN;

-- 1. Funciones copiadas desde producción --------------------------------
CREATE OR REPLACE FUNCTION public.evaluar_resena(p_id text)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  'Nota extrema sin comentario útil')
  ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
  SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
  END IF;

  SELECT count(*)::int INTO v_n
  FROM public.calificaciones c
  JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
  WHERE t.id_trabajador IS NOT DISTINCT FROM v_job.id_trabajador
  AND c.id::text IS DISTINCT FROM v_c.id::text
  AND c.creado_en::timestamptz > now() - interval '6 hours';

  IF COALESCE(v_n, 0) >= 3 THEN
  INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
  VALUES (gen_random_uuid()::text, v_c.id::text, 'rafaga', 0.45,
  format('%s reseñas extra en 6 horas', v_n))
  ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
  SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
  END IF;

  v_norm := regexp_replace(lower(btrim(COALESCE(v_c.comentario, ''))), '\s+', ' ', 'g');
  IF length(v_norm) >= 12 AND EXISTS (
  SELECT 1
  FROM public.calificaciones o
  WHERE o.id::text IS DISTINCT FROM v_c.id::text
  AND regexp_replace(lower(btrim(COALESCE(o.comentario, ''))), '\s+', ' ', 'g') = v_norm
  ) THEN
  INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
  VALUES (gen_random_uuid()::text, v_c.id::text, 'duplicado_texto', 0.40,
  'El texto coincide con otra reseña')
  ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
  SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
  END IF;

  SELECT count(*)::int, avg(c.puntaje), stddev_pop(c.puntaje)
  INTO v_n, v_mean, v_std
  FROM public.calificaciones c
  JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
  WHERE t.id_trabajador IS NOT DISTINCT FROM v_job.id_trabajador
  AND c.id::text IS DISTINCT FROM v_c.id::text
  AND c.estado_revision IS DISTINCT FROM 'excluida';

  IF COALESCE(v_n, 0) >= 5 AND COALESCE(v_std, 0) > 0
  AND abs(v_c.puntaje - v_mean) > 2.0 * v_std THEN
  INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
  VALUES (gen_random_uuid()::text, v_c.id::text, 'outlier', 0.22,
  format('Se aleja de la media %.2f (σ %.2f)', v_mean, v_std))
  ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
  SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
  END IF;

  SELECT count(DISTINCT t.id_trabajador)::int INTO v_n
  FROM public.calificaciones c
  JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
  WHERE c.id_usuario IS NOT DISTINCT FROM v_c.id_usuario
  AND c.puntaje = 5
  AND c.creado_en::timestamptz > now() - interval '24 hours';

  IF COALESCE(v_n, 0) >= 3 THEN
  INSERT INTO public.senales_resena (id, id_calificacion, tipo_senal, puntaje, detalle)
  VALUES (gen_random_uuid()::text, v_c.id::text, 'granja_cinco_estrellas', 0.50,
  format('%s profesionales distintos con 5★ en 24 h', v_n))
  ON CONFLICT (id_calificacion, tipo_senal) DO UPDATE
  SET puntaje = EXCLUDED.puntaje, detalle = EXCLUDED.detalle;
  END IF;

  v_factor := 1;
  FOR v_tipo, v_w IN
  SELECT s.tipo_senal,
  COALESCE((v_pesos ->> s.tipo_senal)::numeric, s.puntaje)
  FROM public.senales_resena s
  WHERE s.id_calificacion = v_c.id::text
  AND s.estado IN ('pendiente', 'fraude_confirmado')
  LOOP
  v_factor := v_factor * (1 - LEAST(GREATEST(v_w, 0), 0.99));
  v_motivo := v_motivo || v_tipo || ' ';
  END LOOP;
  v_risk := 1 - v_factor;

  IF EXISTS (
  SELECT 1 FROM public.senales_resena s
  WHERE s.id_calificacion = v_c.id::text
  AND s.tipo_senal IN ('auto_resena', 'sin_trabajo_valido')
  AND s.estado IS DISTINCT FROM 'falso_positivo'

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
  $function$

;

CREATE OR REPLACE FUNCTION public._registrar_evento_ranking(p_trabajador uuid, p_trabajo text, p_tipo text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  DECLARE
  v_factores jsonb := '{}'::jsonb;
  v_n int;
  BEGIN
  IF p_trabajador IS NULL THEN
  RETURN;
  END IF;

  SELECT score_desglose INTO v_factores
  FROM public.trabajadores
  WHERE id_usuario = p_trabajador;

  INSERT INTO public.eventos_ranking (id, id_trabajador, id_trabajo, tipo_evento, factores)
  VALUES (
  gen_random_uuid()::text,
  p_trabajador,
  p_trabajo,
  p_tipo,
  COALESCE(v_factores, '{}'::jsonb)
  );

  PERFORM public.refrescar_ranking_trabajador(p_trabajador);

  SELECT count(*)::int INTO v_n
  FROM public.eventos_ranking
  WHERE tipo_evento IN ('completado_ok', 'disputado', 'cancelado_trabajador');

  IF v_n >= 12 AND v_n % 8 = 0 THEN
  PERFORM public.aprender_pesos_ranking();
  END IF;
  END;
  $function$

;

CREATE OR REPLACE FUNCTION public.aprender_pesos_ranking()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  DECLARE
  v_cfg public.ranking_config;
  v_antes jsonb;
  v_lr numeric;
  v_pos int;
  v_neg int;
  v_ok numeric[];
  v_bad numeric[];
  v_delta numeric[];
  v_new numeric[];
  v_keys text[] := ARRAY[
  'f_calificacion','f_completados','f_rechazos','f_verificacion',
  'f_impulso','f_recencia','f_confianza'
  ];
  i int;
  v_sum numeric := 0;
  v_despues jsonb;
  BEGIN
  v_cfg := public._ranking_cfg();
  IF COALESCE(v_cfg.aprendizaje_activo, 1) <> 1 THEN
  RETURN jsonb_build_object('ok', false, 'motivo', 'aprendizaje_inactivo');
  END IF;

  v_lr := LEAST(GREATEST(COALESCE(v_cfg.tasa_aprendizaje, 0.15), 0.02), 0.40);
  v_antes := jsonb_build_object(
  'peso_calificacion', v_cfg.peso_calificacion,
  'peso_completados', v_cfg.peso_completados,
  'peso_rechazos', v_cfg.peso_rechazos,
  'peso_verificacion', v_cfg.peso_verificacion,
  'peso_impulso', v_cfg.peso_impulso,
  'peso_recencia', v_cfg.peso_recencia,
  'peso_confianza', v_cfg.peso_confianza
  );

  SELECT
  count(*) FILTER (WHERE tipo_evento = 'completado_ok'),
  count(*) FILTER (WHERE tipo_evento IN ('disputado', 'cancelado_trabajador'))
  INTO v_pos, v_neg
  FROM public.eventos_ranking
  WHERE creado_en > now() - interval '120 days';

  IF COALESCE(v_pos, 0) + COALESCE(v_neg, 0) < 12 THEN
  RETURN jsonb_build_object('ok', false, 'motivo', 'muestra_insuficiente', 'n', COALESCE(v_pos,0)+COALESCE(v_neg,0));
  END IF;

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
  $function$

;

REVOKE ALL ON FUNCTION public.evaluar_resena(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public._registrar_evento_ranking(uuid, text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.aprender_pesos_ranking() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.evaluar_resena(text) TO service_role;
GRANT EXECUTE ON FUNCTION public._registrar_evento_ranking(uuid, text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.aprender_pesos_ranking() TO service_role;

-- 2. Trigger de evaluación de reseñas ------------------------------------
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
  BEGIN
    PERFORM public.evaluar_resena(NEW.id::text);
    SELECT t.id_trabajador INTO v_worker
    FROM public.trabajos t
    WHERE t.id::text = NEW.id_trabajo::text;
    IF v_worker IS NOT NULL THEN
      PERFORM public.refrescar_ranking_trabajador(v_worker);
    END IF;
  EXCEPTION WHEN others THEN
    RAISE WARNING 'evaluar_resena falló para %: %', NEW.id, SQLERRM;
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS calificaciones_evaluar_resena ON public.calificaciones;
CREATE TRIGGER calificaciones_evaluar_resena
  AFTER INSERT OR UPDATE OF puntaje, comentario ON public.calificaciones
  FOR EACH ROW
  EXECUTE FUNCTION public._evaluar_resena_trigger();

REVOKE ALL ON FUNCTION public._evaluar_resena_trigger() FROM PUBLIC, anon, authenticated;

-- 3. Tope de traslado y search_path ---------------------------------------
-- Producción no tiene trabajos con el profesional a más de 30 km
-- (revisado 12 nov 2026), así que el tope no afecta trabajos en curso.
CREATE OR REPLACE FUNCTION public.recargo_traslado_clp(
  p_lat_trabajador double precision,
  p_lng_trabajador double precision,
  p_lat_trabajo double precision,
  p_lng_trabajo double precision,
  p_radio_km numeric
) RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
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

REVOKE ALL ON FUNCTION public.recargo_traslado_clp(double precision, double precision, double precision, double precision, numeric) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.recargo_traslado_clp(double precision, double precision, double precision, double precision, numeric) TO service_role;

ALTER FUNCTION public.km_entre_puntos(double precision, double precision, double precision, double precision)
  SET search_path TO 'public';

COMMIT;

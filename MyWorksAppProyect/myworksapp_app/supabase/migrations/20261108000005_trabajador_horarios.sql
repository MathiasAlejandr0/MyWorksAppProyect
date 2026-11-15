-- La plantilla semanal deja de vivir en trabajadores (visible por REST)
-- y pasa a trabajador_horarios, solo del profesional.

BEGIN;

CREATE OR REPLACE FUNCTION public.normalizar_bloques_horario(p_horarios jsonb)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object('dia', (elem->>'dia')::int, 'hora', elem->>'hora')
      ORDER BY (elem->>'dia')::int, elem->>'hora'
    ),
    '[]'::jsonb
  )
  FROM (
    SELECT DISTINCT ON ((elem->>'dia')::int, elem->>'hora') elem
    FROM jsonb_array_elements(
      CASE
        WHEN jsonb_typeof(coalesce(p_horarios, '[]'::jsonb)) = 'array'
          THEN coalesce(p_horarios, '[]'::jsonb)
        ELSE '[]'::jsonb
      END
    ) AS elem
    WHERE jsonb_typeof(elem) = 'object'
      AND (elem->>'dia') ~ '^[1-7]$'
      AND (elem->>'hora') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
    ORDER BY (elem->>'dia')::int, elem->>'hora'
  ) AS filtrados;
$$;

REVOKE ALL ON FUNCTION public.normalizar_bloques_horario(jsonb) FROM PUBLIC, anon, authenticated;

CREATE TABLE IF NOT EXISTS public.trabajador_horarios (
  id_usuario uuid PRIMARY KEY
    REFERENCES public.trabajadores(id_usuario) ON DELETE CASCADE,
  horarios jsonb NOT NULL DEFAULT '[]'::jsonb,
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.trabajador_horarios IS
  'Plantilla semanal {dia:1-7 ISO, hora:HH:MM}. Solo el profesional. El cliente usa horarios_libres_profesional.';

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.table_name = 'trabajadores'
      AND c.column_name = 'horarios_disponibles'
  ) THEN
    INSERT INTO public.trabajador_horarios (id_usuario, horarios)
    SELECT t.id_usuario, public.normalizar_bloques_horario(t.horarios_disponibles)
    FROM public.trabajadores t
    ON CONFLICT (id_usuario) DO UPDATE
    SET horarios = EXCLUDED.horarios,
        actualizado_en = now();
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.trabajador_horarios_normalizar()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  NEW.horarios := public.normalizar_bloques_horario(NEW.horarios);
  NEW.actualizado_en := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajador_horarios_normalizar ON public.trabajador_horarios;
CREATE TRIGGER trabajador_horarios_normalizar
  BEFORE INSERT OR UPDATE OF horarios ON public.trabajador_horarios
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajador_horarios_normalizar();

CREATE OR REPLACE FUNCTION public.trabajador_horarios_desde_alta()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.trabajador_horarios (id_usuario, horarios)
  VALUES (NEW.id_usuario, '[]'::jsonb)
  ON CONFLICT (id_usuario) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajador_horarios_desde_alta ON public.trabajadores;
CREATE TRIGGER trabajador_horarios_desde_alta
  AFTER INSERT ON public.trabajadores
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajador_horarios_desde_alta();

ALTER TABLE public.trabajador_horarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS trabajador_horarios_propio ON public.trabajador_horarios;
CREATE POLICY trabajador_horarios_propio ON public.trabajador_horarios
  FOR ALL TO authenticated
  USING (id_usuario = (SELECT auth.uid()))
  WITH CHECK (id_usuario = (SELECT auth.uid()));

REVOKE ALL ON TABLE public.trabajador_horarios FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.trabajador_horarios TO authenticated;
GRANT ALL ON TABLE public.trabajador_horarios TO service_role;

CREATE OR REPLACE FUNCTION public.horarios_libres_profesional(
  p_id_trabajador uuid,
  p_dias integer DEFAULT 14
)
RETURNS TABLE (inicio timestamptz)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_slots jsonb;
  v_day date;
  v_end date;
  v_item jsonb;
  v_ts timestamptz;
  v_dias integer;
BEGIN
  v_dias := least(greatest(coalesce(p_dias, 14), 1), 21);

  SELECT h.horarios
  INTO v_slots
  FROM public.trabajador_horarios h
  WHERE h.id_usuario = p_id_trabajador;

  IF v_slots IS NULL OR jsonb_typeof(v_slots) <> 'array' THEN
    RETURN;
  END IF;

  v_day := (timezone('America/Santiago', now()))::date;
  v_end := v_day + v_dias;

  WHILE v_day < v_end LOOP
    FOR v_item IN
      SELECT elem
      FROM jsonb_array_elements(v_slots) AS elem
      WHERE (elem->>'dia')::int = extract(isodow FROM v_day)::int
    LOOP
      v_ts := ((v_day::text || ' ' || (v_item->>'hora'))::timestamp
               AT TIME ZONE 'America/Santiago');
      IF v_ts > now() AND NOT EXISTS (
        SELECT 1
        FROM public.trabajos t
        WHERE t.id_trabajador = p_id_trabajador
          AND t.fecha_programada IS NOT NULL
          AND public.minuto_utc(t.fecha_programada::text) = date_trunc('minute', v_ts)
          AND t.estado NOT IN ('cancelado', 'expirado', 'completado', 'no_asistio')
      ) THEN
        inicio := v_ts;
        RETURN NEXT;
      END IF;
    END LOOP;
    v_day := v_day + 1;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.horarios_libres_profesional(uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.horarios_libres_profesional(uuid, integer) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.horarios_disponibles_propios()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT coalesce(h.horarios, '[]'::jsonb)
  FROM public.trabajador_horarios h
  WHERE h.id_usuario = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.horarios_disponibles_propios() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.horarios_disponibles_propios() TO authenticated;

CREATE OR REPLACE FUNCTION public.guardar_horarios_propios(p_horarios jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_out jsonb;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.trabajadores t WHERE t.id_usuario = v_uid
  ) THEN
    RAISE EXCEPTION 'solo el profesional puede editar su agenda';
  END IF;

  INSERT INTO public.trabajador_horarios (id_usuario, horarios)
  VALUES (v_uid, coalesce(p_horarios, '[]'::jsonb))
  ON CONFLICT (id_usuario) DO UPDATE
  SET horarios = EXCLUDED.horarios
  RETURNING horarios INTO v_out;

  RETURN coalesce(v_out, '[]'::jsonb);
END;
$$;

REVOKE ALL ON FUNCTION public.guardar_horarios_propios(jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.guardar_horarios_propios(jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION public.trabajos_horario_unico()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_prog timestamptz;
  v_local timestamp;
  v_dia integer;
  v_hora text;
  v_slots jsonb;
  v_publicado boolean := false;
  v_cambia_hora boolean;
  v_pendientes integer;
BEGIN
  v_prog := public.texto_a_timestamptz(NEW.fecha_programada::text);
  IF v_prog IS NOT NULL THEN
    v_prog := date_trunc('minute', v_prog);
    NEW.fecha_programada := v_prog;
  END IF;

  IF NEW.estado IN ('cancelado', 'expirado', 'completado', 'no_asistio') THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT'
     AND NEW.estado = 'esperando_pago'
     AND v_prog IS NULL THEN
    RAISE EXCEPTION 'elige un horario publicado por el profesional';
  END IF;

  IF NEW.estado = 'esperando_pago' AND NEW.id_usuario IS NOT NULL THEN
    PERFORM pg_advisory_xact_lock(hashtext('pago:' || NEW.id_usuario::text));
    SELECT count(*)::int
    INTO v_pendientes
    FROM public.trabajos t
    WHERE t.id_usuario = NEW.id_usuario
      AND t.id IS DISTINCT FROM NEW.id
      AND t.estado = 'esperando_pago'
      AND public.texto_a_timestamptz(t.creado_en::text) > now() - interval '35 minutes';
    IF coalesce(v_pendientes, 0) >= 3 THEN
      RAISE EXCEPTION 'demasiados pedidos esperando pago';
    END IF;
  END IF;

  IF v_prog IS NULL OR NEW.id_trabajador IS NULL THEN
    RETURN NEW;
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtext(NEW.id_trabajador::text),
    (abs(extract(epoch FROM v_prog)::bigint) % 2147483647)::int
  );

  v_cambia_hora := TG_OP = 'INSERT'
    OR (TG_OP = 'UPDATE' AND NEW.fecha_programada IS DISTINCT FROM OLD.fecha_programada);

  IF v_cambia_hora THEN
    IF v_prog <= now() THEN
      RAISE EXCEPTION 'esa hora ya no esta disponible';
    END IF;

    SELECT h.horarios
    INTO v_slots
    FROM public.trabajador_horarios h
    WHERE h.id_usuario = NEW.id_trabajador;

    v_local := v_prog AT TIME ZONE 'America/Santiago';
    v_dia := extract(isodow FROM v_local)::int;
    v_hora := to_char(v_local, 'HH24:MI');

    SELECT EXISTS (
      SELECT 1
      FROM jsonb_array_elements(coalesce(v_slots, '[]'::jsonb)) AS elem
      WHERE jsonb_typeof(elem) = 'object'
        AND (elem->>'dia')::int = v_dia
        AND elem->>'hora' = v_hora
    )
    INTO v_publicado;

    IF NOT v_publicado THEN
      RAISE EXCEPTION 'esa hora no esta publicada por el profesional';
    END IF;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.trabajos t
    WHERE t.id_trabajador = NEW.id_trabajador
      AND t.id IS DISTINCT FROM NEW.id
      AND t.fecha_programada IS NOT NULL
      AND public.minuto_utc(t.fecha_programada::text) = v_prog
      AND t.estado NOT IN ('cancelado', 'expirado', 'completado', 'no_asistio')
  ) THEN
    RAISE EXCEPTION 'ese horario ya esta reservado con este profesional';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajadores_normalizar_horarios ON public.trabajadores;
DROP FUNCTION IF EXISTS public.trabajadores_normalizar_horarios();

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.table_name = 'trabajadores'
      AND c.column_name = 'horarios_disponibles'
  ) THEN
    EXECUTE 'REVOKE UPDATE (horarios_disponibles) ON TABLE public.trabajadores FROM anon, authenticated';
    EXECUTE 'ALTER TABLE public.trabajadores DROP COLUMN horarios_disponibles';
  END IF;
END $$;

REVOKE ALL ON FUNCTION public.trabajador_horarios_normalizar() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.trabajador_horarios_desde_alta() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;

-- Aún NO aplicada en wxqrfcqifkfgawrnqmnj.
--
-- 20261115052827 dejó la PK de trabajador_horarios en `id` y el único en
-- (id_usuario, dia_semana). guardar_horarios_propios y el alta seguían con
-- ON CONFLICT (id_usuario), que ya no tiene restricción. Las lecturas
-- (horarios_libres_profesional, el trigger de reserva) toman una fila al
-- azar si hay una por día: ahora eligen la que más horas publicadas trae.
--
-- usa_horario se agregó después del GRANT por columna, así que authenticated
-- no podía actualizar el interruptor.


BEGIN;


GRANT UPDATE (usa_horario) ON TABLE public.trabajadores TO authenticated;


CREATE OR REPLACE FUNCTION public.trabajador_horarios_desde_alta()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.trabajador_horarios (id_usuario, horarios)
  SELECT NEW.id_usuario, '[]'::jsonb
  WHERE NOT EXISTS (
    SELECT 1
    FROM public.trabajador_horarios h
    WHERE h.id_usuario = NEW.id_usuario
  );
  RETURN NEW;
END;
$$;

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
  WHERE h.id_usuario = p_id_trabajador
  ORDER BY jsonb_array_length(coalesce(h.horarios, '[]'::jsonb)) DESC
  LIMIT 1;

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
  WHERE h.id_usuario = auth.uid()
  ORDER BY jsonb_array_length(coalesce(h.horarios, '[]'::jsonb)) DESC
  LIMIT 1;
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

  UPDATE public.trabajador_horarios
  SET horarios = coalesce(p_horarios, '[]'::jsonb)
  WHERE id_usuario = v_uid
  RETURNING horarios INTO v_out;

  IF NOT FOUND THEN
    INSERT INTO public.trabajador_horarios (id_usuario, horarios)
    VALUES (v_uid, coalesce(p_horarios, '[]'::jsonb))
    RETURNING horarios INTO v_out;
  END IF;

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
    WHERE h.id_usuario = NEW.id_trabajador
    ORDER BY jsonb_array_length(coalesce(h.horarios, '[]'::jsonb)) DESC
    LIMIT 1;

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

COMMIT;

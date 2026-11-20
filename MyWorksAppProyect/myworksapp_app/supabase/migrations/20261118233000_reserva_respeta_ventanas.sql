-- La reserva lee trabajador_horas_publicadas. Un día con activo = false
-- no se ofrece ni se puede reservar, aunque quede alguna hora publicada.
-- Dos citas en el mismo minuto siguen chocando.

BEGIN;

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
  v_day date;
  v_end date;
  v_hora text;
  v_ts timestamptz;
  v_dias integer;
BEGIN
  v_dias := least(greatest(coalesce(p_dias, 14), 1), 21);

  v_day := (timezone('America/Santiago', now()))::date;
  v_end := v_day + v_dias;

  WHILE v_day < v_end LOOP
    IF EXISTS (
      SELECT 1
      FROM public.trabajador_horarios w
      WHERE w.id_usuario = p_id_trabajador
        AND w.dia_semana = extract(isodow FROM v_day)::int
        AND w.activo IS FALSE
    ) THEN
      v_day := v_day + 1;
      CONTINUE;
    END IF;

    FOR v_hora IN
      SELECT to_char(h.hora, 'HH24:MI')
      FROM public.trabajador_horas_publicadas h
      WHERE h.id_usuario = p_id_trabajador
        AND h.dia_semana = extract(isodow FROM v_day)::int
      ORDER BY h.hora
    LOOP
      v_ts := ((v_day::text || ' ' || v_hora)::timestamp
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

    v_local := v_prog AT TIME ZONE 'America/Santiago';
    v_dia := extract(isodow FROM v_local)::int;
    v_hora := to_char(v_local, 'HH24:MI');

    SELECT EXISTS (
      SELECT 1
      FROM public.trabajador_horas_publicadas h
      WHERE h.id_usuario = NEW.id_trabajador
        AND h.dia_semana = v_dia
        AND h.hora = v_hora::time
    )
    INTO v_publicado;

    IF NOT v_publicado THEN
      RAISE EXCEPTION 'esa hora no esta publicada por el profesional';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM public.trabajador_horarios w
      WHERE w.id_usuario = NEW.id_trabajador
        AND w.dia_semana = v_dia
        AND w.activo IS FALSE
    ) THEN
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

REVOKE ALL ON FUNCTION public.trabajos_horario_unico() FROM PUBLIC, anon, authenticated;

COMMIT;

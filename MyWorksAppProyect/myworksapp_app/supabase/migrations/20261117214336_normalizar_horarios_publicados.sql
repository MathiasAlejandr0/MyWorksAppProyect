-- Horarios del profesional sin jsonb.
-- Antes trabajador_horarios guardaba, en una columna jsonb, la lista completa de
-- horas publicadas (se repetía en cada fila) y a la vez una ventana por día
-- (hora_inicio, hora_fin) que casi nunca se llenaba (dia_semana vacío en las
-- 64 filas). Ahora:
--   * trabajador_horarios: 7 filas por profesional (una por día) con la ventana
--     de atención: dia_semana, hora_inicio, hora_fin y activo, todos obligatorios;
--     única por (id_usuario, dia_semana).
--   * trabajador_horas_publicadas: una fila por hora de inicio que el profesional
--     publica para reservar (id_usuario, dia_semana, hora). Reemplaza la lista jsonb.

CREATE TABLE public.trabajador_horas_publicadas (
  id_usuario uuid NOT NULL REFERENCES public.trabajadores (id_usuario) ON DELETE CASCADE,
  dia_semana smallint NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),
  hora time NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id_usuario, dia_semana, hora)
);

COMMENT ON TABLE public.trabajador_horas_publicadas IS
  'Horas de inicio que el profesional publica para que el cliente reserve (1 = lunes ... 7 = domingo, hora de Santiago).';

-- Migrar las horas publicadas desde el jsonb (todas las filas del profesional).
INSERT INTO public.trabajador_horas_publicadas (id_usuario, dia_semana, hora)
SELECT DISTINCT h.id_usuario, (e->>'dia')::smallint, (e->>'hora')::time
FROM public.trabajador_horarios h
CROSS JOIN LATERAL jsonb_array_elements(public.normalizar_bloques_horario(h.horarios)) AS e
ON CONFLICT DO NOTHING;

-- Ventana de atención por día: del primer al último bloque publicado ese día
-- (el último bloque dura 1 hora); sin bloques, día inactivo con la ventana por defecto.
DELETE FROM public.trabajador_horarios WHERE dia_semana IS NULL;

WITH ventanas AS (
  SELECT t.id_usuario, d.dia,
         COALESCE(min(p.hora), time '09:00') AS inicio,
         COALESCE(
           CASE WHEN max(p.hora) >= time '23:00' THEN time '23:59' ELSE max(p.hora) + interval '1 hour' END,
           CASE WHEN d.dia <= 5 THEN time '18:00' ELSE time '13:00' END) AS fin,
         count(p.hora) > 0 AS activo
  FROM public.trabajadores t
  CROSS JOIN generate_series(1, 7) AS d(dia)
  LEFT JOIN public.trabajador_horas_publicadas p
    ON p.id_usuario = t.id_usuario AND p.dia_semana = d.dia
  GROUP BY t.id_usuario, d.dia
)
INSERT INTO public.trabajador_horarios (id_usuario, dia_semana, hora_inicio, hora_fin, activo, horarios)
SELECT v.id_usuario, v.dia, v.inicio, v.fin, v.activo, '[]'::jsonb
FROM ventanas v
ON CONFLICT (id_usuario, dia_semana) DO NOTHING;

-- Estructura final de trabajador_horarios.
DROP TRIGGER IF EXISTS trabajador_horarios_normalizar ON public.trabajador_horarios;
DROP FUNCTION IF EXISTS public.trabajador_horarios_normalizar();
ALTER TABLE public.trabajador_horarios DROP COLUMN horarios;
UPDATE public.trabajador_horarios SET activo = true WHERE activo IS NULL;
ALTER TABLE public.trabajador_horarios
  ALTER COLUMN dia_semana SET NOT NULL,
  ALTER COLUMN hora_inicio SET NOT NULL,
  ALTER COLUMN hora_fin SET NOT NULL,
  ALTER COLUMN activo SET NOT NULL,
  ALTER COLUMN activo SET DEFAULT true,
  ADD CONSTRAINT trabajador_horarios_rango_chk CHECK (NOT activo OR hora_inicio < hora_fin);

CREATE OR REPLACE FUNCTION public.trabajador_horarios_tocar()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  NEW.actualizado_en := now();
  RETURN NEW;
END;
$function$;

CREATE TRIGGER trabajador_horarios_tocar
  BEFORE INSERT OR UPDATE ON public.trabajador_horarios
  FOR EACH ROW EXECUTE FUNCTION public.trabajador_horarios_tocar();

-- Un profesional nuevo recibe sus 7 filas (lunes a viernes 09-18 activos).
CREATE OR REPLACE FUNCTION public._asegurar_ventanas_horario(p_id uuid)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  INSERT INTO public.trabajador_horarios (id_usuario, dia_semana, hora_inicio, hora_fin, activo)
  SELECT p_id, d.dia, time '09:00',
         CASE WHEN d.dia <= 5 THEN time '18:00' ELSE time '13:00' END,
         d.dia <= 5
  FROM generate_series(1, 7) AS d(dia)
  ON CONFLICT (id_usuario, dia_semana) DO NOTHING;
$function$;
REVOKE ALL ON FUNCTION public._asegurar_ventanas_horario(uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.trabajador_horarios_desde_alta()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM public._asegurar_ventanas_horario(NEW.id_usuario);
  RETURN NEW;
END;
$function$;

-- Horas publicadas: mismas reglas de acceso que tenía trabajador_horarios.
ALTER TABLE public.trabajador_horas_publicadas ENABLE ROW LEVEL SECURITY;
CREATE POLICY trabajador_horas_publicadas_select ON public.trabajador_horas_publicadas
  FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY trabajador_horas_publicadas_insert ON public.trabajador_horas_publicadas
  FOR INSERT TO authenticated
  WITH CHECK (id_usuario = (SELECT auth.uid()) OR (SELECT public.is_admin()));
CREATE POLICY trabajador_horas_publicadas_update ON public.trabajador_horas_publicadas
  FOR UPDATE TO authenticated
  USING (id_usuario = (SELECT auth.uid()) OR (SELECT public.is_admin()))
  WITH CHECK (id_usuario = (SELECT auth.uid()) OR (SELECT public.is_admin()));
CREATE POLICY trabajador_horas_publicadas_delete ON public.trabajador_horas_publicadas
  FOR DELETE TO authenticated
  USING (id_usuario = (SELECT auth.uid()) OR (SELECT public.is_admin()));

REVOKE ALL ON public.trabajador_horas_publicadas FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.trabajador_horas_publicadas TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.trabajador_horas_publicadas TO authenticated;
GRANT ALL ON public.trabajador_horas_publicadas TO service_role;

-- RPC con la misma firma y el mismo resultado jsonb [{"dia":1,"hora":"09:00"}, ...].
CREATE OR REPLACE FUNCTION public.guardar_horarios_propios(p_horarios jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_norm jsonb;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.trabajadores t WHERE t.id_usuario = v_uid
  ) THEN
    RAISE EXCEPTION 'solo el profesional puede editar su agenda';
  END IF;

  v_norm := public.normalizar_bloques_horario(p_horarios);

  PERFORM public._asegurar_ventanas_horario(v_uid);
  DELETE FROM public.trabajador_horas_publicadas WHERE id_usuario = v_uid;
  INSERT INTO public.trabajador_horas_publicadas (id_usuario, dia_semana, hora)
  SELECT v_uid, (e->>'dia')::smallint, (e->>'hora')::time
  FROM jsonb_array_elements(v_norm) AS e
  ON CONFLICT DO NOTHING;

  RETURN v_norm;
END;
$function$;

CREATE OR REPLACE FUNCTION public.horarios_disponibles_propios()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object('dia', h.dia_semana, 'hora', to_char(h.hora, 'HH24:MI'))
      ORDER BY h.dia_semana, h.hora
    ),
    '[]'::jsonb
  )
  FROM public.trabajador_horas_publicadas h
  WHERE h.id_usuario = auth.uid();
$function$;

CREATE OR REPLACE FUNCTION public.horarios_libres_profesional(p_id_trabajador uuid, p_dias integer DEFAULT 14)
 RETURNS TABLE(inicio timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.trabajos_horario_unico()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;

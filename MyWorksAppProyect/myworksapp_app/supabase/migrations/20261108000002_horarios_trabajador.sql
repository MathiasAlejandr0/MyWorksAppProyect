-- Horarios de atencion del profesional y una sola reserva por hora.
-- El cliente ve las horas que el trabajador publico, no una grilla fija.

BEGIN;

ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS horarios_disponibles jsonb NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.trabajadores.horarios_disponibles IS
  'Bloques semanales {dia: 1-7 ISO, hora: HH:MM}. El profesional los edita en Mi agenda.';

GRANT UPDATE (horarios_disponibles) ON TABLE public.trabajadores TO authenticated;

CREATE OR REPLACE FUNCTION public.trabajadores_normalizar_horarios()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  NEW.horarios_disponibles := (
    SELECT coalesce(
      jsonb_agg(
        jsonb_build_object('dia', (elem->>'dia')::int, 'hora', elem->>'hora')
        ORDER BY (elem->>'dia')::int, elem->>'hora'
      ),
      '[]'::jsonb
    )
    FROM (
      SELECT DISTINCT ON ((elem->>'dia')::int, elem->>'hora') elem
      FROM jsonb_array_elements(coalesce(NEW.horarios_disponibles, '[]'::jsonb)) AS elem
      WHERE jsonb_typeof(elem) = 'object'
        AND (elem->>'dia') ~ '^[1-7]$'
        AND (elem->>'hora') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
      ORDER BY (elem->>'dia')::int, elem->>'hora'
    ) AS filtrados
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajadores_normalizar_horarios ON public.trabajadores;
CREATE TRIGGER trabajadores_normalizar_horarios
  BEFORE INSERT OR UPDATE OF horarios_disponibles ON public.trabajadores
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajadores_normalizar_horarios();

CREATE OR REPLACE FUNCTION public.trabajos_horario_unico()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
  v_prog timestamptz;
BEGIN
  v_prog := public.texto_a_timestamptz(NEW.fecha_programada::text);
  IF v_prog IS NOT NULL THEN
    NEW.fecha_programada := date_trunc('minute', v_prog);
  END IF;

  IF v_prog IS NULL OR NEW.id_trabajador IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.estado IN ('cancelado', 'expirado', 'completado', 'no_asistio') THEN
    RETURN NEW;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.trabajos t
    WHERE t.id_trabajador = NEW.id_trabajador
      AND t.id IS DISTINCT FROM NEW.id
      AND t.fecha_programada IS NOT NULL
      AND date_trunc('minute', public.texto_a_timestamptz(t.fecha_programada::text))
        = date_trunc('minute', v_prog)
      AND t.estado NOT IN ('cancelado', 'expirado', 'completado', 'no_asistio')
  ) THEN
    RAISE EXCEPTION 'ese horario ya esta reservado con este profesional';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajos_horario_unico ON public.trabajos;
CREATE TRIGGER trabajos_horario_unico
  BEFORE INSERT OR UPDATE OF id_trabajador, fecha_programada, estado ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_horario_unico();

CREATE INDEX IF NOT EXISTS trabajos_trabajador_fecha_programada_idx
  ON public.trabajos (id_trabajador, fecha_programada)
  WHERE fecha_programada IS NOT NULL AND id_trabajador IS NOT NULL;

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

  SELECT t.horarios_disponibles
  INTO v_slots
  FROM public.trabajadores t
  WHERE t.id_usuario = p_id_trabajador;

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
          AND date_trunc('minute', public.texto_a_timestamptz(t.fecha_programada::text))
            = date_trunc('minute', v_ts)
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
REVOKE ALL ON FUNCTION public.trabajadores_normalizar_horarios() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.trabajos_horario_unico() FROM PUBLIC, anon, authenticated;

-- Cuentas ya publicadas: una plantilla inicial. Cada profesional la puede cambiar.
UPDATE public.trabajadores
SET horarios_disponibles = (
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object('dia', d.dia, 'hora', h.hora)
      ORDER BY d.dia, h.hora
    ),
    '[]'::jsonb
  )
  FROM (VALUES (1), (2), (3), (4), (5)) AS d(dia)
  CROSS JOIN (VALUES ('09:00'), ('11:00'), ('14:00'), ('16:00'), ('18:00')) AS h(hora)
)
WHERE coalesce(jsonb_array_length(horarios_disponibles), 0) = 0
  AND coalesce(precios_configurados, 0) = 1;

CREATE OR REPLACE FUNCTION public.mensajes_bloquear_contacto()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF public.texto_tiene_contacto(NEW.contenido) THEN
    RAISE EXCEPTION 'mensaje bloqueado: este tipo de contenido no esta permitido';
  END IF;
  RETURN NEW;
END;
$$;

COMMIT;

-- Cierra la auditoría de horarios y chat:
-- hora publicada en servidor, lock + unique, tope de esperando_pago,
-- filtro de contacto más estricto, UPDATE solo leído, agenda oculta al catálogo.

BEGIN;

CREATE OR REPLACE FUNCTION public.texto_tiene_contacto(p_texto text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $$
DECLARE
  v text := COALESCE(p_texto, '');
BEGIN
  IF btrim(v) = '' THEN
    RETURN false;
  END IF;
  IF v ~* '[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}' THEN
    RETURN true;
  END IF;
  IF v ~* '\marroba\M' THEN
    RETURN true;
  END IF;
  IF v ~* '(whats[[:space:]]*app|w[aá]ts?a+p+|\mwsp\M|guasap|wasap|ll[aá]mame|h[aá]blame[[:space:]]+al|telegram|\minsta\M|instagram|wa\.me|t\.me|(plus|m[aá]s)[[:space:]]*56)' THEN
    RETURN true;
  END IF;
  IF v ~* '(https?://|www\.)' THEN
    RETURN true;
  END IF;
  IF v ~* '\m[a-z0-9\-]+\.(cl|com|net|org)\M' THEN
    RETURN true;
  END IF;
  -- Móvil 9xxxxxxxx o fijo Santiago 2xxxxxxxx, con espacios o puntos.
  IF v ~ '(^|[^0-9])(\+?56[[:space:].-]*)?[29]([[:space:].-]?[0-9]){8}([^0-9]|$)' THEN
    RETURN true;
  END IF;
  IF v ~* '(cero|uno|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)([[:space:],-]+(cero|uno|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)){6,}' THEN
    RETURN true;
  END IF;
  RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION public.mensajes_bloquear_contacto()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_prev text;
  v_blob text;
BEGIN
  SELECT string_agg(contenido, ' ' ORDER BY creado_en)
  INTO v_prev
  FROM (
    SELECT contenido, creado_en
    FROM public.mensajes
    WHERE id_trabajo = NEW.id_trabajo
      AND id_remitente = NEW.id_remitente
      AND id IS DISTINCT FROM NEW.id
    ORDER BY creado_en DESC NULLS LAST
    LIMIT 2
  ) AS recientes;

  v_blob := concat_ws(
    ' ',
    v_prev,
    NEW.contenido,
    NEW.ruta_imagen
  );

  IF public.texto_tiene_contacto(v_blob) THEN
    RAISE EXCEPTION 'mensaje bloqueado: este tipo de contenido no esta permitido';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS mensajes_bloquear_contacto ON public.mensajes;
CREATE TRIGGER mensajes_bloquear_contacto
  BEFORE INSERT OR UPDATE OF contenido, ruta_imagen ON public.mensajes
  FOR EACH ROW
  EXECUTE FUNCTION public.mensajes_bloquear_contacto();

CREATE OR REPLACE FUNCTION public.mensajes_solo_marcar_leido()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;
  IF NEW.contenido IS DISTINCT FROM OLD.contenido
     OR NEW.ruta_imagen IS DISTINCT FROM OLD.ruta_imagen
     OR NEW.tipo IS DISTINCT FROM OLD.tipo
     OR NEW.id_trabajo IS DISTINCT FROM OLD.id_trabajo
     OR NEW.id_remitente IS DISTINCT FROM OLD.id_remitente
     OR NEW.id_destinatario IS DISTINCT FROM OLD.id_destinatario
     OR NEW.creado_en IS DISTINCT FROM OLD.creado_en THEN
    RAISE EXCEPTION 'solo se puede marcar el mensaje como leido';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS mensajes_solo_marcar_leido ON public.mensajes;
CREATE TRIGGER mensajes_solo_marcar_leido
  BEFORE UPDATE ON public.mensajes
  FOR EACH ROW
  EXECUTE FUNCTION public.mensajes_solo_marcar_leido();

REVOKE ALL ON FUNCTION public.mensajes_solo_marcar_leido() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.minuto_utc(p_valor text)
RETURNS timestamptz
LANGUAGE sql
IMMUTABLE
SET timezone TO 'UTC'
SET search_path TO 'public'
AS $$
  SELECT date_trunc('minute', public.texto_a_timestamptz(p_valor));
$$;

REVOKE ALL ON FUNCTION public.minuto_utc(text) FROM PUBLIC, anon, authenticated;

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

    SELECT t.horarios_disponibles
    INTO v_slots
    FROM public.trabajadores t
    WHERE t.id_usuario = NEW.id_trabajador;

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

DROP TRIGGER IF EXISTS trabajos_horario_unico ON public.trabajos;
CREATE TRIGGER trabajos_horario_unico
  BEFORE INSERT OR UPDATE OF id_trabajador, fecha_programada, estado ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_horario_unico();

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.trabajos t
    WHERE t.fecha_programada IS NOT NULL
      AND t.id_trabajador IS NOT NULL
      AND t.estado NOT IN ('cancelado', 'expirado', 'completado', 'no_asistio')
    GROUP BY t.id_trabajador, public.minuto_utc(t.fecha_programada::text)
    HAVING count(*) > 1
  ) THEN
    RAISE NOTICE 'hay reservas duplicadas; se omite el UNIQUE y queda el lock';
    RETURN;
  END IF;

  EXECUTE $idx$
    CREATE UNIQUE INDEX IF NOT EXISTS trabajos_trabajador_minuto_activo_uidx
    ON public.trabajos (
      id_trabajador,
      (public.minuto_utc(fecha_programada::text))
    )
    WHERE fecha_programada IS NOT NULL
      AND id_trabajador IS NOT NULL
      AND estado NOT IN ('cancelado', 'expirado', 'completado', 'no_asistio')
  $idx$;
EXCEPTION
  WHEN unique_violation THEN
    RAISE NOTICE 'no se pudo crear el UNIQUE; queda el advisory lock';
END;
$$;

CREATE OR REPLACE FUNCTION public.horarios_disponibles_propios()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT coalesce(horarios_disponibles, '[]'::jsonb)
  FROM public.trabajadores
  WHERE id_usuario = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.horarios_disponibles_propios() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.horarios_disponibles_propios() TO authenticated;

GRANT SELECT ON TABLE public.trabajadores TO anon, authenticated;
GRANT UPDATE (horarios_disponibles) ON TABLE public.trabajadores TO authenticated;

COMMIT;

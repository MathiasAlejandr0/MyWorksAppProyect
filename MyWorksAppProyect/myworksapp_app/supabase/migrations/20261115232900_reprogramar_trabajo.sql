-- Reagendar un trabajo ya reservado.
--
-- Reglas:
--   * Solo el cliente o el profesional del trabajo, y solo mientras el
--     trabajo está pendiente o aceptado (antes de "en camino") y su hora
--     actual todavía no llega.
--   * Una parte propone una hora nueva; la otra la acepta o la rechaza.
--     Hay a lo más una propuesta pendiente por trabajo (proponer de nuevo
--     reemplaza la propia) y un máximo de 6 propuestas por trabajo.
--   * La hora propuesta debe ser un horario publicado y libre del
--     profesional (misma fuente que horarios_libres_profesional); al aceptar,
--     el trigger trabajos_horario_unico lo vuelve a validar con bloqueo.
--   * Con una disputa activa no se reagenda.
--   * El cobro retenido (escrow) no se toca: solo cambia fecha_programada.
--   * Cada propuesta queda como historial (quién, cuándo, de qué hora a cuál,
--     respuesta) y cada paso notifica a la otra parte.
--   * Fuera de estos RPC, fecha_programada ya no cambia por UPDATE directo
--     de un cliente o profesional (antes la política de UPDATE lo permitía).
-- No borra ni modifica filas existentes.

BEGIN;

CREATE TABLE IF NOT EXISTS public.reprogramaciones_trabajo (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_trabajo text NOT NULL REFERENCES public.trabajos (id) ON DELETE CASCADE,
  propuesta_por uuid NOT NULL,
  rol_proponente text NOT NULL CHECK (rol_proponente IN ('cliente', 'profesional')),
  fecha_anterior timestamptz NOT NULL,
  fecha_propuesta timestamptz NOT NULL,
  motivo text CHECK (motivo IS NULL OR char_length(motivo) <= 300),
  estado text NOT NULL DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente', 'aceptada', 'rechazada', 'retirada', 'vencida')),
  respondida_por uuid,
  respondida_en timestamptz,
  creado_en timestamptz NOT NULL DEFAULT now(),
  CHECK (fecha_propuesta <> fecha_anterior)
);

COMMENT ON TABLE public.reprogramaciones_trabajo IS
  'Historial de propuestas para reagendar un trabajo. Solo se escribe vía RPC.';

CREATE UNIQUE INDEX IF NOT EXISTS reprogramaciones_una_pendiente
  ON public.reprogramaciones_trabajo (id_trabajo)
  WHERE estado = 'pendiente';
CREATE INDEX IF NOT EXISTS reprogramaciones_por_trabajo
  ON public.reprogramaciones_trabajo (id_trabajo, creado_en DESC);

ALTER TABLE public.reprogramaciones_trabajo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS reprogramaciones_select ON public.reprogramaciones_trabajo;
CREATE POLICY reprogramaciones_select ON public.reprogramaciones_trabajo
  FOR SELECT TO authenticated
  USING (public.es_parte_trabajo(id_trabajo));

REVOKE ALL ON public.reprogramaciones_trabajo FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.reprogramaciones_trabajo TO authenticated;
GRANT ALL ON public.reprogramaciones_trabajo TO service_role;

-- Notificación para la otra parte (mismo formato que el resto de la base).
CREATE OR REPLACE FUNCTION public._notificar_reprogramacion(
  p_destino uuid,
  p_id_trabajo text,
  p_titulo text,
  p_cuerpo text
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  INSERT INTO public.notificaciones (
    id, id_usuario, tipo, titulo, cuerpo, id_relacionado, leido, creado_en
  )
  SELECT
    gen_random_uuid()::text,
    p_destino,
    'job_rescheduled',
    p_titulo,
    p_cuerpo,
    p_id_trabajo,
    0,
    to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE p_destino IS NOT NULL;
$$;
REVOKE ALL ON FUNCTION public._notificar_reprogramacion(uuid, text, text, text) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public._hora_santiago(p_ts timestamptz)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT to_char(p_ts AT TIME ZONE 'America/Santiago', 'DD/MM HH24:MI');
$$;
REVOKE ALL ON FUNCTION public._hora_santiago(timestamptz) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public._hora_santiago(timestamptz) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.proponer_reprogramacion(
  p_trabajo_id text,
  p_fecha timestamptz,
  p_motivo text DEFAULT NULL
)
RETURNS public.reprogramaciones_trabajo
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_job public.trabajos%ROWTYPE;
  v_actual timestamptz;
  v_nueva timestamptz := date_trunc('minute', p_fecha);
  v_rol text;
  v_destino uuid;
  v_row public.reprogramaciones_trabajo%ROWTYPE;
  v_previa public.reprogramaciones_trabajo%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF p_trabajo_id IS NULL OR p_fecha IS NULL THEN
    RAISE EXCEPTION 'Indica el trabajo y la nueva hora';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id::text = btrim(p_trabajo_id) FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;

  IF v_job.id_usuario = v_uid THEN
    v_rol := 'cliente';
    v_destino := v_job.id_trabajador;
  ELSIF v_job.id_trabajador = v_uid THEN
    v_rol := 'profesional';
    v_destino := v_job.id_usuario;
  ELSE
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_job.id_trabajador IS NULL THEN
    RAISE EXCEPTION 'El trabajo todavía no tiene profesional asignado';
  END IF;
  IF v_job.estado NOT IN ('pendiente', 'aceptado') THEN
    RAISE EXCEPTION 'Solo se puede reagendar antes de que el profesional salga en camino';
  END IF;

  v_actual := public.texto_a_timestamptz(v_job.fecha_programada::text);
  IF v_actual IS NULL THEN
    RAISE EXCEPTION 'El trabajo no tiene una hora agendada';
  END IF;
  IF v_actual <= now() THEN
    RAISE EXCEPTION 'La hora del trabajo ya pasó: no se puede reagendar';
  END IF;
  IF v_nueva = date_trunc('minute', v_actual) THEN
    RAISE EXCEPTION 'Elige una hora distinta a la actual';
  END IF;
  IF v_nueva <= now() + interval '1 hour' THEN
    RAISE EXCEPTION 'La nueva hora debe ser al menos una hora más tarde que ahora';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.disputas d
    WHERE d.id_trabajo = v_job.id
      AND public.disputa_esta_activa(d.estado)
  ) THEN
    RAISE EXCEPTION 'Con una disputa abierta no se puede reagendar';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.horarios_libres_profesional(v_job.id_trabajador, 21) h
    WHERE date_trunc('minute', h.inicio) = v_nueva
  ) THEN
    RAISE EXCEPTION 'Esa hora no está publicada o ya está tomada por el profesional';
  END IF;

  SELECT * INTO v_previa
  FROM public.reprogramaciones_trabajo r
  WHERE r.id_trabajo = v_job.id AND r.estado = 'pendiente'
  FOR UPDATE;
  IF FOUND THEN
    IF v_previa.propuesta_por <> v_uid THEN
      RAISE EXCEPTION 'La otra parte ya propuso una hora: acéptala o recházala primero';
    END IF;
    UPDATE public.reprogramaciones_trabajo
    SET estado = 'retirada', respondida_por = v_uid, respondida_en = now()
    WHERE id = v_previa.id;
  END IF;

  IF (SELECT count(*) FROM public.reprogramaciones_trabajo r WHERE r.id_trabajo = v_job.id) >= 6 THEN
    RAISE EXCEPTION 'Este trabajo ya tuvo demasiadas propuestas de cambio de hora';
  END IF;

  INSERT INTO public.reprogramaciones_trabajo (
    id_trabajo, propuesta_por, rol_proponente, fecha_anterior, fecha_propuesta, motivo
  ) VALUES (
    v_job.id,
    v_uid,
    v_rol,
    date_trunc('minute', v_actual),
    v_nueva,
    NULLIF(left(btrim(COALESCE(p_motivo, '')), 300), '')
  )
  RETURNING * INTO v_row;

  PERFORM public._notificar_reprogramacion(
    v_destino,
    v_job.id,
    'Propuesta para cambiar la hora',
    CASE WHEN v_rol = 'cliente' THEN 'El cliente' ELSE 'El profesional' END
      || ' propone mover la visita del '
      || public._hora_santiago(v_row.fecha_anterior) || ' al '
      || public._hora_santiago(v_row.fecha_propuesta)
      || '. Acéptala o recházala en el detalle del trabajo.'
  );

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.responder_reprogramacion(
  p_id uuid,
  p_acepta boolean
)
RETURNS public.reprogramaciones_trabajo
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_row public.reprogramaciones_trabajo%ROWTYPE;
  v_job public.trabajos%ROWTYPE;
  v_actual timestamptz;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row FROM public.reprogramaciones_trabajo WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'propuesta no encontrada';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id = v_row.id_trabajo FOR UPDATE;
  IF v_uid IS DISTINCT FROM v_job.id_usuario AND v_uid IS DISTINCT FROM v_job.id_trabajador THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_row.estado <> 'pendiente' THEN
    RAISE EXCEPTION 'Esta propuesta ya fue respondida';
  END IF;
  IF v_row.propuesta_por = v_uid THEN
    RAISE EXCEPTION 'La otra parte debe responder tu propuesta';
  END IF;

  v_actual := public.texto_a_timestamptz(v_job.fecha_programada::text);
  IF v_job.estado NOT IN ('pendiente', 'aceptado')
     OR v_actual IS NULL
     OR date_trunc('minute', v_actual) <> v_row.fecha_anterior
     OR v_row.fecha_propuesta <= now() THEN
    UPDATE public.reprogramaciones_trabajo
    SET estado = 'vencida', respondida_en = now()
    WHERE id = v_row.id
    RETURNING * INTO v_row;
    RETURN v_row;
  END IF;

  IF NOT COALESCE(p_acepta, false) THEN
    UPDATE public.reprogramaciones_trabajo
    SET estado = 'rechazada', respondida_por = v_uid, respondida_en = now()
    WHERE id = v_row.id
    RETURNING * INTO v_row;
    PERFORM public._notificar_reprogramacion(
      v_row.propuesta_por,
      v_job.id,
      'Cambio de hora rechazado',
      'Se mantiene la visita del ' || public._hora_santiago(v_row.fecha_anterior) || '.'
    );
    RETURN v_row;
  END IF;

  -- El trigger trabajos_horario_unico valida hora publicada y sin choque.
  PERFORM set_config('mwa.rpc_trabajo', '1', true);
  UPDATE public.trabajos
  SET
    fecha_programada = v_row.fecha_propuesta,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id = v_job.id;
  PERFORM set_config('mwa.rpc_trabajo', '', true);

  UPDATE public.reprogramaciones_trabajo
  SET estado = 'aceptada', respondida_por = v_uid, respondida_en = now()
  WHERE id = v_row.id
  RETURNING * INTO v_row;

  PERFORM public._notificar_reprogramacion(
    v_row.propuesta_por,
    v_job.id,
    'Nueva hora confirmada',
    'La visita quedó para el ' || public._hora_santiago(v_row.fecha_propuesta) || '.'
  );

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.retirar_reprogramacion(p_id uuid)
RETURNS public.reprogramaciones_trabajo
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_row public.reprogramaciones_trabajo%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  UPDATE public.reprogramaciones_trabajo
  SET estado = 'retirada', respondida_por = v_uid, respondida_en = now()
  WHERE id = p_id
    AND propuesta_por = v_uid
    AND estado = 'pendiente'
  RETURNING * INTO v_row;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No hay una propuesta tuya pendiente con ese identificador';
  END IF;
  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.proponer_reprogramacion(text, timestamptz, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.responder_reprogramacion(uuid, boolean) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.retirar_reprogramacion(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.proponer_reprogramacion(text, timestamptz, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.responder_reprogramacion(uuid, boolean) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.retirar_reprogramacion(uuid) TO authenticated, service_role;

-- Si el trabajo avanza (en camino, cancelado…) la propuesta pendiente vence.
CREATE OR REPLACE FUNCTION public.trabajos_vencer_reprogramaciones()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.estado IS DISTINCT FROM OLD.estado
     AND NEW.estado NOT IN ('pendiente', 'aceptado') THEN
    UPDATE public.reprogramaciones_trabajo
    SET estado = 'vencida', respondida_en = now()
    WHERE id_trabajo = NEW.id AND estado = 'pendiente';
  END IF;
  RETURN NULL;
END;
$$;
REVOKE ALL ON FUNCTION public.trabajos_vencer_reprogramaciones() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trabajos_vencer_reprogramaciones ON public.trabajos;
CREATE TRIGGER trabajos_vencer_reprogramaciones
  AFTER UPDATE OF estado ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_vencer_reprogramaciones();

-- fecha_programada de un trabajo existente solo cambia por RPC.
CREATE OR REPLACE FUNCTION public.trabajos_fecha_solo_por_rpc()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF date_trunc('minute', public.texto_a_timestamptz(NEW.fecha_programada::text))
       IS NOT DISTINCT FROM
     date_trunc('minute', public.texto_a_timestamptz(OLD.fecha_programada::text)) THEN
    RETURN NEW;
  END IF;

  IF COALESCE(current_setting('mwa.rpc_trabajo', true), '') = '1'
     OR COALESCE(auth.role(), '') = 'service_role'
     OR public.is_admin()
     OR (auth.role() IS NULL AND auth.uid() IS NULL)
     OR current_user IN ('postgres', 'supabase_admin')
  THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'Para cambiar la hora usa "Reagendar": la otra parte debe aceptarla';
END;
$$;
REVOKE ALL ON FUNCTION public.trabajos_fecha_solo_por_rpc() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trabajos_fecha_solo_por_rpc ON public.trabajos;
CREATE TRIGGER trabajos_fecha_solo_por_rpc
  BEFORE UPDATE OF fecha_programada ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_fecha_solo_por_rpc();

COMMIT;

-- Revisión del profesor patrocinante.
-- Élite del mes, radio urbano sin recargo, reputación del cliente,
-- evidencia obligatoria antes de liberar el escrow y bloqueo de contacto en el chat.
-- Aplicar en el SQL Editor del proyecto. No vuelve a correr migraciones viejas.

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) Ficha del especialista: radio urbano y volumen
-- -----------------------------------------------------------------------------
ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS radio_urbano_km numeric(5,2) NOT NULL DEFAULT 5,
  ADD COLUMN IF NOT EXISTS tarifa_fuera_radio_clp integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS trabajos_completados integer NOT NULL DEFAULT 0;

ALTER TABLE public.trabajadores
  DROP CONSTRAINT IF EXISTS trabajadores_radio_urbano_chk;
ALTER TABLE public.trabajadores
  ADD CONSTRAINT trabajadores_radio_urbano_chk
  CHECK (radio_urbano_km >= 1 AND radio_urbano_km <= 40);

ALTER TABLE public.trabajadores
  DROP CONSTRAINT IF EXISTS trabajadores_tarifa_fuera_radio_chk;
ALTER TABLE public.trabajadores
  ADD CONSTRAINT trabajadores_tarifa_fuera_radio_chk
  CHECK (tarifa_fuera_radio_clp >= 0 AND tarifa_fuera_radio_clp <= 200000);

UPDATE public.trabajadores t
SET trabajos_completados = COALESCE(src.n, 0)
FROM (
  SELECT j.id_trabajador, count(*)::integer AS n
  FROM public.trabajos j
  WHERE j.estado = 'completado'
    AND j.id_trabajador IS NOT NULL
  GROUP BY j.id_trabajador
) src
WHERE t.id_usuario = src.id_trabajador;

ALTER TABLE public.trabajadores
  DROP COLUMN IF EXISTS es_elite;
ALTER TABLE public.trabajadores
  ADD COLUMN es_elite boolean
  GENERATED ALWAYS AS (
    COALESCE(calificacion, 0) >= 4.7 AND trabajos_completados >= 5
  ) STORED;

COMMENT ON COLUMN public.trabajadores.radio_urbano_km IS
  'Kilómetros alrededor de la base donde la movilización es $0.';
COMMENT ON COLUMN public.trabajadores.tarifa_fuera_radio_clp IS
  'Movilización fija si el cliente está fuera del radio urbano. 0 = tampoco cobra fuera.';
COMMENT ON COLUMN public.trabajadores.es_elite IS
  'Destacado del mes: nota >= 4.7 y al menos 5 trabajos completados.';

-- El profesional edita su radio. El volumen y la insignia los calcula el servidor.
GRANT UPDATE (radio_urbano_km, tarifa_fuera_radio_clp)
  ON TABLE public.trabajadores TO authenticated;
REVOKE UPDATE (trabajos_completados) ON TABLE public.trabajadores FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.trabajos_contar_completados()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND OLD.estado IS NOT DISTINCT FROM NEW.estado
     AND OLD.id_trabajador IS NOT DISTINCT FROM NEW.id_trabajador THEN
    RETURN NEW;
  END IF;

  IF TG_OP <> 'INSERT'
     AND OLD.estado = 'completado'
     AND OLD.id_trabajador IS NOT NULL THEN
    UPDATE public.trabajadores
    SET trabajos_completados = GREATEST(trabajos_completados - 1, 0)
    WHERE id_usuario = OLD.id_trabajador;
  END IF;

  IF TG_OP <> 'DELETE'
     AND NEW.estado = 'completado'
     AND NEW.id_trabajador IS NOT NULL THEN
    UPDATE public.trabajadores
    SET trabajos_completados = trabajos_completados + 1
    WHERE id_usuario = NEW.id_trabajador;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trabajos_contar_completados ON public.trabajos;
CREATE TRIGGER trabajos_contar_completados
  AFTER INSERT OR UPDATE OF estado, id_trabajador OR DELETE ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_contar_completados();

REVOKE ALL ON FUNCTION public.trabajos_contar_completados() FROM PUBLIC, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 2) Catálogo: descarta notas bajas y publica élite + radio
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
  prioridad_manual integer,
  radio_urbano_km numeric,
  tarifa_fuera_radio_clp integer,
  es_elite boolean
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
    t.trabajos_completados,
    t.score_listado,
    t.prioridad_manual,
    t.radio_urbano_km,
    t.tarifa_fuera_radio_clp,
    t.es_elite
  FROM public.trabajadores t
  LEFT JOIN public.perfiles p ON p.id = t.id_usuario
  WHERE COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
    AND t.estado_verificacion = 'verificado'
    AND (COALESCE(t.calificacion, 0) = 0 OR t.calificacion >= 3)
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

-- -----------------------------------------------------------------------------
-- 3) Escrow: evidencia antes de pedir conformidad y antes de liberar
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trabajo_tiene_evidencia(p_trabajo_id text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.fotos_trabajo f
    WHERE f.id_trabajo::text = p_trabajo_id
      AND length(btrim(COALESCE(f.ruta_foto, ''))) > 0
  );
$$;

REVOKE ALL ON FUNCTION public.trabajo_tiene_evidencia(text) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.trabajos_exigir_evidencia()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.estado = 'esperando_aprobacion_cliente'
     AND OLD.estado IS DISTINCT FROM NEW.estado
     AND NOT public.trabajo_tiene_evidencia(NEW.id::text) THEN
    RAISE EXCEPTION 'sube al menos una evidencia antes de declarar el trabajo terminado';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajos_exigir_evidencia ON public.trabajos;
CREATE TRIGGER trabajos_exigir_evidencia
  BEFORE UPDATE OF estado ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_exigir_evidencia();

REVOKE ALL ON FUNCTION public.trabajos_exigir_evidencia() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.cerrar_trabajo_conforme(p_trabajo_id text)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
  v_pago public.pagos%ROWTYPE;
  v_mode text;
  v_tier boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row
  FROM public.trabajos
  WHERE id::text = p_trabajo_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;
  IF v_row.id_usuario::text <> auth.uid()::text THEN
    RAISE EXCEPTION 'solo el cliente puede recibir conforme';
  END IF;
  IF v_row.estado <> 'esperando_aprobacion_cliente' THEN
    RAISE EXCEPTION 'el trabajo no espera tu conformidad';
  END IF;
  IF NOT public.trabajo_tiene_evidencia(v_row.id::text) THEN
    RAISE EXCEPTION 'falta la evidencia del especialista; el pago sigue retenido';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.disputas d
    WHERE d.id_trabajo::text = v_row.id::text
      AND d.estado IN ('abierta', 'en_revision')
  ) THEN
    RAISE EXCEPTION 'hay una disputa abierta; el pago sigue retenido';
  END IF;

  v_mode := COALESCE(v_row.modalidad_cobro::text, 'legado');
  BEGIN
    v_tier := COALESCE(v_row.metadatos_servicio::jsonb ->> 'request_type', '')
      = 'worker_tier_invitation';
  EXCEPTION WHEN others THEN
    v_tier := false;
  END;

  SELECT * INTO v_pago
  FROM public.pagos
  WHERE id_trabajo::text = v_row.id::text
    AND tipo_pago = 'principal'
    AND estado IN ('retenido', 'autorizado', 'liberado')
  ORDER BY creado_en DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND AND (v_mode <> 'legado' OR v_tier) THEN
    RAISE EXCEPTION 'no hay un pago en garantia para liberar';
  END IF;

  IF FOUND AND v_pago.estado IN ('retenido', 'autorizado') THEN
    PERFORM public.marcar_pago_liberado(
      v_pago.id,
      auth.uid()::text,
      'CONFORME-' || left(replace(v_row.id::text, '-', ''), 16),
      'Liberado al recibir conforme el trabajo'
    );
  END IF;

  UPDATE public.trabajos
  SET
    estado = 'completado',
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.cerrar_trabajo_conforme(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cerrar_trabajo_conforme(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.cerrar_trabajo_conforme(text) FROM anon;

-- -----------------------------------------------------------------------------
-- 4) Reputación del cliente (doble valoración)
-- -----------------------------------------------------------------------------
ALTER TABLE public.perfiles
  ADD COLUMN IF NOT EXISTS reputacion_cliente numeric(3,2),
  ADD COLUMN IF NOT EXISTS calificaciones_cliente integer NOT NULL DEFAULT 0;

ALTER TABLE public.perfiles
  DROP CONSTRAINT IF EXISTS perfiles_reputacion_cliente_chk;
ALTER TABLE public.perfiles
  ADD CONSTRAINT perfiles_reputacion_cliente_chk
  CHECK (reputacion_cliente IS NULL OR reputacion_cliente BETWEEN 1 AND 5);

REVOKE UPDATE (reputacion_cliente, calificaciones_cliente)
  ON TABLE public.perfiles FROM anon, authenticated;

CREATE TABLE IF NOT EXISTS public.calificaciones_cliente (
  id text PRIMARY KEY,
  id_trabajo text NOT NULL,
  id_cliente uuid NOT NULL,
  id_trabajador uuid NOT NULL,
  puntaje smallint NOT NULL,
  comentario text,
  creado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT calificaciones_cliente_trabajo_unica UNIQUE (id_trabajo),
  CONSTRAINT calificaciones_cliente_puntaje_chk CHECK (puntaje BETWEEN 1 AND 5)
);

ALTER TABLE public.calificaciones_cliente ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.calificaciones_cliente FROM PUBLIC, anon, authenticated;

DROP POLICY IF EXISTS calificaciones_cliente_select ON public.calificaciones_cliente;
CREATE POLICY calificaciones_cliente_select ON public.calificaciones_cliente
  FOR SELECT TO authenticated
  USING (
    id_cliente::text = (SELECT auth.uid())::text
    OR id_trabajador::text = (SELECT auth.uid())::text
    OR public.is_admin()
  );

GRANT SELECT ON TABLE public.calificaciones_cliente TO authenticated;

CREATE OR REPLACE FUNCTION public.calificar_cliente(
  p_trabajo_id text,
  p_puntaje integer,
  p_comentario text DEFAULT NULL
)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_job public.trabajos%ROWTYPE;
  v_avg numeric;
  v_n integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF p_puntaje IS NULL OR p_puntaje < 1 OR p_puntaje > 5 THEN
    RAISE EXCEPTION 'la nota va de 1 a 5';
  END IF;

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = p_trabajo_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;
  IF v_job.id_trabajador::text IS DISTINCT FROM auth.uid()::text THEN
    RAISE EXCEPTION 'solo el especialista de este trabajo puede calificar al cliente';
  END IF;
  IF v_job.estado <> 'completado' THEN
    RAISE EXCEPTION 'califica al cliente cuando el trabajo ya esta completado';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.disputas d
    WHERE d.id_trabajo::text = v_job.id::text
      AND d.estado IN ('abierta', 'en_revision')
  ) THEN
    RAISE EXCEPTION 'hay una disputa abierta; la reputacion queda en pausa';
  END IF;

  INSERT INTO public.calificaciones_cliente (
    id, id_trabajo, id_cliente, id_trabajador, puntaje, comentario
  ) VALUES (
    gen_random_uuid()::text,
    v_job.id::text,
    v_job.id_usuario,
    auth.uid(),
    p_puntaje,
    NULLIF(left(btrim(COALESCE(p_comentario, '')), 500), '')
  );

  SELECT round(avg(puntaje)::numeric, 2), count(*)::integer
  INTO v_avg, v_n
  FROM public.calificaciones_cliente
  WHERE id_cliente = v_job.id_usuario;

  UPDATE public.perfiles
  SET reputacion_cliente = v_avg,
      calificaciones_cliente = v_n
  WHERE id = v_job.id_usuario;

  RETURN v_avg;
END;
$$;

REVOKE ALL ON FUNCTION public.calificar_cliente(text, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.calificar_cliente(text, integer, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.ver_reputacion_cliente(p_cliente uuid)
RETURNS TABLE (
  reputacion numeric,
  calificaciones integer,
  disputas integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF NOT (
    public.is_admin()
    OR p_cliente = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.trabajos t
      WHERE t.id_usuario = p_cliente
        AND t.id_trabajador = auth.uid()
    )
  ) THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;

  RETURN QUERY
  SELECT
    p.reputacion_cliente,
    COALESCE(p.calificaciones_cliente, 0),
    (
      SELECT count(*)::integer
      FROM public.disputas d
      JOIN public.trabajos t ON t.id::text = d.id_trabajo::text
      WHERE t.id_usuario = p_cliente
        AND d.abierta_por = p_cliente
    )
  FROM public.perfiles p
  WHERE p.id = p_cliente;
END;
$$;

REVOKE ALL ON FUNCTION public.ver_reputacion_cliente(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ver_reputacion_cliente(uuid) TO authenticated;

-- -----------------------------------------------------------------------------
-- 5) Chat: teléfono, correo y enlaces no salen de la app
-- -----------------------------------------------------------------------------
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
  IF v ~* '(whats[[:space:]]*app|\mwsp\M|ll[aá]mame|h[aá]blame[[:space:]]+al|telegram|\minsta\M|instagram|wa\.me|t\.me)' THEN
    RETURN true;
  END IF;
  IF v ~* '(https?://|www\.)' THEN
    RETURN true;
  END IF;
  IF v ~* '\m[a-z0-9\-]+\.(cl|com|net|org)\M' THEN
    RETURN true;
  END IF;
  IF v ~ '(^|[^0-9])(\+?56[[:space:].-]*)?9([[:space:].-]?[0-9]){8}([^0-9]|$)' THEN
    RETURN true;
  END IF;
  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.texto_tiene_contacto(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.texto_tiene_contacto(text) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.mensajes_bloquear_contacto()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF public.texto_tiene_contacto(NEW.contenido) THEN
    RAISE EXCEPTION 'mensaje bloqueado: no compartas telefono, correo ni enlaces';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS mensajes_bloquear_contacto ON public.mensajes;
CREATE TRIGGER mensajes_bloquear_contacto
  BEFORE INSERT OR UPDATE OF contenido ON public.mensajes
  FOR EACH ROW
  EXECUTE FUNCTION public.mensajes_bloquear_contacto();

REVOKE ALL ON FUNCTION public.mensajes_bloquear_contacto() FROM PUBLIC, anon, authenticated;

COMMIT;

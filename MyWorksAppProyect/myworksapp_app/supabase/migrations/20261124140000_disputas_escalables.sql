-- Disputas escalables: procedencia de la evidencia, hash perceptual,
-- apelación y reembolso automático encadenado al cron.
-- Aditiva. No aplica nada en el proyecto remoto.
-- El cron no guarda secretos: lee Vault en el momento de invocar.

BEGIN;

DO $$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
EXCEPTION WHEN OTHERS THEN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pgcrypto ya estaba instalado o no se pudo crear: %', SQLERRM;
  END;
END $$;

INSERT INTO public.app_config (clave, valor)
VALUES
  ('soporte_radio_evidencia_m', '500'),
  ('soporte_plazo_apelacion_horas', '72'),
  ('soporte_ventana_nonce_minutos', '10'),
  ('soporte_reembolso_intentos_max', '8')
ON CONFLICT (clave) DO NOTHING;

ALTER TABLE public.disputas
  ADD COLUMN IF NOT EXISTS puntaje_riesgo integer,
  ADD COLUMN IF NOT EXISTS apelada_en timestamptz,
  ADD COLUMN IF NOT EXISTS apelada_por uuid,
  ADD COLUMN IF NOT EXISTS motivo_apelacion text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'disputas_puntaje_riesgo_chk'
  ) THEN
    ALTER TABLE public.disputas
      ADD CONSTRAINT disputas_puntaje_riesgo_chk
      CHECK (puntaje_riesgo IS NULL OR puntaje_riesgo BETWEEN 0 AND 100);
  END IF;
END $$;

ALTER TABLE public.fotos_trabajo
  ADD COLUMN IF NOT EXISTS origen_captura text,
  ADD COLUMN IF NOT EXISTS tipo_evidencia text,
  ADD COLUMN IF NOT EXISTS latitud double precision,
  ADD COLUMN IF NOT EXISTS longitud double precision,
  ADD COLUMN IF NOT EXISTS capturada_en timestamptz,
  ADD COLUMN IF NOT EXISTS recibida_en timestamptz,
  ADD COLUMN IF NOT EXISTS hash_sha256 text,
  ADD COLUMN IF NOT EXISTS hash_original text,
  ADD COLUMN IF NOT EXISTS hash_perceptual text,
  ADD COLUMN IF NOT EXISTS nonce text,
  ADD COLUMN IF NOT EXISTS confianza text NOT NULL DEFAULT 'no_verificada',
  ADD COLUMN IF NOT EXISTS distancia_metros numeric,
  ADD COLUMN IF NOT EXISTS metadata_original jsonb,
  ADD COLUMN IF NOT EXISTS duplicado boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS duplicado_de text;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fotos_trabajo_origen_chk') THEN
    ALTER TABLE public.fotos_trabajo
      ADD CONSTRAINT fotos_trabajo_origen_chk
      CHECK (origen_captura IS NULL OR origen_captura IN ('camara_app', 'galeria', 'web_archivo', 'desconocido'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fotos_trabajo_tipo_evidencia_chk') THEN
    ALTER TABLE public.fotos_trabajo
      ADD CONSTRAINT fotos_trabajo_tipo_evidencia_chk
      CHECK (tipo_evidencia IS NULL OR tipo_evidencia IN ('antes', 'despues', 'detalle', 'video'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fotos_trabajo_confianza_chk') THEN
    ALTER TABLE public.fotos_trabajo
      ADD CONSTRAINT fotos_trabajo_confianza_chk
      CHECK (confianza IN ('confiable', 'no_verificada'));
  END IF;
END $$;

COMMENT ON COLUMN public.fotos_trabajo.confianza IS
  'confiable solo si la registró la cámara de la app con nonce, hash y GPS dentro del radio. La web y la galería quedan no_verificada.';
COMMENT ON COLUMN public.fotos_trabajo.hash_original IS
  'SHA-256 del archivo antes de pasarlo a WebP. No se borra al convertir.';
COMMENT ON COLUMN public.fotos_trabajo.hash_perceptual IS
  'dHash de 64 bits. Detecta la misma foto en otro trabajo. No dice si la imagen la hizo una IA.';

CREATE TABLE IF NOT EXISTS public.evidencia_nonces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nonce text NOT NULL UNIQUE,
  id_trabajo text NOT NULL,
  id_usuario uuid NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now(),
  expira_en timestamptz NOT NULL,
  usado_en timestamptz,
  id_foto text
);

CREATE INDEX IF NOT EXISTS evidencia_nonces_trabajo_idx
  ON public.evidencia_nonces (id_trabajo, creado_en DESC);

CREATE TABLE IF NOT EXISTS public.evidencia_procedencia (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_foto text NOT NULL,
  id_trabajo text NOT NULL,
  origen_captura text,
  tipo_evidencia text,
  hash_sha256 text,
  hash_original text,
  hash_perceptual text,
  latitud double precision,
  longitud double precision,
  distancia_metros numeric,
  capturada_en timestamptz,
  recibida_en timestamptz NOT NULL DEFAULT now(),
  nonce text,
  confianza text NOT NULL,
  motivo text,
  duplicado_de text,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS evidencia_procedencia_foto_idx
  ON public.evidencia_procedencia (id_foto, creado_en DESC);
CREATE INDEX IF NOT EXISTS evidencia_procedencia_trabajo_idx
  ON public.evidencia_procedencia (id_trabajo);

CREATE TABLE IF NOT EXISTS public.alertas_evidencia (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo text NOT NULL,
  id_foto text,
  id_trabajo text,
  id_foto_previa text,
  id_trabajo_previo text,
  hash_perceptual text,
  detalle text,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS alertas_evidencia_hash_idx
  ON public.alertas_evidencia (hash_perceptual);

CREATE TABLE IF NOT EXISTS public.reembolsos_automaticos (
  id_disputa text PRIMARY KEY,
  id_pago text NOT NULL,
  estado text NOT NULL,
  intentos integer NOT NULL DEFAULT 0,
  ultimo_error text,
  solicitud_id bigint,
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  ejecutado_en timestamptz,
  CONSTRAINT reembolsos_automaticos_estado_chk
    CHECK (estado IN ('pendiente', 'en_curso', 'ejecutado', 'fallido'))
);

CREATE INDEX IF NOT EXISTS fotos_trabajo_hash_perceptual_idx
  ON public.fotos_trabajo (hash_perceptual)
  WHERE hash_perceptual IS NOT NULL;

ALTER TABLE public.evidencia_nonces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidencia_procedencia ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alertas_evidencia ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reembolsos_automaticos ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.evidencia_nonces FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.reembolsos_automaticos FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.evidencia_procedencia FROM PUBLIC, anon;
REVOKE ALL ON TABLE public.alertas_evidencia FROM PUBLIC, anon;
GRANT SELECT ON TABLE public.evidencia_procedencia TO authenticated;
GRANT SELECT ON TABLE public.alertas_evidencia TO authenticated;

DROP POLICY IF EXISTS evidencia_procedencia_select ON public.evidencia_procedencia;
CREATE POLICY evidencia_procedencia_select
  ON public.evidencia_procedencia
  FOR SELECT TO authenticated
  USING (
    public.es_parte_trabajo(id_trabajo)
    OR public.rol_consola() IN ('administrador', 'soporte')
  );

DROP POLICY IF EXISTS alertas_evidencia_select ON public.alertas_evidencia;
CREATE POLICY alertas_evidencia_select
  ON public.alertas_evidencia
  FOR SELECT TO authenticated
  USING (public.rol_consola() IN ('administrador', 'soporte'));

-- El cliente no puede marcar una foto como confiable ni reescribir el hash.
CREATE OR REPLACE FUNCTION public.fotos_trabajo_bloquear_procedencia()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF current_setting('mwa.evidencia_servidor', true) = '1' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'INSERT' THEN
    NEW.confianza := 'no_verificada';
    NEW.duplicado := false;
    NEW.duplicado_de := NULL;
    NEW.nonce := NULL;
    NEW.hash_sha256 := NULL;
    NEW.hash_perceptual := NULL;
    NEW.distancia_metros := NULL;
    NEW.recibida_en := now();
    IF NEW.origen_captura IS DISTINCT FROM 'web_archivo'
       AND NEW.origen_captura IS DISTINCT FROM 'galeria' THEN
      NEW.origen_captura := 'desconocido';
    END IF;
    RETURN NEW;
  END IF;
  NEW.confianza := OLD.confianza;
  NEW.duplicado := OLD.duplicado;
  NEW.duplicado_de := OLD.duplicado_de;
  NEW.nonce := OLD.nonce;
  NEW.hash_sha256 := OLD.hash_sha256;
  NEW.hash_original := OLD.hash_original;
  NEW.hash_perceptual := OLD.hash_perceptual;
  NEW.distancia_metros := OLD.distancia_metros;
  NEW.origen_captura := OLD.origen_captura;
  NEW.latitud := OLD.latitud;
  NEW.longitud := OLD.longitud;
  NEW.capturada_en := OLD.capturada_en;
  NEW.recibida_en := OLD.recibida_en;
  NEW.metadata_original := OLD.metadata_original;
  NEW.imagen_webp := OLD.imagen_webp;
  NEW.tipo_evidencia := OLD.tipo_evidencia;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS fotos_trabajo_bloquear_procedencia ON public.fotos_trabajo;
CREATE TRIGGER fotos_trabajo_bloquear_procedencia
  BEFORE INSERT OR UPDATE ON public.fotos_trabajo
  FOR EACH ROW
  EXECUTE FUNCTION public.fotos_trabajo_bloquear_procedencia();

REVOKE ALL ON FUNCTION public.fotos_trabajo_bloquear_procedencia() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.distancia_metros(
  p_lat1 double precision,
  p_lng1 double precision,
  p_lat2 double precision,
  p_lng2 double precision
) RETURNS numeric
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT (
    6371000 * 2 * asin(sqrt(least(1::double precision,
      power(sin(radians(p_lat2 - p_lat1) / 2), 2)
      + cos(radians(p_lat1)) * cos(radians(p_lat2))
        * power(sin(radians(p_lng2 - p_lng1) / 2), 2)
    )))
  )::numeric;
$$;

-- dHash: 8 filas de 9 luminancias. Cada bit compara un pixel con el de la derecha.
CREATE OR REPLACE FUNCTION public.dhash_desde_luma(p_luma bytea)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $$
DECLARE
  v_hex text := '';
  v_nibble integer := 0;
  v_count integer := 0;
  v_row integer;
  v_col integer;
  v_left integer;
  v_right integer;
  v_bit integer;
BEGIN
  IF p_luma IS NULL OR octet_length(p_luma) <> 72 THEN
    RAISE EXCEPTION 'la muestra perceptual debe tener 72 bytes';
  END IF;
  FOR v_row IN 0..7 LOOP
    FOR v_col IN 0..7 LOOP
      v_left := get_byte(p_luma, v_row * 9 + v_col);
      v_right := get_byte(p_luma, v_row * 9 + v_col + 1);
      v_bit := CASE WHEN v_left > v_right THEN 1 ELSE 0 END;
      v_nibble := v_nibble * 2 + v_bit;
      v_count := v_count + 1;
      IF v_count = 4 THEN
        v_hex := v_hex || substr('0123456789abcdef', v_nibble + 1, 1);
        v_nibble := 0;
        v_count := 0;
      END IF;
    END LOOP;
  END LOOP;
  RETURN v_hex;
END;
$$;

CREATE OR REPLACE FUNCTION public.distancia_hamming_hex(p_a text, p_b text)
RETURNS integer
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT count(*)::integer
  FROM generate_series(0, 63) AS g(i)
  WHERE get_bit(decode(lower(p_a), 'hex'), g.i)
     IS DISTINCT FROM get_bit(decode(lower(p_b), 'hex'), g.i);
$$;

CREATE OR REPLACE FUNCTION public.trabajo_tiene_evidencia_confiable(p_trabajo_id text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    EXISTS (
      SELECT 1
      FROM public.fotos_trabajo f
      WHERE f.id_trabajo::text = p_trabajo_id
        AND f.tipo_evidencia = 'antes'
        AND f.confianza = 'confiable'
        AND f.origen_captura = 'camara_app'
        AND COALESCE(f.duplicado, false) = false
        AND f.distancia_metros IS NOT NULL
        AND f.distancia_metros <= public.soporte_numero('soporte_radio_evidencia_m', 500)
    )
    AND EXISTS (
      SELECT 1
      FROM public.fotos_trabajo f
      WHERE f.id_trabajo::text = p_trabajo_id
        AND f.tipo_evidencia = 'despues'
        AND f.confianza = 'confiable'
        AND f.origen_captura = 'camara_app'
        AND COALESCE(f.duplicado, false) = false
        AND f.distancia_metros IS NOT NULL
        AND f.distancia_metros <= public.soporte_numero('soporte_radio_evidencia_m', 500)
    );
$$;

CREATE OR REPLACE FUNCTION public.registrar_alerta_evidencia_duplicada(
  p_id_foto text,
  p_id_trabajo text,
  p_id_previa text,
  p_id_trabajo_previo text,
  p_hash text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_detalle text := left(
    'Foto reutilizada. Actual ' || COALESCE(p_id_foto, '')
    || ' trabajo ' || COALESCE(p_id_trabajo, '')
    || '. Previa ' || COALESCE(p_id_previa, '')
    || ' trabajo ' || COALESCE(p_id_trabajo_previo, ''),
    500
  );
BEGIN
  INSERT INTO public.alertas_evidencia (
    tipo, id_foto, id_trabajo, id_foto_previa, id_trabajo_previo, hash_perceptual, detalle
  ) VALUES (
    'evidencia_duplicada', p_id_foto, p_id_trabajo, p_id_previa, p_id_trabajo_previo, p_hash, v_detalle
  );

  IF to_regclass('public.ia_fraude') IS NULL THEN
    RETURN;
  END IF;

  BEGIN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'ia_fraude' AND column_name = 'regla'
    ) THEN
      EXECUTE
        'INSERT INTO public.ia_fraude (regla, detalle, creado_en) VALUES ($1, $2, now())'
        USING 'evidencia_duplicada', v_detalle;
    ELSIF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'ia_fraude' AND column_name = 'tipo'
    ) THEN
      EXECUTE
        'INSERT INTO public.ia_fraude (tipo, detalle, creado_en) VALUES ($1, $2, now())'
        USING 'evidencia_duplicada', v_detalle;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ia_fraude no recibió la alerta de evidencia';
  END;
END;
$$;

DROP FUNCTION IF EXISTS public.clasificar_disputa(text, text);

CREATE FUNCTION public.clasificar_disputa(
  p_trabajo_id text,
  p_motivo text
)
RETURNS TABLE (decision text, regla text, estado text, vence timestamptz, puntaje integer)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_motivo text := lower(btrim(COALESCE(p_motivo, '')));
  v_monto numeric := 0;
  v_prev integer := 0;
  v_max numeric := public.soporte_numero('soporte_monto_max_auto', 80000);
  v_reinc integer := public.soporte_numero('soporte_reincidencia_max', 1)::integer;
  v_horas integer := GREATEST(public.soporte_numero('soporte_plazo_disputa_horas', 24)::integer, 1);
  v_worker uuid;
  v_verificado boolean := false;
  v_confiable boolean := false;
  v_alguna boolean := false;
  v_duplicado boolean := false;
  v_llego boolean := false;
  v_puntaje integer := 10;
BEGIN
  SELECT t.id_trabajador INTO v_worker
  FROM public.trabajos t
  WHERE t.id::text = p_trabajo_id;

  SELECT COALESCE(p.monto, 0) INTO v_monto
  FROM public.pagos p
  WHERE p.id_trabajo::text = p_trabajo_id
    AND p.tipo_pago = 'principal'
  ORDER BY p.creado_en DESC
  LIMIT 1;

  IF v_worker IS NOT NULL THEN
    SELECT COUNT(*) INTO v_prev
    FROM public.disputas d
    JOIN public.trabajos t ON t.id::text = d.id_trabajo::text
    WHERE t.id_trabajador = v_worker
      AND d.estado = 'resuelta';

    SELECT COALESCE(w.estado_verificacion, '') = 'verificado'
    INTO v_verificado
    FROM public.trabajadores w
    WHERE w.id_usuario = v_worker;
  END IF;

  v_confiable := public.trabajo_tiene_evidencia_confiable(p_trabajo_id);
  v_alguna := public.trabajo_tiene_evidencia(p_trabajo_id);
  v_duplicado := EXISTS (
    SELECT 1
    FROM public.fotos_trabajo f
    WHERE f.id_trabajo::text = p_trabajo_id
      AND COALESCE(f.duplicado, false)
  );
  v_llego := EXISTS (
    SELECT 1 FROM public.ubicacion_en_vivo u
    WHERE u.id_trabajo::text = p_trabajo_id
  );

  IF v_motivo = 'conducta' THEN v_puntaje := v_puntaje + 40; END IF;
  IF v_prev >= v_reinc THEN v_puntaje := v_puntaje + 30; END IF;
  IF v_monto > v_max THEN v_puntaje := v_puntaje + 25; END IF;
  IF v_duplicado THEN v_puntaje := v_puntaje + 25; END IF;
  IF v_alguna AND NOT v_confiable THEN v_puntaje := v_puntaje + 20; END IF;
  IF NOT v_llego THEN v_puntaje := v_puntaje + 10; END IF;
  IF NOT v_confiable THEN v_puntaje := v_puntaje + 15; END IF;
  v_puntaje := LEAST(v_puntaje, 100);

  puntaje := v_puntaje;

  IF v_motivo = 'conducta' THEN
    decision := 'humano'; regla := 'conducta'; estado := 'requiere_humano'; vence := NULL;
    RETURN NEXT; RETURN;
  END IF;
  IF v_prev >= v_reinc THEN
    decision := 'humano'; regla := 'reincidencia'; estado := 'requiere_humano'; vence := NULL;
    RETURN NEXT; RETURN;
  END IF;
  IF v_monto > v_max THEN
    decision := 'humano'; regla := 'monto_alto'; estado := 'requiere_humano'; vence := NULL;
    RETURN NEXT; RETURN;
  END IF;
  IF v_duplicado THEN
    decision := 'humano'; regla := 'evidencia_duplicada'; estado := 'requiere_humano'; vence := NULL;
    RETURN NEXT; RETURN;
  END IF;
  IF v_alguna AND NOT v_confiable THEN
    decision := 'humano'; regla := 'evidencia_no_confiable'; estado := 'requiere_humano'; vence := NULL;
    RETURN NEXT; RETURN;
  END IF;
  IF NOT v_alguna AND NOT v_llego THEN
    decision := 'reembolsar'; regla := 'sin_llegada_ni_evidencia'; estado := 'abierta';
    vence := now() + make_interval(hours => v_horas);
    RETURN NEXT; RETURN;
  END IF;
  IF v_confiable AND v_verificado THEN
    decision := 'liberar'; regla := 'primer_reclamo_con_evidencia'; estado := 'abierta';
    vence := now() + make_interval(hours => v_horas);
    RETURN NEXT; RETURN;
  END IF;

  decision := 'humano'; regla := 'revision_manual'; estado := 'requiere_humano'; vence := NULL;
  puntaje := v_puntaje;
  RETURN NEXT;
END;
$$;

CREATE OR REPLACE FUNCTION public.prioridad_por_regla(p_regla text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT CASE p_regla
    WHEN 'conducta' THEN 'alta'
    WHEN 'reincidencia' THEN 'alta'
    WHEN 'evidencia_duplicada' THEN 'alta'
    WHEN 'apelacion' THEN 'alta'
    WHEN 'fallo_reembolso' THEN 'alta'
    WHEN 'monto_alto' THEN 'media'
    WHEN 'evidencia_no_confiable' THEN 'media'
    WHEN 'revision_manual' THEN 'media'
    ELSE 'baja'
  END;
$$;

CREATE OR REPLACE FUNCTION public.abrir_disputa(
  p_id text,
  p_id_trabajo text,
  p_motivo text,
  p_descripcion text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_clase record;
  v_estado_trabajo text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_id IS NULL OR btrim(p_id) = '' OR p_id_trabajo IS NULL OR btrim(p_id_trabajo) = '' THEN
    RAISE EXCEPTION 'Faltan el identificador y el trabajo';
  END IF;
  IF NOT public.es_parte_trabajo(p_id_trabajo) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF btrim(COALESCE(p_motivo, '')) = '' THEN
    RAISE EXCEPTION 'El motivo es requerido';
  END IF;

  SELECT t.estado INTO v_estado_trabajo
  FROM public.trabajos t
  WHERE t.id::text = btrim(p_id_trabajo);
  IF NOT public.trabajo_admite_disputa(v_estado_trabajo) THEN
    RAISE EXCEPTION 'El trabajo ya está cerrado: no admite disputas';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.disputas d
    WHERE d.id_trabajo = p_id_trabajo
      AND public.disputa_esta_activa(d.estado)
  ) THEN
    RAISE EXCEPTION 'Ya existe una disputa abierta para este trabajo';
  END IF;

  SELECT * INTO v_clase
  FROM public.clasificar_disputa(btrim(p_id_trabajo), p_motivo)
  LIMIT 1;

  INSERT INTO public.disputas (
    id, id_trabajo, abierta_por, motivo, descripcion, estado,
    origen, decision_sugerida, motivo_regla, vence_en,
    puntaje_riesgo, prioridad,
    creado_en, actualizado_en
  ) VALUES (
    btrim(p_id),
    btrim(p_id_trabajo),
    v_uid,
    left(btrim(p_motivo), 80),
    NULLIF(left(btrim(COALESCE(p_descripcion, '')), 2000), ''),
    COALESCE(v_clase.estado, 'requiere_humano'),
    CASE WHEN COALESCE(v_clase.decision, 'humano') = 'humano' THEN 'admin' ELSE 'sistema' END,
    COALESCE(v_clase.decision, 'humano'),
    COALESCE(v_clase.regla, 'revision_manual'),
    v_clase.vence,
    COALESCE(v_clase.puntaje, 50),
    public.prioridad_por_regla(COALESCE(v_clase.regla, 'revision_manual')),
    now(),
    now()
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.revaluar_disputa(p_trabajo_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_disputa public.disputas%ROWTYPE;
  v_clase record;
  v_prio text;
BEGIN
  SELECT * INTO v_disputa
  FROM public.disputas
  WHERE id_trabajo::text = btrim(p_trabajo_id)
    AND public.disputa_esta_activa(estado)
  ORDER BY creado_en DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN;
  END IF;
  IF v_disputa.apelada_en IS NOT NULL OR v_disputa.motivo_regla = 'apelacion' THEN
    RETURN;
  END IF;
  IF v_disputa.estado = 'reembolso_pendiente' THEN
    RETURN;
  END IF;

  SELECT * INTO v_clase
  FROM public.clasificar_disputa(v_disputa.id_trabajo::text, v_disputa.motivo)
  LIMIT 1;
  v_prio := public.prioridad_por_regla(COALESCE(v_clase.regla, 'revision_manual'));

  UPDATE public.disputas
  SET estado = COALESCE(v_clase.estado, 'requiere_humano'),
      decision_sugerida = COALESCE(v_clase.decision, 'humano'),
      motivo_regla = COALESCE(v_clase.regla, 'revision_manual'),
      vence_en = v_clase.vence,
      puntaje_riesgo = COALESCE(v_clase.puntaje, puntaje_riesgo),
      prioridad = CASE
        WHEN prioridad = 'alta' THEN prioridad
        WHEN v_prio = 'alta' THEN 'alta'
        WHEN prioridad IS NULL THEN v_prio
        WHEN prioridad = 'baja' AND v_prio = 'media' THEN 'media'
        ELSE prioridad
      END,
      actualizado_en = now()
  WHERE id = v_disputa.id;
END;
$$;

CREATE OR REPLACE FUNCTION public.fotos_trabajo_revaluar_disputa()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  PERFORM public.revaluar_disputa(NEW.id_trabajo::text);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS fotos_trabajo_revaluar_disputa ON public.fotos_trabajo;
CREATE TRIGGER fotos_trabajo_revaluar_disputa
  AFTER INSERT OR UPDATE OF confianza, duplicado, tipo_evidencia, distancia_metros
  ON public.fotos_trabajo
  FOR EACH ROW
  EXECUTE FUNCTION public.fotos_trabajo_revaluar_disputa();

REVOKE ALL ON FUNCTION public.fotos_trabajo_revaluar_disputa() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.pedir_nonce_evidencia(p_id_trabajo text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_nonce text;
  v_minutos integer;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF NOT public.es_parte_trabajo(p_id_trabajo) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.trabajos t WHERE t.id::text = btrim(p_id_trabajo)
  ) THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;
  v_minutos := GREATEST(public.soporte_numero('soporte_ventana_nonce_minutos', 10)::integer, 1);
  v_nonce := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  INSERT INTO public.evidencia_nonces (nonce, id_trabajo, id_usuario, expira_en)
  VALUES (v_nonce, btrim(p_id_trabajo), v_uid, now() + make_interval(mins => v_minutos));
  RETURN v_nonce;
END;
$$;

CREATE OR REPLACE FUNCTION public.registrar_evidencia_captura(
  p_id_foto text,
  p_id_trabajo text,
  p_nonce text,
  p_hash_sha256 text,
  p_hash_original text,
  p_luma bytea,
  p_lat double precision,
  p_lng double precision,
  p_tipo text,
  p_capturada_en timestamptz,
  p_hash_perceptual text
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_nonce public.evidencia_nonces%ROWTYPE;
  v_foto public.fotos_trabajo%ROWTYPE;
  v_job_lat double precision;
  v_job_lng double precision;
  v_dist numeric;
  v_radio numeric;
  v_hash text;
  v_dhash text;
  v_prev_id text;
  v_prev_trabajo text;
  v_tipo text := lower(btrim(COALESCE(p_tipo, '')));
  v_confianza text := 'confiable';
  v_motivo text := 'procedencia_ok';
BEGIN
  IF v_uid IS NULL OR NOT public.es_parte_trabajo(p_id_trabajo) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_tipo NOT IN ('antes', 'despues', 'detalle') THEN
    RAISE EXCEPTION 'tipo de evidencia no permitido';
  END IF;
  IF p_hash_sha256 IS NULL OR lower(p_hash_sha256) !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION 'hash sha256 invalido';
  END IF;
  IF p_lat IS NULL OR p_lng IS NULL
     OR p_lat < -90 OR p_lat > 90 OR p_lng < -180 OR p_lng > 180 THEN
    RAISE EXCEPTION 'falta el gps de la captura';
  END IF;

  SELECT * INTO v_nonce
  FROM public.evidencia_nonces
  WHERE nonce = btrim(COALESCE(p_nonce, ''))
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'nonce desconocido';
  END IF;
  IF v_nonce.usado_en IS NOT NULL THEN
    RAISE EXCEPTION 'nonce ya usado';
  END IF;
  IF v_nonce.expira_en <= now() THEN
    RAISE EXCEPTION 'nonce vencido';
  END IF;
  IF v_nonce.id_trabajo::text <> btrim(p_id_trabajo) OR v_nonce.id_usuario <> v_uid THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_capturada_en IS NOT NULL AND (
    p_capturada_en < v_nonce.creado_en - interval '1 minute'
    OR p_capturada_en > now() + interval '2 minutes'
  ) THEN
    RAISE EXCEPTION 'la captura está fuera de la ventana de tiempo';
  END IF;

  SELECT * INTO v_foto
  FROM public.fotos_trabajo
  WHERE id::text = btrim(p_id_foto)
    AND id_trabajo::text = btrim(p_id_trabajo);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'la evidencia no está registrada';
  END IF;
  IF v_foto.imagen_webp IS NULL OR octet_length(v_foto.imagen_webp) < 12 THEN
    RAISE EXCEPTION 'falta la imagen para verificar el hash';
  END IF;

  v_hash := encode(extensions.digest(v_foto.imagen_webp, 'sha256'), 'hex');
  IF v_hash IS DISTINCT FROM lower(p_hash_sha256) THEN
    RAISE EXCEPTION 'el hash no coincide con el archivo';
  END IF;

  v_dhash := public.dhash_desde_luma(p_luma);
  IF p_hash_perceptual IS NOT NULL AND lower(p_hash_perceptual) <> v_dhash THEN
    RAISE EXCEPTION 'el hash perceptual no coincide';
  END IF;

  SELECT t.latitud, t.longitud INTO v_job_lat, v_job_lng
  FROM public.trabajos t
  WHERE t.id::text = btrim(p_id_trabajo);
  IF v_job_lat IS NULL OR v_job_lng IS NULL THEN
    RAISE EXCEPTION 'el trabajo no tiene coordenadas';
  END IF;
  v_dist := public.distancia_metros(p_lat, p_lng, v_job_lat, v_job_lng);
  v_radio := public.soporte_numero('soporte_radio_evidencia_m', 500);
  IF v_dist > v_radio THEN
    RAISE EXCEPTION 'gps fuera de radio';
  END IF;

  SELECT f.id::text, f.id_trabajo::text INTO v_prev_id, v_prev_trabajo
  FROM public.fotos_trabajo f
  WHERE f.id::text <> btrim(p_id_foto)
    AND f.hash_perceptual IS NOT NULL
    AND public.distancia_hamming_hex(f.hash_perceptual, v_dhash) <= 10
  ORDER BY f.creado_en
  LIMIT 1;

  IF v_prev_id IS NOT NULL THEN
    v_confianza := 'no_verificada';
    v_motivo := 'evidencia_duplicada';
  END IF;

  PERFORM set_config('mwa.evidencia_servidor', '1', true);
  UPDATE public.fotos_trabajo
  SET origen_captura = 'camara_app',
      tipo_evidencia = v_tipo,
      latitud = p_lat,
      longitud = p_lng,
      capturada_en = COALESCE(p_capturada_en, now()),
      recibida_en = now(),
      hash_sha256 = v_hash,
      hash_original = CASE
        WHEN p_hash_original IS NOT NULL AND lower(p_hash_original) ~ '^[0-9a-f]{64}$'
          THEN lower(p_hash_original)
        ELSE hash_original
      END,
      hash_perceptual = v_dhash,
      nonce = v_nonce.nonce,
      confianza = v_confianza,
      distancia_metros = v_dist,
      duplicado = v_prev_id IS NOT NULL,
      duplicado_de = v_prev_id
  WHERE id::text = btrim(p_id_foto);

  INSERT INTO public.evidencia_procedencia (
    id_foto, id_trabajo, origen_captura, tipo_evidencia,
    hash_sha256, hash_original, hash_perceptual,
    latitud, longitud, distancia_metros,
    capturada_en, recibida_en, nonce, confianza, motivo, duplicado_de
  ) VALUES (
    btrim(p_id_foto), btrim(p_id_trabajo), 'camara_app', v_tipo,
    v_hash, NULLIF(lower(COALESCE(p_hash_original, '')), ''), v_dhash,
    p_lat, p_lng, v_dist,
    COALESCE(p_capturada_en, now()), now(), v_nonce.nonce, v_confianza, v_motivo, v_prev_id
  );

  UPDATE public.evidencia_nonces
  SET usado_en = now(), id_foto = btrim(p_id_foto)
  WHERE id = v_nonce.id;

  IF v_prev_id IS NOT NULL THEN
    PERFORM public.registrar_alerta_evidencia_duplicada(
      btrim(p_id_foto), btrim(p_id_trabajo), v_prev_id, v_prev_trabajo, v_dhash
    );
  END IF;

  RETURN jsonb_build_object(
    'confianza', v_confianza,
    'distancia_metros', v_dist,
    'hash_perceptual', v_dhash,
    'duplicado', v_prev_id IS NOT NULL,
    'motivo', v_motivo
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.registrar_evidencia_web(
  p_id_foto text,
  p_id_trabajo text,
  p_hash_original text,
  p_hash_sha256 text,
  p_luma bytea,
  p_tipo text,
  p_metadata jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_foto public.fotos_trabajo%ROWTYPE;
  v_hash text;
  v_dhash text;
  v_prev_id text;
  v_prev_trabajo text;
  v_tipo text := lower(btrim(COALESCE(p_tipo, 'detalle')));
BEGIN
  IF v_uid IS NULL OR NOT public.es_parte_trabajo(p_id_trabajo) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_tipo NOT IN ('antes', 'despues', 'detalle', 'video') THEN
    v_tipo := 'detalle';
  END IF;

  SELECT * INTO v_foto
  FROM public.fotos_trabajo
  WHERE id::text = btrim(p_id_foto)
    AND id_trabajo::text = btrim(p_id_trabajo);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'la evidencia no está registrada';
  END IF;

  IF v_foto.imagen_webp IS NOT NULL AND octet_length(v_foto.imagen_webp) >= 12 THEN
    v_hash := encode(extensions.digest(v_foto.imagen_webp, 'sha256'), 'hex');
    IF p_hash_sha256 IS NOT NULL AND lower(p_hash_sha256) IS DISTINCT FROM v_hash THEN
      RAISE EXCEPTION 'el hash no coincide con el archivo';
    END IF;
  END IF;

  IF p_luma IS NOT NULL THEN
    v_dhash := public.dhash_desde_luma(p_luma);
    SELECT f.id::text, f.id_trabajo::text INTO v_prev_id, v_prev_trabajo
    FROM public.fotos_trabajo f
    WHERE f.id::text <> btrim(p_id_foto)
      AND f.hash_perceptual IS NOT NULL
      AND public.distancia_hamming_hex(f.hash_perceptual, v_dhash) <= 10
    LIMIT 1;
  END IF;

  PERFORM set_config('mwa.evidencia_servidor', '1', true);
  UPDATE public.fotos_trabajo
  SET origen_captura = 'web_archivo',
      tipo_evidencia = v_tipo,
      recibida_en = now(),
      hash_sha256 = v_hash,
      hash_original = CASE
        WHEN p_hash_original IS NOT NULL AND lower(p_hash_original) ~ '^[0-9a-f]{64}$'
          THEN lower(p_hash_original)
        ELSE hash_original
      END,
      hash_perceptual = COALESCE(v_dhash, hash_perceptual),
      confianza = 'no_verificada',
      metadata_original = COALESCE(p_metadata, metadata_original),
      duplicado = v_prev_id IS NOT NULL OR duplicado,
      duplicado_de = COALESCE(v_prev_id, duplicado_de)
  WHERE id::text = btrim(p_id_foto);

  INSERT INTO public.evidencia_procedencia (
    id_foto, id_trabajo, origen_captura, tipo_evidencia,
    hash_sha256, hash_original, hash_perceptual,
    recibida_en, confianza, motivo, duplicado_de
  ) VALUES (
    btrim(p_id_foto), btrim(p_id_trabajo), 'web_archivo', v_tipo,
    v_hash,
    CASE WHEN p_hash_original ~* '^[0-9a-f]{64}$' THEN lower(p_hash_original) ELSE NULL END,
    v_dhash,
    now(), 'no_verificada', 'web_no_confiable', v_prev_id
  );

  IF v_prev_id IS NOT NULL THEN
    PERFORM public.registrar_alerta_evidencia_duplicada(
      btrim(p_id_foto), btrim(p_id_trabajo), v_prev_id, v_prev_trabajo, v_dhash
    );
  END IF;

  RETURN jsonb_build_object(
    'confianza', 'no_verificada',
    'duplicado', v_prev_id IS NOT NULL,
    'hash_perceptual', v_dhash,
    'motivo', 'web_no_confiable'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.apelar_disputa(p_id text, p_motivo text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_row public.disputas%ROWTYPE;
  v_horas integer := GREATEST(public.soporte_numero('soporte_plazo_apelacion_horas', 72)::integer, 1);
  v_nota text := left(btrim(COALESCE(p_motivo, '')), 1000);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF length(v_nota) < 10 THEN
    RAISE EXCEPTION 'el motivo de la apelación es muy corto';
  END IF;

  SELECT * INTO v_row
  FROM public.disputas
  WHERE id::text = btrim(p_id)
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Disputa no encontrada';
  END IF;
  IF NOT public.es_parte_trabajo(v_row.id_trabajo::text) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_row.estado <> 'resuelta' OR v_row.origen IS DISTINCT FROM 'sistema' THEN
    RAISE EXCEPTION 'solo se apela un cierre automático';
  END IF;
  IF v_row.apelada_en IS NOT NULL THEN
    RAISE EXCEPTION 'esta disputa ya fue apelada';
  END IF;
  IF v_row.resuelta_en IS NULL OR v_row.resuelta_en < now() - make_interval(hours => v_horas) THEN
    RAISE EXCEPTION 'el plazo de apelación ya venció';
  END IF;

  UPDATE public.disputas
  SET estado = 'requiere_humano',
      decision_sugerida = 'humano',
      motivo_regla = 'apelacion',
      prioridad = 'alta',
      apelada_en = now(),
      apelada_por = v_uid,
      motivo_apelacion = v_nota,
      actualizado_en = now()
  WHERE id = v_row.id;
END;
$$;

-- Una apelación no vuelve a mover el dinero. El humano deja constancia.
CREATE OR REPLACE FUNCTION public.aplicar_cierre_disputa(
  p_disputa_id text,
  p_operador text,
  p_decision text,
  p_resolucion text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_disputa public.disputas%ROWTYPE;
  v_job public.trabajos%ROWTYPE;
  v_pago public.pagos%ROWTYPE;
  v_resolucion text;
  v_origen text := CASE
    WHEN p_operador IN ('sistema', 'acuerdo') THEN p_operador
    ELSE 'admin'
  END;
  v_resuelta uuid := CASE
    WHEN p_operador IS NULL OR p_operador IN ('sistema', 'acuerdo') THEN NULL
    ELSE p_operador::uuid
  END;
BEGIN
  IF p_decision NOT IN ('liberar', 'reembolsar') THEN
    RAISE EXCEPTION 'decision invalida';
  END IF;

  SELECT * INTO v_disputa
  FROM public.disputas
  WHERE id::text = p_disputa_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'disputa no encontrada';
  END IF;
  IF v_disputa.estado = 'resuelta' THEN
    RETURN jsonb_build_object('already', true, 'decision', p_decision);
  END IF;
  IF NOT public.disputa_esta_activa(v_disputa.estado) THEN
    RAISE EXCEPTION 'la disputa no esta abierta';
  END IF;

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = v_disputa.id_trabajo::text
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;

  SELECT * INTO v_pago
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
  ORDER BY creado_en DESC
  LIMIT 1
  FOR UPDATE;

  v_resolucion := NULLIF(trim(COALESCE(p_resolucion, '')), '');
  IF v_resolucion IS NULL THEN
    RAISE EXCEPTION 'resolucion requerida';
  END IF;

  IF v_disputa.apelada_en IS NOT NULL
     AND v_pago.id IS NOT NULL
     AND v_pago.estado IN ('liberado', 'reembolsado') THEN
    IF (p_decision = 'reembolsar' AND v_pago.estado = 'liberado')
       OR (p_decision = 'liberar' AND v_pago.estado = 'reembolsado') THEN
      RAISE EXCEPTION 'el dinero ya se movió en el cierre automático';
    END IF;
    UPDATE public.disputas SET
      estado = 'resuelta',
      resolucion = v_resolucion,
      motivo_regla = 'apelacion_revisada',
      resuelta_por = COALESCE(v_resuelta, resuelta_por),
      resuelta_en = COALESCE(resuelta_en, now()),
      actualizado_en = now()
    WHERE id = v_disputa.id;
    RETURN jsonb_build_object(
      'dispute_id', v_disputa.id,
      'decision', p_decision,
      'estado', 'resuelta',
      'apelacion_revisada', true,
      'dinero', 'sin_cambio'
    );
  END IF;

  IF p_decision = 'liberar' THEN
    IF v_job.estado = 'cancelado' THEN
      RAISE EXCEPTION 'el trabajo esta cancelado; no se liberan fondos';
    END IF;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'no hay pago para liberar';
    END IF;
    IF v_pago.estado IN ('retenido', 'autorizado') THEN
      PERFORM public.marcar_pago_liberado(
        v_pago.id,
        COALESCE(p_operador, 'sistema'),
        'DISPUTA-' || left(replace(v_disputa.id::text, '-', ''), 16),
        v_resolucion
      );
    ELSIF v_pago.estado <> 'liberado' THEN
      RAISE EXCEPTION 'Pago no liberable (estado %)', v_pago.estado;
    END IF;

    IF v_job.estado <> 'completado' THEN
      UPDATE public.trabajos
      SET
        estado = 'completado',
        actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
      WHERE id = v_job.id;
    END IF;
  ELSE
    IF NOT FOUND THEN
      RAISE EXCEPTION 'no hay pago para reembolsar';
    END IF;
    IF v_pago.estado = 'liberado' THEN
      RAISE EXCEPTION 'el pago ya fue liberado al profesional';
    END IF;
    IF v_pago.estado <> 'reembolsado' THEN
      IF v_pago.estado NOT IN ('retenido', 'autorizado', 'pendiente') THEN
        RAISE EXCEPTION 'Pago no reembolsable (estado %)', v_pago.estado;
      END IF;
      UPDATE public.pagos SET
        estado = 'reembolsado',
        reembolsado_en = now(),
        actualizado_en = now()
      WHERE id = v_pago.id;
    END IF;

    UPDATE public.trabajos SET
      estado = 'cancelado',
      estado_pago = 'reembolsado',
      actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
    WHERE id = v_job.id;
  END IF;

  UPDATE public.disputas SET
    estado = 'resuelta',
    origen = v_origen,
    resolucion = v_resolucion,
    resuelta_por = v_resuelta,
    resuelta_en = now(),
    actualizado_en = now()
  WHERE id = v_disputa.id;

  RETURN jsonb_build_object(
    'dispute_id', v_disputa.id,
    'decision', p_decision,
    'estado', 'resuelta',
    'origen', v_origen
  );
END;
$$;

-- El silencio del cliente solo libera si la evidencia es confiable.
CREATE OR REPLACE FUNCTION public.resolver_soporte_automatico()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_horas integer := GREATEST(public.soporte_numero('soporte_plazo_silencio_horas', 48)::integer, 1);
  v_job record;
  v_acuerdo public.acuerdos_trabajo%ROWTYPE;
  v_disputa public.disputas%ROWTYPE;
  v_pago_id text;
  v_liberados integer := 0;
  v_acuerdos integer := 0;
  v_reembolsos jsonb := '[]'::jsonb;
BEGIN
  FOR v_job IN
    SELECT t.id::text AS id
    FROM public.trabajos t
    WHERE t.estado = 'esperando_aprobacion_cliente'
      AND public.trabajo_tiene_evidencia_confiable(t.id::text)
      AND NOT EXISTS (
        SELECT 1 FROM public.disputas d
        WHERE d.id_trabajo::text = t.id::text
          AND public.disputa_esta_activa(d.estado)
      )
      AND NULLIF(t.actualizado_en, '')::timestamptz
        < now() - make_interval(hours => v_horas)
  LOOP
    BEGIN
      PERFORM public.liberar_trabajo_sistema(
        v_job.id,
        'El cliente no respondió dentro del plazo. El pago queda liberado.'
      );
      v_liberados := v_liberados + 1;
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'silencio %: %', v_job.id, SQLERRM;
    END;
  END LOOP;

  FOR v_acuerdo IN
    SELECT *
    FROM public.acuerdos_trabajo
    WHERE estado = 'confirmado'
    FOR UPDATE
  LOOP
    BEGIN
      IF v_acuerdo.tipo = 'aceptar' THEN
        IF EXISTS (
          SELECT 1 FROM public.disputas d
          WHERE d.id_trabajo::text = v_acuerdo.id_trabajo::text
            AND public.disputa_esta_activa(d.estado)
        ) THEN
          PERFORM public.aplicar_cierre_disputa(
            (
              SELECT d.id::text FROM public.disputas d
              WHERE d.id_trabajo::text = v_acuerdo.id_trabajo::text
                AND public.disputa_esta_activa(d.estado)
              ORDER BY d.creado_en DESC
              LIMIT 1
            ),
            'acuerdo',
            'liberar',
            'Las dos partes aceptaron la entrega.'
          );
        ELSE
          PERFORM public.liberar_trabajo_sistema(
            v_acuerdo.id_trabajo::text,
            'Las dos partes aceptaron la entrega.'
          );
        END IF;
      ELSIF v_acuerdo.tipo = 'rehacer' THEN
        PERFORM set_config('mwa.pin_inicio_ok', '1', true);
        UPDATE public.trabajos
        SET
          estado = 'en_curso',
          actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
        WHERE id::text = v_acuerdo.id_trabajo::text
          AND estado <> 'cancelado';
        UPDATE public.disputas
        SET
          estado = 'resuelta',
          origen = 'acuerdo',
          resolucion = 'Acordaron rehacer el trabajo. El pago sigue retenido.',
          resuelta_en = now(),
          actualizado_en = now()
        WHERE id_trabajo::text = v_acuerdo.id_trabajo::text
          AND public.disputa_esta_activa(estado);
      ELSIF v_acuerdo.tipo = 'anular' THEN
        SELECT id INTO v_pago_id
        FROM public.pagos
        WHERE id_trabajo::text = v_acuerdo.id_trabajo::text
          AND tipo_pago = 'principal'
          AND estado IN ('retenido', 'autorizado', 'pendiente')
        ORDER BY creado_en DESC
        LIMIT 1;
        IF v_pago_id IS NULL THEN
          UPDATE public.trabajos
          SET estado = 'cancelado',
              actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
          WHERE id::text = v_acuerdo.id_trabajo::text;
        ELSE
          INSERT INTO public.disputas (
            id, id_trabajo, abierta_por, motivo, descripcion, estado,
            origen, decision_sugerida, motivo_regla, creado_en, actualizado_en
          )
          SELECT
            'acuerdo-' || v_acuerdo.id,
            v_acuerdo.id_trabajo,
            v_acuerdo.propuesto_por,
            'acuerdo',
            'Las dos partes anularon el trabajo.',
            'reembolso_pendiente',
            'acuerdo',
            'reembolsar',
            'acuerdo_anular',
            now(),
            now()
          WHERE NOT EXISTS (
            SELECT 1 FROM public.disputas d
            WHERE d.id_trabajo::text = v_acuerdo.id_trabajo::text
              AND public.disputa_esta_activa(d.estado)
          );
          UPDATE public.disputas
          SET estado = 'reembolso_pendiente',
              decision_sugerida = 'reembolsar',
              motivo_regla = 'acuerdo_anular',
              origen = 'acuerdo',
              actualizado_en = now()
          WHERE id_trabajo::text = v_acuerdo.id_trabajo::text
            AND public.disputa_esta_activa(estado)
            AND estado <> 'reembolso_pendiente';
        END IF;
      END IF;

      UPDATE public.acuerdos_trabajo
      SET estado = 'aplicado', aplicado_en = now()
      WHERE id = v_acuerdo.id;
      v_acuerdos := v_acuerdos + 1;
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'acuerdo %: %', v_acuerdo.id, SQLERRM;
    END;
  END LOOP;

  FOR v_disputa IN
    SELECT *
    FROM public.disputas
    WHERE estado = 'abierta'
      AND decision_sugerida = 'liberar'
      AND vence_en IS NOT NULL
      AND vence_en <= now()
    FOR UPDATE
  LOOP
    BEGIN
      PERFORM public.aplicar_cierre_disputa(
        v_disputa.id::text,
        'sistema',
        'liberar',
        'Cierre automático: ' || COALESCE(v_disputa.motivo_regla, 'plazo')
      );
      v_liberados := v_liberados + 1;
    EXCEPTION WHEN others THEN
      UPDATE public.disputas
      SET estado = 'requiere_humano',
          decision_sugerida = 'humano',
          motivo_regla = 'fallo_cierre_automatico',
          prioridad = 'alta',
          actualizado_en = now()
      WHERE id = v_disputa.id;
    END;
  END LOOP;

  FOR v_disputa IN
    SELECT *
    FROM public.disputas
    WHERE estado = 'abierta'
      AND decision_sugerida = 'reembolsar'
      AND vence_en IS NOT NULL
      AND vence_en <= now()
    FOR UPDATE
  LOOP
    UPDATE public.disputas
    SET estado = 'reembolso_pendiente', actualizado_en = now()
    WHERE id = v_disputa.id;
  END LOOP;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'disputa_id', d.id,
    'pago_id', p.id,
    'resolucion', 'Devolución automática: ' || COALESCE(d.motivo_regla, 'plazo')
  )), '[]'::jsonb)
  INTO v_reembolsos
  FROM public.disputas d
  JOIN LATERAL (
    SELECT id
    FROM public.pagos
    WHERE id_trabajo::text = d.id_trabajo::text
      AND tipo_pago = 'principal'
      AND estado IN ('retenido', 'autorizado', 'pendiente', 'reembolsado')
    ORDER BY creado_en DESC
    LIMIT 1
  ) p ON true
  WHERE d.estado = 'reembolso_pendiente';

  RETURN jsonb_build_object(
    'liberados', v_liberados,
    'acuerdos', v_acuerdos,
    'reembolsos', COALESCE(v_reembolsos, '[]'::jsonb)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.marcar_reembolso_automatico(
  p_disputa text,
  p_pago text,
  p_estado text,
  p_error text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_actual text;
BEGIN
  IF p_estado NOT IN ('pendiente', 'en_curso', 'ejecutado', 'fallido') THEN
    RAISE EXCEPTION 'estado de reembolso invalido';
  END IF;
  SELECT estado INTO v_actual
  FROM public.reembolsos_automaticos
  WHERE id_disputa = btrim(p_disputa)
  FOR UPDATE;
  IF v_actual = 'ejecutado' AND p_estado IS DISTINCT FROM 'ejecutado' THEN
    RETURN;
  END IF;
  INSERT INTO public.reembolsos_automaticos (
    id_disputa, id_pago, estado, ultimo_error, ejecutado_en, actualizado_en
  ) VALUES (
    btrim(p_disputa),
    btrim(p_pago),
    p_estado,
    NULLIF(left(COALESCE(p_error, ''), 500), ''),
    CASE WHEN p_estado = 'ejecutado' THEN now() ELSE NULL END,
    now()
  )
  ON CONFLICT (id_disputa) DO UPDATE
  SET estado = EXCLUDED.estado,
      id_pago = EXCLUDED.id_pago,
      ultimo_error = EXCLUDED.ultimo_error,
      ejecutado_en = CASE
        WHEN EXCLUDED.estado = 'ejecutado' THEN now()
        ELSE public.reembolsos_automaticos.ejecutado_en
      END,
      actualizado_en = now();
END;
$$;

-- Punto único que el cron llama. En las pruebas se reemplaza por un mock.
CREATE OR REPLACE FUNCTION public.invocar_reembolso_edge(p_body jsonb)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_url text;
  v_secret text;
  v_id bigint;
BEGIN
  SELECT decrypted_secret INTO v_url
  FROM vault.decrypted_secrets
  WHERE name = 'mwa_supabase_url'
  LIMIT 1;
  SELECT decrypted_secret INTO v_secret
  FROM vault.decrypted_secrets
  WHERE name = 'mwa_soporte_cron_secret'
  LIMIT 1;
  IF v_url IS NULL OR length(btrim(v_url)) = 0 THEN
    RAISE EXCEPTION 'falta el secreto mwa_supabase_url en Vault';
  END IF;
  IF v_secret IS NULL OR length(btrim(v_secret)) = 0 THEN
    RAISE EXCEPTION 'falta el secreto mwa_soporte_cron_secret en Vault';
  END IF;

  SELECT net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/soporte-automatico',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-soporte-secret', v_secret
    ),
    body := COALESCE(p_body, '{}'::jsonb),
    timeout_milliseconds := 30000
  ) INTO v_id;
  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.despachar_reembolsos_automaticos()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row record;
  v_max integer := GREATEST(public.soporte_numero('soporte_reembolso_intentos_max', 8)::integer, 1);
  v_id bigint;
  v_enviados integer := 0;
  v_fallidos integer := 0;
  v_omitidos integer := 0;
BEGIN
  UPDATE public.disputas d
  SET estado = 'requiere_humano',
      decision_sugerida = 'humano',
      motivo_regla = 'fallo_reembolso',
      prioridad = 'alta',
      actualizado_en = now()
  FROM public.reembolsos_automaticos r
  WHERE r.id_disputa = d.id::text
    AND d.estado = 'reembolso_pendiente'
    AND r.estado = 'fallido'
    AND r.intentos >= v_max;

  FOR v_row IN
    SELECT d.id::text AS disputa_id,
           p.id::text AS pago_id,
           'Devolución automática: ' || COALESCE(d.motivo_regla, 'plazo') AS resolucion,
           r.estado AS estado_previo,
           COALESCE(r.intentos, 0) AS intentos
    FROM public.disputas d
    JOIN LATERAL (
      SELECT id
      FROM public.pagos
      WHERE id_trabajo::text = d.id_trabajo::text
        AND tipo_pago = 'principal'
        AND estado IN ('retenido', 'autorizado', 'pendiente')
      ORDER BY creado_en DESC
      LIMIT 1
    ) p ON true
    LEFT JOIN public.reembolsos_automaticos r ON r.id_disputa = d.id::text
    WHERE d.estado = 'reembolso_pendiente'
      AND COALESCE(r.estado, 'pendiente') <> 'ejecutado'
      AND COALESCE(r.intentos, 0) < v_max
      AND (
        r.id_disputa IS NULL
        OR r.estado IN ('pendiente', 'fallido')
        OR (r.estado = 'en_curso' AND r.actualizado_en < now() - interval '10 minutes')
      )
  LOOP
    INSERT INTO public.reembolsos_automaticos (id_disputa, id_pago, estado, intentos, actualizado_en)
    VALUES (v_row.disputa_id, v_row.pago_id, 'en_curso', v_row.intentos + 1, now())
    ON CONFLICT (id_disputa) DO UPDATE
    SET estado = 'en_curso',
        id_pago = EXCLUDED.id_pago,
        intentos = public.reembolsos_automaticos.intentos + 1,
        ultimo_error = NULL,
        actualizado_en = now();

    BEGIN
      v_id := public.invocar_reembolso_edge(jsonb_build_object(
        'disputa_id', v_row.disputa_id,
        'pago_id', v_row.pago_id,
        'resolucion', v_row.resolucion
      ));
      UPDATE public.reembolsos_automaticos
      SET solicitud_id = v_id
      WHERE id_disputa = v_row.disputa_id
        AND estado = 'en_curso';
      v_enviados := v_enviados + 1;
    EXCEPTION WHEN others THEN
      UPDATE public.reembolsos_automaticos
      SET estado = 'fallido',
          ultimo_error = left(SQLERRM, 500),
          actualizado_en = now()
      WHERE id_disputa = v_row.disputa_id
        AND estado IS DISTINCT FROM 'ejecutado';
      v_fallidos := v_fallidos + 1;
    END;
  END LOOP;

  SELECT count(*) INTO v_omitidos
  FROM public.reembolsos_automaticos
  WHERE estado = 'ejecutado';

  RETURN jsonb_build_object(
    'enviados', v_enviados,
    'fallidos', v_fallidos,
    'ejecutados', v_omitidos
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.encadenar_soporte_automatico()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_base jsonb;
  v_envio jsonb;
BEGIN
  v_base := public.resolver_soporte_automatico();
  v_envio := public.despachar_reembolsos_automaticos();
  RETURN COALESCE(v_base, '{}'::jsonb) || jsonb_build_object('despacho', v_envio);
END;
$$;

CREATE OR REPLACE FUNCTION public.soporte_secret_valido(p_secret text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
  v_esperado text;
BEGIN
  IF p_secret IS NULL OR length(p_secret) = 0 THEN
    RETURN false;
  END IF;
  SELECT ds.decrypted_secret INTO v_esperado
  FROM vault.decrypted_secrets ds
  WHERE ds.name = 'mwa_soporte_cron_secret'
  LIMIT 1;
  IF v_esperado IS NULL OR length(v_esperado) = 0 THEN
    RETURN false;
  END IF;
  RETURN pg_catalog.sha256(pg_catalog.convert_to(p_secret, 'UTF8'))
       = pg_catalog.sha256(pg_catalog.convert_to(v_esperado, 'UTF8'));
END;
$$;

DROP FUNCTION IF EXISTS public.consola_disputas_abiertas();

CREATE FUNCTION public.consola_disputas_abiertas()
RETURNS TABLE (
  id text,
  id_trabajo text,
  motivo text,
  descripcion text,
  estado text,
  decision_sugerida text,
  motivo_regla text,
  vence_en timestamptz,
  creado_en text,
  nombre_cliente text,
  nombre_profesional text,
  monto_retenido numeric,
  prioridad text,
  asignado_a uuid,
  nombre_asignado text,
  puntaje_riesgo integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF public.rol_consola() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
  SELECT
    d.id::text,
    d.id_trabajo::text,
    d.motivo,
    d.descripcion,
    d.estado,
    d.decision_sugerida,
    d.motivo_regla,
    d.vence_en,
    d.creado_en::text,
    COALESCE(pc.nombre, 'Cliente'),
    COALESCE(pp.nombre, 'Profesional'),
    COALESCE((
      SELECT max(pg.monto)
      FROM public.pagos pg
      WHERE pg.id_trabajo = d.id_trabajo
        AND pg.estado IN ('autorizado', 'retenido', 'pendiente')
    ), 0),
    d.prioridad,
    d.asignado_a,
    pa.nombre,
    d.puntaje_riesgo
  FROM public.disputas d
  JOIN public.trabajos t ON t.id::text = d.id_trabajo::text
  LEFT JOIN public.perfiles pc ON pc.id = t.id_usuario
  LEFT JOIN public.perfiles pp ON pp.id = t.id_trabajador
  LEFT JOIN public.perfiles pa ON pa.id = d.asignado_a
  WHERE public.disputa_esta_activa(d.estado)
  ORDER BY
    CASE d.prioridad WHEN 'alta' THEN 0 WHEN 'media' THEN 1 WHEN 'baja' THEN 2 ELSE 3 END,
    d.vence_en NULLS LAST,
    d.creado_en DESC
  LIMIT 200;
END;
$$;

DROP FUNCTION IF EXISTS public.evidencia_disputa(text);

CREATE FUNCTION public.evidencia_disputa(p_id_disputa text)
RETURNS TABLE (
  id text,
  imagen_base64 text,
  origen_captura text,
  tipo_evidencia text,
  confianza text,
  distancia_metros numeric,
  duplicado boolean,
  hash_perceptual text,
  luz_amarilla boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() AND public.rol_consola() IS DISTINCT FROM 'soporte' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
  SELECT
    f.id::text,
    encode(f.imagen_webp, 'base64'),
    f.origen_captura,
    f.tipo_evidencia,
    f.confianza,
    f.distancia_metros,
    COALESCE(f.duplicado, false),
    f.hash_perceptual,
    (f.confianza IS DISTINCT FROM 'confiable' OR COALESCE(f.duplicado, false))
  FROM public.fotos_trabajo f
  JOIN public.disputas d ON d.id_trabajo::text = f.id_trabajo::text
  WHERE d.id::text = btrim(p_id_disputa)
    AND f.imagen_webp IS NOT NULL
    AND octet_length(f.imagen_webp) >= 12
  ORDER BY f.creado_en
  LIMIT 8;
END;
$$;

REVOKE ALL ON FUNCTION public.clasificar_disputa(text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.prioridad_por_regla(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.trabajo_tiene_evidencia_confiable(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.registrar_alerta_evidencia_duplicada(text, text, text, text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.revaluar_disputa(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.distancia_metros(double precision, double precision, double precision, double precision) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.dhash_desde_luma(bytea) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.distancia_hamming_hex(text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.resolver_soporte_automatico() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.encadenar_soporte_automatico() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.despachar_reembolsos_automaticos() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.invocar_reembolso_edge(jsonb) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.marcar_reembolso_automatico(text, text, text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.soporte_secret_valido(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.aplicar_cierre_disputa(text, text, text, text) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.pedir_nonce_evidencia(text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.registrar_evidencia_captura(text, text, text, text, text, bytea, double precision, double precision, text, timestamptz, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.registrar_evidencia_web(text, text, text, text, bytea, text, jsonb) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.apelar_disputa(text, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.consola_disputas_abiertas() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.evidencia_disputa(text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.resolver_soporte_automatico() TO service_role;
GRANT EXECUTE ON FUNCTION public.encadenar_soporte_automatico() TO service_role;
GRANT EXECUTE ON FUNCTION public.despachar_reembolsos_automaticos() TO service_role;
GRANT EXECUTE ON FUNCTION public.invocar_reembolso_edge(jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.marcar_reembolso_automatico(text, text, text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.soporte_secret_valido(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.revaluar_disputa(text) TO service_role;

DO $$
DECLARE
  r record;
BEGIN
  IF to_regclass('cron.job') IS NULL THEN
    RAISE NOTICE 'pg_cron no está instalado. Programa SELECT public.encadenar_soporte_automatico(); cada 10 minutos.';
    RETURN;
  END IF;
  FOR r IN
    SELECT jobid FROM cron.job WHERE jobname = 'mwa_resolver_soporte_automatico'
  LOOP
    PERFORM cron.unschedule(r.jobid);
  END LOOP;
  PERFORM cron.schedule(
    'mwa_resolver_soporte_automatico',
    '*/10 * * * *',
    'SELECT public.encadenar_soporte_automatico()'
  );
END $$;

DO $$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pg_net no quedó instalado: %', SQLERRM;
END $$;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT DISTINCT id_trabajo::text AS id
    FROM public.disputas
    WHERE public.disputa_esta_activa(estado)
  LOOP
    PERFORM public.revaluar_disputa(r.id);
  END LOOP;
END $$;

COMMIT;

-- Fase 3: cola de moderación del chat y sugerencia de validación de documentos.
-- El mensaje no se borra. Un humano de la consola confirma o descarta la marca.
-- No aplicar en wxqrfcqifkfgawrnqmnj sin el OK de Mathias.

BEGIN;

CREATE TABLE IF NOT EXISTS public.cola_moderacion (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_mensaje text NOT NULL REFERENCES public.mensajes (id) ON DELETE CASCADE,
  motivo text NOT NULL CHECK (
    motivo IN ('telefono', 'correo', 'banco', 'fuera', 'insulto', 'dudoso', 'llm')
  ),
  detalle text NOT NULL DEFAULT '',
  estado text NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'confirmado', 'descartado')),
  veredicto_llm text,
  creado_en timestamptz NOT NULL DEFAULT now(),
  revisado_por uuid,
  revisado_en timestamptz
);

CREATE INDEX IF NOT EXISTS cola_moderacion_estado_idx
  ON public.cola_moderacion (estado, creado_en DESC);

ALTER TABLE public.cola_moderacion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cola_moderacion REPLICA IDENTITY FULL;
REVOKE ALL ON public.cola_moderacion FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.cola_moderacion TO authenticated;

DROP POLICY IF EXISTS cola_moderacion_select_admin ON public.cola_moderacion;
CREATE POLICY cola_moderacion_select_admin
  ON public.cola_moderacion
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_admin()) OR (SELECT public.rol_consola()) IN ('administrador', 'soporte'));

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.cola_moderacion;
EXCEPTION
  WHEN undefined_object THEN NULL;
  WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION public.clasificar_mensaje(p_texto text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $$
DECLARE
  v text := btrim(coalesce(p_texto, ''));
BEGIN
  IF v = '' THEN
    RETURN 'limpio';
  END IF;
  IF v ~* '[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}' THEN
    RETURN 'correo';
  END IF;
  IF v ~ '(?:^|[^0-9])(?:\+?56[[:space:].-]*)?(?:9(?:[[:space:].-]?[0-9]){8})(?:[^0-9]|$)' THEN
    RETURN 'telefono';
  END IF;
  IF v ~* 'cuenta[[:space:]]+(corriente|vista|rut|de[[:space:]]+ahorro)'
     OR v ~* 'n[uú]mero[[:space:]]+de[[:space:]]+cuenta' THEN
    RETURN 'banco';
  END IF;
  IF v ~* 'p[aá]game[[:space:]]+por[[:space:]]+fuera'
     OR v ~* 'pago[[:space:]]+por[[:space:]]+fuera'
     OR v ~* 'por[[:space:]]+fuera[[:space:]]+de[[:space:]]+la[[:space:]]+app'
     OR v ~* 'sin[[:space:]]+pasar[[:space:]]+por[[:space:]]+la[[:space:]]+app' THEN
    RETURN 'fuera';
  END IF;
  IF v ~* '\m(weon|weón|aweonao|aweona|conchetumare|conchesumadre|ctm|qliao|imbecil|imbécil|idiota)\M'
     OR v ~* 'saco[[:space:]]+de[[:space:]]+wea' THEN
    RETURN 'insulto';
  END IF;
  IF v ~* 'escribeme|mi[[:space:]]+n[uú]mero|por[[:space:]]+interno|te[[:space:]]+paso[[:space:]]+el[[:space:]]+dato'
     OR v ~ '[0-9]{5,7}' THEN
    RETURN 'dudoso';
  END IF;
  RETURN 'limpio';
END;
$$;

REVOKE ALL ON FUNCTION public.clasificar_mensaje(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.clasificar_mensaje(text) TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.mensajes_encolar_moderacion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_motivo text;
BEGIN
  v_motivo := public.clasificar_mensaje(NEW.contenido);
  IF v_motivo = 'limpio' THEN
    RETURN NEW;
  END IF;
  INSERT INTO public.cola_moderacion (id_mensaje, motivo, detalle)
  VALUES (
    NEW.id,
    v_motivo,
    CASE WHEN v_motivo = 'dudoso' THEN 'requiere_llm' ELSE 'regla' END
  );
  INSERT INTO public.notificaciones (
    id, id_usuario, tipo, titulo, cuerpo, id_relacionado, leido, creado_en
  )
  VALUES (
    gen_random_uuid()::text,
    NEW.id_remitente,
    'moderacion_ia',
    'Mensaje marcado',
    'Este mensaje quedó marcado para revisión. No se borró. Un administrador decide.',
    NEW.id,
    0,
    to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS mensajes_encolar_moderacion ON public.mensajes;
CREATE TRIGGER mensajes_encolar_moderacion
  AFTER INSERT ON public.mensajes
  FOR EACH ROW
  EXECUTE FUNCTION public.mensajes_encolar_moderacion();

ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS sugerencia_validacion jsonb;

COMMENT ON COLUMN public.trabajadores.sugerencia_validacion IS
  'Propuesta de la IA sobre el documento. No cambia estado_verificacion. Decide un administrador.';

CREATE OR REPLACE FUNCTION public.guardar_sugerencia_validacion(
  p_usuario uuid,
  p_sugerencia jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v jsonb := COALESCE(p_sugerencia, '{}'::jsonb);
BEGIN
  IF coalesce(auth.role(), '') IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  v := v - 'rut' - 'rut_completo' - 'numero_documento';
  IF v ? 'nota' THEN
    v := jsonb_set(
      v,
      '{nota}',
      to_jsonb(left(regexp_replace(v->>'nota', '\m[0-9]{1,2}\.?[0-9]{3}\.?[0-9]{3}-[0-9Kk]\M', 'RUT oculto', 'g'), 400))
    );
  END IF;
  v := v || jsonb_build_object('decision', 'pendiente_humano', 'en', now());
  UPDATE public.trabajadores
  SET sugerencia_validacion = v
  WHERE id_usuario = p_usuario;
END;
$$;

REVOKE ALL ON FUNCTION public.guardar_sugerencia_validacion(uuid, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.guardar_sugerencia_validacion(uuid, jsonb) TO service_role;

CREATE OR REPLACE FUNCTION public.anotar_veredicto_llm(
  p_mensaje text,
  p_veredicto text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF coalesce(auth.role(), '') IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_veredicto NOT IN ('revisar', 'parece_limpio') THEN
    RAISE EXCEPTION 'veredicto no permitido';
  END IF;
  UPDATE public.cola_moderacion
  SET veredicto_llm = p_veredicto,
      motivo = CASE WHEN motivo = 'dudoso' THEN 'llm' ELSE motivo END,
      detalle = left('llm:' || p_veredicto, 200)
  WHERE id_mensaje = btrim(p_mensaje)
    AND estado = 'pendiente';
END;
$$;

REVOKE ALL ON FUNCTION public.anotar_veredicto_llm(text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.anotar_veredicto_llm(text, text) TO service_role;

COMMENT ON FUNCTION public.anotar_veredicto_llm(text, text) IS
  'Guarda lo que dijo el modelo en un caso dudoso. No borra el mensaje ni cierra la cola.';

COMMIT;

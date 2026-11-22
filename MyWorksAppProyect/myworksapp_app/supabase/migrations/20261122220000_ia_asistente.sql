-- Fase 2: consentimiento, sugerencia de perfil y resumen de reseñas.
-- La IA propone. El profesional acepta o edita el texto en su ficha.
-- No aplicar en wxqrfcqifkfgawrnqmnj sin el OK de Mathias.

BEGIN;

CREATE TABLE IF NOT EXISTS public.ia_sugerencias_perfil (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.perfiles (id) ON DELETE CASCADE,
  texto_sugerido text NOT NULL CHECK (char_length(texto_sugerido) BETWEEN 8 AND 1200),
  estado text NOT NULL DEFAULT 'propuesta' CHECK (estado IN ('propuesta', 'aceptada', 'descartada')),
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ia_sugerencias_perfil_usuario_idx
  ON public.ia_sugerencias_perfil (user_id, creado_en DESC);

ALTER TABLE public.ia_sugerencias_perfil ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ia_sugerencias_perfil FROM PUBLIC, anon, authenticated;
GRANT SELECT, UPDATE ON public.ia_sugerencias_perfil TO authenticated;

DROP POLICY IF EXISTS ia_sugerencias_select_propio ON public.ia_sugerencias_perfil;
CREATE POLICY ia_sugerencias_select_propio
  ON public.ia_sugerencias_perfil
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()) OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS ia_sugerencias_update_propio ON public.ia_sugerencias_perfil;
CREATE POLICY ia_sugerencias_update_propio
  ON public.ia_sugerencias_perfil
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE TABLE IF NOT EXISTS public.ia_resumen_resenas (
  id_profesional uuid PRIMARY KEY REFERENCES public.perfiles (id) ON DELETE CASCADE,
  resumen text NOT NULL CHECK (char_length(resumen) BETWEEN 8 AND 600),
  n_resenas integer NOT NULL CHECK (n_resenas >= 0),
  origen text NOT NULL CHECK (origen IN ('mock', 'ollama', 'gemini')),
  generado_en timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.ia_resumen_resenas ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ia_resumen_resenas FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.ia_resumen_resenas TO anon, authenticated;

DROP POLICY IF EXISTS ia_resumen_select_publico ON public.ia_resumen_resenas;
CREATE POLICY ia_resumen_select_publico
  ON public.ia_resumen_resenas
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE OR REPLACE FUNCTION public.registrar_consentimiento_ia()
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  INSERT INTO public.consentimientos_usuario (
    id, id_usuario, version_consentimiento, aceptado, aceptado_en
  )
  VALUES (
    gen_random_uuid()::text,
    auth.uid(),
    'ia-datos-2026',
    1,
    to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
  );
END;
$$;

REVOKE ALL ON FUNCTION public.registrar_consentimiento_ia() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_consentimiento_ia() TO authenticated;

CREATE OR REPLACE FUNCTION public.ia_tiene_consentimiento(p_usuario uuid DEFAULT NULL)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.consentimientos_usuario c
    WHERE c.id_usuario = COALESCE(p_usuario, auth.uid())
      AND c.version_consentimiento = 'ia-datos-2026'
      AND c.aceptado = 1
      AND (p_usuario IS NULL OR p_usuario = auth.uid() OR public.is_admin() OR coalesce(auth.role(), '') = 'service_role')
  );
$$;

REVOKE ALL ON FUNCTION public.ia_tiene_consentimiento(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ia_tiene_consentimiento(uuid) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.guardar_sugerencia_perfil(
  p_usuario uuid,
  p_texto text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_id uuid;
  v_texto text := left(btrim(coalesce(p_texto, '')), 1200);
BEGIN
  IF coalesce(auth.role(), '') IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_usuario IS NULL OR char_length(v_texto) < 8 THEN
    RAISE EXCEPTION 'sugerencia incompleta';
  END IF;
  INSERT INTO public.ia_sugerencias_perfil (user_id, texto_sugerido)
  VALUES (p_usuario, v_texto)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.guardar_sugerencia_perfil(uuid, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.guardar_sugerencia_perfil(uuid, text) TO service_role;

CREATE OR REPLACE FUNCTION public.resolver_sugerencia_perfil(
  p_id uuid,
  p_estado text
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_estado NOT IN ('aceptada', 'descartada') THEN
    RAISE EXCEPTION 'estado no permitido';
  END IF;
  UPDATE public.ia_sugerencias_perfil
  SET estado = p_estado
  WHERE id = p_id
    AND user_id = auth.uid()
    AND estado = 'propuesta';
END;
$$;

REVOKE ALL ON FUNCTION public.resolver_sugerencia_perfil(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resolver_sugerencia_perfil(uuid, text) TO authenticated;

COMMENT ON FUNCTION public.resolver_sugerencia_perfil(uuid, text) IS
  'El profesional acepta o descarta la redacción. Aceptar no escribe la ficha: la app guarda el texto si él lo confirma.';

CREATE OR REPLACE FUNCTION public.guardar_resumen_resenas(
  p_profesional uuid,
  p_resumen text,
  p_n integer,
  p_origen text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_texto text := left(btrim(coalesce(p_resumen, '')), 600);
BEGIN
  IF coalesce(auth.role(), '') IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_origen NOT IN ('mock', 'ollama', 'gemini') THEN
    RAISE EXCEPTION 'origen no permitido';
  END IF;
  v_texto := regexp_replace(v_texto, '\m[0-9]{1,2}\.[0-9]{3}\.[0-9]{3}-[0-9Kk]\M', 'RUT oculto', 'g');
  v_texto := regexp_replace(v_texto, '\m[0-9]{7,8}-[0-9Kk]\M', 'RUT oculto', 'g');
  IF char_length(v_texto) < 8 THEN
    RAISE EXCEPTION 'resumen demasiado corto';
  END IF;
  INSERT INTO public.ia_resumen_resenas (id_profesional, resumen, n_resenas, origen, generado_en)
  VALUES (p_profesional, v_texto, GREATEST(coalesce(p_n, 0), 0), p_origen, now())
  ON CONFLICT (id_profesional) DO UPDATE
  SET resumen = EXCLUDED.resumen,
      n_resenas = EXCLUDED.n_resenas,
      origen = EXCLUDED.origen,
      generado_en = now();
END;
$$;

REVOKE ALL ON FUNCTION public.guardar_resumen_resenas(uuid, text, integer, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.guardar_resumen_resenas(uuid, text, integer, text) TO service_role;

COMMIT;

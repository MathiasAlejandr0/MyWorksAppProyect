-- Evidencia fotografica en WebP dentro de fotos_trabajo.
-- Las fotos dejan de ser una ruta local y se guardan comprimidas en la fila.

BEGIN;

ALTER TABLE public.fotos_trabajo
  ADD COLUMN IF NOT EXISTS imagen_webp bytea;

COMMENT ON COLUMN public.fotos_trabajo.imagen_webp IS
  'Imagen de evidencia en WebP. Se guarda en la fila para no depender de archivos locales y ocupar menos espacio que JPEG/PNG.';

UPDATE public.fotos_trabajo
SET
  imagen_webp = decode('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', 'base64'),
  ruta_foto = 'evidencia.webp',
  tipo_medio = COALESCE(NULLIF(btrim(tipo_medio), ''), 'foto')
WHERE id = 'demo-foto-conforme'
   OR (id_trabajo = 'demo-job-conforme' AND imagen_webp IS NULL);

CREATE OR REPLACE FUNCTION public.fotos_trabajo_exigir_webp()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF COALESCE(NEW.tipo_medio, 'foto') IS DISTINCT FROM 'video' THEN
    IF NEW.imagen_webp IS NULL OR octet_length(NEW.imagen_webp) < 12 THEN
      RAISE EXCEPTION 'la evidencia fotografica debe guardarse en formato webp';
    END IF;
    IF encode(substring(NEW.imagen_webp from 1 for 4), 'hex') <> '52494646'
       OR encode(substring(NEW.imagen_webp from 9 for 4), 'hex') <> '57454250' THEN
      RAISE EXCEPTION 'la evidencia fotografica debe ser un archivo webp';
    END IF;
    NEW.ruta_foto := COALESCE(NULLIF(btrim(NEW.ruta_foto), ''), 'evidencia.webp');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS fotos_trabajo_exigir_webp ON public.fotos_trabajo;
CREATE TRIGGER fotos_trabajo_exigir_webp
  BEFORE INSERT OR UPDATE ON public.fotos_trabajo
  FOR EACH ROW
  EXECUTE FUNCTION public.fotos_trabajo_exigir_webp();

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
      AND (
        octet_length(COALESCE(f.imagen_webp, ''::bytea)) >= 12
        OR length(btrim(COALESCE(f.ruta_foto, ''))) > 0
      )
  );
$$;

REVOKE ALL ON FUNCTION public.trabajo_tiene_evidencia(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fotos_trabajo_exigir_webp() FROM PUBLIC, anon, authenticated;

COMMIT;

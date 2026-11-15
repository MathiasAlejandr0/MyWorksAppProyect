-- Bucket privado de evidencia del trabajo.
-- Ruta: {id_trabajo}/{id_usuario}/{archivo}.ext
-- No aplicar en vivo desde este PR: solo queda versionada.

BEGIN;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'evidencias',
  'evidencias',
  false,
  52428800,
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    'video/mp4',
    'video/quicktime',
    'video/webm'
  ]
)
ON CONFLICT (id) DO UPDATE
SET public = false,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS evidencias_select ON storage.objects;
CREATE POLICY evidencias_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'evidencias'
    AND (
      public.is_admin()
      OR public.es_parte_trabajo((storage.foldername(name))[1])
    )
  );

DROP POLICY IF EXISTS evidencias_insert ON storage.objects;
CREATE POLICY evidencias_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'evidencias'
    AND (storage.foldername(name))[2] = (SELECT auth.uid())::text
    AND public.es_parte_trabajo((storage.foldername(name))[1])
  );

DROP POLICY IF EXISTS evidencias_delete ON storage.objects;
CREATE POLICY evidencias_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'evidencias'
    AND (
      public.is_admin()
      OR (
        (storage.foldername(name))[2] = (SELECT auth.uid())::text
        AND public.es_parte_trabajo((storage.foldername(name))[1])
      )
    )
  );

COMMIT;

-- Fotos de demostración servidas desde este proyecto.
-- La web publicada solo permite imágenes de *.supabase.co, así que el
-- catálogo puede mostrarlas sin depender de Unsplash ni Pravatar.
INSERT INTO storage.buckets (id, name, public, type, versioning_status, file_size_limit, allowed_mime_types)
VALUES ('fotos-demo', 'fotos-demo', true, 'STANDARD', 'DISABLED', 2097152, ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO UPDATE
SET public = true,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS fotos_demo_lectura ON storage.objects;
CREATE POLICY fotos_demo_lectura
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'fotos-demo');

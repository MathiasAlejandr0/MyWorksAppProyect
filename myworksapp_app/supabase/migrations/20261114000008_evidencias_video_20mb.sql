-- El video de evidencia queda en 20 MB. Las fotos siguen en 8 MB en la app.
-- El tope del bucket es el del archivo más grande permitido.
-- No aplicar en vivo desde este PR.

UPDATE storage.buckets
SET file_size_limit = 20971520
WHERE id = 'evidencias';

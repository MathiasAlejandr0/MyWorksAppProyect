-- Portado desde MathiasAlejandr0/MyWorksAppProyect PR #55 (20261114000008_evidencias_video_20mb.sql).
-- Aplicada en vivo dentro de 20261115051320–20261115051532.
-- No reaplicar el SQL en wxqrfcqifkfgawrnqmnj: ya está en la base.

-- El video de evidencia queda en 20 MB. Las fotos siguen en 8 MB en la app.
-- El tope del bucket es el del archivo más grande permitido.
-- No aplicar en vivo desde este PR.

UPDATE storage.buckets
SET file_size_limit = 20971520
WHERE id = 'evidencias';

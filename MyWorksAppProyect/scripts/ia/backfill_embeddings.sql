-- Rellena embeddings provisionales (hash) de perfiles y solicitudes ya guardados.
-- La función embed con gte-small los reemplaza después.
-- No ejecutar contra wxqrfcqifkfgawrnqmnj.
-- Requiere la migración 20261122210000.

UPDATE public.trabajadores
SET
  embedding = privado.embedding_hash(left(btrim(coalesce(profesion, '') || ' ' || coalesce(descripcion, '')), 2000)),
  embedding_origen = 'hash'
WHERE embedding IS NULL;

UPDATE public.trabajos
SET
  embedding = privado.embedding_hash(left(btrim(coalesce(descripcion, '')), 2000)),
  embedding_origen = 'hash'
WHERE embedding IS NULL
  AND descripcion IS NOT NULL;

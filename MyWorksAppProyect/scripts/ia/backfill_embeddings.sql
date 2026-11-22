-- Encola perfiles y solicitudes que todavía no tienen embedding de gte-small.
-- No escribe un vector falso. La función embed los completa cuando el modelo está.
-- No ejecutar contra wxqrfcqifkfgawrnqmnj.

INSERT INTO public.ia_cola_embeddings (tabla, entidad_id, texto)
SELECT
  'trabajadores',
  t.id_usuario::text,
  left(btrim(coalesce(t.profesion, '') || ' ' || coalesce(t.descripcion, '')), 2000)
FROM public.trabajadores t
WHERE t.embedding IS NULL
  AND btrim(coalesce(t.profesion, '') || coalesce(t.descripcion, '')) <> ''
  AND NOT EXISTS (
    SELECT 1
    FROM public.ia_cola_embeddings c
    WHERE c.tabla = 'trabajadores'
      AND c.entidad_id = t.id_usuario::text
      AND c.estado = 'pendiente'
  );

INSERT INTO public.ia_cola_embeddings (tabla, entidad_id, texto)
SELECT
  'trabajos',
  t.id::text,
  left(btrim(coalesce(t.descripcion, '')), 2000)
FROM public.trabajos t
WHERE t.embedding IS NULL
  AND btrim(coalesce(t.descripcion, '')) <> ''
  AND NOT EXISTS (
    SELECT 1
    FROM public.ia_cola_embeddings c
    WHERE c.tabla = 'trabajos'
      AND c.entidad_id = t.id::text
      AND c.estado = 'pendiente'
  );

-- Plomería y gasfitería aparecían como dos oficios con casi el mismo nombre
-- («Gasfitería y plomería» y «Gasfitería»). Son categorías distintas en la
-- base (plomeria = agua, gasfiteria = gas): se renombran para que se lean
-- distintas en la app y en la web. No cambia ningún id ni trabajo existente.
UPDATE public.servicios
SET nombre = 'Plomería',
    descripcion = 'Fugas de agua, cañerías, grifería y desagües.',
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
WHERE id = 'plumbing'
  AND nombre = 'Gasfitería y plomería';

UPDATE public.servicios
SET nombre = 'Gasfitería (gas)',
    descripcion = 'Calefont, cocinas y conexiones de gas.',
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
WHERE id = 'svc-demo-gasfiteria'
  AND nombre = 'Gasfitería';

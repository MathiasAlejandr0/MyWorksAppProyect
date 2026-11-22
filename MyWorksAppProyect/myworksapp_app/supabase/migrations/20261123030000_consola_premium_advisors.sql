-- Cierra dos avisos menores de la consola premium.
-- No aplicar en el proyecto remoto wxqrfcqifkfgawrnqmnj hasta el merge.
-- consola_premium_item solo usa funciones de catálogo (jsonb_build_object y
-- round) y parámetros; no lee tablas. Se fija search_path para que deje de
-- ser mutable. El índice cubre la FK disputas.asignado_a.

ALTER FUNCTION public.consola_premium_item(text, text, numeric, text, text, text)
  SET search_path = public, pg_temp;

CREATE INDEX IF NOT EXISTS idx_disputas_asignado_a
  ON public.disputas (asignado_a);

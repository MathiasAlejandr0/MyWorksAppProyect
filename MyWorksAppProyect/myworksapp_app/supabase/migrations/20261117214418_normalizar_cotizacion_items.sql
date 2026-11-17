-- El desglose de una cotización deja de ser un JSON dentro de un texto y pasa a
-- una tabla de líneas: propuesta_cotizacion_items(id_propuesta, linea, concepto, monto).
-- Las horas estimadas son un solo valor por cotización: columna horas_estimadas.

ALTER TABLE public.propuestas_cotizacion
  ADD COLUMN horas_estimadas numeric CHECK (horas_estimadas IS NULL OR horas_estimadas >= 0);

CREATE TABLE public.propuesta_cotizacion_items (
  id_propuesta text NOT NULL REFERENCES public.propuestas_cotizacion (id) ON DELETE CASCADE,
  linea smallint NOT NULL CHECK (linea >= 1),
  concepto text NOT NULL CHECK (length(btrim(concepto)) > 0),
  monto numeric NOT NULL CHECK (monto >= 0),
  PRIMARY KEY (id_propuesta, linea)
);

COMMENT ON TABLE public.propuesta_cotizacion_items IS
  'Líneas del desglose de una cotización (materiales, mano de obra, etc.). La suma no reemplaza a monto_total_clp.';

-- Migrar los desgloses existentes (solo los que son un objeto JSON válido).
WITH base AS (
  SELECT p.id,
         CASE WHEN p.desglose ~ '^\s*\{' THEN p.desglose::jsonb END AS d
  FROM public.propuestas_cotizacion p
  WHERE p.desglose IS NOT NULL
)
UPDATE public.propuestas_cotizacion p
SET horas_estimadas = NULLIF(b.d->>'horas_estimadas', '')::numeric
FROM base b
WHERE b.id = p.id AND b.d IS NOT NULL AND b.d ? 'horas_estimadas';

WITH base AS (
  SELECT p.id,
         CASE WHEN p.desglose ~ '^\s*\{' THEN p.desglose::jsonb END AS d
  FROM public.propuestas_cotizacion p
  WHERE p.desglose IS NOT NULL
), lineas AS (
  SELECT id, 'materiales'::text AS concepto, NULLIF(d->>'materiales_clp', '')::numeric AS monto, 1 AS orden FROM base WHERE d IS NOT NULL
  UNION ALL
  SELECT id, 'mano_obra', NULLIF(d->>'mano_obra_clp', '')::numeric, 2 FROM base WHERE d IS NOT NULL
)
INSERT INTO public.propuesta_cotizacion_items (id_propuesta, linea, concepto, monto)
SELECT id, (row_number() OVER (PARTITION BY id ORDER BY orden))::smallint, concepto, monto
FROM lineas WHERE monto IS NOT NULL;

ALTER TABLE public.propuestas_cotizacion DROP COLUMN desglose;

-- La tabla usa privilegios por columna: la columna nueva queda como las demás.
GRANT SELECT (horas_estimadas) ON public.propuestas_cotizacion TO anon, authenticated;
GRANT INSERT (horas_estimadas), UPDATE (horas_estimadas) ON public.propuestas_cotizacion TO authenticated;

-- Mismo acceso que la cotización: la ve quien ve la cotización; escribe solo
-- el profesional dueño mientras la cotización no esté seleccionada o aceptada.
ALTER TABLE public.propuesta_cotizacion_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY propuesta_items_select ON public.propuesta_cotizacion_items
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.propuestas_cotizacion p WHERE p.id = propuesta_cotizacion_items.id_propuesta));
CREATE POLICY propuesta_items_insert ON public.propuesta_cotizacion_items
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.propuestas_cotizacion p
    WHERE p.id = propuesta_cotizacion_items.id_propuesta
      AND p.id_trabajador = (SELECT auth.uid())
      AND p.estado NOT IN ('aceptada', 'seleccionada')));
CREATE POLICY propuesta_items_update ON public.propuesta_cotizacion_items
  FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.propuestas_cotizacion p
    WHERE p.id = propuesta_cotizacion_items.id_propuesta
      AND p.id_trabajador = (SELECT auth.uid())
      AND p.estado NOT IN ('aceptada', 'seleccionada')))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.propuestas_cotizacion p
    WHERE p.id = propuesta_cotizacion_items.id_propuesta
      AND p.id_trabajador = (SELECT auth.uid())
      AND p.estado NOT IN ('aceptada', 'seleccionada')));
CREATE POLICY propuesta_items_delete ON public.propuesta_cotizacion_items
  FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.propuestas_cotizacion p
    WHERE p.id = propuesta_cotizacion_items.id_propuesta
      AND p.id_trabajador = (SELECT auth.uid())
      AND p.estado NOT IN ('aceptada', 'seleccionada')));

REVOKE ALL ON public.propuesta_cotizacion_items FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.propuesta_cotizacion_items TO authenticated;
GRANT ALL ON public.propuesta_cotizacion_items TO service_role;

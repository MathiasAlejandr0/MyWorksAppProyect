-- DEMO / CORRECCIÓN DERIVADA. No es una migración automática.
-- NO correr en producción sin el OK de Mathias.
--
-- Copia a instantanea_precio el monto real ya registrado en pagos (o en
-- una cotización aceptada) cuando el trabajo no tiene snapshot ni tarifa
-- en metadatos. No inventa precios: solo transcribe un monto que ya existe.
-- Así la tarjeta deja de decir «Monto por cotizar» en trabajos que sí
-- tienen un pago o una cotización.
--
-- Reejecutar es seguro: solo toca filas sin precio conocido.

BEGIN;

WITH pago AS (
  SELECT DISTINCT ON (p.id_trabajo)
    p.id_trabajo,
    p.monto::integer AS monto
  FROM public.pagos p
  WHERE p.monto > 0
    AND p.estado IS DISTINCT FROM 'reembolsado'
  ORDER BY
    p.id_trabajo,
    CASE p.tipo_pago WHEN 'principal' THEN 0 ELSE 1 END,
    CASE p.estado
      WHEN 'liberado' THEN 0
      WHEN 'retenido' THEN 1
      WHEN 'autorizado' THEN 2
      WHEN 'pendiente' THEN 3
      ELSE 9
    END,
    p.creado_en DESC NULLS LAST
),
cotiz AS (
  SELECT DISTINCT ON (q.id_trabajo)
    q.id_trabajo,
    q.monto_total_clp AS monto
  FROM public.propuestas_cotizacion q
  WHERE q.monto_total_clp > 0
  ORDER BY
    q.id_trabajo,
    CASE q.estado WHEN 'aceptada' THEN 0 WHEN 'seleccionada' THEN 1 ELSE 2 END,
    q.creado_en DESC NULLS LAST
),
fuente AS (
  SELECT
    j.id,
    COALESCE(pago.monto, cotiz.monto) AS monto
  FROM public.trabajos j
  LEFT JOIN pago ON pago.id_trabajo = j.id
  LEFT JOIN cotiz ON cotiz.id_trabajo = j.id
  WHERE COALESCE(pago.monto, cotiz.monto) IS NOT NULL
    AND (
      j.instantanea_precio IS NULL
      OR length(btrim(j.instantanea_precio)) <= 2
    )
    AND NOT (
      j.metadatos_servicio IS NOT NULL
      AND length(btrim(j.metadatos_servicio)) > 2
      AND (
        COALESCE(NULLIF(btrim(j.metadatos_servicio), ''), '{}')::jsonb
          ?| ARRAY['worker_tier_price_clp','total_clp','totalClp','monto','monto_clp']
      )
    )
)
UPDATE public.trabajos j
SET instantanea_precio = json_build_object(
      'pricing_mode', COALESCE(NULLIF(j.modalidad_cobro, ''), 'precio_fijo'),
      'total_clp', fuente.monto,
      'subtotal_clp', fuente.monto,
      'currency', 'CLP',
      'source', 'backfill_monto_conocido'
    )::text,
    actualizado_en = COALESCE(j.actualizado_en, now()::text)
FROM fuente
WHERE j.id = fuente.id;

COMMIT;

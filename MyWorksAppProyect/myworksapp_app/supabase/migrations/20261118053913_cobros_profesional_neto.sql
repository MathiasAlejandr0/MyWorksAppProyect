-- Desglose de cada cobro del profesional: bruto, comisión del servicio y neto.
--
-- Pago principal: la comisión (5 %, mínimo $1.000) se descuenta del profesional,
-- igual que PricingService.serviceFeeFor en la app. Nunca supera el bruto.
-- Orden de cambio: el cliente paga el monto de la orden más 8 %; el profesional
-- recibe el monto de la orden y la diferencia es la comisión.
--
-- La app y la consola leen estos montos desde aquí; no se modifican datos.

CREATE OR REPLACE FUNCTION public.comision_servicio_clp(p_bruto numeric)
RETURNS integer
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN COALESCE(p_bruto, 0) <= 0 THEN 0
    ELSE LEAST(round(p_bruto)::integer, GREATEST(1000, round(p_bruto * 0.05)::integer))
  END
$$;

COMMENT ON FUNCTION public.comision_servicio_clp(numeric) IS
  'Comisión del servicio sobre un pago principal: 5 % redondeado, mínimo 1.000 CLP, nunca mayor que el pago.';

CREATE OR REPLACE VIEW public.cobros_profesional
WITH (security_invoker = true)
AS
SELECT
  p.id AS id_pago,
  p.id_trabajo,
  t.id_trabajador,
  p.tipo_pago,
  p.estado AS estado_pago,
  round(COALESCE(p.monto, 0))::integer AS bruto_clp,
  d.comision_clp,
  round(COALESCE(p.monto, 0))::integer - d.comision_clp AS neto_clp,
  l.estado_transferencia,
  l.referencia_transferencia,
  l.creado_en AS liquidado_en,
  p.liberado_en,
  p.creado_en
FROM public.pagos p
JOIN public.trabajos t ON t.id = p.id_trabajo
LEFT JOIN public.ordenes_cambio oc
  ON p.tipo_pago = 'orden_cambio' AND oc.id::text = p.id_orden_cambio::text
LEFT JOIN LATERAL (
  SELECT x.estado_transferencia, x.referencia_transferencia, x.creado_en
  FROM public.liquidaciones x
  WHERE x.id_pago = p.id
  ORDER BY x.creado_en DESC
  LIMIT 1
) l ON true
CROSS JOIN LATERAL (
  SELECT CASE
    WHEN p.tipo_pago = 'orden_cambio' AND oc.monto_clp IS NOT NULL
      THEN GREATEST(0, round(COALESCE(p.monto, 0))::integer - round(oc.monto_clp)::integer)
    ELSE public.comision_servicio_clp(p.monto)
  END AS comision_clp
) d;

COMMENT ON VIEW public.cobros_profesional IS
  'Cobros por pago con bruto, comisión y neto para el profesional. Respeta el RLS de pagos, trabajos y liquidaciones.';

REVOKE ALL ON public.cobros_profesional FROM anon, public;
GRANT SELECT ON public.cobros_profesional TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.comision_servicio_clp(numeric) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.comision_servicio_clp(numeric) TO authenticated, service_role;

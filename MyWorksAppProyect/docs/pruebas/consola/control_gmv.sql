-- Control del GMV que devuelve consola_resumen_periodo.
-- Correr en local, con un administrador aal2. La diferencia esperada es 0.
-- No cuenta trabajos completados: no existe fecha_completado.
--
-- gmv_clp del RPC debe coincidir con:
SELECT COALESCE(sum(round(monto)), 0) AS gmv_clp
FROM public.pagos
WHERE estado IN ('retenido', 'liberado')
  AND public.texto_a_timestamptz(creado_en) >= :desde
  AND public.texto_a_timestamptz(creado_en) < :hasta;

-- comision_clp (solo pago principal) debe coincidir con:
SELECT COALESCE(sum(public.comision_servicio_clp(monto)), 0) AS comision_clp
FROM public.pagos
WHERE estado IN ('retenido', 'liberado')
  AND tipo_pago = 'principal'
  AND public.texto_a_timestamptz(creado_en) >= :desde
  AND public.texto_a_timestamptz(creado_en) < :hasta;

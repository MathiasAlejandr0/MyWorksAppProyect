-- Auditoría 2026-10-05 (P1, flujo de liquidaciones).
-- El seed de la demo creaba pagos `liberado` sin `liberado_en` y sin fila en `liquidaciones`.
-- En vivo había 87 pagos liberados y 0 liquidaciones: la auditoría del escritorio decía
-- «Aún no hay liquidaciones registradas». marcar_pago_liberado (la conformidad real) sí
-- escribe las dos cosas; esto deja los pagos de la demo igual que uno liberado de verdad.
--
-- Solo toca filas `demo-%`, solo completa lo que falta y no borra nada.
-- El seed (scripts/demo/seed_demo.sql) hace lo mismo al volver a correrlo.

UPDATE public.pagos
SET liberado_en = COALESCE(
  public.texto_a_timestamptz(actualizado_en::text),
  public.texto_a_timestamptz(creado_en::text),
  now()
)
WHERE id LIKE 'demo-%'
  AND estado = 'liberado'
  AND liberado_en IS NULL;

INSERT INTO public.liquidaciones (
  id, id_pago, id_trabajo, id_trabajador, monto_clp,
  proveedor, referencia_transferencia, notas, id_operador, creado_en
)
SELECT
  'demo-liq-' || p.id,
  p.id,
  p.id_trabajo,
  t.id_trabajador::text,
  p.monto,
  'conformidad',
  'CONFORME-' || left(replace(p.id_trabajo, '-', ''), 16),
  'Pago de la demo liberado al recibir conforme',
  COALESCE(t.id_usuario::text, 'seed-demo'),
  COALESCE(public.texto_a_timestamptz(p.liberado_en::text), now())
FROM public.pagos p
JOIN public.trabajos t ON t.id = p.id_trabajo
WHERE p.id LIKE 'demo-%'
  AND p.estado = 'liberado'
  AND p.monto > 0
  AND NOT EXISTS (
    SELECT 1 FROM public.liquidaciones l WHERE l.id_pago = p.id
  );

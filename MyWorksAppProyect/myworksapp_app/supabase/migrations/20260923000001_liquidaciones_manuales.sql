-- Liquidaciones manuales (admin confirma transferencia bancaria externa)
-- Proveedores futuros: khipu | fintoc (misma tabla, distinto proveedor).

CREATE TABLE IF NOT EXISTS public.liquidaciones (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  id_pago text NOT NULL REFERENCES public.pagos (id),
  id_trabajo text NOT NULL,
  id_trabajador text,
  monto_clp numeric NOT NULL CHECK (monto_clp > 0),
  proveedor text NOT NULL DEFAULT 'manual'
    CHECK (proveedor IN ('manual', 'khipu', 'fintoc')),
  referencia_transferencia text NOT NULL,
  notas text,
  id_operador text NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS liquidaciones_pago_uidx
  ON public.liquidaciones (id_pago);

CREATE INDEX IF NOT EXISTS liquidaciones_creado_idx
  ON public.liquidaciones (creado_en DESC);

ALTER TABLE public.liquidaciones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS liquidaciones_admin_all ON public.liquidaciones;
CREATE POLICY liquidaciones_admin_all
  ON public.liquidaciones
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

GRANT SELECT, INSERT ON public.liquidaciones TO authenticated;
GRANT ALL ON public.liquidaciones TO service_role;

COMMENT ON TABLE public.liquidaciones IS
  'Registro de liquidación al profesional. manual = transferencia externa confirmada por admin; khipu/fintoc = PSP futuro.';

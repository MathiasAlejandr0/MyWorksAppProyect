-- Portado desde MathiasAlejandr0/MyWorksAppProyect PR #55 (20261114000005_pagos_cuenta_bancaria.sql).
-- Aplicada en vivo dentro de 20261115051320–20261115051532.
-- No reaplicar el SQL en wxqrfcqifkfgawrnqmnj: ya está en la base.

-- Pagos al profesional: cuenta bancaria privada y estado de la transferencia.
-- Aditiva. Las liquidaciones que ya existen quedan como `transferido`
-- (así se registraron: con referencia de transferencia).
-- No aplicar en vivo desde este PR.

BEGIN;

ALTER TABLE public.liquidaciones
  ADD COLUMN IF NOT EXISTS estado_transferencia text;

UPDATE public.liquidaciones
SET estado_transferencia = 'transferido'
WHERE estado_transferencia IS NULL;

ALTER TABLE public.liquidaciones
  ALTER COLUMN estado_transferencia SET DEFAULT 'transferido';

ALTER TABLE public.liquidaciones
  ALTER COLUMN estado_transferencia SET NOT NULL;

ALTER TABLE public.liquidaciones
  DROP CONSTRAINT IF EXISTS liquidaciones_estado_transferencia_chk;

ALTER TABLE public.liquidaciones
  ADD CONSTRAINT liquidaciones_estado_transferencia_chk
  CHECK (estado_transferencia IN ('pendiente', 'transferido', 'fallido'));

DROP POLICY IF EXISTS liquidaciones_trabajador_select ON public.liquidaciones;
CREATE POLICY liquidaciones_trabajador_select
  ON public.liquidaciones
  FOR SELECT
  TO authenticated
  USING (id_trabajador = (SELECT auth.uid())::text);

CREATE TABLE IF NOT EXISTS public.cuentas_bancarias (
  id_usuario uuid PRIMARY KEY REFERENCES public.perfiles (id) ON DELETE CASCADE,
  banco text NOT NULL,
  tipo_cuenta text NOT NULL,
  numero_cuenta text NOT NULL,
  rut_titular text NOT NULL,
  nombre_titular text NOT NULL,
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT cuentas_bancarias_tipo_chk
    CHECK (tipo_cuenta IN ('vista', 'corriente', 'rut', 'ahorro')),
  CONSTRAINT cuentas_bancarias_numero_chk
    CHECK (numero_cuenta ~ '^[0-9]{4,20}$')
);

ALTER TABLE public.cuentas_bancarias ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cuentas_bancarias_propietario ON public.cuentas_bancarias;
CREATE POLICY cuentas_bancarias_propietario
  ON public.cuentas_bancarias
  FOR ALL
  TO authenticated
  USING (
    id_usuario = (SELECT auth.uid())
    OR public.is_admin()
  )
  WITH CHECK (
    id_usuario = (SELECT auth.uid())
    OR public.is_admin()
  );

REVOKE ALL ON TABLE public.cuentas_bancarias FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE ON TABLE public.cuentas_bancarias TO authenticated;
GRANT ALL ON TABLE public.cuentas_bancarias TO service_role;

COMMENT ON TABLE public.cuentas_bancarias IS
  'Datos bancarios del profesional. RLS: solo el dueño y un administrador. No es un dato público.';

CREATE OR REPLACE FUNCTION public.registrar_transferencia_profesional(
  p_id_pago text,
  p_referencia text,
  p_notas text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pago public.pagos%ROWTYPE;
  v_job public.trabajos%ROWTYPE;
  v_liq_id text;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_id_pago IS NULL OR length(trim(COALESCE(p_referencia, ''))) < 4 THEN
    RAISE EXCEPTION 'paymentId y referencia (>=4) requeridos';
  END IF;

  SELECT * INTO v_pago FROM public.pagos WHERE id = p_id_pago FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pago no encontrado';
  END IF;

  IF v_pago.estado IN ('reembolsado', 'reembolsado_auto', 'anulado', 'fallido') THEN
    RAISE EXCEPTION 'Pago no liberable (estado %)', v_pago.estado;
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id = v_pago.id_trabajo;

  IF EXISTS (
    SELECT 1 FROM public.liquidaciones
    WHERE id_pago = p_id_pago AND estado_transferencia = 'transferido'
  ) THEN
    RETURN jsonb_build_object(
      'payment_id', p_id_pago,
      'estado', 'transferido',
      'already', true
    );
  END IF;

  IF v_pago.estado IN ('autorizado', 'retenido', 'pagado_por_confirmar') THEN
    UPDATE public.pagos SET
      estado = 'liberado',
      liberado_en = COALESCE(liberado_en, now()),
      actualizado_en = now()
    WHERE id = p_id_pago;

    UPDATE public.trabajos SET
      estado_pago = 'liberado',
      actualizado_en = now()
    WHERE id = v_pago.id_trabajo;
  END IF;

  UPDATE public.liquidaciones SET
    estado_transferencia = 'transferido',
    referencia_transferencia = trim(p_referencia),
    notas = COALESCE(NULLIF(trim(COALESCE(p_notas, '')), ''), notas)
  WHERE id_pago = p_id_pago
  RETURNING id INTO v_liq_id;

  IF v_liq_id IS NULL THEN
    v_liq_id := gen_random_uuid()::text;
    INSERT INTO public.liquidaciones (
      id, id_pago, id_trabajo, id_trabajador, monto_clp,
      proveedor, referencia_transferencia, notas, id_operador,
      creado_en, estado_transferencia
    ) VALUES (
      v_liq_id,
      p_id_pago,
      v_pago.id_trabajo,
      v_job.id_trabajador,
      v_pago.monto,
      'manual',
      trim(p_referencia),
      NULLIF(trim(COALESCE(p_notas, '')), ''),
      (SELECT auth.uid())::text,
      now(),
      'transferido'
    );
  END IF;

  RETURN jsonb_build_object(
    'payment_id', p_id_pago,
    'liquidacion_id', v_liq_id,
    'estado', 'transferido'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.registrar_transferencia_profesional(text, text, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_transferencia_profesional(text, text, text)
  TO authenticated, service_role;

COMMIT;

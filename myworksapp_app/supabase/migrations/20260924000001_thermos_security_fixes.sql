-- Thermos High/Medium remediations: columnas PSP, liberar_escrow, liquidación atómica

-- 1) Clientes autenticados NO pueden leer token_ws / URL TBK
REVOKE SELECT (token_tbk, url_tbk) ON TABLE public.pagos FROM authenticated;
REVOKE SELECT (token_tbk, url_tbk) ON TABLE public.pagos FROM anon;

COMMENT ON COLUMN public.pagos.token_tbk IS
  'token_ws Transbank — solo service_role / Edge Functions';
COMMENT ON COLUMN public.pagos.url_tbk IS
  'URL TBK — solo service_role / Edge Functions';

-- Marca consumo de handoff (ticket de un solo uso efectivo)
ALTER TABLE public.pagos
  ADD COLUMN IF NOT EXISTS handoff_consumido_en timestamptz;

-- 2) Cerrar bypass: liberar_escrow solo service_role (clientes usan Edge webpay-release)
REVOKE ALL ON FUNCTION public.liberar_escrow(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.liberar_escrow(text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.liberar_escrow(text) TO service_role;

-- 3) Liberación + liquidación atómica (admin vía Edge con service role)
CREATE OR REPLACE FUNCTION public.liberar_escrow_manual(
  p_id_pago text,
  p_id_operador text,
  p_referencia text,
  p_notas text DEFAULT NULL,
  p_proveedor text DEFAULT 'manual'
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
  IF p_id_pago IS NULL OR length(trim(p_referencia)) < 4 THEN
    RAISE EXCEPTION 'paymentId y referencia (>=4) requeridos';
  END IF;

  IF p_proveedor IS NULL OR p_proveedor NOT IN ('manual', 'khipu', 'fintoc') THEN
    RAISE EXCEPTION 'proveedor inválido';
  END IF;

  SELECT * INTO v_pago FROM public.pagos WHERE id = p_id_pago FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pago no encontrado';
  END IF;

  IF v_pago.estado NOT IN ('autorizado', 'retenido') THEN
    RAISE EXCEPTION 'Pago no liberable (estado %)', v_pago.estado;
  END IF;

  IF EXISTS (SELECT 1 FROM public.liquidaciones WHERE id_pago = p_id_pago) THEN
    RAISE EXCEPTION 'Pago ya liquidado';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id = v_pago.id_trabajo;

  UPDATE public.pagos SET
    estado = 'liberado',
    liberado_en = now(),
    actualizado_en = now()
  WHERE id = p_id_pago;

  UPDATE public.trabajos SET
    estado_pago = 'liberado',
    actualizado_en = now()
  WHERE id = v_pago.id_trabajo;

  v_liq_id := gen_random_uuid()::text;
  INSERT INTO public.liquidaciones (
    id, id_pago, id_trabajo, id_trabajador, monto_clp,
    proveedor, referencia_transferencia, notas, id_operador, creado_en
  ) VALUES (
    v_liq_id,
    p_id_pago,
    v_pago.id_trabajo,
    v_job.id_trabajador,
    v_pago.monto,
    p_proveedor,
    trim(p_referencia),
    NULLIF(trim(p_notas), ''),
    p_id_operador,
    now()
  );

  RETURN jsonb_build_object(
    'payment_id', p_id_pago,
    'liquidacion_id', v_liq_id,
    'estado', 'liberado'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.liberar_escrow_manual(text, text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.liberar_escrow_manual(text, text, text, text, text) TO service_role;

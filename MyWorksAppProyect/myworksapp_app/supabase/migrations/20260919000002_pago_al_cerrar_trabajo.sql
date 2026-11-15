-- El profesional asignado puede mover el escrow solo cuando el trabajo
-- ya quedó cerrado en la RPC anterior:
--   completado  -> liberar (autorizado|retenido → liberado)
--   cancelado   -> reembolsar (autorizado|retenido → reembolsado)
-- Sigue pudiendo retener al abrir una disputa. No autoriza ni libera a destiempo.

BEGIN;

CREATE OR REPLACE FUNCTION public.simular_transicion_pago(
  p_pago_id text,
  p_nuevo_estado text
)
RETURNS public.pagos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.pagos;
  v_job public.trabajos;
  v_es_cliente boolean := false;
  v_es_trabajador boolean := false;
  v_ok boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id::text = p_pago_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'pago no encontrado';
  END IF;

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = v_row.id_trabajo::text
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo del pago no encontrado';
  END IF;

  v_es_cliente := v_job.id_usuario::text = auth.uid()::text;
  v_es_trabajador := v_job.id_trabajador IS NOT NULL
    AND v_job.id_trabajador::text = auth.uid()::text;

  IF NOT (public.is_admin() OR v_es_cliente OR v_es_trabajador) THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;

  IF public.is_admin() OR v_es_cliente THEN
    IF v_row.estado = 'pendiente' AND p_nuevo_estado IN ('autorizado', 'reembolsado') THEN
      v_ok := true;
    ELSIF v_row.estado = 'autorizado' AND p_nuevo_estado IN ('retenido', 'liberado', 'reembolsado') THEN
      v_ok := true;
    ELSIF v_row.estado = 'retenido' AND p_nuevo_estado IN ('liberado', 'reembolsado') THEN
      v_ok := true;
    END IF;
  ELSIF v_es_trabajador THEN
    IF v_row.estado = 'autorizado' AND p_nuevo_estado = 'retenido' THEN
      v_ok := true;
    ELSIF v_job.estado = 'completado'
       AND v_row.estado IN ('autorizado', 'retenido')
       AND p_nuevo_estado = 'liberado' THEN
      v_ok := true;
    ELSIF v_job.estado = 'cancelado'
       AND v_row.estado IN ('autorizado', 'retenido')
       AND p_nuevo_estado = 'reembolsado' THEN
      v_ok := true;
    END IF;
  END IF;

  IF NOT v_ok THEN
    RAISE EXCEPTION 'transicion de pago no permitida: % -> %', v_row.estado, p_nuevo_estado;
  END IF;

  UPDATE public.pagos
  SET
    estado = p_nuevo_estado,
    autorizado_en = CASE
      WHEN p_nuevo_estado = 'autorizado' THEN to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
      ELSE autorizado_en
    END,
    liberado_en = CASE
      WHEN p_nuevo_estado = 'liberado' THEN to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
      ELSE liberado_en
    END,
    reembolsado_en = CASE
      WHEN p_nuevo_estado = 'reembolsado' THEN to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
      ELSE reembolsado_en
    END,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_pago_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

COMMENT ON FUNCTION public.simular_transicion_pago(text, text) IS
  'MOCK escrow. Cliente y admin usan la matriz completa. El trabajador retiene siempre; libera solo si el trabajo ya está completado y reembolsa solo si ya está cancelado.';

GRANT EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) FROM anon;
REVOKE ALL ON FUNCTION public.simular_transicion_pago(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) TO authenticated;

COMMIT;

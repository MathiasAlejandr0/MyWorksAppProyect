-- Cierre de EXECUTE en RPC SECURITY DEFINER.
-- Ya aplicada en la base como security_lockdown_rpc. Este archivo es la copia
-- del repo y queda antes de 20261006000001. Idempotente: se puede volver a correr.

BEGIN;

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
  -- auth.role() lee el JWT. Un token anon no es NULL: la versión con
  -- request.jwt.claim.role lo dejaba pasar.
  IF NOT (
    COALESCE(auth.role(), '') = 'service_role'
    OR public.is_admin()
    OR (auth.role() IS NULL AND auth.uid() IS NULL)
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

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

DO $$
DECLARE
  r record;
  fn text;
BEGIN
  FOREACH fn IN ARRAY ARRAY[
    'liberar_escrow_manual',
    'liberar_escrow'
  ]
  LOOP
    FOR r IN
      SELECT p.oid::regprocedure AS sig
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = fn
    LOOP
      EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', r.sig);
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role', r.sig);
    END LOOP;
  END LOOP;

  FOREACH fn IN ARRAY ARRAY[
    'admin_actualizar_estado_disputa',
    'admin_metricas_resumen',
    'es_parte_trabajo',
    'listar_trabajos_marketplace'
  ]
  LOOP
    FOR r IN
      SELECT p.oid::regprocedure AS sig
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = fn
    LOOP
      EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', r.sig);
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.sig);
    END LOOP;
  END LOOP;

  FOR r IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'listar_profesionales_catalogo'
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', r.sig);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO anon, authenticated', r.sig);
  END LOOP;

  FOR r IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'proteger_verificacion_profesional'
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', r.sig);
  END LOOP;
END $$;

COMMIT;

-- El reembolso se pide una sola vez. Cancelar con pago retenido exige
-- devolver la tarjeta antes. Una disputa abierta también frena al administrador.

BEGIN;

ALTER TABLE public.pagos
  ADD COLUMN IF NOT EXISTS reembolso_solicitado_en timestamptz;

COMMENT ON COLUMN public.pagos.reembolso_solicitado_en IS
  'Marca que ya se pidió la devolución a Transbank. Un reintento no vuelve a llamar a la tarjeta.';

CREATE OR REPLACE FUNCTION public.transicionar_trabajo(
  p_trabajo_id text,
  p_nuevo_estado text,
  p_pin text DEFAULT NULL
)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
  v_expected_pin text;
  v_mode text;
  v_disputa boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row
  FROM public.trabajos
  WHERE id::text = p_trabajo_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;

  IF NOT (
    public.is_admin()
    OR v_row.id_usuario::text = auth.uid()::text
    OR (
      v_row.id_trabajador IS NOT NULL
      AND v_row.id_trabajador::text = auth.uid()::text
    )
  ) THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;

  v_disputa := EXISTS (
    SELECT 1
    FROM public.disputas d
    WHERE d.id_trabajo::text = v_row.id::text
      AND d.estado IN ('abierta', 'en_revision')
  );

  IF v_disputa AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'hay una disputa abierta; solo atencion al cliente puede continuar';
  END IF;

  IF v_disputa AND p_nuevo_estado = 'cancelado' THEN
    RAISE EXCEPTION 'hay una disputa abierta; resuelvela para liberar o devolver el pago';
  END IF;

  IF NOT public.is_admin() AND p_nuevo_estado = 'completado' THEN
    RAISE EXCEPTION 'recibe conforme el trabajo para liberar el pago';
  END IF;

  IF p_nuevo_estado = 'cancelado'
     AND v_row.estado = 'esperando_aprobacion_cliente' THEN
    RAISE EXCEPTION 'si no estas conforme, abre una disputa; el pago sigue retenido';
  END IF;

  IF p_nuevo_estado = 'cancelado' AND EXISTS (
    SELECT 1
    FROM public.pagos p
    WHERE p.id_trabajo::text = v_row.id::text
      AND p.tipo_pago = 'principal'
      AND p.estado IN ('retenido', 'autorizado')
  ) THEN
    RAISE EXCEPTION 'devuelve el pago a la tarjeta antes de cancelar';
  END IF;

  v_mode := COALESCE(v_row.modalidad_cobro::text, 'legado');

  IF NOT public.is_admin() THEN
    IF NOT public.transicion_trabajo_permitida(
      v_row.estado::text,
      p_nuevo_estado::text,
      v_mode
    ) THEN
      RAISE EXCEPTION 'transicion no permitida: % -> %', v_row.estado, p_nuevo_estado;
    END IF;

    IF v_mode <> 'legado'
       AND (
         p_nuevo_estado IN ('aceptado', 'en_curso', 'completado')
         OR (
           v_row.estado = 'esperando_pago'
           AND p_nuevo_estado = 'pendiente'
         )
       )
       AND NOT EXISTS (
         SELECT 1
         FROM public.pagos p
         WHERE p.id_trabajo::text = v_row.id::text
           AND p.tipo_pago = 'principal'
           AND p.estado IN ('retenido', 'autorizado')
       ) THEN
      RAISE EXCEPTION 'se requiere un pago en garantia antes de %', p_nuevo_estado;
    END IF;
  END IF;

  BEGIN
    v_expected_pin := NULLIF(trim(v_row.metadatos_servicio::jsonb ->> 'pin'), '');
  EXCEPTION WHEN others THEN
    v_expected_pin := NULL;
  END;

  IF NOT public.is_admin()
     AND v_expected_pin IS NOT NULL
     AND p_nuevo_estado IN ('en_curso', 'completado') THEN
    IF p_pin IS NULL OR trim(p_pin) <> v_expected_pin THEN
      RAISE EXCEPTION 'pin incorrecto o requerido';
    END IF;
  END IF;

  IF p_pin IS NOT NULL
     AND length(trim(p_pin)) > 0
     AND v_expected_pin IS NULL THEN
    RAISE EXCEPTION 'pin requerido pero no configurado en el trabajo';
  END IF;

  UPDATE public.trabajos
  SET
    estado = p_nuevo_estado,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.rechazar_trabajo_pendiente(
  p_trabajo_id text,
  p_metadatos text DEFAULT NULL
)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row FROM public.trabajos WHERE id::text = p_trabajo_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;
  IF NOT (
    public.is_admin()
    OR (
      v_row.id_trabajador IS NOT NULL
      AND v_row.id_trabajador::text = auth.uid()::text
    )
  ) THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;
  IF v_row.estado <> 'pendiente' THEN
    RAISE EXCEPTION 'solo se rechazan trabajos pendientes';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM public.pagos p
    WHERE p.id_trabajo::text = v_row.id::text
      AND p.tipo_pago = 'principal'
      AND p.estado IN ('retenido', 'autorizado')
  ) THEN
    RAISE EXCEPTION 'devuelve el pago a la tarjeta antes de rechazar';
  END IF;

  UPDATE public.trabajos
  SET
    estado = 'cancelado',
    metadatos_servicio = COALESCE(p_metadatos, metadatos_servicio),
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.marcar_pago_liberado(
  p_id_pago text,
  p_id_operador text,
  p_referencia text,
  p_notas text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_pago public.pagos%ROWTYPE;
  v_job public.trabajos%ROWTYPE;
BEGIN
  IF p_id_pago IS NULL OR length(trim(p_referencia)) < 4 THEN
    RAISE EXCEPTION 'pago y referencia requeridos';
  END IF;

  SELECT * INTO v_pago FROM public.pagos WHERE id = p_id_pago FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pago no encontrado';
  END IF;
  IF v_pago.reembolso_solicitado_en IS NOT NULL AND v_pago.estado <> 'liberado' THEN
    RAISE EXCEPTION 'el pago ya tiene una devolucion pedida a la tarjeta';
  END IF;
  IF v_pago.estado = 'liberado' THEN
    RETURN;
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
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id = v_pago.id_trabajo;

  INSERT INTO public.liquidaciones (
    id, id_pago, id_trabajo, id_trabajador, monto_clp,
    proveedor, referencia_transferencia, notas, id_operador, creado_en
  ) VALUES (
    gen_random_uuid()::text,
    p_id_pago,
    v_pago.id_trabajo,
    v_job.id_trabajador,
    v_pago.monto,
    'conformidad',
    trim(p_referencia),
    NULLIF(trim(COALESCE(p_notas, '')), ''),
    p_id_operador,
    now()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.reembolsar_escrow(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reembolsar_escrow(text) FROM authenticated;
REVOKE ALL ON FUNCTION public.reembolsar_escrow(text) FROM anon;
GRANT EXECUTE ON FUNCTION public.reembolsar_escrow(text) TO service_role;

COMMIT;

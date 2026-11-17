-- liquidaciones: id_trabajador e id_operador pasan de text a uuid con clave
-- foránea a perfiles. El operador 'sistema' (liberación automática) queda como
-- NULL y se marca en liberada_por_sistema; todas las liquidaciones deben tener
-- un operador o estar marcadas como del sistema.

ALTER TABLE public.liquidaciones
  ADD COLUMN liberada_por_sistema boolean NOT NULL DEFAULT false;

UPDATE public.liquidaciones SET liberada_por_sistema = true
WHERE lower(btrim(id_operador)) = 'sistema';

DROP POLICY IF EXISTS liquidaciones_select ON public.liquidaciones;
ALTER TABLE public.liquidaciones DROP CONSTRAINT IF EXISTS liquidaciones_id_trabajador_uuid_chk;

ALTER TABLE public.liquidaciones
  ALTER COLUMN id_trabajador TYPE uuid USING id_trabajador::uuid,
  ALTER COLUMN id_operador DROP NOT NULL,
  ALTER COLUMN id_operador TYPE uuid
    USING CASE WHEN id_operador ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
               THEN id_operador::uuid END;

ALTER TABLE public.liquidaciones
  ADD CONSTRAINT liquidaciones_id_trabajador_fkey
    FOREIGN KEY (id_trabajador) REFERENCES public.perfiles (id) ON DELETE SET NULL,
  ADD CONSTRAINT liquidaciones_id_operador_fkey
    FOREIGN KEY (id_operador) REFERENCES public.perfiles (id) ON DELETE SET NULL,
  ADD CONSTRAINT liquidaciones_operador_chk
    CHECK (id_operador IS NOT NULL OR liberada_por_sistema);

CREATE INDEX IF NOT EXISTS liquidaciones_operador_idx
  ON public.liquidaciones (id_operador) WHERE id_operador IS NOT NULL;

CREATE POLICY liquidaciones_select ON public.liquidaciones
  FOR SELECT TO authenticated
  USING ((SELECT public.is_admin()) OR id_trabajador = (SELECT auth.uid()));

CREATE OR REPLACE FUNCTION public.fijar_liquidacion_desde_pago()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_job text;
  v_worker uuid;
BEGIN
  SELECT t.id::text, NULLIF(t.id_trabajador::text, '')::uuid
  INTO v_job, v_worker
  FROM public.pagos p
  JOIN public.trabajos t ON t.id::text = p.id_trabajo::text
  WHERE p.id::text = NEW.id_pago::text;

  IF v_job IS NULL THEN
    RAISE EXCEPTION 'el pago de la liquidación no existe';
  END IF;

  NEW.id_trabajo := v_job;
  NEW.id_trabajador := v_worker;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.liberar_escrow_manual(p_id_pago text, p_id_operador text, p_referencia text, p_notas text DEFAULT NULL::text, p_proveedor text DEFAULT 'manual'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_pago public.pagos%ROWTYPE;
  v_job public.trabajos%ROWTYPE;
  v_liq_id text;
BEGIN
  -- auth.role() lee request.jwt.claims (PostgREST actual) y el GUC legado.
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
    proveedor, referencia_transferencia, notas, id_operador, liberada_por_sistema, creado_en
  ) VALUES (
    v_liq_id,
    p_id_pago,
    v_pago.id_trabajo,
    v_job.id_trabajador::uuid,
    v_pago.monto,
    p_proveedor,
    trim(p_referencia),
    NULLIF(trim(p_notas), ''),
    CASE WHEN lower(btrim(COALESCE(p_id_operador, ''))) IN ('', 'sistema') THEN NULL ELSE btrim(p_id_operador)::uuid END,
    lower(btrim(COALESCE(p_id_operador, ''))) IN ('', 'sistema'),
    now()
  );

  RETURN jsonb_build_object(
    'payment_id', p_id_pago,
    'liquidacion_id', v_liq_id,
    'estado', 'liberado'
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.marcar_pago_liberado(p_id_pago text, p_id_operador text, p_referencia text, p_notas text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    proveedor, referencia_transferencia, notas, id_operador, liberada_por_sistema, creado_en
  ) VALUES (
    gen_random_uuid()::text,
    p_id_pago,
    v_pago.id_trabajo,
    v_job.id_trabajador::uuid,
    v_pago.monto,
    'conformidad',
    trim(p_referencia),
    NULLIF(trim(COALESCE(p_notas, '')), ''),
    CASE WHEN lower(btrim(COALESCE(p_id_operador, ''))) IN ('', 'sistema') THEN NULL ELSE btrim(p_id_operador)::uuid END,
    lower(btrim(COALESCE(p_id_operador, ''))) IN ('', 'sistema'),
    now()
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.registrar_transferencia_profesional(p_id_pago text, p_referencia text, p_notas text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
      v_job.id_trabajador::uuid,
      v_pago.monto,
      'manual',
      trim(p_referencia),
      NULLIF(trim(COALESCE(p_notas, '')), ''),
      (SELECT auth.uid()),
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
$function$;

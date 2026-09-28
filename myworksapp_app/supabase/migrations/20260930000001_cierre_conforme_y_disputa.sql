-- El profesional acepta o rechaza después del cobro en garantía.
-- El cliente recibe conforme y ahí se libera el pago.
-- Con disputa abierta nadie mueve el dinero: solo el cierre de atención al cliente.

BEGIN;

CREATE OR REPLACE FUNCTION public.transicion_trabajo_permitida(
  p_desde text,
  p_hacia text,
  p_modalidad text DEFAULT 'legado'
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $$
DECLARE
  v_mode text := COALESCE(NULLIF(trim(p_modalidad), ''), 'legado');
BEGIN
  IF p_desde IS NULL OR p_hacia IS NULL OR p_desde = p_hacia THEN
    RETURN false;
  END IF;

  IF p_desde IN ('completado', 'cancelado', 'expirado', 'no_asistio') THEN
    RETURN false;
  END IF;

  IF p_hacia = 'cancelado' AND p_desde NOT IN ('completado', 'cancelado') THEN
    RETURN true;
  END IF;

  CASE v_mode
    WHEN 'precio_fijo', 'bloque_horas' THEN
      RETURN (p_desde, p_hacia) IN (
        ('esperando_pago', 'pendiente'),
        ('pendiente', 'aceptado'),
        ('aceptado', 'en_curso'),
        ('en_curso', 'esperando_aprobacion_cliente'),
        ('en_curso', 'no_asistio'),
        ('en_curso', 'pausado_orden_cambio'),
        ('pausado_orden_cambio', 'en_curso')
      );
    WHEN 'cotizacion_abierta' THEN
      RETURN (p_desde, p_hacia) IN (
        ('esperando_cotizaciones', 'cotizacion_seleccionada'),
        ('esperando_cotizaciones', 'expirado'),
        ('cotizacion_seleccionada', 'esperando_pago'),
        ('esperando_pago', 'pendiente'),
        ('pendiente', 'aceptado'),
        ('aceptado', 'en_curso'),
        ('en_curso', 'esperando_aprobacion_cliente'),
        ('en_curso', 'no_asistio'),
        ('en_curso', 'pausado_orden_cambio'),
        ('pausado_orden_cambio', 'en_curso')
      );
    ELSE
      RETURN (p_desde, p_hacia) IN (
        ('pendiente', 'aceptado'),
        ('pendiente', 'expirado'),
        ('aceptado', 'en_curso'),
        ('aceptado', 'pendiente'),
        ('en_curso', 'esperando_aprobacion_cliente'),
        ('en_curso', 'no_asistio'),
        ('en_curso', 'pausado_orden_cambio'),
        ('pausado_orden_cambio', 'en_curso')
      );
  END CASE;
END;
$$;

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

  IF NOT public.is_admin() AND EXISTS (
    SELECT 1
    FROM public.disputas d
    WHERE d.id_trabajo::text = v_row.id::text
      AND d.estado IN ('abierta', 'en_revision')
  ) THEN
    RAISE EXCEPTION 'hay una disputa abierta; solo atencion al cliente puede continuar';
  END IF;

  IF NOT public.is_admin() AND p_nuevo_estado = 'completado' THEN
    RAISE EXCEPTION 'recibe conforme el trabajo para liberar el pago';
  END IF;

  IF NOT public.is_admin()
     AND p_nuevo_estado = 'cancelado'
     AND v_row.estado = 'esperando_aprobacion_cliente' THEN
    RAISE EXCEPTION 'si no estas conforme, abre una disputa; el pago sigue retenido';
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

-- El cliente pide a un profesional concreto sin dejar el trabajo aceptado.
CREATE OR REPLACE FUNCTION public.vincular_trabajador_solicitud(
  p_trabajo_id text,
  p_trabajador_id text
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
  IF p_trabajador_id IS NULL OR length(trim(p_trabajador_id)) = 0 THEN
    RAISE EXCEPTION 'trabajador requerido';
  END IF;
  IF NOT public.es_rol_trabajador(p_trabajador_id) THEN
    RAISE EXCEPTION 'el usuario no es trabajador';
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
  ) THEN
    RAISE EXCEPTION 'solo el cliente puede pedir a este profesional';
  END IF;
  IF v_row.estado NOT IN ('esperando_pago', 'pendiente') THEN
    RAISE EXCEPTION 'estado no permite pedir profesional: %', v_row.estado;
  END IF;
  IF v_row.id_trabajador IS NOT NULL
     AND v_row.id_trabajador::text <> p_trabajador_id THEN
    RAISE EXCEPTION 'el trabajo ya tiene otro profesional';
  END IF;

  UPDATE public.trabajos
  SET
    id_trabajador = p_trabajador_id,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.vincular_trabajador_solicitud(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.vincular_trabajador_solicitud(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.vincular_trabajador_solicitud(text, text) FROM anon;

-- Aceptar un trabajo abierto ya no salta el pago ni la conformidad.
CREATE OR REPLACE FUNCTION public.asignar_trabajador_trabajo(
  p_trabajo_id text,
  p_trabajador_id text
)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
  v_mode text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF p_trabajador_id IS NULL OR length(trim(p_trabajador_id)) = 0 THEN
    RAISE EXCEPTION 'trabajador requerido';
  END IF;
  IF NOT public.es_rol_trabajador(p_trabajador_id) THEN
    RAISE EXCEPTION 'el usuario no es trabajador';
  END IF;
  IF NOT (public.is_admin() OR auth.uid()::text = p_trabajador_id) THEN
    RAISE EXCEPTION 'solo el trabajador o admin puede aceptar';
  END IF;

  SELECT * INTO v_row FROM public.trabajos WHERE id::text = p_trabajo_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;
  IF v_row.estado NOT IN ('pendiente', 'esperando_pago', 'cotizacion_seleccionada') THEN
    RAISE EXCEPTION 'estado no permite asignacion: %', v_row.estado;
  END IF;
  IF v_row.id_trabajador IS NOT NULL
     AND v_row.id_trabajador::text <> p_trabajador_id
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'trabajo ya asignado a otro trabajador';
  END IF;

  v_mode := COALESCE(v_row.modalidad_cobro::text, 'legado');

  IF v_row.estado = 'esperando_pago' THEN
    UPDATE public.trabajos
    SET
      id_trabajador = p_trabajador_id,
      actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
    WHERE id::text = p_trabajo_id
    RETURNING * INTO v_row;
    RETURN v_row;
  END IF;

  IF v_mode <> 'legado' AND NOT EXISTS (
    SELECT 1
    FROM public.pagos p
    WHERE p.id_trabajo::text = v_row.id::text
      AND p.tipo_pago = 'principal'
      AND p.estado IN ('retenido', 'autorizado')
  ) THEN
    RAISE EXCEPTION 'se requiere un pago en garantia antes de aceptar';
  END IF;

  UPDATE public.trabajos
  SET
    id_trabajador = p_trabajador_id,
    estado = 'aceptado',
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT con.conname
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE nsp.nspname = 'public'
      AND rel.relname = 'liquidaciones'
      AND con.contype = 'c'
      AND pg_get_constraintdef(con.oid) ILIKE '%proveedor%'
  LOOP
    EXECUTE format(
      'ALTER TABLE public.liquidaciones DROP CONSTRAINT %I',
      r.conname
    );
  END LOOP;
END $$;

ALTER TABLE public.liquidaciones
  ADD CONSTRAINT liquidaciones_proveedor_check
  CHECK (proveedor IN ('manual', 'khipu', 'fintoc', 'conformidad'));

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

REVOKE ALL ON FUNCTION public.marcar_pago_liberado(text, text, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.marcar_pago_liberado(text, text, text, text) FROM authenticated;
REVOKE ALL ON FUNCTION public.marcar_pago_liberado(text, text, text, text) FROM anon;

CREATE OR REPLACE FUNCTION public.cerrar_trabajo_conforme(p_trabajo_id text)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
  v_pago public.pagos%ROWTYPE;
  v_mode text;
  v_tier boolean := false;
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
  IF v_row.id_usuario::text <> auth.uid()::text THEN
    RAISE EXCEPTION 'solo el cliente puede recibir conforme';
  END IF;
  IF v_row.estado <> 'esperando_aprobacion_cliente' THEN
    RAISE EXCEPTION 'el trabajo no espera tu conformidad';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.disputas d
    WHERE d.id_trabajo::text = v_row.id::text
      AND d.estado IN ('abierta', 'en_revision')
  ) THEN
    RAISE EXCEPTION 'hay una disputa abierta; el pago sigue retenido';
  END IF;

  v_mode := COALESCE(v_row.modalidad_cobro::text, 'legado');
  BEGIN
    v_tier := COALESCE(v_row.metadatos_servicio::jsonb ->> 'request_type', '')
      = 'worker_tier_invitation';
  EXCEPTION WHEN others THEN
    v_tier := false;
  END;

  SELECT * INTO v_pago
  FROM public.pagos
  WHERE id_trabajo::text = v_row.id::text
    AND tipo_pago = 'principal'
    AND estado IN ('retenido', 'autorizado', 'liberado')
  ORDER BY creado_en DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND AND (v_mode <> 'legado' OR v_tier) THEN
    RAISE EXCEPTION 'no hay un pago en garantia para liberar';
  END IF;

  IF FOUND AND v_pago.estado IN ('retenido', 'autorizado') THEN
    PERFORM public.marcar_pago_liberado(
      v_pago.id,
      auth.uid()::text,
      'CONFORME-' || left(replace(v_row.id::text, '-', ''), 16),
      'Liberado al recibir conforme el trabajo'
    );
  END IF;

  UPDATE public.trabajos
  SET
    estado = 'completado',
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.cerrar_trabajo_conforme(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cerrar_trabajo_conforme(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.cerrar_trabajo_conforme(text) FROM anon;

-- Atención al cliente cierra la disputa y mueve el dinero en el mismo paso.
CREATE OR REPLACE FUNCTION public.aplicar_cierre_disputa(
  p_disputa_id text,
  p_operador text,
  p_decision text,
  p_resolucion text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_disputa public.disputas%ROWTYPE;
  v_job public.trabajos%ROWTYPE;
  v_pago public.pagos%ROWTYPE;
  v_resolucion text;
BEGIN
  IF p_decision NOT IN ('liberar', 'reembolsar') THEN
    RAISE EXCEPTION 'decision invalida';
  END IF;

  SELECT * INTO v_disputa
  FROM public.disputas
  WHERE id::text = p_disputa_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'disputa no encontrada';
  END IF;
  IF v_disputa.estado = 'resuelta' THEN
    RETURN jsonb_build_object('already', true, 'decision', p_decision);
  END IF;
  IF v_disputa.estado NOT IN ('abierta', 'en_revision') THEN
    RAISE EXCEPTION 'la disputa no esta abierta';
  END IF;

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = v_disputa.id_trabajo::text
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;

  SELECT * INTO v_pago
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
  ORDER BY creado_en DESC
  LIMIT 1
  FOR UPDATE;

  v_resolucion := NULLIF(trim(COALESCE(p_resolucion, '')), '');
  IF v_resolucion IS NULL THEN
    RAISE EXCEPTION 'resolucion requerida';
  END IF;

  IF p_decision = 'liberar' THEN
    IF v_job.estado = 'cancelado' THEN
      RAISE EXCEPTION 'el trabajo esta cancelado; no se liberan fondos';
    END IF;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'no hay pago para liberar';
    END IF;
    IF v_pago.estado IN ('retenido', 'autorizado') THEN
      PERFORM public.marcar_pago_liberado(
        v_pago.id,
        p_operador,
        'DISPUTA-' || left(replace(v_disputa.id::text, '-', ''), 16),
        v_resolucion
      );
    ELSIF v_pago.estado <> 'liberado' THEN
      RAISE EXCEPTION 'Pago no liberable (estado %)', v_pago.estado;
    END IF;

    IF v_job.estado <> 'completado' THEN
      UPDATE public.trabajos
      SET
        estado = 'completado',
        actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
      WHERE id = v_job.id;
    END IF;
  ELSE
    IF NOT FOUND THEN
      RAISE EXCEPTION 'no hay pago para reembolsar';
    END IF;
    IF v_pago.estado = 'liberado' THEN
      RAISE EXCEPTION 'el pago ya fue liberado al profesional';
    END IF;
    IF v_pago.estado <> 'reembolsado' THEN
      IF v_pago.estado NOT IN ('retenido', 'autorizado', 'pendiente') THEN
        RAISE EXCEPTION 'Pago no reembolsable (estado %)', v_pago.estado;
      END IF;
      UPDATE public.pagos SET
        estado = 'reembolsado',
        reembolsado_en = now(),
        actualizado_en = now()
      WHERE id = v_pago.id;
    END IF;

    UPDATE public.trabajos SET
      estado = 'cancelado',
      estado_pago = 'reembolsado',
      actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
    WHERE id = v_job.id;
  END IF;

  UPDATE public.disputas SET
    estado = 'resuelta',
    resolucion = v_resolucion,
    resuelta_por = p_operador,
    resuelta_en = now(),
    actualizado_en = now()
  WHERE id = v_disputa.id;

  RETURN jsonb_build_object(
    'dispute_id', v_disputa.id,
    'decision', p_decision,
    'estado', 'resuelta'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.aplicar_cierre_disputa(text, text, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.aplicar_cierre_disputa(text, text, text, text) FROM authenticated;
REVOKE ALL ON FUNCTION public.aplicar_cierre_disputa(text, text, text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.aplicar_cierre_disputa(text, text, text, text) TO service_role;

COMMIT;

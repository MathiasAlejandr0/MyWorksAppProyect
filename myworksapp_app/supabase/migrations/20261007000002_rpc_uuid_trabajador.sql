-- 20261004 dejó trabajos.id_trabajador y disputas.resuelta_por en uuid.
-- Estas RPC seguían asignando text. El casteo va en la función; la firma
-- sigue en text porque la app manda el id como texto.
-- Idempotente. Grants iguales a los de 20260930 / 20260928.

BEGIN;

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
    id_trabajador = p_trabajador_id::uuid,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.vincular_trabajador_solicitud(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.vincular_trabajador_solicitud(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.vincular_trabajador_solicitud(text, text) FROM anon;

CREATE OR REPLACE FUNCTION public.vincular_trabajador_cotizacion(
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
  IF NOT (public.is_admin() OR v_row.id_usuario::text = auth.uid()::text) THEN
    RAISE EXCEPTION 'solo el cliente del trabajo puede elegir la cotización';
  END IF;
  IF v_row.estado::text <> 'cotizacion_seleccionada' THEN
    RAISE EXCEPTION 'el trabajo no está en cotización seleccionada';
  END IF;

  UPDATE public.trabajos
  SET
    id_trabajador = p_trabajador_id::uuid,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.vincular_trabajador_cotizacion(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.vincular_trabajador_cotizacion(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.vincular_trabajador_cotizacion(text, text) FROM anon;

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
      id_trabajador = p_trabajador_id::uuid,
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
    id_trabajador = p_trabajador_id::uuid,
    estado = 'aceptado',
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.asignar_trabajador_trabajo(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.asignar_trabajador_trabajo(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.asignar_trabajador_trabajo(text, text) FROM anon;

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
    resuelta_por = p_operador::uuid,
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

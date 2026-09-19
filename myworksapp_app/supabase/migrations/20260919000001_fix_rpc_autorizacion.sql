-- Corrige autorización de las RPC de la migración 20260915000001.
-- No reescribe esa migración: si ya está aplicada en remoto, basta ejecutar este archivo.
--
-- 1) rechazar_trabajo_pendiente: id_trabajador NULL ya no pasa el control.
-- 2) asignar_trabajador_trabajo: el que acepta tiene que ser trabajador, no cualquier usuario.
-- 3) simular_transicion_pago: el profesional no libera ni reembolsa; el cliente sí.
-- 4) transicionar_trabajo: si el trabajo tiene pin, en_curso y completado lo exigen.

BEGIN;

CREATE OR REPLACE FUNCTION public.es_rol_trabajador(p_usuario_id text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT p_usuario_id IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.perfiles
      WHERE id::text = p_usuario_id
        AND lower(rol) IN ('trabajador', 'worker', 'especialista', 'specialist')
        AND estado_cuenta IN ('activo', 'active')
    );
$$;

REVOKE ALL ON FUNCTION public.es_rol_trabajador(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.es_rol_trabajador(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.es_rol_trabajador(text) FROM anon;

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

  IF NOT public.is_admin() THEN
    IF NOT public.transicion_trabajo_permitida(
      v_row.estado,
      p_nuevo_estado,
      COALESCE(v_row.modalidad_cobro, 'legado')
    ) THEN
      RAISE EXCEPTION 'transicion no permitida: % -> %', v_row.estado, p_nuevo_estado;
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

COMMENT ON FUNCTION public.transicionar_trabajo(text, text, text) IS
  'Transición de estado validada. Si metadatos_servicio.pin existe, en_curso y completado exigen p_pin (admin no).';

GRANT EXECUTE ON FUNCTION public.transicionar_trabajo(text, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.transicionar_trabajo(text, text, text) FROM anon;
REVOKE ALL ON FUNCTION public.transicionar_trabajo(text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.transicionar_trabajo(text, text, text) TO authenticated;

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
  WHERE id::text = v_row.id_trabajo::text;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo del pago no encontrado';
  END IF;

  v_es_cliente := v_job.id_usuario::text = auth.uid()::text;
  v_es_trabajador := v_job.id_trabajador IS NOT NULL
    AND v_job.id_trabajador::text = auth.uid()::text;

  IF NOT (public.is_admin() OR v_es_cliente OR v_es_trabajador) THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;

  IF public.is_admin() THEN
    IF v_row.estado = 'pendiente' AND p_nuevo_estado IN ('autorizado', 'reembolsado') THEN
      v_ok := true;
    ELSIF v_row.estado = 'autorizado' AND p_nuevo_estado IN ('retenido', 'liberado', 'reembolsado') THEN
      v_ok := true;
    ELSIF v_row.estado = 'retenido' AND p_nuevo_estado IN ('liberado', 'reembolsado') THEN
      v_ok := true;
    END IF;
  ELSIF v_es_cliente THEN
    IF v_row.estado = 'pendiente' AND p_nuevo_estado IN ('autorizado', 'reembolsado') THEN
      v_ok := true;
    ELSIF v_row.estado = 'autorizado' AND p_nuevo_estado IN ('retenido', 'liberado', 'reembolsado') THEN
      v_ok := true;
    ELSIF v_row.estado = 'retenido' AND p_nuevo_estado IN ('liberado', 'reembolsado') THEN
      v_ok := true;
    END IF;
  ELSIF v_es_trabajador THEN
    -- Solo congelar el escrow al abrir disputa. No libera ni reembolsa.
    IF v_row.estado = 'autorizado' AND p_nuevo_estado = 'retenido' THEN
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
  'MOCK escrow. Cliente autoriza, retiene, libera y reembolsa. Trabajador solo retiene. Admin misma matriz, sin saltarla.';

GRANT EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) FROM anon;
REVOKE ALL ON FUNCTION public.simular_transicion_pago(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.simular_transicion_pago(text, text) TO authenticated;

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

COMMENT ON FUNCTION public.asignar_trabajador_trabajo(text, text) IS
  'Acepta un trabajo abierto. El destino tiene que tener rol trabajador. Un cliente no puede autoasignarse.';

GRANT EXECUTE ON FUNCTION public.asignar_trabajador_trabajo(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.asignar_trabajador_trabajo(text, text) FROM anon;
REVOKE ALL ON FUNCTION public.asignar_trabajador_trabajo(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.asignar_trabajador_trabajo(text, text) TO authenticated;

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

COMMENT ON FUNCTION public.rechazar_trabajo_pendiente(text, text) IS
  'Cancela un pendiente. Solo admin o el trabajador ya asignado. Sin id_trabajador el control no se salta.';

GRANT EXECUTE ON FUNCTION public.rechazar_trabajo_pendiente(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.rechazar_trabajo_pendiente(text, text) FROM anon;
REVOKE ALL ON FUNCTION public.rechazar_trabajo_pendiente(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rechazar_trabajo_pendiente(text, text) TO authenticated;

COMMIT;

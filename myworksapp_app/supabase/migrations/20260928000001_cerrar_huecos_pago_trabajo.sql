-- Cierra huecos de la auditoría: el estado del trabajo no puede saltarse el pago,
-- un trabajo nuevo no nace cerrado, un segundo clic no abre otro cobro,
-- y el catálogo abierto no entrega la dirección.

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) Transición: modalidades con escrow exigen pago retenido o autorizado
-- -----------------------------------------------------------------------------
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
       AND p_nuevo_estado IN ('aceptado', 'en_curso', 'completado')
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

-- -----------------------------------------------------------------------------
-- 2) INSERT: solo estados iniciales y sin profesional asignado
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS trabajos_insert ON public.trabajos;
CREATE POLICY trabajos_insert ON public.trabajos
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR (
      id_usuario::text = auth.uid()::text
      AND id_trabajador IS NULL
      AND estado IN ('pendiente', 'esperando_cotizaciones', 'esperando_pago')
    )
  );

-- La dirección de un trabajo abierto no se lee por SELECT directo.
-- El listado usa listar_trabajos_marketplace / obtener_trabajo_sin_direccion.
DROP POLICY IF EXISTS trabajos_select ON public.trabajos;
CREATE POLICY trabajos_select ON public.trabajos
  FOR SELECT TO authenticated
  USING (
    id_usuario::text = auth.uid()::text
    OR id_trabajador::text = auth.uid()::text
    OR public.is_admin()
  );

-- -----------------------------------------------------------------------------
-- 3) Una intención principal activa por trabajo
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crear_intencion_pago(
  p_id_trabajo text,
  p_monto numeric,
  p_buy_order text DEFAULT NULL
)
RETURNS public.pagos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid text := auth.uid()::text;
  v_job public.trabajos;
  v_expected numeric;
  v_row public.pagos;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id::text = p_id_trabajo;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trabajo no encontrado';
  END IF;

  IF v_job.id_usuario::text <> v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo el cliente del trabajo puede crear la intención de pago';
  END IF;

  SELECT COALESCE(
    (SELECT c.monto_total_clp FROM public.propuestas_cotizacion c
      WHERE c.id_trabajo = v_job.id AND c.estado IN ('seleccionada', 'aceptada')
      ORDER BY c.creado_en DESC LIMIT 1),
    (SELECT w.tarifa_visita FROM public.trabajadores w
      WHERE w.id_usuario = v_job.id_trabajador)
  ) INTO v_expected;

  IF v_expected IS NULL OR v_expected <= 0 THEN
    RAISE EXCEPTION 'No hay tarifa/cotización para validar el monto';
  END IF;

  IF p_monto IS NULL OR abs(p_monto - v_expected) > 1 THEN
    RAISE EXCEPTION 'Monto % no coincide con tarifa/cotización %', p_monto, v_expected;
  END IF;

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
    AND estado IN ('retenido', 'autorizado')
  LIMIT 1;
  IF FOUND THEN
    RAISE EXCEPTION 'este trabajo ya tiene un pago en garantia';
  END IF;

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
    AND estado = 'pendiente'
  ORDER BY creado_en DESC
  LIMIT 1;
  IF FOUND THEN
    IF v_row.token_tbk IS NOT NULL AND length(trim(v_row.token_tbk)) > 0 THEN
      RAISE EXCEPTION 'ya hay un cobro en curso para este trabajo';
    END IF;
    RETURN v_row;
  END IF;

  INSERT INTO public.pagos (
    id, id_trabajo, monto, moneda, estado, tipo_pago, metodo_pago,
    creado_en, actualizado_en, buy_order, ambiente
  ) VALUES (
    gen_random_uuid()::text,
    v_job.id,
    v_expected,
    'CLP',
    'pendiente',
    'principal',
    'webpay',
    now(),
    now(),
    p_buy_order,
    'integration'
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.crear_intencion_pago(text, numeric, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crear_intencion_pago(text, numeric, text) TO authenticated;

-- -----------------------------------------------------------------------------
-- 4) El cliente puede vincular al profesional de la cotización elegida
-- -----------------------------------------------------------------------------
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
    id_trabajador = p_trabajador_id,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.vincular_trabajador_cotizacion(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.vincular_trabajador_cotizacion(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.vincular_trabajador_cotizacion(text, text) FROM anon;

-- -----------------------------------------------------------------------------
-- 5) estado_pago se copia desde la fila de pagos, no desde el cliente
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sincronizar_estado_pago_trabajo(p_trabajo_id text)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
  v_estado text;
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
    OR (v_row.id_trabajador IS NOT NULL AND v_row.id_trabajador::text = auth.uid()::text)
  ) THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;

  SELECT p.estado INTO v_estado
  FROM public.pagos p
  WHERE p.id_trabajo::text = v_row.id::text
    AND p.tipo_pago = 'principal'
  ORDER BY p.creado_en DESC
  LIMIT 1;

  IF v_estado IS NULL THEN
    RETURN v_row;
  END IF;

  UPDATE public.trabajos
  SET
    estado_pago = v_estado,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.sincronizar_estado_pago_trabajo(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sincronizar_estado_pago_trabajo(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.sincronizar_estado_pago_trabajo(text) FROM anon;

-- -----------------------------------------------------------------------------
-- 6) Listado abierto sin dirección
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.listar_trabajos_marketplace(integer);

CREATE OR REPLACE FUNCTION public.listar_trabajos_marketplace(
  p_limite integer DEFAULT 50
)
RETURNS TABLE (
  id text,
  estado text,
  descripcion text,
  creado_en text,
  actualizado_en text,
  id_servicio text,
  modalidad_cobro text,
  metadatos_servicio text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT t.id::text,
         t.estado::text,
         t.descripcion::text,
         t.creado_en::text,
         t.actualizado_en::text,
         t.id_servicio::text,
         COALESCE(t.modalidad_cobro::text, 'legado'),
         t.metadatos_servicio::text
  FROM public.trabajos t
  WHERE t.id_trabajador IS NULL
    AND t.estado IN ('pendiente', 'esperando_cotizaciones', 'esperando_pago')
  ORDER BY t.creado_en DESC
  LIMIT GREATEST(1, LEAST(COALESCE(p_limite, 50), 100));
$$;

REVOKE ALL ON FUNCTION public.listar_trabajos_marketplace(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_trabajos_marketplace(integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.obtener_trabajo_sin_direccion(p_id text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row FROM public.trabajos WHERE id::text = p_id;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  IF v_row.id_trabajador IS NOT NULL
     OR v_row.estado NOT IN ('pendiente', 'esperando_cotizaciones', 'esperando_pago') THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'id', v_row.id,
    'estado', v_row.estado,
    'descripcion', v_row.descripcion,
    'creado_en', v_row.creado_en,
    'actualizado_en', v_row.actualizado_en,
    'id_servicio', v_row.id_servicio,
    'modalidad_cobro', COALESCE(v_row.modalidad_cobro, 'legado'),
    'metadatos_servicio', v_row.metadatos_servicio
  );
END;
$$;

REVOKE ALL ON FUNCTION public.obtener_trabajo_sin_direccion(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.obtener_trabajo_sin_direccion(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.obtener_trabajo_sin_direccion(text) FROM anon;

COMMIT;

-- Auditoría 2026-10-05 (P1).
-- transicionar_trabajo ya validaba la matriz de estados y el pago retenido, pero no QUIÉN
-- pedía el cambio: el cliente podía marcar «aceptado», «en camino» o «en curso» en lugar
-- del profesional, y cualquiera de los dos podía cerrar en «no_asistio» con el dinero retenido.
-- Esa regla solo vivía en Dart (JobStateMachine._validatePermission). Ahora la exige Postgres.
--
-- Profesional del trabajo: aceptado, en_camino, en_curso, esperando_aprobacion_cliente,
--   pausado_orden_cambio, no_asistio.
-- Cliente del trabajo: cotizacion_seleccionada, esperando_pago y reanudar en_curso desde
--   pausado_orden_cambio (rechazo de la orden de cambio).
-- Ambos: pendiente, expirado, cancelado (con los controles de pago que ya existían).
-- Admin: sin cambios.

CREATE OR REPLACE FUNCTION public.transicionar_trabajo(
  p_trabajo_id text,
  p_nuevo_estado text,
  p_pin text DEFAULT NULL::text
)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_row public.trabajos;
  v_expected_pin text;
  v_mode text;
  v_disputa boolean;
  v_admin boolean;
  v_es_cliente boolean;
  v_es_pro boolean;
  v_retenido boolean;
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

  v_admin := public.is_admin();
  v_es_cliente := v_row.id_usuario::text = auth.uid()::text;
  v_es_pro := v_row.id_trabajador IS NOT NULL
    AND v_row.id_trabajador::text = auth.uid()::text;

  IF NOT (v_admin OR v_es_cliente OR v_es_pro) THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;

  v_disputa := EXISTS (
    SELECT 1
    FROM public.disputas d
    WHERE d.id_trabajo::text = v_row.id::text
      AND d.estado IN ('abierta', 'en_revision')
  );

  IF v_disputa AND NOT v_admin THEN
    RAISE EXCEPTION 'hay una disputa abierta; solo atencion al cliente puede continuar';
  END IF;

  IF v_disputa AND p_nuevo_estado = 'cancelado' THEN
    RAISE EXCEPTION 'hay una disputa abierta; resuelvela para liberar o devolver el pago';
  END IF;

  IF NOT v_admin AND p_nuevo_estado = 'completado' THEN
    RAISE EXCEPTION 'recibe conforme el trabajo para liberar el pago';
  END IF;

  IF p_nuevo_estado = 'cancelado'
     AND v_row.estado = 'esperando_aprobacion_cliente' THEN
    RAISE EXCEPTION 'si no estas conforme, abre una disputa; el pago sigue retenido';
  END IF;

  v_retenido := EXISTS (
    SELECT 1
    FROM public.pagos p
    WHERE p.id_trabajo::text = v_row.id::text
      AND p.tipo_pago = 'principal'
      AND p.estado IN ('retenido', 'autorizado')
  );

  IF p_nuevo_estado = 'cancelado' AND v_retenido THEN
    RAISE EXCEPTION 'devuelve el pago a la tarjeta antes de cancelar';
  END IF;

  v_mode := COALESCE(v_row.modalidad_cobro::text, 'legado');

  IF NOT v_admin THEN
    IF NOT public.transicion_trabajo_permitida(
      v_row.estado::text,
      p_nuevo_estado::text,
      v_mode
    ) THEN
      RAISE EXCEPTION 'transicion no permitida: % -> %', v_row.estado, p_nuevo_estado;
    END IF;

    -- Quién puede pedir cada paso.
    IF p_nuevo_estado IN (
         'aceptado', 'en_camino', 'esperando_aprobacion_cliente',
         'pausado_orden_cambio', 'no_asistio'
       ) AND NOT v_es_pro THEN
      RAISE EXCEPTION 'solo el profesional del trabajo puede pasar a %', p_nuevo_estado;
    END IF;

    IF p_nuevo_estado = 'en_curso'
       AND NOT v_es_pro
       AND NOT (v_es_cliente AND v_row.estado = 'pausado_orden_cambio') THEN
      RAISE EXCEPTION 'solo el profesional del trabajo puede pasar a en_curso';
    END IF;

    IF p_nuevo_estado IN ('cotizacion_seleccionada', 'esperando_pago')
       AND NOT v_es_cliente THEN
      RAISE EXCEPTION 'solo el cliente del trabajo puede pasar a %', p_nuevo_estado;
    END IF;

    IF p_nuevo_estado = 'no_asistio' AND v_retenido THEN
      RAISE EXCEPTION 'hay un pago retenido; abre una disputa para cerrar por inasistencia';
    END IF;

    IF v_mode <> 'legado'
       AND (
         p_nuevo_estado IN ('aceptado', 'en_curso', 'completado')
         OR (
           v_row.estado = 'esperando_pago'
           AND p_nuevo_estado = 'pendiente'
         )
       )
       AND NOT v_retenido THEN
      RAISE EXCEPTION 'se requiere un pago en garantia antes de %', p_nuevo_estado;
    END IF;
  END IF;

  BEGIN
    v_expected_pin := NULLIF(trim(v_row.metadatos_servicio::jsonb ->> 'pin'), '');
  EXCEPTION WHEN others THEN
    v_expected_pin := NULL;
  END;

  IF NOT v_admin
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
$function$;

REVOKE ALL ON FUNCTION public.transicionar_trabajo(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.transicionar_trabajo(text, text, text) TO authenticated, service_role;

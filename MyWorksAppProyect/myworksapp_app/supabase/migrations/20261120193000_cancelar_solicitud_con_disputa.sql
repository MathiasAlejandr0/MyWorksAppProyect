-- Con una disputa abierta el trabajo no avanza.
-- La parte cliente sí puede cancelar la solicitud si la disputa fue un error.
-- Al cancelar, las disputas activas de ese trabajo quedan cerradas.
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
      AND public.disputa_esta_activa(d.estado)
  );

  IF v_disputa AND NOT v_admin AND NOT (p_nuevo_estado = 'cancelado' AND v_es_cliente) THEN
    RAISE EXCEPTION 'hay una disputa abierta; solo atencion al cliente puede continuar';
  END IF;

  IF NOT v_admin AND p_nuevo_estado = 'completado' THEN
    RAISE EXCEPTION 'recibe conforme el trabajo para liberar el pago';
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

  IF p_nuevo_estado = 'en_curso'
     AND v_row.estado IN ('aceptado', 'en_camino')
     AND NOT v_admin THEN
    IF NOT v_es_pro THEN
      RAISE EXCEPTION 'solo el profesional del trabajo puede pasar a en_curso';
    END IF;
    IF NOT EXISTS (
      SELECT 1
      FROM public.bloqueos_pin_inicio b
      WHERE b.id_trabajo = v_row.id::text
        AND b.pin_ok_hasta IS NOT NULL
        AND b.pin_ok_hasta > now()
        AND b.pin_ok_usuario = auth.uid()
    ) THEN
      RAISE EXCEPTION 'Ingresa el PIN de 4 dígitos que te muestra el cliente.';
    END IF;
    UPDATE public.bloqueos_pin_inicio
    SET pin_ok_hasta = NULL, pin_ok_usuario = NULL, actualizado_en = now()
    WHERE id_trabajo = v_row.id::text;
  END IF;

  IF p_nuevo_estado = 'en_curso' THEN
    PERFORM set_config('mwa.pin_inicio_ok', '1', true);
  END IF;

  UPDATE public.trabajos
  SET
    estado = p_nuevo_estado,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  IF p_nuevo_estado = 'cancelado' AND v_disputa THEN
    UPDATE public.disputas
    SET estado = 'resuelta',
        resolucion = 'La solicitud se canceló',
        actualizado_en = now()
    WHERE id_trabajo::text = p_trabajo_id
      AND public.disputa_esta_activa(estado);
  END IF;

  RETURN v_row;
END;
$function$;

COMMENT ON FUNCTION public.transicionar_trabajo(text, text, text) IS
  'Transición de estado. Una disputa abierta impide continuar el trabajo. El cliente puede cancelar la solicitud igual, y eso cierra la disputa. Iniciar exige el PIN del cliente.';

REVOKE ALL ON FUNCTION public.transicionar_trabajo(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.transicionar_trabajo(text, text, text) TO authenticated, service_role;


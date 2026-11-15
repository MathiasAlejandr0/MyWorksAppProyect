-- Iniciar un trabajo (aceptado o en_camino -> en_curso) exige el PIN del cliente.
-- El PIN vive en pines_inicio_trabajo: lo lee el cliente (y un admin), no el
-- profesional. El cambio de estado a en_curso solo pasa por transicionar_trabajo
-- (SECURITY DEFINER), que valida el PIN, cuenta intentos y deja el flag de
-- sesión. Un UPDATE directo de authenticated o service_role no puede arrancar.
--
-- No hay regla de producto que impida iniciar antes de fecha_programada:
-- esta migración no agrega esa ventana.
--
-- Reanudaciones que ya no son un inicio (orden de cambio pagada, acuerdo de
-- rehacer) siguen en sus RPC. webpay-commit, webpay-reconcile y
-- confirmar_trabajo_tras_captura no escriben en_curso.
-- No aplicar esta migración a la base en vivo desde aquí.

BEGIN;

CREATE TABLE IF NOT EXISTS public.pines_inicio_trabajo (
  id_trabajo text PRIMARY KEY REFERENCES public.trabajos (id) ON DELETE CASCADE,
  pin text NOT NULL CHECK (pin ~ '^[0-9]{4}$'),
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.bloqueos_pin_inicio (
  id_trabajo text PRIMARY KEY REFERENCES public.trabajos (id) ON DELETE CASCADE,
  fallos integer NOT NULL DEFAULT 0 CHECK (fallos >= 0),
  bloqueado_hasta timestamptz,
  -- Ventana corta tras un PIN correcto. transicionar_trabajo la exige para
  -- iniciar: así un PIN malo queda grabado (la función no lanza) y no se
  -- pierde cuando el RPC de estado aborta.
  pin_ok_hasta timestamptz,
  pin_ok_usuario uuid,
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.intentos_pin_inicio (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_trabajo text NOT NULL,
  id_usuario uuid,
  resultado text NOT NULL CHECK (resultado IN ('correcto', 'incorrecto', 'bloqueado')),
  intentos_restantes integer NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS intentos_pin_inicio_trabajo_idx
  ON public.intentos_pin_inicio (id_trabajo, creado_en DESC);

ALTER TABLE public.pines_inicio_trabajo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bloqueos_pin_inicio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intentos_pin_inicio ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.pines_inicio_trabajo FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.bloqueos_pin_inicio FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.intentos_pin_inicio FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.pines_inicio_trabajo TO authenticated;

DROP POLICY IF EXISTS pines_inicio_select_cliente ON public.pines_inicio_trabajo;
CREATE POLICY pines_inicio_select_cliente
  ON public.pines_inicio_trabajo
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.trabajos t
      WHERE t.id::text = pines_inicio_trabajo.id_trabajo
        AND t.id_usuario::text = (SELECT auth.uid())::text
    )
  );

-- authenticated ya no tiene UPDATE en trabajos. Se reafirma y, además, el
-- trigger impide poner en_curso aunque alguien vuelva a conceder el privilegio.
REVOKE UPDATE, DELETE ON TABLE public.trabajos FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.asegurar_pin_inicio(p_trabajo_id text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_pin text;
  v_meta text;
BEGIN
  SELECT pin INTO v_pin
  FROM public.pines_inicio_trabajo
  WHERE id_trabajo = p_trabajo_id;
  IF v_pin IS NOT NULL THEN
    RETURN v_pin;
  END IF;

  SELECT metadatos_servicio INTO v_meta
  FROM public.trabajos
  WHERE id::text = p_trabajo_id;

  BEGIN
    IF v_meta IS NOT NULL AND btrim(v_meta) <> '' THEN
      v_pin := NULLIF(btrim(v_meta::jsonb ->> 'pin'), '');
    END IF;
  EXCEPTION WHEN others THEN
    v_pin := NULL;
  END;

  IF v_pin IS NULL OR v_pin !~ '^[0-9]{4}$' THEN
    v_pin := lpad((floor(random() * 10000))::int::text, 4, '0');
  END IF;

  INSERT INTO public.pines_inicio_trabajo (id_trabajo, pin)
  VALUES (p_trabajo_id, v_pin)
  ON CONFLICT (id_trabajo) DO UPDATE
    SET pin = public.pines_inicio_trabajo.pin
  RETURNING pin INTO v_pin;

  IF v_meta IS NOT NULL AND position('"pin"' IN v_meta) > 0 THEN
    UPDATE public.trabajos
    SET metadatos_servicio = public.metadatos_sin_pin(metadatos_servicio)
    WHERE id::text = p_trabajo_id
      AND metadatos_servicio IS DISTINCT FROM public.metadatos_sin_pin(metadatos_servicio);
  END IF;

  RETURN v_pin;
END;
$$;

REVOKE ALL ON FUNCTION public.asegurar_pin_inicio(text) FROM PUBLIC, anon, authenticated;

-- No lanza si el PIN está mal: PostgREST revierte la transacción de un
-- RAISE y el contador no quedaría. Devuelve {ok, mensaje}.
CREATE OR REPLACE FUNCTION public.intentar_pin_inicio(
  p_trabajo_id text,
  p_pin text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
  v_expected text;
  v_given text;
  v_fallos integer;
  v_hasta timestamptz;
  v_restantes integer;
  v_uid uuid := auth.uid();
  v_mensaje text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row
  FROM public.trabajos
  WHERE id::text = p_trabajo_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;

  IF NOT public.is_admin()
     AND (v_row.id_trabajador IS NULL OR v_row.id_trabajador::text IS DISTINCT FROM v_uid::text) THEN
    RAISE EXCEPTION 'solo el profesional del trabajo puede pasar a en_curso';
  END IF;

  IF v_row.estado NOT IN ('aceptado', 'en_camino') THEN
    RETURN jsonb_build_object(
      'ok', false,
      'mensaje', 'El trabajo no está listo para iniciarse.'
    );
  END IF;

  v_expected := public.asegurar_pin_inicio(p_trabajo_id);
  v_given := NULLIF(btrim(COALESCE(p_pin, '')), '');

  INSERT INTO public.bloqueos_pin_inicio (id_trabajo, fallos)
  VALUES (p_trabajo_id, 0)
  ON CONFLICT (id_trabajo) DO NOTHING;

  SELECT fallos, bloqueado_hasta
  INTO v_fallos, v_hasta
  FROM public.bloqueos_pin_inicio
  WHERE id_trabajo = p_trabajo_id
  FOR UPDATE;

  IF v_hasta IS NOT NULL AND v_hasta > now() THEN
    INSERT INTO public.intentos_pin_inicio (
      id_trabajo, id_usuario, resultado, intentos_restantes
    ) VALUES (p_trabajo_id, v_uid, 'bloqueado', 0);
    RETURN jsonb_build_object(
      'ok', false,
      'mensaje', 'Demasiados intentos fallidos. Espera 15 minutos para volver a ingresar el PIN.'
    );
  END IF;

  IF v_hasta IS NOT NULL AND v_hasta <= now() THEN
    v_fallos := 0;
  END IF;

  IF v_given IS NOT NULL AND v_given = v_expected THEN
    UPDATE public.bloqueos_pin_inicio
    SET fallos = 0,
        bloqueado_hasta = NULL,
        pin_ok_hasta = now() + interval '2 minutes',
        pin_ok_usuario = v_uid,
        actualizado_en = now()
    WHERE id_trabajo = p_trabajo_id;
    INSERT INTO public.intentos_pin_inicio (
      id_trabajo, id_usuario, resultado, intentos_restantes
    ) VALUES (p_trabajo_id, v_uid, 'correcto', 5);
    RETURN jsonb_build_object('ok', true);
  END IF;

  v_fallos := COALESCE(v_fallos, 0) + 1;
  IF v_fallos >= 5 THEN
    UPDATE public.bloqueos_pin_inicio
    SET fallos = 5,
        bloqueado_hasta = now() + interval '15 minutes',
        pin_ok_hasta = NULL,
        pin_ok_usuario = NULL,
        actualizado_en = now()
    WHERE id_trabajo = p_trabajo_id;
    INSERT INTO public.intentos_pin_inicio (
      id_trabajo, id_usuario, resultado, intentos_restantes
    ) VALUES (p_trabajo_id, v_uid, 'bloqueado', 0);
    RETURN jsonb_build_object(
      'ok', false,
      'mensaje', 'Demasiados intentos fallidos. Espera 15 minutos para volver a ingresar el PIN.'
    );
  END IF;

  v_restantes := 5 - v_fallos;
  UPDATE public.bloqueos_pin_inicio
  SET fallos = v_fallos,
      bloqueado_hasta = NULL,
      pin_ok_hasta = NULL,
      pin_ok_usuario = NULL,
      actualizado_en = now()
  WHERE id_trabajo = p_trabajo_id;
  INSERT INTO public.intentos_pin_inicio (
    id_trabajo, id_usuario, resultado, intentos_restantes
  ) VALUES (p_trabajo_id, v_uid, 'incorrecto', v_restantes);

  IF v_given IS NULL THEN
    IF v_restantes = 1 THEN
      v_mensaje := 'Ingresa el PIN de 4 dígitos que te muestra el cliente. Te queda 1 intento.';
    ELSE
      v_mensaje := format(
        'Ingresa el PIN de 4 dígitos que te muestra el cliente. Te quedan %s intentos.',
        v_restantes
      );
    END IF;
  ELSIF v_restantes = 1 THEN
    v_mensaje := 'PIN incorrecto. Te queda 1 intento.';
  ELSE
    v_mensaje := format('PIN incorrecto. Te quedan %s intentos.', v_restantes);
  END IF;

  RETURN jsonb_build_object('ok', false, 'mensaje', v_mensaje);
END;
$$;

REVOKE ALL ON FUNCTION public.intentar_pin_inicio(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.intentar_pin_inicio(text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.obtener_pin_inicio(p_trabajo_id text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
  v_pin text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row
  FROM public.trabajos
  WHERE id::text = p_trabajo_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;

  IF v_row.id_usuario::text IS DISTINCT FROM auth.uid()::text
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo el cliente puede ver el PIN de inicio.';
  END IF;

  IF v_row.estado NOT IN ('pendiente', 'aceptado', 'en_camino', 'esperando_pago') THEN
    RETURN NULL;
  END IF;

  v_pin := public.asegurar_pin_inicio(p_trabajo_id);
  RETURN v_pin;
END;
$$;

REVOKE ALL ON FUNCTION public.obtener_pin_inicio(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.obtener_pin_inicio(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.trabajos_crear_pin_inicio()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  PERFORM public.asegurar_pin_inicio(NEW.id::text);
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.trabajos_crear_pin_inicio() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trabajos_crear_pin_inicio ON public.trabajos;
CREATE TRIGGER trabajos_crear_pin_inicio
  AFTER INSERT ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_crear_pin_inicio();

-- INVOKER a propósito: current_user es quien ejecuta el UPDATE.
-- Dentro de un RPC SECURITY DEFINER ese usuario es el dueño de la función,
-- no el rol authenticated de la API.
CREATE OR REPLACE FUNCTION public.trabajos_bloquear_en_curso_directo()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.estado IS NOT DISTINCT FROM OLD.estado OR NEW.estado IS DISTINCT FROM 'en_curso' THEN
    RETURN NEW;
  END IF;

  IF current_setting('mwa.pin_inicio_ok', true) = '1' THEN
    RETURN NEW;
  END IF;

  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF OLD.estado IN ('aceptado', 'en_camino')
     OR current_user IN ('authenticated', 'anon', 'authenticator', 'service_role') THEN
    RAISE EXCEPTION 'Para iniciar el trabajo confirma el PIN de 4 dígitos del cliente.';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.trabajos_bloquear_en_curso_directo() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trabajos_bloquear_en_curso_directo ON public.trabajos;
CREATE TRIGGER trabajos_bloquear_en_curso_directo
  BEFORE UPDATE OF estado ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_bloquear_en_curso_directo();

-- Misma función que 20261112000001, con el PIN obligatorio para iniciar.
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

  RETURN v_row;
END;
$function$;

COMMENT ON FUNCTION public.transicionar_trabajo(text, text, text) IS
  'Transición de estado. Iniciar (aceptado o en_camino -> en_curso) exige el PIN del cliente al profesional asignado. El admin no lo exige. Tras 5 PIN malos, 15 minutos de bloqueo.';

REVOKE ALL ON FUNCTION public.transicionar_trabajo(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.transicionar_trabajo(text, text, text) TO authenticated, service_role;

-- Reanudar tras pagar la orden de cambio marca el flag para el trigger.
CREATE OR REPLACE FUNCTION public.marcar_orden_cambio_pagada(
  p_id_orden_cambio text,
  p_id_pago text
)
RETURNS public.ordenes_cambio
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid text := auth.uid()::text;
  v_role text := coalesce(auth.role(), '');
  v_order public.ordenes_cambio;
  v_job public.trabajos;
  v_pago public.pagos;
BEGIN
  SELECT * INTO v_order
  FROM public.ordenes_cambio
  WHERE id::text = p_id_orden_cambio
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Orden de cambio no encontrada';
  END IF;

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = v_order.id_trabajo::text
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trabajo no encontrado';
  END IF;

  IF v_role <> 'service_role'
     AND v_uid IS DISTINCT FROM v_job.id_usuario::text
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo el cliente puede confirmar el cobro adicional';
  END IF;

  SELECT * INTO v_pago
  FROM public.pagos
  WHERE id::text = p_id_pago;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pago no encontrado';
  END IF;

  IF v_pago.id_orden_cambio::text IS DISTINCT FROM v_order.id::text THEN
    RAISE EXCEPTION 'El pago no corresponde a esta orden de cambio';
  END IF;

  IF v_pago.estado NOT IN ('retenido', 'autorizado', 'liberado') THEN
    RAISE EXCEPTION 'El cobro adicional aún no está retenido';
  END IF;

  UPDATE public.ordenes_cambio
  SET
    estado = 'pagada',
    id_pago = v_pago.id,
    respondido_en = COALESCE(respondido_en, now())
  WHERE id = v_order.id
  RETURNING * INTO v_order;

  IF v_job.estado = 'pausado_orden_cambio' THEN
    PERFORM set_config('mwa.pin_inicio_ok', '1', true);
    UPDATE public.trabajos
    SET
      estado = 'en_curso',
      actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
    WHERE id = v_job.id;
  END IF;

  RETURN v_order;
END;
$$;

REVOKE ALL ON FUNCTION public.marcar_orden_cambio_pagada(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.marcar_orden_cambio_pagada(text, text)
  TO authenticated, service_role;

-- Acuerdo «rehacer»: no es un inicio con PIN. Marca el flag antes del UPDATE.
CREATE OR REPLACE FUNCTION public.resolver_soporte_automatico()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_horas integer := GREATEST(public.soporte_numero('soporte_plazo_silencio_horas', 48)::integer, 1);
  v_job record;
  v_acuerdo public.acuerdos_trabajo%ROWTYPE;
  v_disputa public.disputas%ROWTYPE;
  v_pago_id text;
  v_liberados integer := 0;
  v_acuerdos integer := 0;
  v_reembolsos jsonb := '[]'::jsonb;
BEGIN
  FOR v_job IN
    SELECT t.id::text AS id
    FROM public.trabajos t
    WHERE t.estado = 'esperando_aprobacion_cliente'
      AND public.trabajo_tiene_evidencia(t.id::text)
      AND NOT EXISTS (
        SELECT 1 FROM public.disputas d
        WHERE d.id_trabajo::text = t.id::text
          AND public.disputa_esta_activa(d.estado)
      )
      AND NULLIF(t.actualizado_en, '')::timestamptz
        < now() - make_interval(hours => v_horas)
  LOOP
    BEGIN
      PERFORM public.liberar_trabajo_sistema(
        v_job.id,
        'El cliente no respondió dentro del plazo. El pago queda liberado.'
      );
      v_liberados := v_liberados + 1;
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'silencio %: %', v_job.id, SQLERRM;
    END;
  END LOOP;

  FOR v_acuerdo IN
    SELECT *
    FROM public.acuerdos_trabajo
    WHERE estado = 'confirmado'
    FOR UPDATE
  LOOP
    BEGIN
      IF v_acuerdo.tipo = 'aceptar' THEN
        IF EXISTS (
          SELECT 1 FROM public.disputas d
          WHERE d.id_trabajo::text = v_acuerdo.id_trabajo::text
            AND public.disputa_esta_activa(d.estado)
        ) THEN
          PERFORM public.aplicar_cierre_disputa(
            (
              SELECT d.id::text FROM public.disputas d
              WHERE d.id_trabajo::text = v_acuerdo.id_trabajo::text
                AND public.disputa_esta_activa(d.estado)
              ORDER BY d.creado_en DESC
              LIMIT 1
            ),
            'acuerdo',
            'liberar',
            'Las dos partes aceptaron la entrega.'
          );
        ELSE
          PERFORM public.liberar_trabajo_sistema(
            v_acuerdo.id_trabajo::text,
            'Las dos partes aceptaron la entrega.'
          );
        END IF;
      ELSIF v_acuerdo.tipo = 'rehacer' THEN
        PERFORM set_config('mwa.pin_inicio_ok', '1', true);
        UPDATE public.trabajos
        SET
          estado = 'en_curso',
          actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
        WHERE id::text = v_acuerdo.id_trabajo::text
          AND estado <> 'cancelado';
        UPDATE public.disputas
        SET
          estado = 'resuelta',
          origen = 'acuerdo',
          resolucion = 'Acordaron rehacer el trabajo. El pago sigue retenido.',
          resuelta_en = now(),
          actualizado_en = now()
        WHERE id_trabajo::text = v_acuerdo.id_trabajo::text
          AND public.disputa_esta_activa(estado);
      ELSIF v_acuerdo.tipo = 'anular' THEN
        SELECT id INTO v_pago_id
        FROM public.pagos
        WHERE id_trabajo::text = v_acuerdo.id_trabajo::text
          AND tipo_pago = 'principal'
          AND estado IN ('retenido', 'autorizado', 'pendiente')
        ORDER BY creado_en DESC
        LIMIT 1;
        IF v_pago_id IS NULL THEN
          UPDATE public.trabajos
          SET estado = 'cancelado',
              actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
          WHERE id::text = v_acuerdo.id_trabajo::text;
        ELSE
          INSERT INTO public.disputas (
            id, id_trabajo, abierta_por, motivo, descripcion, estado,
            origen, decision_sugerida, motivo_regla, creado_en, actualizado_en
          )
          SELECT
            'acuerdo-' || v_acuerdo.id,
            v_acuerdo.id_trabajo,
            v_acuerdo.propuesto_por,
            'acuerdo',
            'Las dos partes anularon el trabajo.',
            'reembolso_pendiente',
            'acuerdo',
            'reembolsar',
            'acuerdo_anular',
            now(),
            now()
          WHERE NOT EXISTS (
            SELECT 1 FROM public.disputas d
            WHERE d.id_trabajo::text = v_acuerdo.id_trabajo::text
              AND public.disputa_esta_activa(d.estado)
          );
          UPDATE public.disputas
          SET estado = 'reembolso_pendiente',
              decision_sugerida = 'reembolsar',
              motivo_regla = 'acuerdo_anular',
              origen = 'acuerdo',
              actualizado_en = now()
          WHERE id_trabajo::text = v_acuerdo.id_trabajo::text
            AND public.disputa_esta_activa(estado)
            AND estado <> 'reembolso_pendiente';
        END IF;
      END IF;

      UPDATE public.acuerdos_trabajo
      SET estado = 'aplicado', aplicado_en = now()
      WHERE id = v_acuerdo.id;
      v_acuerdos := v_acuerdos + 1;
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'acuerdo %: %', v_acuerdo.id, SQLERRM;
    END;
  END LOOP;

  FOR v_disputa IN
    SELECT *
    FROM public.disputas
    WHERE estado = 'abierta'
      AND decision_sugerida = 'liberar'
      AND vence_en IS NOT NULL
      AND vence_en <= now()
    FOR UPDATE
  LOOP
    BEGIN
      PERFORM public.aplicar_cierre_disputa(
        v_disputa.id::text,
        'sistema',
        'liberar',
        'Cierre automático: ' || COALESCE(v_disputa.motivo_regla, 'plazo')
      );
      v_liberados := v_liberados + 1;
    EXCEPTION WHEN others THEN
      UPDATE public.disputas
      SET estado = 'requiere_humano',
          decision_sugerida = 'humano',
          motivo_regla = 'fallo_cierre_automatico',
          actualizado_en = now()
      WHERE id = v_disputa.id;
    END;
  END LOOP;

  FOR v_disputa IN
    SELECT *
    FROM public.disputas
    WHERE estado = 'abierta'
      AND decision_sugerida = 'reembolsar'
      AND vence_en IS NOT NULL
      AND vence_en <= now()
    FOR UPDATE
  LOOP
    UPDATE public.disputas
    SET estado = 'reembolso_pendiente', actualizado_en = now()
    WHERE id = v_disputa.id;
  END LOOP;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'disputa_id', d.id,
    'pago_id', p.id,
    'resolucion', 'Devolución automática: ' || COALESCE(d.motivo_regla, 'plazo')
  )), '[]'::jsonb)
  INTO v_reembolsos
  FROM public.disputas d
  JOIN LATERAL (
    SELECT id
    FROM public.pagos
    WHERE id_trabajo::text = d.id_trabajo::text
      AND tipo_pago = 'principal'
      AND estado IN ('retenido', 'autorizado', 'pendiente', 'reembolsado')
    ORDER BY creado_en DESC
    LIMIT 1
  ) p ON true
  WHERE d.estado = 'reembolso_pendiente';

  RETURN jsonb_build_object(
    'liberados', v_liberados,
    'acuerdos', v_acuerdos,
    'reembolsos', COALESCE(v_reembolsos, '[]'::jsonb)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.resolver_soporte_automatico() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.resolver_soporte_automatico() TO service_role;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT id::text AS id FROM public.trabajos LOOP
    PERFORM public.asegurar_pin_inicio(r.id);
  END LOOP;
END $$;

COMMIT;

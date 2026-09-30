-- Precios los fija el servidor, el invitado no reusa el token de Transbank,
-- las calificaciones salen del cliente del trabajo terminado y el catálogo
-- anónimo deja de leer la ficha cruda del profesional.
-- Idempotente. Aplicar después de 20261008000004.
-- Pruebas: docs/PRUEBAS_RLS_20261009.sql (transacción que hace ROLLBACK).

BEGIN;

-- -----------------------------------------------------------------------------
-- 0) Interruptores. demo_modo=1 deja el selector de login de la demo.
--    admin_requiere_aal2=0 para que el panel de mañana funcione aunque el
--    JWT todavía no sea aal2. Antes del lanzamiento: poner ambos en el
--    valor de producción (demo_modo=0, admin_requiere_aal2=1) y revocar
--    anon en listar_cuentas_demo_acceso. ON CONFLICT no pisa un valor ya
--    cambiado a mano.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_config (
  clave text PRIMARY KEY,
  valor text NOT NULL,
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.app_config FROM PUBLIC, anon, authenticated;

INSERT INTO public.app_config (clave, valor)
VALUES ('demo_modo', '1'), ('admin_requiere_aal2', '0')
ON CONFLICT (clave) DO NOTHING;

UPDATE public.perfiles
SET rol = 'administrador'
WHERE rol = 'admin';

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.perfiles p
    WHERE p.id::text = auth.uid()::text
      AND p.rol = 'administrador'
      AND p.estado_cuenta IN ('activo', 'active')
      AND (
        COALESCE(
          (SELECT c.valor FROM public.app_config c WHERE c.clave = 'admin_requiere_aal2'),
          '0'
        ) IS DISTINCT FROM '1'
        OR COALESCE(auth.jwt()->>'aal', '') = 'aal2'
      )
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- -----------------------------------------------------------------------------
-- 1) Cotizaciones: el cliente solo lee. Elige por RPC.
--    El monto no cambia después de aceptar. El alta del trabajo no guarda
--    un precio escrito por el cliente ni un estado ya pagado.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.proteger_campos_trabajo()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP <> 'UPDATE' THEN
    RETURN NEW;
  END IF;

  IF NEW.estado IS NOT DISTINCT FROM OLD.estado
     AND NEW.id_trabajador IS NOT DISTINCT FROM OLD.id_trabajador
     AND NEW.id_usuario IS NOT DISTINCT FROM OLD.id_usuario
     AND NEW.estado_pago IS NOT DISTINCT FROM OLD.estado_pago
     AND NEW.modalidad_cobro IS NOT DISTINCT FROM OLD.modalidad_cobro
     AND NEW.instantanea_precio IS NOT DISTINCT FROM OLD.instantanea_precio
     AND NEW.id_cotizacion_seleccionada IS NOT DISTINCT FROM OLD.id_cotizacion_seleccionada
  THEN
    RETURN NEW;
  END IF;

  IF COALESCE(current_setting('mwa.rpc_trabajo', true), '') = '1'
     OR COALESCE(auth.role(), '') = 'service_role'
     OR public.is_admin()
     OR (auth.role() IS NULL AND auth.uid() IS NULL)
     OR current_user IN ('postgres', 'supabase_admin')
  THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'estado, profesional, cotización y pago solo cambian por los procedimientos del trabajo';
END;
$$;

REVOKE ALL ON FUNCTION public.proteger_campos_trabajo() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.limpiar_alta_trabajo()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF COALESCE(auth.role(), '') = 'service_role'
     OR public.is_admin()
     OR (auth.role() IS NULL AND auth.uid() IS NULL)
     OR current_user IN ('postgres', 'supabase_admin')
  THEN
    RETURN NEW;
  END IF;

  NEW.instantanea_precio := NULL;
  NEW.id_cotizacion_seleccionada := NULL;
  IF NEW.estado_pago IS NOT NULL AND NEW.estado_pago NOT IN ('pendiente', 'ninguno') THEN
    NEW.estado_pago := 'pendiente';
  END IF;
  IF NEW.estado NOT IN ('pendiente', 'esperando_pago', 'esperando_cotizaciones') THEN
    RAISE EXCEPTION 'un trabajo nuevo solo puede empezar pendiente, esperando pago o esperando cotizaciones';
  END IF;
  IF NEW.id_trabajador IS NOT NULL AND NEW.estado = 'pendiente' THEN
    RAISE EXCEPTION 'un trabajo con profesional no puede nacer ya pendiente de ejecución';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.limpiar_alta_trabajo() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trabajos_limpiar_alta ON public.trabajos;
CREATE TRIGGER trabajos_limpiar_alta
  BEFORE INSERT ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.limpiar_alta_trabajo();

DROP POLICY IF EXISTS trabajos_insert ON public.trabajos;
CREATE POLICY trabajos_insert ON public.trabajos
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR (
      id_usuario = (SELECT auth.uid())
      AND id_cotizacion_seleccionada IS NULL
      AND (estado_pago IS NULL OR estado_pago IN ('pendiente', 'ninguno'))
      AND (
        (
          id_trabajador IS NULL
          AND estado IN ('pendiente', 'esperando_cotizaciones')
        )
        OR (
          id_trabajador IS NOT NULL
          AND estado IN ('esperando_pago', 'esperando_cotizaciones')
          AND EXISTS (
            SELECT 1
            FROM public.trabajadores w
            JOIN public.perfiles p ON p.id = w.id_usuario
            WHERE w.id_usuario = trabajos.id_trabajador
              AND COALESCE(w.disponible, 0) = 1
              AND COALESCE(w.precios_configurados, 0) = 1
              AND w.estado_verificacion = 'verificado'
              AND p.rol = 'trabajador'
              AND p.estado_cuenta IN ('activo', 'active')
          )
        )
      )
    )
  );

CREATE OR REPLACE FUNCTION public.proteger_monto_cotizacion()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP <> 'UPDATE' THEN
    RETURN NEW;
  END IF;

  IF COALESCE(current_setting('mwa.rpc_trabajo', true), '') = '1'
     OR COALESCE(auth.role(), '') = 'service_role'
     OR public.is_admin()
     OR (auth.role() IS NULL AND auth.uid() IS NULL)
     OR current_user IN ('postgres', 'supabase_admin')
  THEN
    RETURN NEW;
  END IF;

  IF OLD.estado IN ('seleccionada', 'aceptada')
     AND NEW.monto_total_clp IS DISTINCT FROM OLD.monto_total_clp THEN
    RAISE EXCEPTION 'el monto de una cotización elegida no se modifica';
  END IF;

  IF NEW.estado IN ('seleccionada', 'aceptada')
     AND NEW.estado IS DISTINCT FROM OLD.estado THEN
    RAISE EXCEPTION 'la cotización se elige con seleccionar_cotizacion';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.proteger_monto_cotizacion() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS propuestas_proteger_monto ON public.propuestas_cotizacion;
CREATE TRIGGER propuestas_proteger_monto
  BEFORE UPDATE ON public.propuestas_cotizacion
  FOR EACH ROW
  EXECUTE FUNCTION public.proteger_monto_cotizacion();

DROP POLICY IF EXISTS propuestas_all ON public.propuestas_cotizacion;
DROP POLICY IF EXISTS propuestas_select ON public.propuestas_cotizacion;
DROP POLICY IF EXISTS propuestas_insert ON public.propuestas_cotizacion;
DROP POLICY IF EXISTS propuestas_update ON public.propuestas_cotizacion;

CREATE POLICY propuestas_select ON public.propuestas_cotizacion
  FOR SELECT TO authenticated
  USING (
    id_trabajador = (SELECT auth.uid())
    OR public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.trabajos j
      WHERE j.id::text = propuestas_cotizacion.id_trabajo::text
        AND j.id_usuario = (SELECT auth.uid())
    )
  );

CREATE POLICY propuestas_insert ON public.propuestas_cotizacion
  FOR INSERT TO authenticated
  WITH CHECK (
    id_trabajador = (SELECT auth.uid())
    AND public.es_rol_trabajador((SELECT auth.uid())::text)
    AND estado IN ('enviada', 'borrador')
    AND EXISTS (
      SELECT 1
      FROM public.trabajos j
      WHERE j.id::text = propuestas_cotizacion.id_trabajo::text
    )
  );

CREATE POLICY propuestas_update ON public.propuestas_cotizacion
  FOR UPDATE TO authenticated
  USING (
    id_trabajador = (SELECT auth.uid())
    AND public.es_rol_trabajador((SELECT auth.uid())::text)
  )
  WITH CHECK (
    id_trabajador = (SELECT auth.uid())
    AND public.es_rol_trabajador((SELECT auth.uid())::text)
    AND estado NOT IN ('aceptada', 'seleccionada')
  );

CREATE OR REPLACE FUNCTION public.seleccionar_cotizacion(p_id_cotizacion text)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_quote public.propuestas_cotizacion;
  v_job public.trabajos;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_quote
  FROM public.propuestas_cotizacion
  WHERE id::text = p_id_cotizacion;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Cotización no encontrada';
  END IF;

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = v_quote.id_trabajo::text;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trabajo no encontrado';
  END IF;

  IF v_job.id_usuario::text IS DISTINCT FROM v_uid::text THEN
    RAISE EXCEPTION 'Solo el cliente del trabajo puede elegir la cotización';
  END IF;

  IF v_job.estado NOT IN ('esperando_cotizaciones', 'cotizacion_seleccionada') THEN
    RAISE EXCEPTION 'Este trabajo no está esperando una cotización';
  END IF;

  IF v_quote.estado NOT IN ('enviada', 'aceptada', 'seleccionada') THEN
    RAISE EXCEPTION 'Esta cotización ya no está disponible';
  END IF;

  IF NOT public.es_rol_trabajador(v_quote.id_trabajador::text) THEN
    RAISE EXCEPTION 'El autor de la cotización no es un profesional activo';
  END IF;

  IF v_job.id_trabajador IS NOT NULL
     AND v_job.id_trabajador::text IS DISTINCT FROM v_quote.id_trabajador::text THEN
    RAISE EXCEPTION 'La cotización no es del profesional del trabajo';
  END IF;

  PERFORM set_config('mwa.rpc_trabajo', '1', true);

  UPDATE public.propuestas_cotizacion
  SET estado = 'rechazada'
  WHERE id_trabajo::text = v_job.id::text
    AND id::text IS DISTINCT FROM v_quote.id::text
    AND estado = 'enviada';

  UPDATE public.propuestas_cotizacion
  SET estado = 'aceptada'
  WHERE id::text = v_quote.id::text;

  UPDATE public.trabajos
  SET id_trabajador = v_quote.id_trabajador,
      id_cotizacion_seleccionada = v_quote.id,
      estado = 'esperando_pago',
      estado_pago = CASE
        WHEN estado_pago IS NULL OR estado_pago = 'ninguno' THEN 'pendiente'
        ELSE estado_pago
      END,
      actualizado_en = now()
  WHERE id::text = v_job.id::text
  RETURNING * INTO v_job;

  RETURN v_job;
END;
$$;

REVOKE ALL ON FUNCTION public.seleccionar_cotizacion(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.seleccionar_cotizacion(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.monto_esperado_trabajo(p_job public.trabajos)
RETURNS numeric
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_expected numeric;
BEGIN
  IF p_job.id_cotizacion_seleccionada IS NOT NULL
     OR COALESCE(p_job.modalidad_cobro, '') IN ('cotizacion_abierta', 'cotizacion') THEN
    IF p_job.id_cotizacion_seleccionada IS NULL OR p_job.id_trabajador IS NULL THEN
      RAISE EXCEPTION 'No hay cotización seleccionada para este trabajo';
    END IF;
    SELECT c.monto_total_clp INTO v_expected
    FROM public.propuestas_cotizacion c
    WHERE c.id::text = p_job.id_cotizacion_seleccionada::text
      AND c.id_trabajador::text = p_job.id_trabajador::text
      AND c.id_trabajo::text = p_job.id::text
      AND c.estado IN ('seleccionada', 'aceptada');
  ELSE
    SELECT w.tarifa_visita INTO v_expected
    FROM public.trabajadores w
    JOIN public.perfiles p ON p.id = w.id_usuario
    WHERE w.id_usuario::text = p_job.id_trabajador::text
      AND COALESCE(w.disponible, 0) = 1
      AND COALESCE(w.precios_configurados, 0) = 1
      AND w.estado_verificacion = 'verificado'
      AND p.rol = 'trabajador'
      AND p.estado_cuenta IN ('activo', 'active');
  END IF;

  IF v_expected IS NULL OR v_expected <= 0 THEN
    RAISE EXCEPTION 'No hay tarifa/cotización para validar el monto';
  END IF;
  RETURN v_expected;
END;
$$;

REVOKE ALL ON FUNCTION public.monto_esperado_trabajo(public.trabajos) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.monto_esperado_trabajo(public.trabajos) TO postgres, service_role;

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

  v_expected := public.monto_esperado_trabajo(v_job);

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

  IF v_job.estado IS DISTINCT FROM 'esperando_pago' THEN
    RAISE EXCEPTION 'El trabajo ya no está pendiente de pago';
  END IF;

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
    AND estado = 'pendiente'
  ORDER BY creado_en DESC
  LIMIT 1;
  IF FOUND THEN
    IF v_row.token_tbk IS NOT NULL AND length(trim(v_row.token_tbk)) > 0
       AND COALESCE(v_row.metodo_pago, 'webpay') IS DISTINCT FROM 'oneclick' THEN
      RAISE EXCEPTION 'ya hay un cobro en curso para este trabajo';
    END IF;
    UPDATE public.pagos
      SET monto = v_expected,
          actualizado_en = now()
      WHERE id = v_row.id
      RETURNING * INTO v_row;
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

REVOKE ALL ON FUNCTION public.crear_intencion_pago(text, numeric, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.crear_intencion_pago(text, numeric, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.crear_intencion_pago_servicio(
  p_id_usuario text,
  p_id_trabajo text,
  p_monto numeric
)
RETURNS public.pagos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_job public.trabajos;
  v_expected numeric;
  v_row public.pagos;
BEGIN
  IF p_id_usuario IS NULL OR length(trim(p_id_usuario)) = 0 THEN
    RAISE EXCEPTION 'usuario requerido';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id::text = p_id_trabajo;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trabajo no encontrado';
  END IF;

  IF v_job.id_usuario::text <> p_id_usuario THEN
    RAISE EXCEPTION 'Solo el cliente del trabajo puede crear la intención de pago';
  END IF;

  v_expected := public.monto_esperado_trabajo(v_job);

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
    RETURN v_row;
  END IF;

  IF v_job.estado IS DISTINCT FROM 'esperando_pago' THEN
    RAISE EXCEPTION 'El trabajo ya no está pendiente de pago';
  END IF;

  SELECT * INTO v_row
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
    AND estado = 'pendiente'
  ORDER BY creado_en DESC
  LIMIT 1;
  IF FOUND THEN
    IF v_row.token_tbk IS NOT NULL AND length(trim(v_row.token_tbk)) > 0
       AND COALESCE(v_row.metodo_pago, 'webpay') IS DISTINCT FROM 'oneclick' THEN
      RAISE EXCEPTION 'ya hay un cobro en curso para este trabajo';
    END IF;
    UPDATE public.pagos
      SET monto = v_expected,
          actualizado_en = now()
      WHERE id = v_row.id
      RETURNING * INTO v_row;
    RETURN v_row;
  END IF;

  INSERT INTO public.pagos (
    id, id_trabajo, monto, moneda, estado, tipo_pago, metodo_pago,
    creado_en, actualizado_en, ambiente
  ) VALUES (
    gen_random_uuid()::text,
    v_job.id,
    v_expected,
    'CLP',
    'pendiente',
    'principal',
    'oneclick',
    now(),
    now(),
    'integration'
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.crear_intencion_pago_servicio(text, text, numeric) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.crear_intencion_pago_servicio(text, text, numeric) FROM anon;
REVOKE ALL ON FUNCTION public.crear_intencion_pago_servicio(text, text, numeric) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.crear_intencion_pago_servicio(text, text, numeric) TO service_role;

-- -----------------------------------------------------------------------------
-- 2) Pagos: el cliente no lee token, URL ni código de autorización.
--    El alta de invitado guarda el hash del nonce y un jti de un solo uso.
-- -----------------------------------------------------------------------------
ALTER TABLE public.pagos
  ADD COLUMN IF NOT EXISTS alta_nonce_hash text,
  ADD COLUMN IF NOT EXISTS alta_jti text,
  ADD COLUMN IF NOT EXISTS alta_consumido_en timestamptz;

COMMENT ON COLUMN public.pagos.alta_nonce_hash IS
  'SHA-256 del nonce que solo tiene el navegador del invitado.';
COMMENT ON COLUMN public.pagos.alta_jti IS
  'Identificador de un solo uso del enlace para crear la contraseña.';
COMMENT ON COLUMN public.pagos.alta_consumido_en IS
  'Cuándo se usó el enlace. Un segundo intento no sirve.';

CREATE UNIQUE INDEX IF NOT EXISTS pagos_alta_jti_uidx
  ON public.pagos (alta_jti)
  WHERE alta_jti IS NOT NULL;

REVOKE SELECT ON TABLE public.pagos FROM anon, authenticated;

DO $$
DECLARE
  col text;
  safe text := '';
BEGIN
  FOR col IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'pagos'
      AND column_name NOT IN (
        'token_tbk',
        'url_tbk',
        'id_transaccion',
        'orden_detalle_oneclick',
        'cobro_reclamado_en',
        'handoff_consumido_en',
        'origen_retorno',
        'alta_nonce_hash',
        'alta_jti',
        'alta_consumido_en'
      )
    ORDER BY ordinal_position
  LOOP
    safe := safe || quote_ident(col) || ', ';
  END LOOP;
  safe := rtrim(safe, ', ');
  IF safe = '' THEN
    RAISE EXCEPTION 'pagos no tiene columnas legibles';
  END IF;
  EXECUTE format('GRANT SELECT (%s) ON TABLE public.pagos TO authenticated', safe);
END $$;

-- -----------------------------------------------------------------------------
-- 3) Calificaciones: una por trabajo y cliente, solo si el trabajo terminó.
--    La nota del profesional la recalcula el trigger. El cliente no escribe
--    calificación, rechazos ni verificación.
-- -----------------------------------------------------------------------------
DELETE FROM public.calificaciones c
WHERE c.ctid IN (
  SELECT ctid FROM (
    SELECT
      ctid,
      row_number() OVER (
        PARTITION BY id_trabajo, id_usuario
        ORDER BY creado_en DESC NULLS LAST, ctid DESC
      ) AS rn
    FROM public.calificaciones
  ) s
  WHERE rn > 1
);

CREATE UNIQUE INDEX IF NOT EXISTS calificaciones_trabajo_usuario_uidx
  ON public.calificaciones (id_trabajo, id_usuario);

DROP POLICY IF EXISTS calificaciones_insert ON public.calificaciones;
CREATE POLICY calificaciones_insert ON public.calificaciones
  FOR INSERT TO authenticated
  WITH CHECK (
    id_usuario = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.trabajos t
      WHERE t.id::text = calificaciones.id_trabajo::text
        AND t.id_usuario = (SELECT auth.uid())
        AND t.estado = 'completado'
    )
  );

REVOKE UPDATE, DELETE ON TABLE public.calificaciones FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.proteger_campos_trabajador()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.calificacion IS NOT DISTINCT FROM OLD.calificacion
     AND NEW.conteo_rechazos IS NOT DISTINCT FROM OLD.conteo_rechazos
     AND NEW.estado_verificacion IS NOT DISTINCT FROM OLD.estado_verificacion
     AND NEW.nota_verificacion IS NOT DISTINCT FROM OLD.nota_verificacion
  THEN
    RETURN NEW;
  END IF;

  IF COALESCE(current_setting('mwa.rpc_trabajador', true), '') = '1'
     OR COALESCE(auth.role(), '') = 'service_role'
     OR public.is_admin()
     OR (auth.role() IS NULL AND auth.uid() IS NULL)
     OR current_user IN ('postgres', 'supabase_admin')
  THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'calificación, rechazos y verificación no los edita el profesional';
END;
$$;

REVOKE ALL ON FUNCTION public.proteger_campos_trabajador() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trabajadores_proteger_campos_sensibles ON public.trabajadores;
CREATE TRIGGER trabajadores_proteger_campos_sensibles
  BEFORE UPDATE ON public.trabajadores
  FOR EACH ROW
  EXECUTE FUNCTION public.proteger_campos_trabajador();

REVOKE UPDATE (
  calificacion,
  conteo_rechazos,
  estado_verificacion,
  nota_verificacion
) ON TABLE public.trabajadores FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.enviar_verificacion_profesional(p_nota text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_updated int;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF p_nota IS NULL OR length(btrim(p_nota)) < 8 THEN
    RAISE EXCEPTION 'La nota de verificación es demasiado corta';
  END IF;
  PERFORM set_config('mwa.rpc_trabajador', '1', true);
  UPDATE public.trabajadores
  SET estado_verificacion = 'en_revision',
      nota_verificacion = left(btrim(p_nota), 4000)
  WHERE id_usuario = v_uid
    AND estado_verificacion IN ('pendiente', 'rechazado', 'en_revision');
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    RAISE EXCEPTION 'No se pudo enviar la verificación';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.enviar_verificacion_profesional(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.enviar_verificacion_profesional(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.fijar_verificacion_profesional(
  p_id_usuario uuid,
  p_estado text,
  p_nota text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo un administrador puede fijar la verificación';
  END IF;
  IF p_estado NOT IN ('pendiente', 'en_revision', 'verificado', 'rechazado') THEN
    RAISE EXCEPTION 'Estado de verificación inválido';
  END IF;
  PERFORM set_config('mwa.rpc_trabajador', '1', true);
  UPDATE public.trabajadores
  SET estado_verificacion = p_estado,
      nota_verificacion = CASE
        WHEN p_nota IS NULL THEN nota_verificacion
        ELSE left(p_nota, 4000)
      END
  WHERE id_usuario = p_id_usuario;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profesional no encontrado';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.fijar_verificacion_profesional(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fijar_verificacion_profesional(uuid, text, text) TO authenticated;

-- -----------------------------------------------------------------------------
-- 4) Anon no lee la tabla de profesionales. El catálogo redondea ~3 decimales
--    y no devuelve la nota de verificación.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS trabajadores_select_marketplace ON public.trabajadores;
REVOKE SELECT ON TABLE public.trabajadores FROM anon;

CREATE OR REPLACE FUNCTION public.listar_profesionales_catalogo(
  p_categoria text DEFAULT NULL,
  p_zona text DEFAULT NULL,
  p_cursor_calificacion numeric DEFAULT NULL,
  p_cursor_id uuid DEFAULT NULL,
  p_limit integer DEFAULT 20
)
RETURNS TABLE (
  id_usuario uuid,
  profesion text,
  descripcion text,
  calificacion numeric,
  tarifa_visita numeric,
  categoria_servicio text,
  zona_trabajo text,
  nombre text,
  ruta_foto_perfil text,
  latitud_base double precision,
  longitud_base double precision,
  radio_servicio_km numeric,
  origen_base text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    t.id_usuario,
    t.profesion,
    t.descripcion,
    t.calificacion,
    t.tarifa_visita,
    t.categoria_servicio,
    t.zona_trabajo,
    p.nombre,
    p.ruta_foto_perfil,
    round(t.latitud_base::numeric, 3)::double precision,
    round(t.longitud_base::numeric, 3)::double precision,
    t.radio_servicio_km,
    t.origen_base
  FROM public.trabajadores t
  LEFT JOIN public.perfiles p ON p.id = t.id_usuario
  WHERE COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
    AND (
      p_categoria IS NULL
      OR btrim(p_categoria) = ''
      OR t.categoria_servicio = p_categoria
    )
    AND (
      p_zona IS NULL
      OR btrim(p_zona) = ''
      OR t.zona_trabajo ILIKE
        ('%' || replace(replace(btrim(p_zona), '%', ''), '_', '') || '%')
    )
    AND (
      p_cursor_id IS NULL
      OR COALESCE(t.calificacion, 0) < COALESCE(p_cursor_calificacion, 0)
      OR (
        COALESCE(t.calificacion, 0) = COALESCE(p_cursor_calificacion, 0)
        AND t.id_usuario > p_cursor_id
      )
    )
  ORDER BY COALESCE(t.calificacion, 0) DESC, t.id_usuario ASC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 40);
$$;

REVOKE ALL ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) TO anon, authenticated;

-- -----------------------------------------------------------------------------
-- 5) Selector de la demo. Con demo_modo=0 no devuelve correos.
--    Antes del lanzamiento: UPDATE app_config SET valor='0' WHERE clave='demo_modo'
--    y REVOKE EXECUTE ON FUNCTION public.listar_cuentas_demo_acceso() FROM anon.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.listar_cuentas_demo_acceso()
RETURNS TABLE (
  id uuid,
  nombre text,
  correo text,
  rol text,
  profesion text,
  categoria_servicio text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT p.id, p.nombre, p.correo, p.rol, t.profesion, t.categoria_servicio
  FROM public.perfiles p
  JOIN public.trabajadores t ON t.id_usuario = p.id
  WHERE COALESCE((SELECT c.valor FROM public.app_config c WHERE c.clave = 'demo_modo'), '0') = '1'
    AND p.rol = 'trabajador'
    AND p.correo ILIKE '%@demo.myworksapp.cl';
$$;

REVOKE ALL ON FUNCTION public.listar_cuentas_demo_acceso() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_cuentas_demo_acceso() TO anon, authenticated;

COMMIT;

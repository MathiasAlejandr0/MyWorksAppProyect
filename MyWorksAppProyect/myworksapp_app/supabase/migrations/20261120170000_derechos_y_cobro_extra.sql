-- Derechos del titular (exportar y solicitar eliminación), libreta de
-- direcciones del cliente y rechazo de un cobro adicional.
-- La fórmula del monto del cobro adicional no se toca: sigue en
-- crear_intencion_pago_orden_cambio. Esta migración solo la lee.
-- No está aplicada.

BEGIN;

CREATE OR REPLACE FUNCTION public.monto_a_cobrar_orden_cambio(p_id text)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_order public.ordenes_cambio;
  v_job public.trabajos;
  v_expected numeric;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_order FROM public.ordenes_cambio WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Orden de cambio no encontrada';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id = v_order.id_trabajo;
  IF NOT FOUND OR v_job.id_usuario IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Solo el cliente del trabajo puede ver este cobro';
  END IF;

  -- Misma expresión que crear_intencion_pago_orden_cambio. No cambia la comisión.
  v_expected := coalesce(v_order.monto_clp, 0)::numeric
    + round(coalesce(v_order.monto_clp, 0)::numeric * 0.08);
  RETURN v_expected::integer;
END;
$$;

REVOKE ALL ON FUNCTION public.monto_a_cobrar_orden_cambio(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.monto_a_cobrar_orden_cambio(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.rechazar_orden_cambio(p_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_order public.ordenes_cambio;
  v_job public.trabajos;
  v_ahora text := to_char(clock_timestamp() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_order FROM public.ordenes_cambio WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Orden de cambio no encontrada';
  END IF;
  IF v_order.estado IS DISTINCT FROM 'pendiente_cliente' THEN
    RAISE EXCEPTION 'La orden de cambio ya fue respondida';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id = v_order.id_trabajo FOR UPDATE;
  IF NOT FOUND OR v_job.id_usuario IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Solo el cliente del trabajo puede rechazar el cobro';
  END IF;

  UPDATE public.ordenes_cambio
  SET estado = 'rechazada', respondido_en = v_ahora
  WHERE id = v_order.id;

  IF v_job.estado = 'pausado_orden_cambio' THEN
    PERFORM set_config('mwa.rpc_trabajo', '1', true);
    UPDATE public.trabajos
    SET estado = 'en_curso', actualizado_en = v_ahora
    WHERE id = v_job.id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.rechazar_orden_cambio(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rechazar_orden_cambio(text) TO authenticated;

CREATE TABLE IF NOT EXISTS public.direcciones_cliente (
  id text PRIMARY KEY,
  id_usuario uuid NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
  etiqueta text NOT NULL DEFAULT '',
  direccion text NOT NULL,
  creado_en text NOT NULL
);

ALTER TABLE public.direcciones_cliente ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS direcciones_cliente_propias ON public.direcciones_cliente;
CREATE POLICY direcciones_cliente_propias
  ON public.direcciones_cliente
  FOR ALL
  TO authenticated
  USING (id_usuario = (SELECT auth.uid()))
  WITH CHECK (id_usuario = (SELECT auth.uid()));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.direcciones_cliente TO authenticated;
REVOKE ALL ON public.direcciones_cliente FROM anon;

CREATE OR REPLACE FUNCTION public.exportar_mis_datos()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  RETURN jsonb_build_object(
    'exportado_en', to_char(clock_timestamp() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'perfil', (
      SELECT jsonb_build_object(
        'id', p.id,
        'nombre', p.nombre,
        'correo', p.correo,
        'telefono', p.telefono,
        'rol', p.rol,
        'estado_cuenta', p.estado_cuenta,
        'creado_en', p.creado_en
      )
      FROM public.perfiles p
      WHERE p.id = v_uid
    ),
    'direcciones', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', d.id, 'etiqueta', d.etiqueta, 'direccion', d.direccion, 'creado_en', d.creado_en
      ))
      FROM public.direcciones_cliente d
      WHERE d.id_usuario = v_uid
    ), '[]'::jsonb),
    'consentimientos', COALESCE((
      SELECT jsonb_agg(to_jsonb(c) - 'id')
      FROM public.consentimientos_usuario c
      WHERE c.id_usuario = v_uid
    ), '[]'::jsonb),
    'pedidos', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', t.id,
        'estado', t.estado,
        'direccion', t.direccion,
        'descripcion', t.descripcion,
        'fecha_programada', t.fecha_programada,
        'creado_en', t.creado_en
      ))
      FROM public.trabajos t
      WHERE t.id_usuario = v_uid
    ), '[]'::jsonb),
    'mensajes', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', m.id, 'id_trabajo', m.id_trabajo, 'contenido', m.contenido, 'creado_en', m.creado_en
      ))
      FROM public.mensajes m
      WHERE m.id_remitente = v_uid
    ), '[]'::jsonb),
    'calificaciones', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', c.id, 'id_trabajo', c.id_trabajo, 'puntaje', c.puntaje, 'comentario', c.comentario, 'creado_en', c.creado_en
      ))
      FROM public.calificaciones c
      WHERE c.id_usuario = v_uid
    ), '[]'::jsonb)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.exportar_mis_datos() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.exportar_mis_datos() TO authenticated;

-- El trigger de perfiles impide que el titular cambie estado_cuenta.
-- Esta bandera solo la pone la función de eliminación, que es SECURITY DEFINER.
CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $function$
BEGIN
  IF coalesce(current_setting('mwa.derechos_titular', true), '') = '1'
     AND NEW.id IS NOT DISTINCT FROM OLD.id
     AND NEW.rol IS NOT DISTINCT FROM OLD.rol THEN
    RETURN NEW;
  END IF;
  IF NOT (public.is_admin() OR COALESCE(auth.role(), '') = 'service_role') THEN
    IF NEW.rol IS DISTINCT FROM OLD.rol THEN
      RAISE EXCEPTION 'No puedes cambiar tu rol';
    END IF;
    IF NEW.estado_cuenta IS DISTINCT FROM OLD.estado_cuenta THEN
      RAISE EXCEPTION 'No puedes cambiar el estado de tu cuenta';
    END IF;
  END IF;
  IF current_user IN ('authenticated', 'anon')
     AND NOT public.is_admin()
     AND (NEW.reputacion_cliente IS DISTINCT FROM OLD.reputacion_cliente
          OR NEW.calificaciones_cliente IS DISTINCT FROM OLD.calificaciones_cliente) THEN
    RAISE EXCEPTION 'La reputación la calcula el sistema';
  END IF;
  RETURN NEW;
END;
$function$;

ALTER TABLE public.perfiles
  ADD COLUMN IF NOT EXISTS telefono text;

COMMENT ON COLUMN public.perfiles.telefono IS
  'Teléfono de contacto del titular, en E.164. Lo edita solo su cuenta.';

CREATE OR REPLACE FUNCTION public.solicitar_eliminacion_cuenta()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_ahora text := to_char(clock_timestamp() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM public.trabajos t
    WHERE (t.id_usuario = v_uid OR t.id_trabajador = v_uid)
      AND t.estado IN (
        'esperando_pago', 'aceptado', 'en_camino', 'en_curso',
        'pausado_orden_cambio', 'esperando_aprobacion_cliente'
      )
  ) THEN
    RAISE EXCEPTION 'Tienes un pedido abierto. Ciérralo antes de eliminar la cuenta';
  END IF;

  PERFORM set_config('mwa.derechos_titular', '1', true);
  UPDATE public.perfiles
  SET
    nombre = 'Usuario eliminado',
    correo = 'eliminado+' || v_uid::text || '@invalid',
    telefono = NULL,
    ruta_foto_perfil = NULL,
    estado_cuenta = 'eliminado'
  WHERE id = v_uid;

  DELETE FROM public.direcciones_cliente WHERE id_usuario = v_uid;
  DELETE FROM public.consentimientos_usuario WHERE id_usuario = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.solicitar_eliminacion_cuenta() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.solicitar_eliminacion_cuenta() TO authenticated;

COMMIT;

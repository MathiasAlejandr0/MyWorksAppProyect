-- El RPC transicionar_trabajo llama a transicion_trabajo_permitida(text, text, text).
-- En remoto esa firma no existe (42883), así que aceptar un trabajo falla
-- antes de cambiar el estado. Se recrea el helper y se castea la llamada.

BEGIN;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'transicion_trabajo_permitida'
      AND pg_get_function_identity_arguments(p.oid) IS DISTINCT FROM 'text, text, text'
  LOOP
    EXECUTE format(
      'DROP FUNCTION IF EXISTS public.transicion_trabajo_permitida(%s)',
      r.args
    );
  END LOOP;
END $$;

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
  IF p_desde IS NULL OR p_hacia IS NULL THEN
    RETURN false;
  END IF;
  IF p_desde = p_hacia THEN
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
        ('esperando_pago', 'aceptado'),
        ('aceptado', 'en_curso'),
        ('en_curso', 'completado'),
        ('en_curso', 'no_asistio'),
        ('en_curso', 'pausado_orden_cambio'),
        ('pausado_orden_cambio', 'en_curso')
      );
    WHEN 'cotizacion_abierta' THEN
      RETURN (p_desde, p_hacia) IN (
        ('esperando_cotizaciones', 'cotizacion_seleccionada'),
        ('esperando_cotizaciones', 'expirado'),
        ('cotizacion_seleccionada', 'esperando_pago'),
        ('esperando_pago', 'aceptado'),
        ('aceptado', 'en_curso'),
        ('en_curso', 'completado'),
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
        ('en_curso', 'completado'),
        ('en_curso', 'esperando_aprobacion_cliente'),
        ('en_curso', 'no_asistio'),
        ('en_curso', 'pausado_orden_cambio'),
        ('esperando_aprobacion_cliente', 'completado'),
        ('esperando_aprobacion_cliente', 'en_curso'),
        ('pausado_orden_cambio', 'en_curso')
      );
  END CASE;
END;
$$;

REVOKE ALL ON FUNCTION public.transicion_trabajo_permitida(text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.transicion_trabajo_permitida(text, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.transicion_trabajo_permitida(text, text, text) FROM anon;

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
      v_row.estado::text,
      p_nuevo_estado::text,
      COALESCE(v_row.modalidad_cobro::text, 'legado')
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
  'Transición de estado validada contra transicion_trabajo_permitida(text, text, text).';

GRANT EXECUTE ON FUNCTION public.transicionar_trabajo(text, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.transicionar_trabajo(text, text, text) FROM anon;
REVOKE ALL ON FUNCTION public.transicionar_trabajo(text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.transicionar_trabajo(text, text, text) TO authenticated;

COMMIT;

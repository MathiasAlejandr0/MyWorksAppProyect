-- La app pregunta aquí qué estados siguen. La lista vive solo en
-- transicion_trabajo_permitida. También borra cuentas de invitado
-- cuyo pago no llegó a garantía.

BEGIN;

CREATE OR REPLACE FUNCTION public.transiciones_trabajo_posibles(
  p_desde text,
  p_modalidad text DEFAULT 'legado'
)
RETURNS text[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT COALESCE(array_agg(candidato ORDER BY candidato), ARRAY[]::text[])
  FROM unnest(ARRAY[
    'pendiente',
    'esperando_cotizaciones',
    'cotizacion_seleccionada',
    'esperando_pago',
    'aceptado',
    'en_curso',
    'pausado_orden_cambio',
    'esperando_aprobacion_cliente',
    'completado',
    'cancelado',
    'expirado',
    'no_asistio'
  ]::text[]) AS candidato
  WHERE public.transicion_trabajo_permitida(
    p_desde,
    candidato,
    COALESCE(NULLIF(trim(p_modalidad), ''), 'legado')
  );
$$;

REVOKE ALL ON FUNCTION public.transiciones_trabajo_posibles(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.transiciones_trabajo_posibles(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.transiciones_trabajo_posibles(text, text) FROM anon;

CREATE OR REPLACE FUNCTION public.limpiar_invitados_sin_pago()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
DECLARE
  n integer := 0;
  r record;
BEGIN
  FOR r IN
    SELECT u.id
    FROM auth.users u
    WHERE COALESCE(u.raw_user_meta_data->>'guest_checkout', '') IN ('true', '1')
      AND u.created_at < now() - interval '2 hours'
      AND NOT EXISTS (
        SELECT 1
        FROM public.trabajos t
        JOIN public.pagos p ON p.id_trabajo::text = t.id::text
        WHERE t.id_usuario::text = u.id::text
          AND p.tipo_pago = 'principal'
          AND p.estado IN ('retenido', 'autorizado', 'liberado')
      )
  LOOP
    DELETE FROM public.pagos p
    USING public.trabajos t
    WHERE p.id_trabajo::text = t.id::text
      AND t.id_usuario::text = r.id::text
      AND p.estado = 'pendiente';

    DELETE FROM public.trabajos t
    WHERE t.id_usuario::text = r.id::text
      AND t.estado = 'esperando_pago';

    DELETE FROM public.perfiles WHERE id::text = r.id::text;
    DELETE FROM auth.users WHERE id = r.id;
    n := n + 1;
  END LOOP;
  RETURN n;
END;
$$;

REVOKE ALL ON FUNCTION public.limpiar_invitados_sin_pago() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.limpiar_invitados_sin_pago() TO service_role;
REVOKE EXECUTE ON FUNCTION public.limpiar_invitados_sin_pago() FROM anon, authenticated;

COMMIT;

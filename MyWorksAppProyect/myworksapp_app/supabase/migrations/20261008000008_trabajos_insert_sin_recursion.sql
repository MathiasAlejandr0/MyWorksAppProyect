-- 000005 consultaba trabajadores y perfiles dentro de trabajos_insert.
-- Esas políticas de SELECT miran trabajos y Postgres responde 42P17.
-- trabajador_reservable corre como definer y corta el ciclo.

BEGIN;

CREATE OR REPLACE FUNCTION public.trabajador_reservable(p_trabajador uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p_trabajador IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.trabajadores w
      JOIN public.perfiles p ON p.id = w.id_usuario
      WHERE w.id_usuario = p_trabajador
        AND COALESCE(w.disponible, 0) = 1
        AND COALESCE(w.precios_configurados, 0) = 1
        AND w.estado_verificacion = 'verificado'
        AND p.rol = 'trabajador'
        AND p.estado_cuenta IN ('activo', 'active')
    );
$$;

REVOKE ALL ON FUNCTION public.trabajador_reservable(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.trabajador_reservable(uuid) TO authenticated, service_role;

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
          AND public.trabajador_reservable(id_trabajador)
        )
      )
    )
  );

CREATE OR REPLACE FUNCTION public.texto_a_timestamptz(p_valor text)
RETURNS timestamptz
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
BEGIN
  IF p_valor IS NULL OR btrim(p_valor) = '' THEN
    RETURN NULL;
  END IF;
  RETURN p_valor::timestamptz;
EXCEPTION
  WHEN others THEN
    RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.texto_a_timestamptz(text) FROM PUBLIC, anon, authenticated;

COMMIT;

-- Lectura de ajustes y cola de disputas de la consola.
--
-- app_config solo se lee con is_admin(). Si la sesión no pasa, PostgREST
-- devuelve cero filas y Ajustes queda en blanco. consola_leer_config exige
-- el mismo control y falla de forma explícita.
--
-- consola_disputas_abiertas queda en disputa_esta_activa: abierta,
-- en_revision, requiere_humano y reembolso_pendiente. No cambia demo_modo
-- ni la comisión.

CREATE OR REPLACE FUNCTION public.consola_leer_config()
RETURNS TABLE (clave text, valor text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
  SELECT c.clave, c.valor
  FROM public.app_config c
  ORDER BY c.clave;
END;
$$;

REVOKE ALL ON FUNCTION public.consola_leer_config() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_leer_config() TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_disputas_abiertas()
RETURNS TABLE (
  id text,
  id_trabajo text,
  motivo text,
  descripcion text,
  estado text,
  decision_sugerida text,
  motivo_regla text,
  vence_en timestamptz,
  creado_en text,
  nombre_cliente text,
  nombre_profesional text,
  monto_retenido numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF public.rol_consola() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
  SELECT
    d.id::text,
    d.id_trabajo::text,
    d.motivo,
    d.descripcion,
    d.estado,
    d.decision_sugerida,
    d.motivo_regla,
    d.vence_en,
    d.creado_en::text,
    COALESCE(pc.nombre, 'Cliente'),
    COALESCE(pp.nombre, 'Profesional'),
    COALESCE((
      SELECT max(pg.monto)
      FROM public.pagos pg
      WHERE pg.id_trabajo = d.id_trabajo
        AND pg.estado IN ('autorizado', 'retenido', 'pendiente')
    ), 0)
  FROM public.disputas d
  JOIN public.trabajos t ON t.id::text = d.id_trabajo::text
  LEFT JOIN public.perfiles pc ON pc.id = t.id_usuario
  LEFT JOIN public.perfiles pp ON pp.id = t.id_trabajador
  WHERE public.disputa_esta_activa(d.estado)
  ORDER BY d.creado_en DESC
  LIMIT 200;
END;
$$;

REVOKE ALL ON FUNCTION public.consola_disputas_abiertas() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_disputas_abiertas() TO authenticated, service_role;

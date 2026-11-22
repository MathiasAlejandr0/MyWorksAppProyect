-- Consola: la cola de disputas y la lectura de ajustes.
-- No aplicar en el proyecto remoto. Solo base local.
--
-- 1) consola_disputas_abiertas solo devolvía requiere_humano y
--    reembolso_pendiente. El resumen sí cuenta abierta y en_revision
--    (disputa_esta_activa). Por eso Inicio podía mostrar un número y
--    Disputas quedaba vacío.
-- 2) app_config tiene REVOKE a authenticated y una política USING (false).
--    Un administrador no puede leer la tabla: Ajustes parece vacío.
--    La escritura sigue solo en consola_editar_config.

BEGIN;

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

-- Lectura de ajustes solo para administrador con sesión válida (is_admin).
-- Sin políticas de escritura: el cliente no inserta ni cambia filas.
REVOKE ALL ON TABLE public.app_config FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.app_config TO authenticated;

DROP POLICY IF EXISTS app_config_sin_acceso_cliente ON public.app_config;
DROP POLICY IF EXISTS app_config_select_admin ON public.app_config;
CREATE POLICY app_config_select_admin
  ON public.app_config
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_admin()));

COMMIT;

-- La vista perfiles_publicos quedó como security definer (security_invoker = false)
-- y el advisor la marca como ERROR. El nombre y la foto salen por una RPC
-- con la misma forma, solo para autenticados. anon no la ejecuta.
--
-- listar_cuentas_demo_acceso sigue en anon: la pantalla de login de la app
-- lista chips @demo.myworksapp.cl antes de tener sesión. No devuelve otras cuentas.
-- Idempotente. Aplicar después de 20261008000001.

BEGIN;

CREATE OR REPLACE FUNCTION public.perfiles_publicos_por_ids(p_ids uuid[])
RETURNS TABLE (
  id uuid,
  nombre text,
  rol text,
  ruta_foto_perfil text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT p.id, p.nombre, p.rol, p.ruta_foto_perfil
  FROM public.perfiles p
  WHERE auth.uid() IS NOT NULL
    AND p.id = ANY(COALESCE(p_ids, ARRAY[]::uuid[]))
  LIMIT 200;
$$;

REVOKE ALL ON FUNCTION public.perfiles_publicos_por_ids(uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.perfiles_publicos_por_ids(uuid[]) TO authenticated;

DROP VIEW IF EXISTS public.perfiles_publicos;

-- El login de la demo corre sin sesión. Sigue limitado al dominio de la demo.
REVOKE ALL ON FUNCTION public.listar_cuentas_demo_acceso() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_cuentas_demo_acceso() TO anon, authenticated;

COMMIT;

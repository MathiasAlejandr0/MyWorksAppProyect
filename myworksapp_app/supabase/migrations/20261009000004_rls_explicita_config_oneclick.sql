-- Auditoría 2026-10-05 (P2, limpieza del asesor rls_enabled_no_policy).
-- app_config y metodos_pago_oneclick ya estaban cerradas: RLS activo, sin políticas y sin
-- GRANT a anon ni authenticated. Solo las leen las Edge Functions con service_role y las
-- funciones SECURITY DEFINER (is_admin, listar_cuentas_demo_acceso).
-- Se deja la intención escrita con una política que niega todo a los clientes.
-- service_role y el dueño de la tabla no pasan por RLS: nada cambia en la operación.

DROP POLICY IF EXISTS app_config_sin_acceso_cliente ON public.app_config;
CREATE POLICY app_config_sin_acceso_cliente ON public.app_config
  FOR ALL TO anon, authenticated
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS metodos_pago_oneclick_sin_acceso_cliente ON public.metodos_pago_oneclick;
CREATE POLICY metodos_pago_oneclick_sin_acceso_cliente ON public.metodos_pago_oneclick
  FOR ALL TO anon, authenticated
  USING (false)
  WITH CHECK (false);

REVOKE ALL ON TABLE public.app_config FROM anon, authenticated;
REVOKE ALL ON TABLE public.metodos_pago_oneclick FROM anon, authenticated;

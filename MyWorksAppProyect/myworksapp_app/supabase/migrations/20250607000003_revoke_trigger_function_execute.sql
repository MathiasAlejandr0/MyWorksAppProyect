-- Funciones de trigger no deben ser invocables vía PostgREST/RPC.
REVOKE ALL ON FUNCTION public.protect_profile_sensitive_fields() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.protect_profile_sensitive_fields() FROM anon;
REVOKE EXECUTE ON FUNCTION public.protect_profile_sensitive_fields() FROM authenticated;

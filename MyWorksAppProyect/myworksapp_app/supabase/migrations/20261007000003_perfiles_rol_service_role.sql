-- handle_new_user deja todo perfil en 'usuario'. El service role de
-- invitar-colaborador tiene que poder pasar ese perfil a administrador.
-- Un JWT anon o authenticated no puede cambiar rol ni estado de cuenta.
-- Idempotente.

BEGIN;

CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT (
    public.is_admin()
    OR COALESCE(auth.role(), '') = 'service_role'
  ) THEN
    IF NEW.rol IS DISTINCT FROM OLD.rol THEN
      RAISE EXCEPTION 'No puedes cambiar tu rol';
    END IF;
    IF NEW.estado_cuenta IS DISTINCT FROM OLD.estado_cuenta THEN
      RAISE EXCEPTION 'No puedes cambiar el estado de tu cuenta';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.protect_profile_sensitive_fields() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.protect_profile_sensitive_fields() FROM anon;
REVOKE ALL ON FUNCTION public.protect_profile_sensitive_fields() FROM authenticated;

COMMIT;

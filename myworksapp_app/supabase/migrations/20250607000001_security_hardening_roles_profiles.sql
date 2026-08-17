-- Rol seguro al crear perfil: solo user o worker
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  requested_role text;
  safe_role text;
BEGIN
  requested_role := lower(trim(coalesce(new.raw_user_meta_data->>'role', 'user')));
  IF requested_role = 'worker' THEN
    safe_role := 'worker';
  ELSE
    safe_role := 'user';
  END IF;

  INSERT INTO public.profiles (id, name, email, role, "accountStatus", "createdAt")
  VALUES (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', ''),
    new.email,
    safe_role,
    'active',
    to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'No puedes cambiar tu rol';
    END IF;
    IF NEW."accountStatus" IS DISTINCT FROM OLD."accountStatus" THEN
      RAISE EXCEPTION 'No puedes cambiar el estado de tu cuenta';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_profiles_sensitive ON public.profiles;
CREATE TRIGGER protect_profiles_sensitive
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_sensitive_fields();

DROP POLICY IF EXISTS app_error_logs_insert ON public.app_error_logs;
CREATE POLICY app_error_logs_insert ON public.app_error_logs
  FOR INSERT TO authenticated
  WITH CHECK ("userId" IS NULL OR "userId" = auth.uid());

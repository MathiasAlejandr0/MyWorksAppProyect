-- Nombre de perfil desde metadatos OAuth (Google full_name, Apple name, etc.)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  requested_role text;
  safe_role text;
  display_name text;
BEGIN
  requested_role := lower(trim(coalesce(new.raw_user_meta_data->>'role', 'user')));
  IF requested_role = 'worker' THEN
    safe_role := 'worker';
  ELSE
    safe_role := 'user';
  END IF;

  display_name := trim(
    coalesce(
      nullif(new.raw_user_meta_data->>'name', ''),
      nullif(new.raw_user_meta_data->>'full_name', ''),
      nullif(new.raw_user_meta_data->>'given_name', ''),
      split_part(coalesce(new.email, ''), '@', 1)
    )
  );

  INSERT INTO public.profiles (id, name, email, role, "accountStatus", "createdAt")
  VALUES (
    new.id,
    display_name,
    new.email,
    safe_role,
    'active',
    to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

-- Permite alias de negocio en raw_user_meta_data.role:
-- cliente → usuario, especialista → trabajador.
-- El registro público nunca puede crear administrador.

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
  requested_role := lower(trim(coalesce(new.raw_user_meta_data->>'role', 'usuario')));
  IF requested_role IN ('worker', 'trabajador', 'especialista', 'specialist') THEN
    safe_role := 'trabajador';
  ELSE
    safe_role := 'usuario';
  END IF;

  display_name := trim(
    coalesce(
      nullif(new.raw_user_meta_data->>'name', ''),
      nullif(new.raw_user_meta_data->>'nombre', ''),
      nullif(new.raw_user_meta_data->>'full_name', ''),
      nullif(new.raw_user_meta_data->>'given_name', ''),
      split_part(coalesce(new.email, ''), '@', 1)
    )
  );

  INSERT INTO public.perfiles (id, nombre, correo, rol, estado_cuenta, creado_en)
  VALUES (
    new.id,
    display_name,
    new.email,
    safe_role,
    'activo',
    to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

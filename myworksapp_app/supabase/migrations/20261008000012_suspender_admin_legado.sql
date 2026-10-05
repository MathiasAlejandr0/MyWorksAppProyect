-- Auditoría 2026-10-05 (P0).
-- admin@demo.com seguía activo como administrador y entraba con `demo123`,
-- una clave publicada en el repositorio (myworksapp_app/lib/core/config/demo_credentials.dart).
-- Con admin_requiere_aal2 = 0 en la demo, cualquiera podía operar el panel y leer todos los datos.
--
-- No se borra nada: se suspende el perfil (is_admin() exige estado_cuenta activo)
-- y se bloquea el ingreso en Auth. Para revertir:
--   UPDATE auth.users SET banned_until = NULL WHERE email = 'admin@demo.com';
--   UPDATE public.perfiles SET estado_cuenta = 'activo' WHERE correo = 'admin@demo.com';
-- La cuenta de la demo es admin.ops@demo.myworksapp.cl y no se toca.

-- protect_profile_sensitive_fields solo deja cambiar estado_cuenta a admin o service_role.
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

UPDATE public.perfiles
SET estado_cuenta = 'suspendido'
WHERE lower(correo) = 'admin@demo.com'
  AND estado_cuenta IS DISTINCT FROM 'suspendido';

UPDATE auth.users
SET banned_until = '2999-12-31 00:00:00+00'
WHERE lower(email) = 'admin@demo.com';

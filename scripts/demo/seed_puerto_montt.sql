-- Profesionales de muestra en Puerto Montt y alrededores.
-- No es una migración. Correr en el SQL Editor DESPUÉS de
-- 20261025000001_revision_patrocinante.sql.
-- Contraseña de todas: Demo2026!
-- Reejecutar actualiza las mismas fichas y no toca las cuentas de Santiago.

BEGIN;

DO $pm$
DECLARE
  v_hash text;
  v_now text := to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US');
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'trabajadores'
      AND column_name = 'radio_urbano_km'
  ) THEN
    RAISE EXCEPTION 'Falta radio_urbano_km. Aplica 20261025000001_revision_patrocinante.sql antes.';
  END IF;

  BEGIN
    v_hash := extensions.crypt('Demo2026!', extensions.gen_salt('bf'));
  EXCEPTION
    WHEN undefined_function THEN
      v_hash := crypt('Demo2026!', gen_salt('bf'));
  END;

  CREATE TEMP TABLE pm_cuentas (
    email text PRIMARY KEY,
    uid uuid NOT NULL,
    nombre text NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO pm_cuentas (email, uid, nombre) VALUES
    ('mateo.oyarzo@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000301', 'Mateo Oyarzo'),
    ('elsa.caicheo@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000302', 'Elsa Caicheo'),
    ('bruno.levio@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000303', 'Bruno Levio'),
    ('nora.huenchun@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000304', 'Nora Huenchun'),
    ('ivan.barria@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000305', 'Iván Barría'),
    ('sofia.alvarado@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000306', 'Sofía Alvarado'),
    ('clemente.navarro@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000307', 'Clemente Navarro'),
    ('rosa.millalonco@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000308', 'Rosa Millalonco');

  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
  )
  SELECT
    '00000000-0000-0000-0000-000000000000',
    c.uid, 'authenticated', 'authenticated', c.email, v_hash, now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('nombre', c.nombre, 'role', 'especialista'),
    now(), now(), '', '', '', ''
  FROM pm_cuentas c
  WHERE NOT EXISTS (
    SELECT 1 FROM auth.users u
    WHERE lower(u.email) = c.email OR u.id = c.uid
  );

  UPDATE auth.users u
  SET
    encrypted_password = v_hash,
    email_confirmed_at = COALESCE(u.email_confirmed_at, now()),
    raw_user_meta_data = jsonb_build_object('nombre', c.nombre, 'role', 'especialista'),
    updated_at = now()
  FROM pm_cuentas c
  WHERE lower(u.email) = c.email;

  UPDATE pm_cuentas c
  SET uid = u.id
  FROM auth.users u
  WHERE lower(u.email) = c.email;

  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
  )
  SELECT
    gen_random_uuid(), c.uid,
    jsonb_build_object('sub', c.uid::text, 'email', c.email, 'email_verified', true),
    'email', c.uid::text, now(), now(), now()
  FROM pm_cuentas c
  WHERE NOT EXISTS (
    SELECT 1 FROM auth.identities i
    WHERE i.user_id = c.uid AND i.provider = 'email'
  );

  ALTER TABLE public.perfiles DISABLE TRIGGER protect_profiles_sensitive;
  BEGIN
    INSERT INTO public.perfiles (id, nombre, correo, rol, estado_cuenta, creado_en)
    SELECT c.uid, c.nombre, c.email, 'trabajador', 'activo', v_now
    FROM pm_cuentas c
    ON CONFLICT (id) DO UPDATE SET
      nombre = EXCLUDED.nombre,
      correo = EXCLUDED.correo,
      rol = 'trabajador',
      estado_cuenta = 'activo';
    ALTER TABLE public.perfiles ENABLE TRIGGER protect_profiles_sensitive;
  EXCEPTION
    WHEN OTHERS THEN
      ALTER TABLE public.perfiles ENABLE TRIGGER protect_profiles_sensitive;
      RAISE;
  END;

  ALTER TABLE public.trabajadores DISABLE TRIGGER trabajadores_proteger_verificacion;
  BEGIN
    INSERT INTO public.trabajadores (
      id_usuario, profesion, descripcion, calificacion, disponible, tarifa_visita,
      categoria_servicio, precios_configurados, zona_trabajo, estado_verificacion,
      nota_verificacion, latitud_base, longitud_base, radio_servicio_km, origen_base,
      radio_urbano_km, tarifa_fuera_radio_clp, trabajos_completados
    )
    SELECT
      c.uid, v.profesion, v.descripcion, v.calificacion, 1, v.tarifa,
      v.categoria, 1, v.zona, 'verificado', 'Ficha de muestra, Puerto Montt.',
      v.lat, v.lng, v.radio, 'mapa', v.urbano, v.fuera, v.hechos
    FROM (
      VALUES
        ('mateo.oyarzo@demo.myworksapp.cl', 'Gasfíter', 'Destacado del mes en el centro de Puerto Montt. Fugas y calefont.', 4.9::numeric, 32000, 'plomeria', 'Puerto Montt', -41.4718::float8, -72.9396::float8, 12::numeric, 5::numeric, 7000, 8),
        ('elsa.caicheo@demo.myworksapp.cl', 'Electricista', 'Tableros domiciliarios en la costanera.', 4.8, 38000, 'electricidad', 'Puerto Montt', -41.4682, -72.9424, 10, 5, 0, 6),
        ('bruno.levio@demo.myworksapp.cl', 'Pintor', 'Interiores en Pelluco. Buena nota, poco volumen.', 4.4, 27000, 'pintura', 'Pelluco', -41.4925, -72.9055, 8, 4, 5000, 3),
        ('nora.huenchun@demo.myworksapp.cl', 'Maestra', 'Obras menores en Alerce. Nota media: baja en el feed.', 3.4, 30000, 'construccion', 'Alerce', -41.3960, -72.9030, 15, 6, 9000, 4),
        ('ivan.barria@demo.myworksapp.cl', 'Jardinero', 'Élite en Puerto Varas, fuera del radio urbano de Puerto Montt.', 4.9, 26000, 'jardineria', 'Puerto Varas', -41.3195, -72.9854, 18, 5, 12000, 9),
        ('sofia.alvarado@demo.myworksapp.cl', 'Aseo hogar', 'Nota baja. El catálogo no la muestra hasta que supere 3.0.', 2.6, 20000, 'limpieza', 'Angelmó', -41.4835, -72.9580, 8, 5, 4000, 2),
        ('clemente.navarro@demo.myworksapp.cl', 'Cerrajero', 'Aperturas en La Paloma. Relevancia media.', 4.1, 25000, 'cerrajeria', 'La Paloma', -41.4550, -72.9550, 10, 5, 6000, 4),
        ('rosa.millalonco@demo.myworksapp.cl', 'Soporte técnico', 'Élite en Chinquihue. Radio urbano corto, sin cobro fuera.', 4.8, 24000, 'soporte_tecnico', 'Chinquihue', -41.5050, -73.0100, 14, 5, 0, 7)
    ) AS v(email, profesion, descripcion, calificacion, tarifa, categoria, zona, lat, lng, radio, urbano, fuera, hechos)
    JOIN pm_cuentas c ON c.email = v.email
    ON CONFLICT (id_usuario) DO UPDATE SET
      profesion = EXCLUDED.profesion,
      descripcion = EXCLUDED.descripcion,
      calificacion = EXCLUDED.calificacion,
      disponible = 1,
      tarifa_visita = EXCLUDED.tarifa_visita,
      categoria_servicio = EXCLUDED.categoria_servicio,
      precios_configurados = 1,
      zona_trabajo = EXCLUDED.zona_trabajo,
      estado_verificacion = 'verificado',
      nota_verificacion = EXCLUDED.nota_verificacion,
      latitud_base = EXCLUDED.latitud_base,
      longitud_base = EXCLUDED.longitud_base,
      radio_servicio_km = EXCLUDED.radio_servicio_km,
      origen_base = 'mapa',
      radio_urbano_km = EXCLUDED.radio_urbano_km,
      tarifa_fuera_radio_clp = EXCLUDED.tarifa_fuera_radio_clp,
      trabajos_completados = EXCLUDED.trabajos_completados;
    ALTER TABLE public.trabajadores ENABLE TRIGGER trabajadores_proteger_verificacion;
  EXCEPTION
    WHEN OTHERS THEN
      ALTER TABLE public.trabajadores ENABLE TRIGGER trabajadores_proteger_verificacion;
      RAISE;
  END;

  -- Las cuentas de Santiago que ya son élite por nota quedan con volumen suficiente
  -- para la insignia, si todavía no tienen 5 trabajos reales.
  UPDATE public.trabajadores t
  SET trabajos_completados = GREATEST(t.trabajos_completados, 5),
      radio_urbano_km = COALESCE(NULLIF(t.radio_urbano_km, 0), 5),
      tarifa_fuera_radio_clp = CASE
        WHEN t.tarifa_fuera_radio_clp > 0 THEN t.tarifa_fuera_radio_clp
        ELSE 6000
      END
  FROM public.perfiles p
  WHERE p.id = t.id_usuario
    AND p.correo ILIKE '%@demo.myworksapp.cl'
    AND t.estado_verificacion = 'verificado'
    AND COALESCE(t.calificacion, 0) >= 4.7
    AND t.id_usuario NOT IN (SELECT uid FROM pm_cuentas);
END;
$pm$;

COMMIT;

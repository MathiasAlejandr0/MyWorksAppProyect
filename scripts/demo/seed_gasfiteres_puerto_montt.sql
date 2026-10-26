-- =============================================================================
-- DEMO / TEST. No es una migración.
-- 9 gasfíteres extra en Puerto Montt, con coordenadas distintas, para el
-- radar/mapa y el filtro por calificación.
--   3 bajo la media (2.5, 3.0, 3.4)
--   3 en la media   (4.0, 4.1, 4.2)
--   3 sobre la media (4.6, 4.8, 4.9)
-- Contraseña: Demo2026!
-- Reejecutar es seguro: actualiza las mismas 9 cuentas.
-- =============================================================================

BEGIN;

DO $pm$
DECLARE
  v_hash text;
  v_now text := to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US');
  v_svc text;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'trabajadores'
      AND column_name = 'latitud_base'
  ) THEN
    RAISE EXCEPTION 'Falta latitud_base. Aplica las migraciones de GPS antes de este seed.';
  END IF;

  BEGIN
    v_hash := extensions.crypt('Demo2026!', extensions.gen_salt('bf'));
  EXCEPTION
    WHEN undefined_function THEN
      v_hash := crypt('Demo2026!', gen_salt('bf'));
  END;

  CREATE TEMP TABLE demo_cuentas_pm (
    email text PRIMARY KEY,
    uid uuid NOT NULL,
    nombre text NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO demo_cuentas_pm (email, uid, nombre) VALUES
    ('oscar.nunez@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000201', 'Óscar Núñez'),
    ('beatriz.soto@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000202', 'Beatriz Soto'),
    ('manuel.almonacid@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000203', 'Manuel Almonacid'),
    ('lorena.cayun@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000204', 'Lorena Cayún'),
    ('claudio.barria@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000205', 'Claudio Barría'),
    ('patricia.oyarzun@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000206', 'Patricia Oyarzún'),
    ('ignacio.mansilla@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000207', 'Ignacio Mansilla'),
    ('valeria.antillanca@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000208', 'Valeria Antillanca'),
    ('ricardo.cheuquepan@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000209', 'Ricardo Cheuquepán');

  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
  )
  SELECT
    '00000000-0000-0000-0000-000000000000',
    c.uid,
    'authenticated',
    'authenticated',
    c.email,
    v_hash,
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('nombre', c.nombre, 'role', 'especialista'),
    now(),
    now(),
    '',
    '',
    '',
    ''
  FROM demo_cuentas_pm c
  WHERE NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE lower(u.email) = c.email
  );

  UPDATE auth.users u
  SET
    encrypted_password = v_hash,
    email_confirmed_at = COALESCE(u.email_confirmed_at, now()),
    raw_user_meta_data = jsonb_build_object('nombre', c.nombre, 'role', 'especialista'),
    updated_at = now()
  FROM demo_cuentas_pm c
  WHERE lower(u.email) = c.email;

  UPDATE demo_cuentas_pm c
  SET uid = u.id
  FROM auth.users u
  WHERE lower(u.email) = c.email;

  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
  )
  SELECT
    gen_random_uuid(),
    c.uid,
    jsonb_build_object('sub', c.uid::text, 'email', c.email, 'email_verified', true),
    'email',
    c.uid::text,
    now(),
    now(),
    now()
  FROM demo_cuentas_pm c
  WHERE NOT EXISTS (
    SELECT 1 FROM auth.identities i
    WHERE i.user_id = c.uid AND i.provider = 'email'
  );

  ALTER TABLE public.perfiles DISABLE TRIGGER protect_profiles_sensitive;
  BEGIN
    INSERT INTO public.perfiles (id, nombre, correo, rol, estado_cuenta, creado_en)
    SELECT c.uid, c.nombre, c.email, 'trabajador', 'activo', v_now
    FROM demo_cuentas_pm c
    ON CONFLICT (id) DO UPDATE SET
      nombre = EXCLUDED.nombre,
      correo = EXCLUDED.correo,
      rol = EXCLUDED.rol,
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
      nota_verificacion, latitud_base, longitud_base, radio_servicio_km, origen_base
    )
    SELECT
      c.uid, v.profesion, v.descripcion, v.calificacion, 1, v.tarifa,
      'gasfiteria', 1, 'Puerto Montt', 'verificado',
      'Cédula revisada para la demo.', v.lat, v.lng, 7, 'mapa'
    FROM (
      VALUES
        ('oscar.nunez@demo.myworksapp.cl', 'Gasfíter', 'Fugas y llaves en el centro de Puerto Montt.', 2.5, 28000, -41.4718::float8, -72.9396::float8),
        ('beatriz.soto@demo.myworksapp.cl', 'Gasfíter', 'Calefont y conexiones en Angelmó.', 3.0, 29000, -41.4788, -72.9615),
        ('manuel.almonacid@demo.myworksapp.cl', 'Gasfíter', 'Reparaciones de agua en Pelluco.', 3.4, 30000, -41.4874, -72.8993),
        ('lorena.cayun@demo.myworksapp.cl', 'Gasfíter', 'Gasfitería domiciliaria en Mirasol.', 4.0, 32000, -41.4824, -72.9707),
        ('claudio.barria@demo.myworksapp.cl', 'Gasfíter', 'Llaves y desagües en Cardonal.', 4.1, 33000, -41.4623, -72.9925),
        ('patricia.oyarzun@demo.myworksapp.cl', 'Gasfíter', 'Instalaciones en Puerto Montt Alto.', 4.2, 34000, -41.4480, -72.9380),
        ('ignacio.mansilla@demo.myworksapp.cl', 'Gasfíter', 'Gasfitería en Alerce.', 4.6, 36000, -41.3997, -72.9085),
        ('valeria.antillanca@demo.myworksapp.cl', 'Gasfíter', 'Urgencias de agua en Piedra Azul.', 4.8, 37000, -41.4890, -72.8119),
        ('ricardo.cheuquepan@demo.myworksapp.cl', 'Gasfíter', 'Conexiones y calefont en Chamiza.', 4.9, 38000, -41.4499, -72.8148)
    ) AS v(email, profesion, descripcion, calificacion, tarifa, lat, lng)
    JOIN demo_cuentas_pm c ON c.email = v.email
    ON CONFLICT (id_usuario) DO UPDATE SET
      profesion = EXCLUDED.profesion,
      descripcion = EXCLUDED.descripcion,
      calificacion = EXCLUDED.calificacion,
      disponible = 1,
      tarifa_visita = EXCLUDED.tarifa_visita,
      categoria_servicio = 'gasfiteria',
      precios_configurados = 1,
      zona_trabajo = 'Puerto Montt',
      estado_verificacion = 'verificado',
      nota_verificacion = EXCLUDED.nota_verificacion,
      latitud_base = EXCLUDED.latitud_base,
      longitud_base = EXCLUDED.longitud_base,
      radio_servicio_km = 7,
      origen_base = 'mapa';
    ALTER TABLE public.trabajadores ENABLE TRIGGER trabajadores_proteger_verificacion;
  EXCEPTION
    WHEN OTHERS THEN
      ALTER TABLE public.trabajadores ENABLE TRIGGER trabajadores_proteger_verificacion;
      RAISE;
  END;

  UPDATE public.trabajadores t
  SET niveles_precio = '{"service_basic":30000,"service_standard":50000,"service_premium":80000}'::jsonb
  FROM demo_cuentas_pm c
  WHERE t.id_usuario = c.uid;

  SELECT id INTO v_svc
  FROM public.servicios
  WHERE categoria = 'gasfiteria' AND COALESCE(activo, 0) = 1
  ORDER BY creado_en NULLS LAST
  LIMIT 1;

  IF v_svc IS NULL THEN
    RAISE EXCEPTION 'No hay un servicio activo de gasfitería.';
  END IF;

  CREATE TEMP TABLE demo_notas_pm (
    slug text,
    email text,
    lat float8,
    lng float8,
    puntajes int[]
  ) ON COMMIT DROP;

  INSERT INTO demo_notas_pm (slug, email, lat, lng, puntajes) VALUES
    ('oscar', 'oscar.nunez@demo.myworksapp.cl', -41.4718, -72.9396, ARRAY[2,2,3,3]),
    ('beatriz', 'beatriz.soto@demo.myworksapp.cl', -41.4788, -72.9615, ARRAY[3,3,3,3]),
    ('manuel', 'manuel.almonacid@demo.myworksapp.cl', -41.4874, -72.8993, ARRAY[3,3,3,4,4]),
    ('lorena', 'lorena.cayun@demo.myworksapp.cl', -41.4824, -72.9707, ARRAY[4,4,4,4,4]),
    ('claudio', 'claudio.barria@demo.myworksapp.cl', -41.4623, -72.9925, ARRAY[4,4,4,4,4,4,4,4,4,5]),
    ('patricia', 'patricia.oyarzun@demo.myworksapp.cl', -41.4480, -72.9380, ARRAY[4,4,4,4,5]),
    ('ignacio', 'ignacio.mansilla@demo.myworksapp.cl', -41.3997, -72.9085, ARRAY[5,5,5,4,4]),
    ('valeria', 'valeria.antillanca@demo.myworksapp.cl', -41.4890, -72.8119, ARRAY[5,5,5,5,4]),
    ('ricardo', 'ricardo.cheuquepan@demo.myworksapp.cl', -41.4499, -72.8148, ARRAY[5,5,5,5,5,5,5,5,5,4]);

  IF to_regclass('public.ubicacion_en_vivo') IS NOT NULL THEN
    DELETE FROM public.ubicacion_en_vivo
    WHERE id_trabajo LIKE 'demo-job-nota-oscar-%'
       OR id_trabajo LIKE 'demo-job-nota-beatriz-%'
       OR id_trabajo LIKE 'demo-job-nota-manuel-%'
       OR id_trabajo LIKE 'demo-job-nota-lorena-%'
       OR id_trabajo LIKE 'demo-job-nota-claudio-%'
       OR id_trabajo LIKE 'demo-job-nota-patricia-%'
       OR id_trabajo LIKE 'demo-job-nota-ignacio-%'
       OR id_trabajo LIKE 'demo-job-nota-valeria-%'
       OR id_trabajo LIKE 'demo-job-nota-ricardo-%';
  END IF;
  IF to_regclass('public.liquidaciones') IS NOT NULL THEN
    DELETE FROM public.liquidaciones
    WHERE id_pago LIKE 'demo-pago-nota-oscar-%'
       OR id_pago LIKE 'demo-pago-nota-beatriz-%'
       OR id_pago LIKE 'demo-pago-nota-manuel-%'
       OR id_pago LIKE 'demo-pago-nota-lorena-%'
       OR id_pago LIKE 'demo-pago-nota-claudio-%'
       OR id_pago LIKE 'demo-pago-nota-patricia-%'
       OR id_pago LIKE 'demo-pago-nota-ignacio-%'
       OR id_pago LIKE 'demo-pago-nota-valeria-%'
       OR id_pago LIKE 'demo-pago-nota-ricardo-%';
  END IF;
  DELETE FROM public.calificaciones
  WHERE id LIKE 'demo-rating-oscar-%'
     OR id LIKE 'demo-rating-beatriz-%'
     OR id LIKE 'demo-rating-manuel-%'
     OR id LIKE 'demo-rating-lorena-%'
     OR id LIKE 'demo-rating-claudio-%'
     OR id LIKE 'demo-rating-patricia-%'
     OR id LIKE 'demo-rating-ignacio-%'
     OR id LIKE 'demo-rating-valeria-%'
     OR id LIKE 'demo-rating-ricardo-%';
  DELETE FROM public.pagos
  WHERE id LIKE 'demo-pago-nota-oscar-%'
     OR id LIKE 'demo-pago-nota-beatriz-%'
     OR id LIKE 'demo-pago-nota-manuel-%'
     OR id LIKE 'demo-pago-nota-lorena-%'
     OR id LIKE 'demo-pago-nota-claudio-%'
     OR id LIKE 'demo-pago-nota-patricia-%'
     OR id LIKE 'demo-pago-nota-ignacio-%'
     OR id LIKE 'demo-pago-nota-valeria-%'
     OR id LIKE 'demo-pago-nota-ricardo-%';
  DELETE FROM public.trabajos
  WHERE id LIKE 'demo-job-nota-oscar-%'
     OR id LIKE 'demo-job-nota-beatriz-%'
     OR id LIKE 'demo-job-nota-manuel-%'
     OR id LIKE 'demo-job-nota-lorena-%'
     OR id LIKE 'demo-job-nota-claudio-%'
     OR id LIKE 'demo-job-nota-patricia-%'
     OR id LIKE 'demo-job-nota-ignacio-%'
     OR id LIKE 'demo-job-nota-valeria-%'
     OR id LIKE 'demo-job-nota-ricardo-%';

  INSERT INTO public.trabajos (
    id, id_usuario, id_trabajador, id_servicio, estado, estado_pago, direccion,
    descripcion, latitud, longitud, modalidad_cobro, creado_en, actualizado_en
  )
  SELECT
    'demo-job-nota-' || n.slug || '-' || g.ord,
    (
      SELECT id FROM public.perfiles
      WHERE correo = CASE WHEN g.ord % 2 = 0
        THEN 'camila.soto@demo.myworksapp.cl'
        ELSE 'andres.pizarro@demo.myworksapp.cl' END
      LIMIT 1
    ),
    c.uid,
    v_svc,
    'completado',
    'liberado',
    'Trabajo cerrado de la demo, Puerto Montt',
    'Visita cerrada para la calificación publicada.',
    n.lat,
    n.lng,
    'precio_fijo',
    v_now,
    v_now
  FROM demo_notas_pm n
  JOIN demo_cuentas_pm c ON c.email = n.email
  JOIN LATERAL unnest(n.puntajes) WITH ORDINALITY AS g(puntaje, ord) ON true;

  INSERT INTO public.pagos (
    id, id_trabajo, monto, moneda, estado, tipo_pago, metodo_pago, creado_en, actualizado_en
  )
  SELECT
    'demo-pago-nota-' || n.slug || '-' || g.ord,
    'demo-job-nota-' || n.slug || '-' || g.ord,
    25000,
    'CLP',
    'liberado',
    'principal',
    'webpay',
    v_now,
    v_now
  FROM demo_notas_pm n
  JOIN LATERAL unnest(n.puntajes) WITH ORDINALITY AS g(puntaje, ord) ON true;

  INSERT INTO public.calificaciones (id, id_trabajo, id_usuario, puntaje, comentario, creado_en)
  SELECT
    'demo-rating-' || n.slug || '-' || g.ord,
    'demo-job-nota-' || n.slug || '-' || g.ord,
    (
      SELECT id FROM public.perfiles
      WHERE correo = CASE WHEN g.ord % 2 = 0
        THEN 'camila.soto@demo.myworksapp.cl'
        ELSE 'andres.pizarro@demo.myworksapp.cl' END
      LIMIT 1
    ),
    g.puntaje,
    'Trabajo de la demo en Puerto Montt.',
    v_now
  FROM demo_notas_pm n
  JOIN LATERAL unnest(n.puntajes) WITH ORDINALITY AS g(puntaje, ord) ON true;

  UPDATE public.trabajadores w
  SET calificacion = src.promedio
  FROM (
    SELECT t.id_trabajador AS id_usuario,
           round(avg(c.puntaje)::numeric, 2) AS promedio
    FROM public.calificaciones c
    JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
    JOIN demo_cuentas_pm d ON d.uid::text = t.id_trabajador::text
    GROUP BY t.id_trabajador
  ) src
  WHERE w.id_usuario::text = src.id_usuario::text;

  IF to_regprocedure('public.refrescar_ranking_todos()') IS NOT NULL THEN
    PERFORM public.refrescar_ranking_todos();
  END IF;
END
$pm$;

COMMIT;

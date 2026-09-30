-- =============================================================================
-- DEMO / TEST. No es una migración. No corre en producción sola.
-- Proyecto: wxqrfcqifkfgawrnqmnj
-- Aplicar en el SQL Editor DESPUÉS de las migraciones de GPS y de las de
-- 20261007. Si ya corriste 20261008000001, este script sigue siendo válido:
-- entra como postgres, sin JWT.
-- Contraseña de todas las cuentas: Demo2026!
-- Reejecutar deja las mismas cuentas y reinicia solo filas id demo-*.
-- =============================================================================

BEGIN;

DO $demo$
DECLARE
  v_hash text;
  v_now text := to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US');
  v_svc_plomeria text;
  v_svc_electricidad text;
  v_svc_pintura text;
  v_svc_construccion text;
  v_svc_limpieza text;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'trabajadores'
      AND column_name = 'latitud_base'
  ) THEN
    RAISE EXCEPTION 'Falta latitud_base. Aplica 20261006000001_gps_y_base_profesional.sql antes de este seed.';
  END IF;

  BEGIN
    v_hash := extensions.crypt('Demo2026!', extensions.gen_salt('bf'));
  EXCEPTION
    WHEN undefined_function THEN
      v_hash := crypt('Demo2026!', gen_salt('bf'));
  END;

  CREATE TEMP TABLE demo_cuentas (
    email text PRIMARY KEY,
    uid uuid NOT NULL,
    nombre text NOT NULL,
    rol text NOT NULL,
    meta_role text NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO demo_cuentas (email, uid, nombre, rol, meta_role) VALUES
    ('camila.soto@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000001', 'Camila Soto', 'usuario', 'cliente'),
    ('andres.pizarro@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000002', 'Andrés Pizarro', 'usuario', 'cliente'),
    ('pedro.rojas@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000101', 'Pedro Rojas', 'trabajador', 'especialista'),
    ('maria.fuentes@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000102', 'María Fuentes', 'trabajador', 'especialista'),
    ('jose.munoz@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000103', 'José Muñoz', 'trabajador', 'especialista'),
    ('tomas.herrera@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000104', 'Tomás Herrera', 'trabajador', 'especialista'),
    ('ana.vidal@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000105', 'Ana Vidal', 'trabajador', 'especialista'),
    ('luis.contreras@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000106', 'Luis Contreras', 'trabajador', 'especialista'),
    ('admin.ops@demo.myworksapp.cl', '11111111-1111-4111-8111-000000000901', 'Valentina Riquelme', 'administrador', 'usuario');

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
    jsonb_build_object('nombre', c.nombre, 'role', c.meta_role),
    now(),
    now(),
    '',
    '',
    '',
    ''
  FROM demo_cuentas c
  WHERE NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE lower(u.email) = c.email
  );

  UPDATE auth.users u
  SET
    encrypted_password = v_hash,
    email_confirmed_at = COALESCE(u.email_confirmed_at, now()),
    raw_user_meta_data = jsonb_build_object('nombre', c.nombre, 'role', c.meta_role),
    updated_at = now()
  FROM demo_cuentas c
  WHERE lower(u.email) = c.email;

  UPDATE demo_cuentas c
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
  FROM demo_cuentas c
  WHERE NOT EXISTS (
    SELECT 1 FROM auth.identities i
    WHERE i.user_id = c.uid AND i.provider = 'email'
  );

  -- handle_new_user deja el perfil en 'usuario'. El trigger impide cambiar el rol
  -- si no eres admin ni service_role. El seed corre como postgres, sin JWT.
  ALTER TABLE public.perfiles DISABLE TRIGGER protect_profiles_sensitive;
  BEGIN
    INSERT INTO public.perfiles (id, nombre, correo, rol, estado_cuenta, creado_en)
    SELECT c.uid, c.nombre, c.email, c.rol, 'activo', v_now
    FROM demo_cuentas c
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
    c.uid, v.profesion, v.descripcion, v.calificacion, v.disponible, v.tarifa,
    v.categoria, 1, v.zona, v.verificacion, v.nota, v.lat, v.lng, v.radio, 'mapa'
  FROM (
    VALUES
      ('pedro.rojas@demo.myworksapp.cl', 'Gasfíter', 'Fugas, llaves y calefont en el sector oriente.', 4.8, 1, 35000, 'plomeria', 'Providencia', 'verificado', 'Cédula revisada para la demo.', -33.4314::float8, -70.6093::float8, 12),
      ('maria.fuentes@demo.myworksapp.cl', 'Electricista', 'Tableros, enchufes y fallas domiciliarias.', 4.9, 1, 42000, 'electricidad', 'Las Condes', 'verificado', 'Cédula revisada para la demo.', -33.4172, -70.5476, 15),
      ('jose.munoz@demo.myworksapp.cl', 'Pintor', 'Interiores y fachadas en el sur de Santiago.', 4.6, 1, 28000, 'pintura', 'La Florida', 'verificado', 'Cédula revisada para la demo.', -33.5225, -70.5980, 18),
      ('tomas.herrera@demo.myworksapp.cl', 'Maestro', 'Obras menores y albañilería.', 4.7, 1, 45000, 'construccion', 'Maipú', 'verificado', 'Cédula revisada para la demo.', -33.5111, -70.7580, 20),
      ('ana.vidal@demo.myworksapp.cl', 'Aseo hogar', 'Limpieza de departamentos y casas.', 4.9, 1, 25000, 'limpieza', 'Ñuñoa', 'verificado', 'Cédula revisada para la demo.', -33.4569, -70.5978, 10),
      ('luis.contreras@demo.myworksapp.cl', 'Gasfíter', 'En revisión: aún no toma pedidos.', 0, 0, 30000, 'plomeria', 'Santiago', 'en_revision', 'Documento de demo pendiente de aprobación.', -33.4489, -70.6693, 15)
  ) AS v(email, profesion, descripcion, calificacion, disponible, tarifa, categoria, zona, verificacion, nota, lat, lng, radio)
  JOIN demo_cuentas c ON c.email = v.email
  ON CONFLICT (id_usuario) DO UPDATE SET
    profesion = EXCLUDED.profesion,
    descripcion = EXCLUDED.descripcion,
    calificacion = EXCLUDED.calificacion,
    disponible = EXCLUDED.disponible,
    tarifa_visita = EXCLUDED.tarifa_visita,
    categoria_servicio = EXCLUDED.categoria_servicio,
    precios_configurados = 1,
    zona_trabajo = EXCLUDED.zona_trabajo,
    estado_verificacion = EXCLUDED.estado_verificacion,
    nota_verificacion = EXCLUDED.nota_verificacion,
    latitud_base = EXCLUDED.latitud_base,
    longitud_base = EXCLUDED.longitud_base,
    radio_servicio_km = EXCLUDED.radio_servicio_km,
    origen_base = 'mapa';
  ALTER TABLE public.trabajadores ENABLE TRIGGER trabajadores_proteger_verificacion;
  EXCEPTION
    WHEN OTHERS THEN
      ALTER TABLE public.trabajadores ENABLE TRIGGER trabajadores_proteger_verificacion;
      RAISE;
  END;

  UPDATE public.trabajadores t
  SET disponible = 0
  FROM public.perfiles p
  WHERE p.id = t.id_usuario
    AND COALESCE(p.correo, '') NOT ILIKE '%@demo.myworksapp.cl';

  IF EXISTS (
    SELECT 1
    FROM (
      VALUES ('plomeria'), ('electricidad'), ('pintura'), ('construccion'), ('limpieza')
    ) AS c(categoria)
    WHERE NOT EXISTS (
      SELECT 1
      FROM public.trabajadores t
      JOIN public.perfiles p ON p.id = t.id_usuario
      WHERE t.categoria_servicio = c.categoria
        AND COALESCE(t.disponible, 0) = 1
        AND t.estado_verificacion = 'verificado'
        AND p.correo ILIKE '%@demo.myworksapp.cl'
        AND t.latitud_base IS NOT NULL
        AND t.longitud_base IS NOT NULL
    )
  ) THEN
    RAISE EXCEPTION 'Falta un profesional demo verificado y disponible en Santiago para alguna categoría.';
  END IF;

  INSERT INTO public.servicios (
    id, nombre, descripcion, categoria, activo,
    requiere_certificacion, modelo_precio, creado_en, actualizado_en
  )
  SELECT v.id, v.nombre, v.descripcion, v.categoria, 1, 0, 'por_hora', v_now, v_now
  FROM (
    VALUES
      ('svc-demo-plomeria', 'Gasfitería y plomería', 'Reparaciones de agua.', 'plomeria'),
      ('svc-demo-electricidad', 'Electricidad domiciliaria', 'Fallas e instalaciones.', 'electricidad'),
      ('svc-demo-pintura', 'Pintura', 'Interiores y fachadas.', 'pintura'),
      ('svc-demo-construccion', 'Construcción y albañilería', 'Obras menores.', 'construccion'),
      ('svc-demo-limpieza', 'Limpieza e higiene', 'Casas y departamentos.', 'limpieza')
  ) AS v(id, nombre, descripcion, categoria)
  WHERE NOT EXISTS (
    SELECT 1 FROM public.servicios s WHERE s.categoria = v.categoria
  );

  SELECT id INTO v_svc_plomeria FROM public.servicios WHERE categoria = 'plomeria' ORDER BY activo DESC LIMIT 1;
  SELECT id INTO v_svc_electricidad FROM public.servicios WHERE categoria = 'electricidad' ORDER BY activo DESC LIMIT 1;
  SELECT id INTO v_svc_pintura FROM public.servicios WHERE categoria = 'pintura' ORDER BY activo DESC LIMIT 1;
  SELECT id INTO v_svc_construccion FROM public.servicios WHERE categoria = 'construccion' ORDER BY activo DESC LIMIT 1;
  SELECT id INTO v_svc_limpieza FROM public.servicios WHERE categoria = 'limpieza' ORDER BY activo DESC LIMIT 1;

  IF v_svc_plomeria IS NULL OR v_svc_electricidad IS NULL OR v_svc_pintura IS NULL
     OR v_svc_construccion IS NULL OR v_svc_limpieza IS NULL THEN
    RAISE EXCEPTION 'No se pudieron crear los servicios de la demo.';
  END IF;

  IF to_regclass('public.ubicacion_en_vivo') IS NOT NULL THEN
    DELETE FROM public.ubicacion_en_vivo WHERE id_trabajo LIKE 'demo-%';
  END IF;
  IF to_regclass('public.liquidaciones') IS NOT NULL THEN
    DELETE FROM public.liquidaciones
    WHERE id_pago LIKE 'demo-%' OR id_trabajo LIKE 'demo-%';
  END IF;
  DELETE FROM public.mensajes WHERE id LIKE 'demo-%';
  DELETE FROM public.calificaciones WHERE id LIKE 'demo-%';
  DELETE FROM public.disputas WHERE id LIKE 'demo-%';
  DELETE FROM public.notificaciones WHERE id LIKE 'demo-%';
  DELETE FROM public.pagos WHERE id LIKE 'demo-%';
  DELETE FROM public.trabajos WHERE id LIKE 'demo-%';

  INSERT INTO public.trabajos (
    id, id_usuario, id_trabajador, id_servicio, estado, estado_pago, direccion,
    descripcion, latitud, longitud, modalidad_cobro, creado_en, actualizado_en
  )
  SELECT
    v.id,
    (SELECT uid FROM demo_cuentas WHERE email = v.cliente),
    (SELECT uid FROM demo_cuentas WHERE email = v.pro),
    v.servicio,
    v.estado,
    'retenido',
    v.direccion,
    v.descripcion,
    v.lat,
    v.lng,
    'precio_fijo',
    v_now,
    v_now
  FROM (
    VALUES
      ('demo-job-pendiente', 'camila.soto@demo.myworksapp.cl', 'pedro.rojas@demo.myworksapp.cl', v_svc_plomeria, 'pendiente', 'Av. Irarrázaval 3456, Ñuñoa', 'Fuga bajo el lavaplatos.', -33.4569::float8, -70.5978::float8),
      ('demo-job-aceptado', 'andres.pizarro@demo.myworksapp.cl', 'maria.fuentes@demo.myworksapp.cl', v_svc_electricidad, 'aceptado', 'Av. Apoquindo 4500, Las Condes', 'Enchufe del living sin corriente.', -33.4172, -70.5476),
      ('demo-job-en-camino', 'camila.soto@demo.myworksapp.cl', 'pedro.rojas@demo.myworksapp.cl', v_svc_plomeria, 'en_camino', 'Av. Irarrázaval 2800, Ñuñoa', 'Cambio de llave de cocina.', -33.4540, -70.6010),
      ('demo-job-en-curso', 'andres.pizarro@demo.myworksapp.cl', 'jose.munoz@demo.myworksapp.cl', COALESCE(v_svc_pintura, v_svc_plomeria), 'en_curso', 'Walker Martínez 1200, La Florida', 'Pintura del dormitorio principal.', -33.5225, -70.5980),
      ('demo-job-conforme', 'camila.soto@demo.myworksapp.cl', 'ana.vidal@demo.myworksapp.cl', v_svc_limpieza, 'esperando_aprobacion_cliente', 'Pedro de Valdivia 3200, Ñuñoa', 'Limpieza profunda del departamento.', -33.4569, -70.5978),
      ('demo-job-cerrado', 'andres.pizarro@demo.myworksapp.cl', 'tomas.herrera@demo.myworksapp.cl', COALESCE(v_svc_construccion, v_svc_plomeria), 'completado', 'Av. Pajaritos 2500, Maipú', 'Reparación de muro interior.', -33.5111, -70.7580),
      ('demo-job-disputa', 'camila.soto@demo.myworksapp.cl', 'maria.fuentes@demo.myworksapp.cl', v_svc_electricidad, 'en_curso', 'Av. Providencia 2100, Providencia', 'El automático salta al encender el horno.', -33.4314, -70.6093)
  ) AS v(id, cliente, pro, servicio, estado, direccion, descripcion, lat, lng);

  UPDATE public.trabajos
  SET estado_pago = 'liberado'
  WHERE id = 'demo-job-cerrado';

  INSERT INTO public.pagos (
    id, id_trabajo, monto, moneda, estado, tipo_pago, metodo_pago, creado_en, actualizado_en
  )
  SELECT
    'demo-pago-' || right(t.id, 12),
    t.id,
    CASE t.id
      WHEN 'demo-job-pendiente' THEN 35000
      WHEN 'demo-job-aceptado' THEN 42000
      WHEN 'demo-job-en-camino' THEN 35000
      WHEN 'demo-job-en-curso' THEN 28000
      WHEN 'demo-job-conforme' THEN 25000
      WHEN 'demo-job-cerrado' THEN 45000
      ELSE 42000
    END,
    'CLP',
    CASE WHEN t.id = 'demo-job-cerrado' THEN 'liberado' ELSE 'retenido' END,
    'principal',
    'webpay',
    v_now,
    v_now
  FROM public.trabajos t
  WHERE t.id LIKE 'demo-job-%';

  INSERT INTO public.ubicacion_en_vivo (
    id_trabajo, id_trabajador, latitud, longitud, precision_metros, actualizado_en
  )
  SELECT
    'demo-job-en-camino',
    (SELECT uid FROM demo_cuentas WHERE email = 'pedro.rojas@demo.myworksapp.cl'),
    -33.4480,
    -70.6120,
    18,
    now();

  INSERT INTO public.mensajes (
    id, id_trabajo, id_remitente, id_destinatario, contenido, leido, tipo, creado_en
  ) VALUES
    (
      'demo-msg-1',
      'demo-job-en-curso',
      (SELECT uid FROM demo_cuentas WHERE email = 'jose.munoz@demo.myworksapp.cl'),
      (SELECT uid FROM demo_cuentas WHERE email = 'andres.pizarro@demo.myworksapp.cl'),
      'Ya estoy en el dormitorio. El color es el blanco que dejaste en la bolsa.',
      0,
      'texto',
      v_now
    ),
    (
      'demo-msg-2',
      'demo-job-en-curso',
      (SELECT uid FROM demo_cuentas WHERE email = 'andres.pizarro@demo.myworksapp.cl'),
      (SELECT uid FROM demo_cuentas WHERE email = 'jose.munoz@demo.myworksapp.cl'),
      'Perfecto. Cualquier mancha del marco me avisas.',
      1,
      'texto',
      v_now
    );

  INSERT INTO public.calificaciones (id, id_trabajo, id_usuario, puntaje, comentario, creado_en)
  VALUES (
    'demo-rating-1',
    'demo-job-cerrado',
    (SELECT uid FROM demo_cuentas WHERE email = 'andres.pizarro@demo.myworksapp.cl'),
    5,
    'El muro quedó parejo y se llevó los escombros.',
    v_now
  );

  INSERT INTO public.disputas (
    id, id_trabajo, abierta_por, motivo, descripcion, estado, creado_en, actualizado_en
  ) VALUES (
    'demo-disputa-1',
    'demo-job-disputa',
    (SELECT uid FROM demo_cuentas WHERE email = 'camila.soto@demo.myworksapp.cl'),
    'trabajo_incompleto',
    'El automático sigue saltando después de la visita.',
    'abierta',
    v_now,
    v_now
  );

  INSERT INTO public.notificaciones (
    id, id_usuario, titulo, cuerpo, tipo, leido, id_relacionado, creado_en
  )
  SELECT
    'demo-notif-pedro',
    (SELECT uid FROM demo_cuentas WHERE email = 'pedro.rojas@demo.myworksapp.cl'),
    'Nuevo pedido',
    'Camila Soto pidió un gasfíter en Ñuñoa.',
    'trabajo',
    0,
    'demo-job-pendiente',
    v_now;
END
$demo$;

COMMIT;

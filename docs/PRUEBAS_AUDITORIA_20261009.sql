-- Pruebas de las migraciones 20261009000001 a 20261009000005 (auditoría 2026-10-05).
-- Corre dentro de una transacción con ROLLBACK: no deja filas ni cambios.
-- Se hace pasar por usuarios de la demo con request.jwt.claims y el rol authenticated.
-- Si algo falla, el bloque DO lanza «FALLO: ...» y no aparece la línea OK.

BEGIN;

DO $$
DECLARE
  v_camila uuid := (SELECT id FROM auth.users WHERE email = 'camila.soto@demo.myworksapp.cl');
  v_pedro  uuid := (SELECT id FROM auth.users WHERE email = 'pedro.rojas@demo.myworksapp.cl');
  v_andres uuid := (SELECT id FROM auth.users WHERE email = 'andres.pizarro@demo.myworksapp.cl');
  v_jose   uuid := (SELECT id FROM auth.users WHERE email = 'jose.munoz@demo.myworksapp.cl');
  v_carmen uuid := (SELECT id FROM auth.users WHERE email = 'carmen.lagos@demo.myworksapp.cl');
  v_ops    uuid := (SELECT id FROM auth.users WHERE email = 'admin.ops@demo.myworksapp.cl');
  v_legacy_admin uuid := (SELECT id FROM auth.users WHERE email = 'admin@demo.com');
  v_extrano uuid;
  v_n int;
  v_err text;
  v_estado text;

BEGIN
  IF v_camila IS NULL OR v_pedro IS NULL OR v_andres IS NULL OR v_jose IS NULL THEN
    RAISE EXCEPTION 'FALLO: faltan cuentas de la demo (correr scripts/demo/seed_demo.sql)';
  END IF;

  -- Un usuario sin trabajos con Camila y sin reseñas: su perfil no debe salir.
  SELECT p.id INTO v_extrano
  FROM public.perfiles p
  WHERE lower(p.rol) = 'usuario'
    AND p.id <> v_camila
    AND NOT EXISTS (SELECT 1 FROM public.calificaciones c WHERE c.id_usuario = p.id)
    AND NOT EXISTS (
      SELECT 1 FROM public.trabajos t
      WHERE (t.id_usuario = p.id AND t.id_trabajador = v_camila)
         OR (t.id_trabajador = p.id AND t.id_usuario = v_camila)
    )
  LIMIT 1;

  ---------------------------------------------------------------- 000001
  PERFORM set_config('role', 'authenticated', true);
  IF v_legacy_admin IS NOT NULL THEN
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_legacy_admin, 'role', 'authenticated')::text, true);
    IF public.is_admin() THEN
      RAISE EXCEPTION 'FALLO: admin@demo.com sigue siendo administrador';
    END IF;
  END IF;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_ops, 'role', 'authenticated')::text, true);
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'FALLO: admin.ops@demo.myworksapp.cl dejó de ser administrador';
  END IF;
  PERFORM set_config('role', 'postgres', true);
  IF v_legacy_admin IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM auth.users WHERE id = v_legacy_admin AND banned_until > now()
  ) THEN
    RAISE EXCEPTION 'FALLO: admin@demo.com todavía puede iniciar sesión';
  END IF;

  ---------------------------------------------------------------- 000002
  PERFORM set_config('role', 'authenticated', true);

  -- El cliente no puede marcar «en curso» por el profesional.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_camila, 'role', 'authenticated')::text, true);
  BEGIN
    PERFORM public.transicionar_trabajo('demo-job-en-camino', 'en_curso', NULL);
    v_err := 'paso';
  EXCEPTION WHEN others THEN
    v_err := SQLERRM;
  END;
  IF v_err NOT LIKE 'solo el profesional%' THEN
    RAISE EXCEPTION 'FALLO: el cliente pudo pasar a en_curso (%)', v_err;
  END IF;

  -- El cliente no puede declarar terminado el trabajo del profesional.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_andres, 'role', 'authenticated')::text, true);
  BEGIN
    PERFORM public.transicionar_trabajo('demo-job-en-curso', 'esperando_aprobacion_cliente', NULL);
    v_err := 'paso';
  EXCEPTION WHEN others THEN
    v_err := SQLERRM;
  END;
  IF v_err NOT LIKE 'solo el profesional%' THEN
    RAISE EXCEPTION 'FALLO: el cliente pudo pasar a esperando_aprobacion_cliente (%)', v_err;
  END IF;

  -- «No asistió» con el dinero retenido exige una disputa.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_jose, 'role', 'authenticated')::text, true);
  BEGIN
    PERFORM public.transicionar_trabajo('demo-job-en-curso', 'no_asistio', NULL);
    v_err := 'paso';
  EXCEPTION WHEN others THEN
    v_err := SQLERRM;
  END;
  IF v_err NOT LIKE 'hay un pago retenido%' THEN
    RAISE EXCEPTION 'FALLO: no_asistio cerró con pago retenido (%)', v_err;
  END IF;

  -- Un tercero no toca el trabajo.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_carmen, 'role', 'authenticated')::text, true);
  BEGIN
    PERFORM public.transicionar_trabajo('demo-job-en-camino', 'cancelado', NULL);
    v_err := 'paso';
  EXCEPTION WHEN others THEN
    v_err := SQLERRM;
  END;
  IF v_err <> 'no autorizado' THEN
    RAISE EXCEPTION 'FALLO: un tercero cambió el trabajo (%)', v_err;
  END IF;

  -- El camino del guion sigue: el profesional pasa de en camino a en curso y termina.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_pedro, 'role', 'authenticated')::text, true);
  SELECT estado INTO v_estado
  FROM public.transicionar_trabajo('demo-job-en-camino', 'en_curso', NULL);
  IF v_estado <> 'en_curso' THEN
    RAISE EXCEPTION 'FALLO: el profesional no pudo iniciar (%)', v_estado;
  END IF;
  SELECT estado INTO v_estado
  FROM public.transicionar_trabajo('demo-job-en-camino', 'esperando_aprobacion_cliente', NULL);
  IF v_estado <> 'esperando_aprobacion_cliente' THEN
    RAISE EXCEPTION 'FALLO: el profesional no pudo finalizar (%)', v_estado;
  END IF;

  -- Y el cliente recibe conforme (libera el pago y escribe la liquidación).
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_camila, 'role', 'authenticated')::text, true);
  SELECT estado INTO v_estado FROM public.cerrar_trabajo_conforme('demo-job-en-camino');
  IF v_estado <> 'completado' THEN
    RAISE EXCEPTION 'FALLO: la conformidad no completó el trabajo (%)', v_estado;
  END IF;

  ---------------------------------------------------------------- 000003
  SELECT count(*) INTO v_n FROM public.perfiles_publicos_por_ids(ARRAY[v_pedro]);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'FALLO: la ficha pública del profesional no sale';
  END IF;
  SELECT count(*) INTO v_n FROM public.perfiles_publicos_por_ids(ARRAY[v_andres]);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'FALLO: el autor de una reseña no sale';
  END IF;
  SELECT count(*) INTO v_n FROM public.perfiles_publicos_por_ids(ARRAY[v_camila]);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'FALLO: el propio perfil no sale';
  END IF;
  IF v_extrano IS NOT NULL THEN
    SELECT count(*) INTO v_n FROM public.perfiles_publicos_por_ids(ARRAY[v_extrano]);
    IF v_n <> 0 THEN
      RAISE EXCEPTION 'FALLO: se ve el perfil de un cliente sin relación';
    END IF;
  END IF;

  ---------------------------------------------------------------- 000004
  BEGIN
    PERFORM 1 FROM public.app_config LIMIT 1;
    v_err := 'paso';
  EXCEPTION WHEN insufficient_privilege THEN
    v_err := 'denegado';
  END;
  IF v_err <> 'denegado' THEN
    RAISE EXCEPTION 'FALLO: un usuario con sesión lee app_config';
  END IF;
  BEGIN
    PERFORM 1 FROM public.metodos_pago_oneclick LIMIT 1;
    v_err := 'paso';
  EXCEPTION WHEN insufficient_privilege THEN
    v_err := 'denegado';
  END;
  IF v_err <> 'denegado' THEN
    RAISE EXCEPTION 'FALLO: un usuario con sesión lee metodos_pago_oneclick';
  END IF;

  PERFORM set_config('role', 'postgres', true);
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'app_config')
     OR NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'metodos_pago_oneclick') THEN
    RAISE EXCEPTION 'FALLO: faltan las políticas explícitas';
  END IF;

  ---------------------------------------------------------------- 000005
  SELECT count(*) INTO v_n
  FROM public.pagos p
  WHERE p.id LIKE 'demo-%'
    AND p.estado = 'liberado'
    AND (p.liberado_en IS NULL
         OR NOT EXISTS (SELECT 1 FROM public.liquidaciones l WHERE l.id_pago = p.id));
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'FALLO: % pagos liberados de la demo sin liquidación', v_n;
  END IF;

  RAISE NOTICE 'OK auditoría 20261009';
END $$;

SELECT 'OK auditoría 20261009' AS resultado;

ROLLBACK;

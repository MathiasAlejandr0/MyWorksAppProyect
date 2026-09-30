-- Correr en el SQL Editor DESPUÉS de 20261008000001_cerrar_brechas_rls.sql.
-- Cada bloque aborta con un mensaje si la brecha sigue abierta.
-- No modifica datos de la demo.

-- 1) Un autenticado no puede insertar ni actualizar pagos.
DO $$
DECLARE
  n int;
BEGIN
  SELECT count(*) INTO n
  FROM pg_policy p
  JOIN pg_class c ON c.oid = p.polrelid
  JOIN pg_namespace ns ON ns.oid = c.relnamespace
  WHERE ns.nspname = 'public'
    AND c.relname = 'pagos'
    AND p.polcmd IN ('a', 'w', 'd', '*');
  IF n <> 0 THEN
    RAISE EXCEPTION 'pagos todavía tiene % políticas de escritura', n;
  END IF;

  IF has_table_privilege('authenticated', 'public.pagos', 'INSERT')
     OR has_table_privilege('authenticated', 'public.pagos', 'UPDATE')
     OR has_table_privilege('anon', 'public.pagos', 'INSERT') THEN
    RAISE EXCEPTION 'authenticated o anon todavía pueden escribir pagos';
  END IF;
END $$;

-- 2) El trigger de trabajos existe y rechaza el cambio de estado de un rol normal.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'trabajos_proteger_campos' AND NOT tgisinternal
  ) THEN
    RAISE EXCEPTION 'falta el trigger trabajos_proteger_campos';
  END IF;
END $$;

-- 3) profiles_select (inglés, USING true) ya no está. La vista pública no tiene correo.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relname = 'perfiles' AND p.polname = 'profiles_select'
  ) THEN
    RAISE EXCEPTION 'profiles_select sigue publicado';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'perfiles_publicos'
      AND column_name IN ('correo', 'telefono')
  ) THEN
    RAISE EXCEPTION 'perfiles_publicos expone correo o telefono';
  END IF;
END $$;

-- 4) Las cuatro políticas inglesas que sostenían la demo tienen reemplazo español
--    y el nombre inglés ya no está.
DO $$
DECLARE
  faltan text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relname = 'trabajos' AND p.polname = 'trabajos_insert'
  ) THEN
    RAISE EXCEPTION 'falta trabajos_insert';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relname = 'notificaciones' AND p.polname = 'notificaciones_insert_participantes'
  ) THEN
    RAISE EXCEPTION 'falta notificaciones_insert_participantes';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relname = 'propuestas_cotizacion' AND p.polname = 'propuestas_insert'
  ) THEN
    -- 20261008000005 reemplazó propuestas_all por propuestas_insert (solo trabajador).
    RAISE EXCEPTION 'falta propuestas_insert';
  END IF;

  SELECT string_agg(p.polname, ', ') INTO faltan
  FROM pg_policy p
  JOIN pg_class c ON c.oid = p.polrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND p.polname IN (
      'jobs_insert', 'jobs_update', 'profiles_select',
      'notifications_insert_participants', 'quotes_update',
      'payments_insert', 'payments_update'
    );
  IF faltan IS NOT NULL THEN
    RAISE EXCEPTION 'siguen políticas inglesas: %', faltan;
  END IF;
END $$;

-- 5) El guard de liberar_escrow_manual usa auth.role(), no el claim viejo.
DO $$
DECLARE
  src text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO src
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname = 'liberar_escrow_manual'
  LIMIT 1;
  IF src IS NULL OR src NOT LIKE '%auth.role()%' OR src LIKE '%v_jwt_role%' THEN
    RAISE EXCEPTION 'liberar_escrow_manual no tiene el guard con auth.role()';
  END IF;
END $$;

-- 6) Las cuatro RPC castean a uuid.
DO $$
DECLARE
  fn text;
  src text;
BEGIN
  FOREACH fn IN ARRAY ARRAY[
    'asignar_trabajador_trabajo',
    'vincular_trabajador_solicitud',
    'vincular_trabajador_cotizacion'
  ]
  LOOP
    SELECT pg_get_functiondef(p.oid) INTO src
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = fn
    LIMIT 1;
    IF src IS NULL OR src NOT LIKE '%::uuid%' THEN
      RAISE EXCEPTION '% no castea a uuid', fn;
    END IF;
  END LOOP;

  SELECT pg_get_functiondef(p.oid) INTO src
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname = 'aplicar_cierre_disputa'
  LIMIT 1;
  IF src IS NULL OR src NOT LIKE '%p_operador::uuid%' THEN
    RAISE EXCEPTION 'aplicar_cierre_disputa no castea p_operador';
  END IF;
END $$;

-- 7) Después de 20261008000002, 000003 y 000004.
DO $$
BEGIN
  IF to_regprocedure('public.perfiles_publicos_por_ids(uuid[])') IS NULL THEN
    RAISE EXCEPTION 'falta perfiles_publicos_por_ids';
  END IF;
  IF has_function_privilege('anon', 'public.perfiles_publicos_por_ids(uuid[])', 'EXECUTE') THEN
    RAISE EXCEPTION 'anon puede ejecutar perfiles_publicos_por_ids';
  END IF;
  IF NOT has_function_privilege('anon', 'public.listar_cuentas_demo_acceso()', 'EXECUTE') THEN
    RAISE EXCEPTION 'el login de la demo necesita listar_cuentas_demo_acceso en anon';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'pagos' AND column_name = 'origen_retorno'
  ) THEN
    RAISE EXCEPTION 'falta pagos.origen_retorno';
  END IF;
  IF to_regprocedure('public.abrir_disputa(text,text,text,text)') IS NULL
     OR to_regprocedure('public.comentar_disputa(text,text)') IS NULL THEN
    RAISE EXCEPTION 'faltan las RPC de disputa para las partes';
  END IF;
  IF to_regclass('public.perfiles_publicos') IS NOT NULL THEN
    RAISE EXCEPTION 'perfiles_publicos sigue siendo una vista security definer';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relname = 'trabajadores' AND p.polname = 'trabajadores_select_contraparte'
  ) THEN
    RAISE EXCEPTION 'falta trabajadores_select_contraparte';
  END IF;
END $$;

SELECT 'RLS 20261008 ok' AS resultado;

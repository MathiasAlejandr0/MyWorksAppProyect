-- Prueba de 20261120140000_ocultar_profesionales_demo.sql.
-- Corre contra una base local que ya tenga esa migración. No apunta a
-- producción. Abre una transacción y la revierte, incluidos los cambios
-- de demo_modo y de disponible.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/ocultar_profesionales_demo.sql

BEGIN;

DO $$
BEGIN
  IF public.correo_es_demo('maria.fuentes@demo.myworksapp.cl') IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'correo_es_demo no reconoce @demo.myworksapp.cl';
  END IF;
  IF public.correo_es_demo('Ana@DEMO.COM') IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'correo_es_demo no reconoce @demo.com';
  END IF;
  IF public.correo_es_demo('persona@gmail.com') IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'correo_es_demo marcó un correo real';
  END IF;
  IF public.correo_es_demo('sin-arroba') IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'correo_es_demo marcó un texto sin dominio';
  END IF;
  IF public.correo_es_demo(NULL) IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'correo_es_demo marcó NULL';
  END IF;
END $$;

UPDATE public.app_config SET valor = '0' WHERE clave = 'demo_modo';

DO $$
BEGIN
  IF public.demo_modo_activo() IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'demo_modo_activo quedó encendido con valor 0';
  END IF;
  IF public.catalogo_muestra_profesional(true) IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'con demo_modo=0 el catálogo muestra una cuenta demo';
  END IF;
  IF public.catalogo_muestra_profesional(false) IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'con demo_modo=0 el catálogo oculta una cuenta real';
  END IF;
END $$;

DO $$
DECLARE
  v_demo integer;
  v_en_catalogo integer;
  v_offset integer := 0;
  v_pagina integer;
BEGIN
  SELECT count(*) INTO v_demo FROM public.trabajadores WHERE es_demo;
  IF v_demo = 0 THEN
    RAISE NOTICE 'no hay filas es_demo: se omite el barrido del catálogo';
    RETURN;
  END IF;

  LOOP
    SELECT count(*) INTO v_pagina
    FROM public.listar_profesionales_catalogo(NULL, NULL, NULL, NULL, 40, NULL, NULL, v_offset) c
    JOIN public.trabajadores t ON t.id_usuario = c.id_usuario
    WHERE t.es_demo;
    v_en_catalogo := coalesce(v_pagina, 0);
    IF v_en_catalogo <> 0 THEN
      RAISE EXCEPTION 'listar_profesionales_catalogo devolvió % cuentas demo con demo_modo=0 (offset %)', v_en_catalogo, v_offset;
    END IF;
    IF v_pagina IS NULL THEN
      EXIT;
    END IF;
    -- La página completa se mira por el tamaño, no por las demos.
    PERFORM 1
    FROM public.listar_profesionales_catalogo(NULL, NULL, NULL, NULL, 40, NULL, NULL, v_offset);
    GET DIAGNOSTICS v_pagina = ROW_COUNT;
    EXIT WHEN v_pagina < 40 OR v_offset > 2000;
    v_offset := v_offset + 40;
  END LOOP;
END $$;

-- Con el resto oculto, el catálogo en modo 0 no puede devolver demos.
UPDATE public.trabajadores SET disponible = 0 WHERE NOT es_demo;

DO $$
DECLARE
  v_visibles integer;
  v_demo_publicables integer;
BEGIN
  SELECT count(*) INTO v_visibles
  FROM public.listar_profesionales_catalogo(NULL, NULL, NULL, NULL, 40, NULL, NULL, 0);
  IF coalesce(v_visibles, 0) <> 0 THEN
    RAISE EXCEPTION 'con demo_modo=0 y solo demos disponibles, el catálogo devolvió % filas', v_visibles;
  END IF;

  UPDATE public.app_config SET valor = '1' WHERE clave = 'demo_modo';
  IF public.catalogo_muestra_profesional(true) IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'con demo_modo=1 una cuenta demo queda fuera del predicado';
  END IF;

  SELECT count(*) INTO v_demo_publicables
  FROM public.trabajadores t
  WHERE t.es_demo
    AND coalesce(t.disponible, 0) = 1
    AND coalesce(t.precios_configurados, 0) = 1
    AND t.estado_verificacion = 'verificado';

  SELECT count(*) INTO v_visibles
  FROM public.listar_profesionales_catalogo(NULL, NULL, NULL, NULL, 40, NULL, NULL, 0);

  IF v_demo_publicables > 0 AND coalesce(v_visibles, 0) = 0 THEN
    RAISE EXCEPTION 'con demo_modo=1 el catálogo no muestra las cuentas demo publicables';
  END IF;

  UPDATE public.app_config SET valor = '0' WHERE clave = 'demo_modo';
END $$;

DO $$
DECLARE
  v_worker uuid;
  v_client uuid;
  v_servicio text;
  v_ahora text := to_char(clock_timestamp() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"');
BEGIN
  SELECT t.id_usuario INTO v_worker
  FROM public.trabajadores t
  WHERE t.es_demo
  LIMIT 1;
  IF v_worker IS NULL THEN
    RAISE NOTICE 'no hay profesional demo: se omite el bloqueo de reserva y de pago';
    RETURN;
  END IF;
  IF public.profesional_bloqueado_por_demo(v_worker) IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'profesional_bloqueado_por_demo no frena al demo con demo_modo=0';
  END IF;

  SELECT p.id INTO v_client
  FROM public.perfiles p
  WHERE p.id <> v_worker
  LIMIT 1;
  SELECT s.id INTO v_servicio FROM public.servicios s LIMIT 1;
  IF v_client IS NULL OR v_servicio IS NULL THEN
    RAISE NOTICE 'faltan perfil cliente o servicio: se omite el INSERT';
    RETURN;
  END IF;

  BEGIN
    INSERT INTO public.trabajos (
      id, id_usuario, id_trabajador, id_servicio, estado, direccion, creado_en, actualizado_en
    ) VALUES (
      'prueba-demo-reserva', v_client, v_worker, v_servicio, 'pendiente', 'prueba local', v_ahora, v_ahora
    );
    RAISE EXCEPTION 'la reserva de un profesional demo no fue bloqueada';
  EXCEPTION
    WHEN check_violation THEN
      IF SQLERRM NOT LIKE '%no está disponible para reservar%' THEN
        RAISE;
      END IF;
  END;

  UPDATE public.app_config SET valor = '1' WHERE clave = 'demo_modo';
  IF public.profesional_bloqueado_por_demo(v_worker) IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'con demo_modo=1 el profesional demo sigue bloqueado';
  END IF;
  UPDATE public.app_config SET valor = '0' WHERE clave = 'demo_modo';
END $$;

ROLLBACK;

-- Procedencia de video, radio GPS, tope de 30 s / 20 MB y nonce.
-- Transacción con ROLLBACK. No apunta a producción.
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/evidencia_video_captura.sql
-- Requiere la migración 20261124180000_evidencia_video_captura.sql (sin aplicar en prod).

BEGIN;

DO $$
DECLARE
  v_worker uuid := gen_random_uuid();
  v_client uuid := gen_random_uuid();
  v_ahora text := to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"');
  v_hash text := encode(extensions.digest(convert_to('video-prueba-mwa', 'UTF8'), 'sha256'), 'hex');
  v_hash2 text := encode(extensions.digest(convert_to('video-prueba-mwa-2', 'UTF8'), 'sha256'), 'hex');
  v_nonce text;
  v_nonce_lejos text;
  v_nonce_tope text;
  v_reg jsonb;
  v_ruta text := 'trabajos/job-vid-a/prueba/video-a.mp4';
BEGIN
  INSERT INTO auth.users (id, aud, role, email, created_at, updated_at)
  VALUES
    (v_worker, 'authenticated', 'authenticated', 'vid-' || v_worker || '@prueba.test', now(), now()),
    (v_client, 'authenticated', 'authenticated', 'vcli-' || v_client || '@prueba.test', now(), now());
  INSERT INTO public.perfiles (id, nombre, correo, rol, estado_cuenta, creado_en)
  VALUES
    (v_worker, 'Trabajador video', 'vid-' || v_worker || '@prueba.test', 'trabajador', 'activo', v_ahora),
    (v_client, 'Cliente video', 'vcli-' || v_client || '@prueba.test', 'usuario', 'activo', v_ahora);
  INSERT INTO public.trabajos (
    id, id_usuario, id_trabajador, id_servicio, estado, direccion,
    latitud, longitud, creado_en, actualizado_en
  ) VALUES
    ('job-vid-a', v_client, v_worker, 'svc-plomeria', 'en_curso', 'Cardonal 1',
      -41.4717, -72.9366, v_ahora, v_ahora);

  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_worker, 'role', 'authenticated')::text, true);
  PERFORM set_config('request.jwt.claim.sub', v_worker::text, true);

  INSERT INTO public.fotos_trabajo (id, id_trabajo, ruta_foto, creado_en, tipo_medio)
  VALUES
    ('video-a', 'job-vid-a', v_ruta, v_ahora, 'video'),
    ('video-lejos', 'job-vid-a', v_ruta, v_ahora, 'video'),
    ('video-tope', 'job-vid-a', v_ruta, v_ahora, 'video');

  INSERT INTO storage.objects (bucket_id, name, metadata)
  VALUES ('evidencias', v_ruta, jsonb_build_object('mimetype', 'video/mp4', 'size', 2048));

  v_nonce := public.pedir_nonce_evidencia('job-vid-a');
  v_reg := public.registrar_evidencia_video_captura(
    'video-a', 'job-vid-a', v_nonce, v_hash,
    -41.4717, -72.9366, 'antes', 2048, 8, NULL
  );
  IF v_reg->>'confianza' IS DISTINCT FROM 'confiable' THEN
    RAISE EXCEPTION 'el video en el lugar debía ser confiable: %', v_reg;
  END IF;

  BEGIN
    PERFORM public.registrar_evidencia_video_captura(
      'video-a', 'job-vid-a', v_nonce, v_hash,
      -41.4717, -72.9366, 'antes', 2048, 8, NULL
    );
    RAISE EXCEPTION 'un nonce reusado no fue rechazado';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT ILIKE '%nonce ya usado%' THEN
      RAISE;
    END IF;
  END;

  v_nonce_lejos := public.pedir_nonce_evidencia('job-vid-a');
  BEGIN
    PERFORM public.registrar_evidencia_video_captura(
      'video-lejos', 'job-vid-a', v_nonce_lejos, v_hash2,
      -33.45, -70.66, 'despues', 2048, 8, NULL
    );
    RAISE EXCEPTION 'un gps a más de 500 m no fue rechazado';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT ILIKE '%gps fuera de radio%' THEN
      RAISE;
    END IF;
  END;

  v_nonce_tope := public.pedir_nonce_evidencia('job-vid-a');
  BEGIN
    PERFORM public.registrar_evidencia_video_captura(
      'video-tope', 'job-vid-a', v_nonce_tope, v_hash2,
      -41.4717, -72.9366, 'detalle', 2048, 45, NULL
    );
    RAISE EXCEPTION 'un video de más de 30 s no fue rechazado';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT ILIKE '%30 segundos%' THEN
      RAISE;
    END IF;
  END;

  BEGIN
    PERFORM public.registrar_evidencia_video_captura(
      'video-tope', 'job-vid-a', v_nonce_tope, v_hash2,
      -41.4717, -72.9366, 'detalle', 20971521, 8, NULL
    );
    RAISE EXCEPTION 'un video de más de 20 MB no fue rechazado';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT ILIKE '%20 MB%' THEN
      RAISE;
    END IF;
  END;
END;
$$;

ROLLBACK;

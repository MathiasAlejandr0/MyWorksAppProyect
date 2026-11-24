-- Procedencia verificada para videos tomados con la cámara de la app.
-- Tope alineado al plan gratuito de Storage: 30 s (~720p) y 20 MB.
-- NO aplicar en producción hasta que se apruebe esta rama / este PR.

ALTER TABLE public.fotos_trabajo
  ADD COLUMN IF NOT EXISTS duracion_segundos integer;

COMMENT ON COLUMN public.fotos_trabajo.duracion_segundos IS
  'Duración del video de evidencia, en segundos. Nulo en fotos.';

CREATE OR REPLACE FUNCTION public.registrar_evidencia_video_captura(
  p_id_foto text,
  p_id_trabajo text,
  p_nonce text,
  p_hash_sha256 text,
  p_lat double precision,
  p_lng double precision,
  p_tipo text,
  p_bytes integer,
  p_duracion_seg integer,
  p_capturada_en timestamptz
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_nonce public.evidencia_nonces%ROWTYPE;
  v_foto public.fotos_trabajo%ROWTYPE;
  v_job_lat double precision;
  v_job_lng double precision;
  v_dist numeric;
  v_radio numeric;
  v_prev_id text;
  v_prev_trabajo text;
  v_tipo text := lower(btrim(COALESCE(p_tipo, '')));
  v_confianza text := 'confiable';
  v_motivo text := 'procedencia_ok';
  v_hash text := lower(btrim(COALESCE(p_hash_sha256, '')));
BEGIN
  IF v_uid IS NULL OR NOT public.es_parte_trabajo(p_id_trabajo) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_tipo NOT IN ('antes', 'despues', 'detalle') THEN
    RAISE EXCEPTION 'tipo de evidencia no permitido';
  END IF;
  IF v_hash !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION 'hash sha256 invalido';
  END IF;
  IF p_lat IS NULL OR p_lng IS NULL
     OR p_lat < -90 OR p_lat > 90 OR p_lng < -180 OR p_lng > 180 THEN
    RAISE EXCEPTION 'falta el gps de la captura';
  END IF;
  IF p_bytes IS NULL OR p_bytes <= 0 THEN
    RAISE EXCEPTION 'el video está vacío';
  END IF;
  IF p_bytes > 20971520 THEN
    RAISE EXCEPTION 'el video supera el tope de 20 MB';
  END IF;
  IF p_duracion_seg IS NULL OR p_duracion_seg < 1 THEN
    RAISE EXCEPTION 'el video es demasiado corto';
  END IF;
  IF p_duracion_seg > 31 THEN
    RAISE EXCEPTION 'el video no puede durar más de 30 segundos';
  END IF;

  SELECT * INTO v_nonce
  FROM public.evidencia_nonces
  WHERE nonce = btrim(COALESCE(p_nonce, ''))
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'nonce desconocido';
  END IF;
  IF v_nonce.usado_en IS NOT NULL THEN
    RAISE EXCEPTION 'nonce ya usado';
  END IF;
  IF v_nonce.expira_en <= now() THEN
    RAISE EXCEPTION 'nonce vencido';
  END IF;
  IF v_nonce.id_trabajo::text <> btrim(p_id_trabajo) OR v_nonce.id_usuario <> v_uid THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_capturada_en IS NOT NULL AND (
    p_capturada_en < v_nonce.creado_en - interval '1 minute'
    OR p_capturada_en > now() + interval '2 minutes'
  ) THEN
    RAISE EXCEPTION 'la captura está fuera de la ventana de tiempo';
  END IF;

  SELECT * INTO v_foto
  FROM public.fotos_trabajo
  WHERE id::text = btrim(p_id_foto)
    AND id_trabajo::text = btrim(p_id_trabajo);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'la evidencia no está registrada';
  END IF;
  IF COALESCE(v_foto.tipo_medio, '') <> 'video' THEN
    RAISE EXCEPTION 'la evidencia no es un video';
  END IF;
  IF v_foto.ruta_foto IS NULL OR btrim(v_foto.ruta_foto) = '' THEN
    RAISE EXCEPTION 'falta la ruta del video';
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM storage.objects o
    WHERE o.bucket_id = 'evidencias'
      AND o.name = v_foto.ruta_foto
  ) THEN
    RAISE EXCEPTION 'el video no está en el almacenamiento';
  END IF;

  SELECT t.latitud, t.longitud INTO v_job_lat, v_job_lng
  FROM public.trabajos t
  WHERE t.id::text = btrim(p_id_trabajo);
  IF v_job_lat IS NULL OR v_job_lng IS NULL THEN
    RAISE EXCEPTION 'el trabajo no tiene coordenadas';
  END IF;
  v_dist := public.distancia_metros(p_lat, p_lng, v_job_lat, v_job_lng);
  v_radio := public.soporte_numero('soporte_radio_evidencia_m', 500);
  IF v_dist > v_radio THEN
    RAISE EXCEPTION 'gps fuera de radio';
  END IF;

  SELECT f.id::text, f.id_trabajo::text INTO v_prev_id, v_prev_trabajo
  FROM public.fotos_trabajo f
  WHERE f.id::text <> btrim(p_id_foto)
    AND f.hash_sha256 IS NOT NULL
    AND lower(f.hash_sha256) = v_hash
  ORDER BY f.creado_en
  LIMIT 1;

  IF v_prev_id IS NOT NULL THEN
    v_confianza := 'no_verificada';
    v_motivo := 'evidencia_duplicada';
  END IF;

  PERFORM set_config('mwa.evidencia_servidor', '1', true);
  UPDATE public.fotos_trabajo
  SET origen_captura = 'camara_app',
      tipo_evidencia = v_tipo,
      latitud = p_lat,
      longitud = p_lng,
      capturada_en = COALESCE(p_capturada_en, now()),
      recibida_en = now(),
      hash_sha256 = v_hash,
      duracion_segundos = p_duracion_seg,
      nonce = v_nonce.nonce,
      confianza = v_confianza,
      distancia_metros = v_dist,
      duplicado = v_prev_id IS NOT NULL,
      duplicado_de = v_prev_id
  WHERE id::text = btrim(p_id_foto);

  INSERT INTO public.evidencia_procedencia (
    id_foto, id_trabajo, origen_captura, tipo_evidencia,
    hash_sha256, hash_original, hash_perceptual,
    latitud, longitud, distancia_metros,
    capturada_en, recibida_en, nonce, confianza, motivo, duplicado_de
  ) VALUES (
    btrim(p_id_foto), btrim(p_id_trabajo), 'camara_app', v_tipo,
    v_hash, NULL, NULL,
    p_lat, p_lng, v_dist,
    COALESCE(p_capturada_en, now()), now(), v_nonce.nonce, v_confianza, v_motivo, v_prev_id
  );

  UPDATE public.evidencia_nonces
  SET usado_en = now(), id_foto = btrim(p_id_foto)
  WHERE id = v_nonce.id;

  RETURN jsonb_build_object(
    'confianza', v_confianza,
    'distancia_metros', v_dist,
    'duracion_segundos', p_duracion_seg,
    'duplicado', v_prev_id IS NOT NULL,
    'motivo', v_motivo
  );
END;
$$;

COMMENT ON FUNCTION public.registrar_evidencia_video_captura(
  text, text, text, text, double precision, double precision, text, integer, integer, timestamptz
) IS
  'Registra un video tomado con la cámara de la app. Exige nonce, SHA-256, hora del servidor y GPS a no más de 500 m. Tope: 30 s y 20 MB. El objeto debe existir en el bucket evidencias. No aplicar en producción sin aprobación.';

GRANT EXECUTE ON FUNCTION public.registrar_evidencia_video_captura(
  text, text, text, text, double precision, double precision, text, integer, integer, timestamptz
) TO authenticated, service_role;

-- Alta de un profesional: el trigger crea 7 ventanas y 45 horas publicadas
-- (lunes a viernes, 09:00 a 17:00). Transacción con ROLLBACK. No apunta a producción.
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/alta_profesional_agenda.sql

BEGIN;

DO $$
DECLARE
  v_id uuid := gen_random_uuid();
  v_horas int;
  v_ventanas int;
  v_usa boolean;
BEGIN
  INSERT INTO auth.users (id, aud, role, email, created_at, updated_at)
  VALUES (v_id, 'authenticated', 'authenticated', 'alta-' || v_id || '@prueba.test', now(), now());
  INSERT INTO public.perfiles (id, nombre, correo, rol, estado_cuenta, creado_en)
  VALUES (v_id, 'Alta prueba', 'alta-' || v_id || '@prueba.test', 'trabajador', 'activo',
    to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'));

  INSERT INTO public.trabajadores (id_usuario, profesion, disponible, tarifa_visita,
    precios_configurados, estado_verificacion, radio_servicio_km)
  VALUES (v_id, 'Prueba', 0, 20000, 1, 'pendiente', 10);

  SELECT count(*) INTO v_horas FROM public.trabajador_horas_publicadas WHERE id_usuario = v_id;
  SELECT count(*) INTO v_ventanas FROM public.trabajador_horarios WHERE id_usuario = v_id;
  SELECT usa_horario INTO v_usa FROM public.trabajadores WHERE id_usuario = v_id;

  IF v_ventanas <> 7 THEN
    RAISE EXCEPTION 'se esperaban 7 ventanas y hay %', v_ventanas;
  END IF;
  IF v_horas <> 45 THEN
    RAISE EXCEPTION 'se esperaban 45 horas publicadas y hay %', v_horas;
  END IF;
  IF v_usa IS NOT TRUE THEN
    RAISE EXCEPTION 'usa_horario debe quedar en true';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.trabajador_horas_publicadas
    WHERE id_usuario = v_id AND (dia_semana NOT BETWEEN 1 AND 5 OR hora < '09:00' OR hora > '17:00')
  ) THEN
    RAISE EXCEPTION 'hay horas fuera de lunes a viernes 09:00-17:00';
  END IF;
END $$;

ROLLBACK;

-- Prueba manual del inicio con PIN (20261115180001).
-- Corre en una transacción y termina en ROLLBACK. No toca la base en vivo
-- si se ejecuta así. Necesita un trabajo en aceptado o en_camino y las
-- cuentas de la demo (scripts/demo/seed_demo.sql) más la migración aplicada.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/PRUEBAS_PIN_INICIO.sql

BEGIN;

DO $$
DECLARE
  v_camila uuid := (SELECT id FROM auth.users WHERE email = 'camila.soto@demo.myworksapp.cl');
  v_pedro uuid := (SELECT id FROM auth.users WHERE email = 'pedro.rojas@demo.myworksapp.cl');
  v_pin text;
  v_err text;
  v_estado text;
  v_restantes integer;
BEGIN
  IF v_camila IS NULL OR v_pedro IS NULL THEN
    RAISE EXCEPTION 'FALLO: faltan cuentas de la demo';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.trabajos WHERE id = 'demo-job-en-camino' AND estado = 'en_camino') THEN
    RAISE EXCEPTION 'FALLO: demo-job-en-camino no está en camino';
  END IF;

  PERFORM set_config('role', 'postgres', true);
  v_pin := public.asegurar_pin_inicio('demo-job-en-camino');
  UPDATE public.bloqueos_pin_inicio
  SET fallos = 0, bloqueado_hasta = NULL
  WHERE id_trabajo = 'demo-job-en-camino';

  -- El profesional no lee el PIN por la tabla.
  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config(
    'request.jwt.claims',
    json_build_object('sub', v_pedro, 'role', 'authenticated')::text,
    true
  );
  IF EXISTS (
    SELECT 1 FROM public.pines_inicio_trabajo WHERE id_trabajo = 'demo-job-en-camino'
  ) THEN
    RAISE EXCEPTION 'FALLO: el profesional puede leer el PIN';
  END IF;

  -- Un UPDATE directo no pone el trabajo en curso.
  BEGIN
    UPDATE public.trabajos
    SET estado = 'en_curso'
    WHERE id = 'demo-job-en-camino';
    v_err := 'paso';
  EXCEPTION WHEN others THEN
    v_err := SQLERRM;
  END;
  IF v_err = 'paso' THEN
    RAISE EXCEPTION 'FALLO: el UPDATE directo pasó a en_curso';
  END IF;

  -- Sin PIN no inicia. El quinto error bloquea 15 minutos.
  -- intentar_pin_inicio no lanza: así el contador queda grabado.
  FOR v_restantes IN 1..4 LOOP
    v_err := public.intentar_pin_inicio('demo-job-en-camino', '0000') ->> 'mensaje';
    IF v_err NOT LIKE 'PIN incorrecto%' THEN
      RAISE EXCEPTION 'FALLO: intento % no avisó el PIN (%)', v_restantes, v_err;
    END IF;
  END LOOP;
  v_err := public.intentar_pin_inicio('demo-job-en-camino', '0000') ->> 'mensaje';
  IF v_err NOT LIKE 'Demasiados intentos%' THEN
    RAISE EXCEPTION 'FALLO: el quinto intento no bloqueó (%)', v_err;
  END IF;

  PERFORM set_config('role', 'postgres', true);
  UPDATE public.bloqueos_pin_inicio
  SET fallos = 0, bloqueado_hasta = NULL
  WHERE id_trabajo = 'demo-job-en-camino';
  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config(
    'request.jwt.claims',
    json_build_object('sub', v_pedro, 'role', 'authenticated')::text,
    true
  );

  IF (public.intentar_pin_inicio('demo-job-en-camino', v_pin) ->> 'ok') IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'FALLO: el PIN correcto no abrió el inicio';
  END IF;
  SELECT estado INTO v_estado
  FROM public.transicionar_trabajo('demo-job-en-camino', 'en_curso', v_pin);
  IF v_estado <> 'en_curso' THEN
    RAISE EXCEPTION 'FALLO: el PIN correcto no inició (%)', v_estado;
  END IF;

  -- La clienta ve el PIN mientras el trabajo sigue antes de iniciarse.
  -- Este pedido ya quedó en curso, así que el RPC devuelve null.
  PERFORM set_config(
    'request.jwt.claims',
    json_build_object('sub', v_camila, 'role', 'authenticated')::text,
    true
  );
  IF public.obtener_pin_inicio('demo-job-en-camino') IS NOT NULL THEN
    RAISE EXCEPTION 'FALLO: el PIN sigue visible después de iniciar';
  END IF;

  RAISE NOTICE 'OK pin de inicio';
END $$;

ROLLBACK;

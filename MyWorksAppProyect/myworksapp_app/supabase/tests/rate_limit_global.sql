-- Prueba de 20261120150000_rate_limit_global.sql en una base local.
-- Transacción con ROLLBACK. No apunta a producción.
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rate_limit_global.sql

BEGIN;

DO $$
DECLARE
  v_clave text := 'prueba-rate-' || gen_random_uuid()::text;
BEGIN
  IF public.rate_limit_consumir('', 2, 60) IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'una clave vacía no debe pasar';
  END IF;
  IF public.rate_limit_consumir(v_clave, 2, 60) IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'el primer intento debe pasar';
  END IF;
  IF public.rate_limit_consumir(v_clave, 2, 60) IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'el segundo intento debe pasar';
  END IF;
  IF public.rate_limit_consumir(v_clave, 2, 60) IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'el tercer intento debe bloquearse';
  END IF;

  UPDATE public.rate_limit_ventana
  SET vence_en = clock_timestamp() - interval '1 second'
  WHERE clave = v_clave;

  IF public.rate_limit_consumir(v_clave, 2, 60) IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'una ventana vencida debe volver a contar desde 1';
  END IF;
END $$;

ROLLBACK;

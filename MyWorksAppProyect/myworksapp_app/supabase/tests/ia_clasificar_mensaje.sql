-- Casos de clasificar_mensaje. No apunta a producción.
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/ia_clasificar_mensaje.sql
DO $$
DECLARE
  v text;
BEGIN
  v := public.clasificar_mensaje('págame por fuera de la app');
  IF v IS DISTINCT FROM 'fuera' THEN
    RAISE EXCEPTION 'esperaba fuera, obtuvo %', v;
  END IF;
  v := public.clasificar_mensaje('mi número de cuenta es este');
  IF v IS DISTINCT FROM 'banco' THEN
    RAISE EXCEPTION 'esperaba banco, obtuvo %', v;
  END IF;
  v := public.clasificar_mensaje('el calefont gotea en la cocina');
  IF v IS DISTINCT FROM 'limpio' THEN
    RAISE EXCEPTION 'esperaba limpio, obtuvo %', v;
  END IF;
  IF to_regclass('public.eventos') IS NULL THEN
    RAISE EXCEPTION 'falta la tabla eventos';
  END IF;
  IF to_regclass('public.mv_stats_profesional') IS NULL THEN
    RAISE EXCEPTION 'falta mv_stats_profesional';
  END IF;
END $$;

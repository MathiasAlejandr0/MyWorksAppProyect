-- Auditoría de base de datos 2026-11-16 (5/5): is_admin() evaluado una vez por consulta.
--
-- En una política RLS, una llamada directa a is_admin() se ejecuta por cada
-- fila que la consulta revisa (cada vez busca el perfil del usuario). Envuelta
-- en un subselect, ( SELECT is_admin() ), Postgres la calcula una sola vez
-- (InitPlan) y reutiliza el resultado. Medición con 200.000 filas sintéticas
-- (docs/pruebas/rendimiento_base_datos.md): 3.580 ms -> 178 ms.
--
-- El bloque recorre las políticas del esquema public que todavía llaman
-- is_admin() sin subselect (42 al momento de la auditoría) y reescribe solo esa
-- llamada; el resto de cada expresión queda igual. Es idempotente.
DO $$
DECLARE
  r record;
  v_using text;
  v_check text;
  v_re constant text := '(^|[^.a-z_])is_admin\(\)';
  v_rep constant text := '\1( SELECT is_admin() AS is_admin)';
BEGIN
  FOR r IN
    SELECT tablename, policyname, qual, with_check
    FROM pg_policies
    WHERE schemaname = 'public'
      AND (coalesce(qual, '') || ' ' || coalesce(with_check, '')) ~ v_re
      AND (coalesce(qual, '') || ' ' || coalesce(with_check, '')) !~ 'SELECT is_admin\(\) AS is_admin'
  LOOP
    v_using := regexp_replace(r.qual, v_re, v_rep, 'g');
    v_check := regexp_replace(r.with_check, v_re, v_rep, 'g');
    EXECUTE format('ALTER POLICY %I ON public.%I%s%s',
      r.policyname, r.tablename,
      CASE WHEN v_using IS NOT NULL THEN ' USING (' || v_using || ')' ELSE '' END,
      CASE WHEN v_check IS NOT NULL THEN ' WITH CHECK (' || v_check || ')' ELSE '' END);
  END LOOP;
END $$;

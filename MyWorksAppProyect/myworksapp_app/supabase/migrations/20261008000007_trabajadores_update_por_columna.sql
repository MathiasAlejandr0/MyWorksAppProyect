-- REVOKE UPDATE (col) no alcanza: authenticated conserva UPDATE a nivel de tabla.
-- Una columna nueva de trabajadores necesita GRANT UPDATE explícito.

BEGIN;

REVOKE UPDATE ON TABLE public.trabajadores FROM anon, authenticated;

DO $$
DECLARE
  col text;
BEGIN
  FOR col IN
    SELECT a.attname
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'trabajadores'
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attname NOT IN (
        'calificacion',
        'conteo_rechazos',
        'estado_verificacion',
        'nota_verificacion'
      )
  LOOP
    EXECUTE format(
      'GRANT UPDATE (%I) ON TABLE public.trabajadores TO authenticated',
      col
    );
  END LOOP;
END $$;

REVOKE INSERT, DELETE, TRUNCATE ON TABLE public.trabajadores FROM anon;

COMMIT;

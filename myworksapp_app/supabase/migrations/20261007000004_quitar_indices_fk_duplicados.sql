-- Quita índices idx_*_fkey cuando otro índice válido y no parcial ya
-- empieza por las mismas columnas. int2vector es 0-based: se compara
-- con string_to_array(indkey::text, ' '), que es 1-based.
-- Idempotente. Si dos índices _fkey se pisan, queda el de nombre menor.

BEGIN;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT n.nspname AS schema_name, ic.relname AS index_name
    FROM pg_index i
    JOIN pg_class ic ON ic.oid = i.indexrelid
    JOIN pg_class t ON t.oid = i.indrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND ic.relname ~ '_fkey$'
      AND i.indisvalid
      AND i.indisready
      AND i.indpred IS NULL
      AND NOT i.indisprimary
      AND EXISTS (
        SELECT 1
        FROM pg_index o
        JOIN pg_class oc ON oc.oid = o.indexrelid
        WHERE o.indrelid = i.indrelid
          AND o.indexrelid <> i.indexrelid
          AND o.indisvalid
          AND o.indisready
          AND o.indpred IS NULL
          AND (
            oc.relname !~ '_fkey$'
            OR oc.relname < ic.relname
          )
          AND (string_to_array(o.indkey::text, ' ')::smallint[])[
            1:cardinality(string_to_array(i.indkey::text, ' '))
          ] = string_to_array(i.indkey::text, ' ')::smallint[]
      )
  LOOP
    EXECUTE format('DROP INDEX IF EXISTS %I.%I', r.schema_name, r.index_name);
  END LOOP;
END $$;

COMMIT;

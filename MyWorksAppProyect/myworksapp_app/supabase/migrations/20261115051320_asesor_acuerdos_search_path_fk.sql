-- Portado desde MathiasAlejandr0/MyWorksAppProyect PR #55 (20261114000001_asesor_acuerdos_search_path_fk.sql).
-- Aplicada en vivo dentro de 20261115051320–20261115051532. El archivo local usa otra versión para ordenar después de 20261115000001.
-- No reaplicar el SQL en wxqrfcqifkfgawrnqmnj: ya está en la base.

-- Hallazgos del asesor de Supabase (no aplicar en este PR; solo versionar).
-- 1) acuerdo_pendiente, proponer_acuerdo y responder_acuerdo no deben
--    ejecutarse como anon/PUBLIC. Se conserva el cuerpo (y sus chequeos de auth).
-- 2) slug_geo y disputa_esta_activa quedan con search_path fijo.
-- 3) Toda FK de public sin índice que cubra sus columnas (el asesor reportó 8)
--    recibe un índice. Idempotente: si la función o la FK no existe, no falla.
-- service_role conserva EXECUTE: las Edge Functions no pasan por el rol anon.

BEGIN;

DO $$
DECLARE
  r record;
  fn text;
BEGIN
  FOREACH fn IN ARRAY ARRAY[
    'acuerdo_pendiente',
    'proponer_acuerdo',
    'responder_acuerdo'
  ]
  LOOP
    FOR r IN
      SELECT p.oid::regprocedure AS sig
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = fn
    LOOP
      EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', r.sig);
      EXECUTE format(
        'GRANT EXECUTE ON FUNCTION %s TO authenticated, service_role',
        r.sig
      );
    END LOOP;
  END LOOP;

  FOREACH fn IN ARRAY ARRAY[
    'slug_geo',
    'disputa_esta_activa'
  ]
  LOOP
    FOR r IN
      SELECT p.oid::regprocedure AS sig
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = fn
    LOOP
      EXECUTE format('ALTER FUNCTION %s SET search_path = public', r.sig);
    END LOOP;
  END LOOP;
END $$;

-- Misma condición que el linter de FKs sin índice (prefijo del índice, base 0).
DO $$
DECLARE
  r record;
  idx_name text;
BEGIN
  FOR r IN
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      (
        SELECT string_agg(quote_ident(a.attname), ', ' ORDER BY u.ord)
        FROM unnest(con.conkey) WITH ORDINALITY AS u(attnum, ord)
        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = u.attnum
      ) AS col_list,
      (
        SELECT string_agg(a.attname, '_' ORDER BY u.ord)
        FROM unnest(con.conkey) WITH ORDINALITY AS u(attnum, ord)
        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = u.attnum
      ) AS col_slug
    FROM pg_constraint con
    JOIN pg_class c ON c.oid = con.conrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE con.contype = 'f'
      AND n.nspname = 'public'
      AND NOT EXISTS (
        SELECT 1
        FROM pg_index i
        WHERE i.indrelid = c.oid
          AND i.indisvalid
          AND i.indisready
          AND i.indpred IS NULL
          AND ((i.indkey::int[])[0:cardinality(con.conkey) - 1]) @> con.conkey::int[]
      )
  LOOP
    idx_name := left('idx_' || r.table_name || '_' || r.col_slug || '_fkey', 63);
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I (%s)',
      idx_name, r.schema_name, r.table_name, r.col_list
    );
  END LOOP;
END $$;

COMMIT;

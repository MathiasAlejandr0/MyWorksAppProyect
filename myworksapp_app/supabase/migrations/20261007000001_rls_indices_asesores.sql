-- Asesores de Supabase: initplan de auth.uid(), políticas idénticas duplicadas,
-- índices idénticos y FKs sin índice.
-- No borra políticas inglesas: jobs_insert, profiles_select,
-- notifications_insert_participants y quotes_update conceden cosas que las
-- españolas todavía no cubren. Ese cierre va en 20261008000001.
-- Idempotente. No revoca EXECUTE.
-- Aplicar después de 20261006000001_gps_y_base_profesional.sql.

BEGIN;

-- Pares con el mismo comando, roles y expresión: queda un solo nombre.
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    WITH pols AS (
      SELECT
        n.nspname AS schema_name,
        c.relname AS table_name,
        p.polname,
        p.polcmd,
        p.polpermissive,
        p.polroles::text AS roles_sig,
        regexp_replace(lower(COALESCE(pg_get_expr(p.polqual, p.polrelid), '')), '\s+', '', 'g') AS qual_n,
        regexp_replace(lower(COALESCE(pg_get_expr(p.polwithcheck, p.polrelid), '')), '\s+', '', 'g') AS check_n
      FROM pg_policy p
      JOIN pg_class c ON c.oid = p.polrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname IN ('public', 'storage')
        AND p.polpermissive
    ),
    ranked AS (
      SELECT
        schema_name,
        table_name,
        polname,
        row_number() OVER (
          PARTITION BY schema_name, table_name, polcmd, polpermissive, roles_sig, qual_n, check_n
          ORDER BY polname
        ) AS rn
      FROM pols
    )
    SELECT schema_name, table_name, polname
    FROM ranked
    WHERE rn > 1
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I.%I',
      r.polname, r.schema_name, r.table_name
    );
  END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- 2) auth.uid() por fila -> (select auth.uid()) para el initplan
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  r record;
  new_using text;
  new_check text;
  cmd_sql text;
  roles_sql text;
  perm_sql text;
  ddl text;
BEGIN
  FOR r IN
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      p.polname,
      p.polcmd,
      p.polpermissive,
      p.polroles,
      pg_get_expr(p.polqual, p.polrelid) AS qual,
      pg_get_expr(p.polwithcheck, p.polrelid) AS withcheck
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'storage')
      AND (
        COALESCE(pg_get_expr(p.polqual, p.polrelid), '') ~* 'auth\.uid\s*\('
        OR COALESCE(pg_get_expr(p.polwithcheck, p.polrelid), '') ~* 'auth\.uid\s*\('
      )
  LOOP
    new_using := r.qual;
    new_check := r.withcheck;

    IF new_using IS NOT NULL THEN
      new_using := regexp_replace(
        new_using,
        '\(\s*select\s+auth\.uid\s*\(\s*\)\s*(as\s+uid\s*)?\)',
        '___WRAPPED_AUTH_UID___',
        'gi'
      );
      new_using := regexp_replace(new_using, 'auth\.uid\s*\(\s*\)', '(select auth.uid())', 'gi');
      new_using := replace(new_using, '___WRAPPED_AUTH_UID___', '(select auth.uid())');
    END IF;

    IF new_check IS NOT NULL THEN
      new_check := regexp_replace(
        new_check,
        '\(\s*select\s+auth\.uid\s*\(\s*\)\s*(as\s+uid\s*)?\)',
        '___WRAPPED_AUTH_UID___',
        'gi'
      );
      new_check := regexp_replace(new_check, 'auth\.uid\s*\(\s*\)', '(select auth.uid())', 'gi');
      new_check := replace(new_check, '___WRAPPED_AUTH_UID___', '(select auth.uid())');
    END IF;

    IF new_using IS NOT DISTINCT FROM r.qual AND new_check IS NOT DISTINCT FROM r.withcheck THEN
      CONTINUE;
    END IF;

    cmd_sql := CASE r.polcmd
      WHEN 'r' THEN 'SELECT'
      WHEN 'a' THEN 'INSERT'
      WHEN 'w' THEN 'UPDATE'
      WHEN 'd' THEN 'DELETE'
      ELSE 'ALL'
    END;
    perm_sql := CASE WHEN r.polpermissive THEN 'PERMISSIVE' ELSE 'RESTRICTIVE' END;

    SELECT CASE
      WHEN r.polroles = '{0}'::oid[] OR cardinality(r.polroles) = 0 THEN 'PUBLIC'
      ELSE (
        SELECT string_agg(quote_ident(rol.rolname), ', ' ORDER BY rol.rolname)
        FROM pg_roles rol
        WHERE rol.oid = ANY (r.polroles)
      )
    END
    INTO roles_sql;

    IF roles_sql IS NULL OR roles_sql = '' THEN
      roles_sql := 'PUBLIC';
    END IF;

    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I.%I',
      r.polname, r.schema_name, r.table_name
    );

    ddl := format(
      'CREATE POLICY %I ON %I.%I AS %s FOR %s TO %s',
      r.polname, r.schema_name, r.table_name, perm_sql, cmd_sql, roles_sql
    );
    IF new_using IS NOT NULL THEN
      ddl := ddl || ' USING (' || new_using || ')';
    END IF;
    IF new_check IS NOT NULL THEN
      ddl := ddl || ' WITH CHECK (' || new_check || ')';
    END IF;
    EXECUTE ddl;
  END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- 3) Índices duplicados del rename (mensajes, notificaciones, pagos, trabajos x2)
--    Se elimina el nombre inglés si ya existe el equivalente español.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    WITH idx AS (
      SELECT
        n.nspname AS schema_name,
        t.relname AS table_name,
        ic.relname AS index_name,
        x.indisunique,
        x.indkey::text AS key_sig,
        COALESCE(pg_get_expr(x.indpred, x.indrelid), '') AS pred,
        COALESCE(pg_get_expr(x.indexprs, x.indrelid), '') AS exprs
      FROM pg_index x
      JOIN pg_class ic ON ic.oid = x.indexrelid
      JOIN pg_class t ON t.oid = x.indrelid
      JOIN pg_namespace n ON n.oid = t.relnamespace
      WHERE n.nspname = 'public'
        AND NOT x.indisprimary
    )
    SELECT DISTINCT a.schema_name, a.index_name
    FROM idx a
    JOIN idx b
      ON a.table_name = b.table_name
     AND a.index_name <> b.index_name
     AND a.indisunique = b.indisunique
     AND a.key_sig = b.key_sig
     AND a.pred = b.pred
     AND a.exprs = b.exprs
    WHERE a.index_name ~ '^(idx_messages_|idx_notifications_|idx_payments_|idx_jobs_)'
      AND b.index_name !~ '^(idx_messages_|idx_notifications_|idx_payments_|idx_jobs_)'
  LOOP
    EXECUTE format('DROP INDEX IF EXISTS %I.%I', r.schema_name, r.index_name);
  END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- 4) FKs sin índice en la columna líder (los 8 del asesor y cualquier otro)
-- -----------------------------------------------------------------------------
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
          AND (string_to_array(i.indkey::text, ' ')::smallint[])[1:cardinality(con.conkey)] = con.conkey::smallint[]
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

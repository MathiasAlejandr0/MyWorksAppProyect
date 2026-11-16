-- EXPLAIN (ANALYZE, BUFFERS) de las consultas principales con el contexto real de RLS.
-- Se ejecuta como rol authenticated con los claims JWT de un usuario (cliente o profesional demo).
-- Uso: reemplazar :cliente y :pro por UUID reales. Todo queda dentro de una transacción con ROLLBACK.
CREATE OR REPLACE FUNCTION pg_temp.plan(q text, reps int DEFAULT 5)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE j jsonb; t numeric[] := '{}'; i int; p jsonb;
BEGIN
  FOR i IN 1..reps LOOP
    EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || q INTO j;
    t := t || ((j->0->>'Execution Time')::numeric + (j->0->>'Planning Time')::numeric);
    p := j;
  END LOOP;
  RETURN jsonb_build_object(
    'ms_mediana', (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY x) FROM unnest(t) x),
    'ms_min', (SELECT min(x) FROM unnest(t) x), 'ms_max', (SELECT max(x) FROM unnest(t) x),
    'nodo', p->0->'Plan'->>'Node Type', 'filas', p->0->'Plan'->>'Actual Rows',
    'buffers_hit', p->0->'Plan'->>'Shared Hit Blocks', 'buffers_read', p->0->'Plan'->>'Shared Read Blocks',
    'plan', p);
END $$;

-- Prueba de escala sintética (tablas temporales, no toca datos reales).
-- Reproduce, con 200.000 filas, los patrones corregidos por la migración de
-- rendimiento, para medir el efecto que con ~240 trabajos reales no se nota.
CREATE OR REPLACE FUNCTION pg_temp.med(q text, reps int DEFAULT 7)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE j jsonb; t numeric[] := '{}'; i int; nodo text; hit bigint;
BEGIN
  FOR i IN 1..reps LOOP
    EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || q INTO j;
    t := t || ((j->0->>'Execution Time')::numeric + (j->0->>'Planning Time')::numeric);
  END LOOP;
  WITH RECURSIVE n(p) AS (SELECT j->0->'Plan' UNION ALL SELECT x FROM n, jsonb_array_elements(n.p->'Plans') x)
  SELECT string_agg(DISTINCT (p->>'Node Type') || COALESCE(' ' || (p->>'Index Name'), ''), ', ')
    INTO nodo FROM n WHERE p->>'Node Type' ~ 'Scan';
  RETURN jsonb_build_object('ms_mediana', (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY x) FROM unnest(t) x),
    'ms_min', (SELECT min(x) FROM unnest(t) x), 'ms_max', (SELECT max(x) FROM unnest(t) x),
    'buffers', (j->0->'Plan'->>'Shared Hit Blocks')::bigint + COALESCE((j->0->'Plan'->>'Local Hit Blocks')::bigint,0), 'nodos', nodo);
END $$;

CREATE TEMP TABLE s_usuarios AS
  SELECT gen_random_uuid() AS id FROM generate_series(1, 5000);
CREATE TEMP TABLE s_trabajos AS
  WITH u AS (SELECT array_agg(id) a FROM s_usuarios)
  SELECT gen_random_uuid() AS id,
         u.a[(g % 5000) + 1] AS id_usuario,
         now() - (g || ' minutes')::interval AS creado_en,
         repeat('x', 120) AS descripcion
  FROM generate_series(1, 200000) g, u;
CREATE INDEX ON s_trabajos (id_usuario, creado_en DESC);
CREATE TEMP TABLE s_liq AS
  SELECT gen_random_uuid()::text AS id, (g % 2000)::text AS id_trabajador,
         (now() - (g || ' minutes')::interval)::text AS creado_en, 1000 AS monto
  FROM generate_series(1, 200000) g;
ANALYZE s_trabajos; ANALYZE s_liq;

CREATE TEMP TABLE s_res AS SELECT jsonb_build_object(
 'R2_cast_texto', pg_temp.med(format($q$SELECT id, creado_en FROM s_trabajos WHERE id_usuario::text = %L::uuid::text ORDER BY creado_en DESC$q$, (SELECT id FROM s_usuarios LIMIT 1))),
 'R2_uuid',       pg_temp.med(format($q$SELECT id, creado_en FROM s_trabajos WHERE id_usuario = %L::uuid ORDER BY creado_en DESC$q$, (SELECT id FROM s_usuarios LIMIT 1))),
 'R4_liq_sin_indice', pg_temp.med($q$SELECT * FROM s_liq WHERE id_trabajador = '42' ORDER BY creado_en DESC LIMIT 50$q$)
) AS r;
CREATE INDEX ON s_liq (id_trabajador, creado_en DESC);
ANALYZE s_liq;
INSERT INTO s_res SELECT jsonb_build_object(
 'R4_liq_con_indice', pg_temp.med($q$SELECT * FROM s_liq WHERE id_trabajador = '42' ORDER BY creado_en DESC LIMIT 50$q$),
 'R1_funcion_por_fila', pg_temp.med($q$SELECT count(*) FROM s_trabajos WHERE public.is_admin() OR id_usuario IS NULL$q$, 3),
 'R1_initplan',         pg_temp.med($q$SELECT count(*) FROM s_trabajos WHERE (SELECT public.is_admin()) OR id_usuario IS NULL$q$, 3)
);
SELECT jsonb_agg(r) FROM s_res;
DROP TABLE s_res, s_trabajos, s_liq, s_usuarios;

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


CREATE OR REPLACE FUNCTION pg_temp.set_ctx(r text, c text) RETURNS text LANGUAGE plpgsql AS $$
BEGIN PERFORM set_config('request.jwt.claims', c, true); PERFORM set_config('role', r, true); RETURN r; END $$;

create temp table _res(id text, descr text, p jsonb); grant all on _res to authenticated, anon;
select pg_temp.set_ctx('anon','{"role": "anon"}');
insert into _res select 'Q01','Catálogo: profesionales de un oficio (RPC listar_profesionales_catalogo)', pg_temp.plan('select * from public.listar_profesionales_catalogo(''gasfiteria'', null, null, null, 20)');
reset role;
select pg_temp.set_ctx('anon','{"role": "anon"}');
insert into _res select 'Q02','Portada: oficios con profesionales disponibles (RPC categorias_con_disponibles)', pg_temp.plan('select * from public.categorias_con_disponibles()');
reset role;
select pg_temp.set_ctx('anon','{"role": "anon"}');
insert into _res select 'Q03','Agenda pública: horas libres de un profesional, 14 días (RPC horarios_libres_profesional)', pg_temp.plan('select * from public.horarios_libres_profesional(''11111111-1111-4111-8111-000000000209''::uuid, 14)');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000001", "aal": "aal2"}');
insert into _res select 'Q04','Mis pedidos (cliente con 92 trabajos), orden por fecha', pg_temp.plan('select id,id_usuario,id_trabajador,id_servicio,estado,direccion,descripcion,creado_en from public.trabajos where id_usuario=''11111111-1111-4111-8111-000000000001'' order by creado_en desc');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000209", "aal": "aal2"}');
insert into _res select 'Q05','Agenda del profesional: sus trabajos por fecha', pg_temp.plan('select id,estado,fecha_programada,creado_en from public.trabajos where id_trabajador=''11111111-1111-4111-8111-000000000209'' order by creado_en desc');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000001", "aal": "aal2"}');
insert into _res select 'Q06','Chat de un trabajo, orden cronológico', pg_temp.plan('select * from public.mensajes where id_trabajo=''80b4f7d1-0439-4e86-87fc-cf669df1cbe9'' order by creado_en');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000001", "aal": "aal2"}');
insert into _res select 'Q07','Pago/escrow de un trabajo', pg_temp.plan('select id,estado,monto,tipo_pago,creado_en from public.pagos where id_trabajo=''80b4f7d1-0439-4e86-87fc-cf669df1cbe9''');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000209", "aal": "aal2"}');
insert into _res select 'Q08','Ganancias del profesional: pagos de sus trabajos (autorizado/retenido/liberado)', pg_temp.plan('select p.id,p.monto,p.estado,p.creado_en from public.pagos p where p.id_trabajo in (select id from public.trabajos where id_trabajador=''11111111-1111-4111-8111-000000000209'') and p.estado in (''autorizado'',''retenido'',''liberado'') order by p.creado_en desc');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000209", "aal": "aal2"}');
insert into _res select 'Q09','Liquidaciones del profesional', pg_temp.plan('select * from public.liquidaciones where id_trabajador=''11111111-1111-4111-8111-000000000209'' order by creado_en desc');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000901", "aal": "aal2"}');
insert into _res select 'Q10','Panel admin: métricas resumen (RPC admin_metricas_resumen)', pg_temp.plan('select public.admin_metricas_resumen()');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000901", "aal": "aal2"}');
insert into _res select 'Q11','Panel admin: trabajos activos', pg_temp.plan('select id,estado from public.trabajos where estado in (''pendiente'',''aceptado'',''en_camino'',''en_curso'')');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000001", "aal": "aal2"}');
insert into _res select 'Q12','Notificaciones del usuario', pg_temp.plan('select * from public.notificaciones where id_usuario=''11111111-1111-4111-8111-000000000001'' order by creado_en desc limit 50');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000001", "aal": "aal2"}');
insert into _res select 'Q13','Reseñas públicas de un profesional', pg_temp.plan('select c.puntaje,c.comentario,c.creado_en from public.calificaciones c where c.id_calificado=''11111111-1111-4111-8111-000000000209'' and c.direccion=''cliente_a_trabajador'' order by c.creado_en desc limit 20');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000209", "aal": "aal2"}');
insert into _res select 'Q14','Marketplace de trabajos abiertos (RPC listar_trabajos_marketplace)', pg_temp.plan('select * from public.listar_trabajos_marketplace(50)');
reset role;
select pg_temp.set_ctx('authenticated','{"role": "authenticated", "sub": "11111111-1111-4111-8111-000000000209", "aal": "aal2"}');
insert into _res select 'Q15','Ficha propia del profesional (RPC mi_ficha_propia)', pg_temp.plan('select * from public.mi_ficha_propia()');
reset role;
select jsonb_agg(jsonb_build_object('id',id,'desc',descr,'ms_mediana',p->'ms_mediana','ms_min',p->'ms_min','ms_max',p->'ms_max','nodo',p->'nodo','filas',p->'filas','hit',p->'buffers_hit','read',p->'buffers_read','plan',p->'plan') order by id) from _res;
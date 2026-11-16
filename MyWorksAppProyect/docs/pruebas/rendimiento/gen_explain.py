import json,sys
CLI='11111111-1111-4111-8111-000000000001'; PRO='11111111-1111-4111-8111-000000000209'
JOB='80b4f7d1-0439-4e86-87fc-cf669df1cbe9'; ADM='11111111-1111-4111-8111-000000000901'
Q=[
 ("Q01","anon","Catálogo: profesionales de un oficio (RPC listar_profesionales_catalogo)", None, "select * from public.listar_profesionales_catalogo('gasfiteria', null, null, null, 20)"),
 ("Q02","anon","Portada: oficios con profesionales disponibles (RPC categorias_con_disponibles)", None, "select * from public.categorias_con_disponibles()"),
 ("Q03","anon","Agenda pública: horas libres de un profesional, 14 días (RPC horarios_libres_profesional)", None, f"select * from public.horarios_libres_profesional('{PRO}'::uuid, 14)"),
 ("Q04","authenticated","Mis pedidos (cliente con 92 trabajos), orden por fecha", CLI, f"select id,id_usuario,id_trabajador,id_servicio,estado,direccion,descripcion,creado_en from public.trabajos where id_usuario='{CLI}' order by creado_en desc"),
 ("Q05","authenticated","Agenda del profesional: sus trabajos por fecha", PRO, f"select id,estado,fecha_programada,creado_en from public.trabajos where id_trabajador='{PRO}' order by creado_en desc"),
 ("Q06","authenticated","Chat de un trabajo, orden cronológico", CLI, f"select * from public.mensajes where id_trabajo='{JOB}' order by creado_en"),
 ("Q07","authenticated","Pago/escrow de un trabajo", CLI, f"select id,estado,monto,tipo_pago,creado_en from public.pagos where id_trabajo='{JOB}'"),
 ("Q08","authenticated","Ganancias del profesional: pagos de sus trabajos (autorizado/retenido/liberado)", PRO, f"select p.id,p.monto,p.estado,p.creado_en from public.pagos p where p.id_trabajo in (select id from public.trabajos where id_trabajador='{PRO}') and p.estado in ('autorizado','retenido','liberado') order by p.creado_en desc"),
 ("Q09","authenticated","Liquidaciones del profesional", PRO, f"select * from public.liquidaciones where id_trabajador='{PRO}' order by creado_en desc"),
 ("Q10","authenticated","Panel admin: métricas resumen (RPC admin_metricas_resumen)", ADM, "select public.admin_metricas_resumen()"),
 ("Q11","authenticated","Panel admin: trabajos activos", ADM, "select id,estado from public.trabajos where estado in ('pendiente','aceptado','en_camino','en_curso')"),
 ("Q12","authenticated","Notificaciones del usuario", CLI, f"select * from public.notificaciones where id_usuario='{CLI}' order by creado_en desc limit 50"),
 ("Q13","authenticated","Reseñas públicas de un profesional", CLI, f"select c.puntaje,c.comentario,c.creado_en from public.calificaciones c where c.id_calificado='{PRO}' and c.direccion='cliente_a_trabajador' order by c.creado_en desc limit 20"),
 ("Q14","authenticated","Marketplace de trabajos abiertos (RPC listar_trabajos_marketplace)", PRO, "select * from public.listar_trabajos_marketplace(50)"),
 ("Q15","authenticated","Ficha propia del profesional (RPC mi_ficha_propia)", PRO, "select * from public.mi_ficha_propia()"),
]
sql=open('explain_real.sql').read()+"\nselect jsonb_agg(r) from (\n"
parts=[]
for qid,role,desc,uid,q in Q:
    claims={"role":role}
    if uid: claims.update({"sub":uid,"aal":"aal2"})
    qq=q.replace("'","''")
    parts.append(f"select '{qid}' id, pg_temp.set_ctx('{role}','{json.dumps(claims)}') ctx, pg_temp.plan('{qq}') p")
sql=sql.replace("RETURNS jsonb LANGUAGE plpgsql AS $$\nDECLARE j jsonb;","RETURNS jsonb LANGUAGE plpgsql AS $$\nDECLARE j jsonb;",1)
ctx="""
CREATE OR REPLACE FUNCTION pg_temp.set_ctx(r text, c text) RETURNS text LANGUAGE plpgsql AS $$
BEGIN PERFORM set_config('request.jwt.claims', c, true); PERFORM set_config('role', r, true); RETURN r; END $$;
"""
# run each query in its own subselect sequentially (lateral order not guaranteed) -> use a DO-free approach: one statement per query
out=[sql.split("\nselect jsonb_agg")[0], ctx]
for p,(qid,role,desc,uid,q) in zip(parts,Q):
    out.append(p.replace(" ctx, pg_temp.plan"," ctx, (select pg_temp.plan")+") as p_; reset role;" if False else "")
# simpler: build sequential selects into a temp table
body=[sql.split("\nselect jsonb_agg")[0], ctx, "create temp table _res(id text, descr text, p jsonb); grant all on _res to authenticated, anon;"]
for qid,role,desc,uid,q in Q:
    claims={"role":role}
    if uid: claims.update({"sub":uid,"aal":"aal2"})
    qq=q.replace("'","''")
    body.append(f"select pg_temp.set_ctx('{role}','{json.dumps(claims)}');\ninsert into _res select '{qid}','{desc}', pg_temp.plan('{qq}');\nreset role;")
body.append("select jsonb_agg(jsonb_build_object('id',id,'desc',descr,'ms_mediana',p->'ms_mediana','ms_min',p->'ms_min','ms_max',p->'ms_max','nodo',p->'nodo','filas',p->'filas','hit',p->'buffers_hit','read',p->'buffers_read','plan',p->'plan') order by id) from _res;")
open(sys.argv[1],'w').write("\n".join(body))
json.dump([{"id":a,"rol":b,"desc":c,"sql":e} for a,b,c,d,e in Q],open('consultas.json','w'),ensure_ascii=False,indent=1)

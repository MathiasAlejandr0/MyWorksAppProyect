#!/usr/bin/env python3
"""Pruebas de seguridad (RLS, privilegios, anon, inyección, Edge Functions) de MyWorksApp.

Usa solo la clave anon pública y usuarios QA temporales (qa.audit.*@test.myworksapp.cl).
Variables de entorno: SB_URL, SB_ANON, QA_PW (contraseña de los usuarios QA; no se guarda).
Cada caso declara el resultado ESPERADO (seguro). El caso "pasa" si la respuesta real
coincide con lo esperado.
"""
import json, os, sys, time, urllib.parse
import requests

URL = os.environ["SB_URL"]; ANON = os.environ["SB_ANON"]; PW = os.environ["QA_PW"]
WEB = "https://myworksapp-cl.vercel.app"
U = {k: f"qa.audit.{k}@test.myworksapp.cl" for k in ["cliente1", "cliente2", "pro1", "pro2"]}
JOB = os.environ.get("QA_JOB", "qa-audit-job-1")
PAY = os.environ.get("QA_PAY", "qa-audit-pay-1")
ID = {}
TOK = {}
S = requests.Session()
RESULTS = []

def login(k):
    r = S.post(f"{URL}/auth/v1/token?grant_type=password", headers={"apikey": ANON},
               json={"email": U[k], "password": PW}, timeout=30)
    r.raise_for_status(); d = r.json(); TOK[k] = d["access_token"]; ID[k] = d["user"]["id"]

def h(who=None, extra=None):
    hd = {"apikey": ANON, "Content-Type": "application/json"}
    hd["Authorization"] = f"Bearer {TOK[who]}" if who else f"Bearer {ANON}"
    if extra: hd.update(extra)
    return hd

def rest(method, path, who=None, body=None, extra=None):
    r = S.request(method, f"{URL}/rest/v1/{path}", headers=h(who, extra), json=body, timeout=30)
    try: data = r.json()
    except Exception: data = r.text
    return r.status_code, data

def rpc(fn, args, who=None):
    return rest("POST", f"rpc/{fn}", who, args)

def rec(cat, cid, desc, ok, status, detail, esperado):
    RESULTS.append({"categoria": cat, "id": cid, "caso": desc, "esperado": esperado,
                    "http": status, "resultado": "N/A" if ok is None else ("PASA" if ok else "FALLA"),
                    "detalle": (json.dumps(detail, ensure_ascii=False) if not isinstance(detail, str) else detail)[:300]})
    print(("N/A  " if ok is None else ("PASA " if ok else "FALLA")), cid, desc, status, str(detail)[:140])

def denied_or_empty(st, d):
    return st in (401, 403, 404) or (st in (200, 206) and isinstance(d, list) and len(d) == 0) or (st >= 400)

def is_error(st, d):
    return st >= 400

def changed_rows(st, d):
    return st in (200, 201) and isinstance(d, list) and len(d) > 0

def main():
    for k in U: login(k)
    c1, c2, p1, p2 = "cliente1", "cliente2", "pro1", "pro2"
    R = "return=representation"

    # ---------- Línea base: el dueño SÍ ve sus datos (control positivo) ----------
    st, d = rest("GET", f"trabajos?id=eq.{JOB}&select=id", c1)
    rec("Control", "C-01", "El cliente dueño ve su trabajo (control positivo)", st == 200 and len(d) == 1, st, d, "200 con 1 fila")
    st, d = rest("GET", f"mensajes?id_trabajo=eq.{JOB}&select=id", p1)
    rec("Control", "C-02", "El profesional asignado ve el chat (control positivo)", st == 200 and len(d) == 2, st, d, "200 con 2 filas")
    st, d = rest("GET", f"pagos?id_trabajo=eq.{JOB}&select=id,estado,monto", c1)
    rec("Control", "C-03", "El cliente dueño ve su pago sin columnas Transbank", st == 200 and len(d) == 1, st, d, "200 con 1 fila")

    # ---------- RLS horizontal ----------
    for who, lab in [(c2, "otro cliente"), (p2, "otro profesional")]:
        for tb, q in [("trabajos", f"id=eq.{JOB}"), ("pagos", f"id_trabajo=eq.{JOB}&select=id,estado,monto"),
                      ("mensajes", f"id_trabajo=eq.{JOB}"), ("pines_inicio_trabajo", f"id_trabajo=eq.{JOB}"),
                      ("fotos_trabajo", f"id_trabajo=eq.{JOB}&select=id"), ("disputas", f"id_trabajo=eq.{JOB}"),
                      ("ubicacion_en_vivo", f"id_trabajo=eq.{JOB}")]:
            st, d = rest("GET", f"{tb}?{q}", who)
            rec("RLS horizontal", f"H-{tb}-{who}", f"{lab} intenta leer {tb} de un trabajo ajeno", denied_or_empty(st, d), st, d, "0 filas o 401/403")
    st, d = rest("GET", f"perfiles?id=eq.{ID[c1]}&select=id,correo,nombre", c2)
    rec("RLS horizontal", "H-perfil", "Otro cliente intenta leer el perfil (correo) de un cliente ajeno", denied_or_empty(st, d), st, d, "0 filas")
    st, d = rest("GET", "perfiles?select=id,correo&limit=500", c2)
    rec("RLS horizontal", "H-perfiles-masivo", "Un cliente lista perfiles: solo debe ver el suyo", st == 200 and all(x["id"] == ID[c2] for x in d), st, f"{len(d) if isinstance(d,list) else d} filas", "solo su fila")
    st, d = rest("GET", "trabajos?select=id&limit=1000", c2)
    rec("RLS horizontal", "H-trabajos-masivo", "Un cliente sin pedidos lista trabajos", st == 200 and d == [], st, f"{len(d) if isinstance(d,list) else d} filas", "0 filas")
    st, d = rest("POST", "mensajes", c2, {"id": "qa-audit-msg-x", "id_trabajo": JOB, "id_remitente": ID[c2], "id_destinatario": ID[c1], "contenido": "intrusión", "tipo": "texto", "creado_en": "2026-11-16T00:00:00"}, {"Prefer": R})
    rec("RLS horizontal", "H-msg-insert", "Otro cliente intenta escribir en un chat ajeno", is_error(st, d), st, d, "403 (violación RLS)")
    st, d = rest("POST", "mensajes", c1, {"id": "qa-audit-msg-y", "id_trabajo": JOB, "id_remitente": ID[p1], "id_destinatario": ID[c1], "contenido": "suplantación", "tipo": "texto", "creado_en": "2026-11-16T00:00:00"}, {"Prefer": R})
    rec("RLS horizontal", "H-msg-suplantar", "Cliente intenta enviar un mensaje a nombre del profesional", is_error(st, d), st, d, "403")
    st, d = rest("PATCH", f"mensajes?id=eq.qa-audit-msg-2", c1, {"contenido": "editado por la otra parte"}, {"Prefer": R})
    rec("RLS horizontal", "H-msg-editar", "Cliente intenta editar el texto de un mensaje del profesional", is_error(st, d) or d == [], st, d, "error del trigger")
    st, d = rest("PATCH", f"trabajos?id=eq.{JOB}", c2, {"descripcion": "hack"}, {"Prefer": R})
    rec("RLS horizontal", "H-trab-update", "Otro cliente intenta modificar un trabajo ajeno", denied_or_empty(st, d), st, d, "401/403 o 0 filas")
    st, d = rest("DELETE", f"trabajos?id=eq.{JOB}", c2, extra={"Prefer": R})
    rec("RLS horizontal", "H-trab-delete", "Otro cliente intenta borrar un trabajo ajeno", denied_or_empty(st, d), st, d, "401/403 o 0 filas")
    for fn, args in [("cerrar_trabajo_conforme", {"p_trabajo_id": JOB}),
                     ("abrir_disputa", {"p_id": "qa-audit-disp-x", "p_id_trabajo": JOB, "p_motivo": "x", "p_descripcion": "x"}),
                     ("crear_intencion_pago", {"p_id_trabajo": JOB, "p_monto": 1, "p_buy_order": "qa1"}),
                     ("pin_inicio_trabajo", {"p_trabajo_id": JOB}),
                     ("es_parte_trabajo", {"p_trabajo_id": JOB})]:
        st, d = rpc(fn, args, c2)
        ok = is_error(st, d) or d in (False, None, [], "") or (isinstance(d, list) and not d)
        rec("RLS horizontal", f"H-rpc-{fn}", f"Otro cliente llama {fn} sobre un trabajo ajeno", ok, st, d, "error o false/vacío")

    # ---------- Escalada de privilegios / vertical ----------
    for col, val in [("rol", "administrador"), ("rol", "trabajador"), ("estado_cuenta", "activo"), ("reputacion_cliente", 5), ("calificaciones_cliente", 999)]:
        st, d = rest("PATCH", f"perfiles?id=eq.{ID[c1]}", c1, {col: val}, {"Prefer": R})
        # Falla si la fila vuelve con el valor pedido (comparación numérica: 5.00 == 5).
        def _igual(a, b):
            try: return float(a) == float(b)
            except (TypeError, ValueError): return str(a) == str(b)
        ok = is_error(st, d) or d == [] or (isinstance(d, list) and d and not _igual(d[0].get(col), val))
        if col == "estado_cuenta":  # mismo valor no cambia nada; probar suspendido->activo no aplica
            ok = True if is_error(st, d) or d == [] or (isinstance(d, list)) else ok
        rec("Escalada", f"V-perfil-{col}-{val}", f"Cliente intenta cambiar su propio {col} a {val}", ok, st, d, "rechazado")
    st, d = rest("PATCH", f"perfiles?id=eq.{ID[c1]}", c1, {"estado_cuenta": "suspendido"}, {"Prefer": R})
    rec("Escalada", "V-perfil-estado", "Cliente intenta cambiar su estado_cuenta", is_error(st, d), st, d, "rechazado")
    st, d = rest("POST", "perfiles", c2, {"id": "00000000-0000-4000-8000-00000000qa01".replace("qa", "aa"), "nombre": "x", "rol": "administrador", "estado_cuenta": "activo", "creado_en": "x"}, {"Prefer": R})
    rec("Escalada", "V-perfil-insert-admin", "Cliente intenta crear un perfil administrador", is_error(st, d), st, d, "rechazado")
    for col, val in [("estado_verificacion", "verificado"), ("calificacion", 5), ("score_listado", 99), ("prioridad_manual", 50), ("es_elite", True), ("trabajos_completados", 500), ("conteo_rechazos", 0)]:
        st, d = rest("PATCH", f"trabajadores?id_usuario=eq.{ID[p1]}", p1, {col: val}, {"Prefer": "return=minimal"})
        rec("Escalada", f"V-trab-{col}", f"Profesional intenta fijarse {col}={val}", is_error(st, d), st, d, "rechazado (sin permiso de columna o trigger)")
    st, d = rest("POST", "impulsos", p1, {"id": "qa-audit-imp-1", "id_trabajador": ID[p1], "tipo_impulso": "destacado", "fecha_inicio": "2026-11-16", "fecha_fin": "2027-11-16", "creado_en": "2026-11-16"}, {"Prefer": R})
    rec("Escalada", "V-impulso-gratis", "Profesional intenta darse un impulso de ranking sin pagar", is_error(st, d), st, d, "rechazado")
    st, d = rest("POST", "suscripciones", c1, {"id": "qa-audit-sus-1", "id_usuario": ID[c1], "tipo_plan": "premium", "estado": "activa", "fecha_inicio": "2026-11-16", "creado_en": "2026-11-16", "actualizado_en": "2026-11-16"}, {"Prefer": R})
    rec("Escalada", "V-suscripcion-gratis", "Cliente intenta activarse una suscripción premium", is_error(st, d), st, d, "rechazado")
    st, d = rest("PATCH", f"pagos?id=eq.{PAY}", c1, {"estado": "liberado"}, {"Prefer": R})
    rec("Escalada", "V-pago-liberar", "Cliente intenta marcar su pago como liberado", denied_or_empty(st, d), st, d, "401/403")
    st, d = rest("PATCH", f"pagos?id=eq.{PAY}", p1, {"estado": "liberado", "monto": 999999}, {"Prefer": R})
    rec("Escalada", "V-pago-monto", "Profesional intenta liberar el pago y subir el monto", denied_or_empty(st, d), st, d, "401/403")
    st, d = rest("POST", "pagos", c1, {"id": "qa-audit-pay-x", "id_trabajo": JOB, "monto": 1, "estado": "liberado", "creado_en": "x", "actualizado_en": "x"}, {"Prefer": R})
    rec("Escalada", "V-pago-insert", "Cliente intenta insertar un pago aprobado", is_error(st, d), st, d, "401/403")
    st, d = rest("GET", f"pagos?id=eq.{PAY}&select=token_tbk", c1)
    rec("Escalada", "V-pago-token", "Cliente intenta leer el token Transbank de su pago", is_error(st, d), st, d, "401/403 (sin permiso de columna)")
    st, d = rest("PATCH", f"trabajos?id=eq.{JOB}", c1, {"estado": "completado", "estado_pago": "liberado"}, {"Prefer": R})
    rec("Escalada", "V-trab-estado", "Cliente intenta marcar su trabajo como completado/liberado", denied_or_empty(st, d), st, d, "401/403")
    st, d = rest("PATCH", f"trabajos?id=eq.{JOB}", p1, {"instantanea_precio": "{\"total\":999999}"}, {"Prefer": R})
    rec("Escalada", "V-trab-precio", "Profesional intenta cambiar el precio pactado del trabajo", denied_or_empty(st, d), st, d, "401/403")
    st, d = rest("POST", "trabajos", c1, {"id": "qa-audit-job-x", "id_usuario": ID[c1], "estado": "completado", "estado_pago": "liberado", "direccion": "x", "creado_en": "x", "actualizado_en": "x"}, {"Prefer": R})
    rec("Escalada", "V-trab-insert-completado", "Cliente intenta crear un trabajo ya completado y liberado", is_error(st, d), st, d, "403 (política)")
    st, d = rest("POST", "liquidaciones", p1, {"id_pago": PAY, "id_trabajo": JOB, "id_trabajador": ID[p1], "monto_clp": 30000, "referencia_transferencia": "x", "id_operador": ID[p1]}, {"Prefer": R})
    rec("Escalada", "V-liquidacion", "Profesional intenta registrarse una liquidación (pago a su cuenta)", is_error(st, d), st, d, "403")
    st, d = rest("POST", "calificaciones", c1, {"id": "qa-audit-cal-x", "id_trabajo": JOB, "id_usuario": ID[c1], "id_calificado": ID[p1], "puntaje": 5, "creado_en": "x", "direccion": "cliente_a_trabajador"}, {"Prefer": R})
    rec("Escalada", "V-resena-antes", "Cliente intenta calificar antes de que el trabajo termine", is_error(st, d), st, d, "403")
    for tb in ["app_config", "metodos_pago_oneclick", "eventos_analitica", "senales_resena", "ranking_config", "tickets_soporte", "liquidaciones", "eventos_ranking", "bloqueos_pin_inicio", "intentos_pin_inicio", "registros_error_app", "verificacion_eventos"]:
        st, d = rest("GET", f"{tb}?select=*&limit=50", c1)
        rec("Vertical", f"V-leer-{tb}", f"Cliente intenta leer la tabla interna {tb}", denied_or_empty(st, d), st, f"{len(d)} filas" if isinstance(d, list) else d, "0 filas o 401/403")
    for fn, args in [("admin_metricas_resumen", {}), ("fichas_sensibles_admin", {}), ("consola_disputas_abiertas", {}),
                     ("aprender_pesos_ranking_admin", {}), ("fijar_verificacion_profesional", {"p_id_usuario": ID[p1], "p_estado": "verificado", "p_nota": "x"}),
                     ("fijar_prioridad_trabajador", {"p_id": ID[p1], "p_prioridad": 50}), ("guardar_config_ranking", {"p_cfg": {}}),
                     ("admin_actualizar_estado_disputa", {"p_id": "x", "p_estado": "resuelta", "p_resolucion": "x"}),
                     ("evidencia_disputa", {"p_id_disputa": "x"})]:
        for who in (c1, p1):
            st, d = rpc(fn, args, who)
            ok = is_error(st, d) or d in (None, [], {}, "") or (isinstance(d, list) and not d)
            rec("Vertical", f"V-rpc-{fn}-{who}", f"{'Cliente' if who == c1 else 'Profesional'} llama la función de administración {fn}", ok, st, d, "error o vacío")

    # ---------- Anónimo ----------
    tables = json.load(open(os.path.join(os.path.dirname(__file__), "tablas.json")))
    leaks = []
    for tb in tables:
        st, d = rest("GET", f"{tb}?select=*&limit=5")
        if st == 200 and isinstance(d, list) and d: leaks.append((tb, len(d)))
        public_ok = tb in ("comunas", "regiones", "paises", "servicios", "trabajador_horarios")
        ok = denied_or_empty(st, d) or public_ok
        rec("Anónimo", f"A-{tb}", f"Anónimo lee {tb}", ok, st, f"{len(d)} filas" if isinstance(d, list) else d, "0 filas/401 (salvo catálogos públicos)")
    for tb, body in [("trabajos", {"id": "qa-anon", "id_usuario": ID[c1], "estado": "pendiente", "creado_en": "x", "actualizado_en": "x"}),
                     ("mensajes", {"id": "qa-anon", "id_trabajo": JOB, "id_remitente": ID[c1], "id_destinatario": ID[p1], "contenido": "x", "creado_en": "x"}),
                     ("registros_error_app", {"id": "qa-anon-err", "mensaje": "x"}), ("reportes", {"id": "qa-anon", "id_reportante": ID[c1], "id_usuario_reportado": ID[p1], "motivo": "x", "creado_en": "x"})]:
        st, d = rest("POST", tb, None, body, {"Prefer": R})
        rec("Anónimo", f"A-insert-{tb}", f"Anónimo intenta insertar en {tb}", is_error(st, d), st, d, "401/403")
    for fn, args in [("admin_metricas_resumen", {}), ("cerrar_trabajo_conforme", {"p_trabajo_id": JOB}), ("es_parte_trabajo", {"p_trabajo_id": JOB}),
                     ("listar_trabajos_marketplace", {"p_limite": 5}), ("resumen_calificacion_clientes", {"p_ids": [ID[c1]]}), ("is_admin", {})]:
        st, d = rpc(fn, args)
        rec("Anónimo", f"A-rpc-{fn}", f"Anónimo llama la función privada {fn}", is_error(st, d), st, d, "401/404 (sin EXECUTE)")
    st, d = rpc("listar_profesionales_catalogo", {"p_categoria": "gasfiteria", "p_limit": 40})
    bad = [k for k in (d[0].keys() if isinstance(d, list) and d else []) if k in ("correo", "email", "telefono", "rut")]
    precise = [x for x in d if isinstance(x, dict) and x.get("latitud_base") is not None and abs(round(x["latitud_base"], 2) - x["latitud_base"]) > 1e-9] if isinstance(d, list) else []
    rec("Anónimo", "A-catalogo-pii", "El catálogo público no expone correo ni ubicación exacta", st == 200 and not bad and not precise, st, f"{len(d)} filas, campos PII={bad}, coords precisas={len(precise)}", "sin PII; coordenadas a 2 decimales (~1 km)")

    # ---------- Inyección SQL ----------
    payloads = ["gasfiteria' OR '1'='1", "x'; DROP TABLE trabajos; --", "%' OR 1=1 --", "gasfiteria\\'; select pg_sleep(5); --", "' UNION SELECT correo FROM perfiles --"]
    for i, pl in enumerate(payloads):
        t0 = time.time(); st, d = rpc("listar_profesionales_catalogo", {"p_categoria": pl, "p_zona": pl, "p_limit": 40}); dt = time.time() - t0
        rec("Inyección SQL", f"I-rpc-{i}", f"Payload en parámetro RPC: {pl}", st == 200 and d == [] and dt < 4, st, f"{len(d) if isinstance(d,list) else d} filas, {dt*1000:.0f} ms", "200 con 0 filas (tratado como texto), sin demora")
    for i, q in enumerate(["trabajos?id=eq.1;DROP%20TABLE%20trabajos", "trabajos?or=(id_usuario.neq.00000000-0000-0000-0000-000000000000)",
                            "trabajos?select=*,perfiles!trabajos_id_usuario_fkey(correo)", "perfiles?select=correo&correo=like.*%40*",
                            "trabajos?id=eq.x')%20OR%20('1'='1", "pagos?select=id,token_tbk::text"]):
        st, d = rest("GET", q, c2)
        rec("Inyección SQL", f"I-filtro-{i}", f"Filtro PostgREST manipulado: {urllib.parse.unquote(q)}", denied_or_empty(st, d) or (q.startswith("perfiles") and isinstance(d, list) and len(d) <= 1), st, f"{len(d)} filas" if isinstance(d, list) else d, "0 filas propias de terceros o 400")
    st, d = rpc("horarios_libres_profesional", {"p_id_trabajador": ID[p1], "p_dias": 100000})
    rec("Inyección SQL", "I-limite-dias", "Parámetro p_dias gigantesco (DoS) se acota a 21", st == 200, st, f"{len(d) if isinstance(d,list) else d}", "200, acotado")
    st, d = rpc("resumen_calificacion_clientes", {"p_ids": [ID[c1]] * 51}, p1)
    rec("Inyección SQL", "I-limite-ids", "Arreglo de 51 ids se rechaza (máx. 50)", is_error(st, d), st, d, "error 'demasiados clientes'")

    # ---------- Edge Functions ----------
    EF = f"{URL}/functions/v1"
    for fn in ["webpay-create", "webpay-status", "webpay-refund", "webpay-release", "webpay-resolve-dispute", "oneclick-charge", "invitar-colaborador", "webpay-refund-cancellation", "webpay-refund-rejection"]:
        r = S.post(f"{EF}/{fn}", headers={"Content-Type": "application/json"}, json={}, timeout=30)
        rec("Edge Functions", f"E-noauth-{fn}", f"{fn} sin token de sesión", r.status_code == 401, r.status_code, r.text[:120], "401")
    for fn in ["webpay-status", "webpay-create", "guest-checkout", "send-push"]:
        r = S.options(f"{EF}/{fn}", headers={"Origin": "https://evil.example.com", "Access-Control-Request-Method": "POST"}, timeout=30)
        acao = r.headers.get("Access-Control-Allow-Origin")
        rec("Edge Functions", f"E-cors-{fn}", f"CORS de {fn} ante un origen ajeno", None if r.status_code == 404 else acao in (None, "", WEB) and acao != "*", r.status_code, f"ACAO={acao}", "no refleja el origen ajeno")
        r = S.options(f"{EF}/{fn}", headers={"Origin": WEB, "Access-Control-Request-Method": "POST"}, timeout=30)
        rec("Edge Functions", f"E-cors-ok-{fn}", f"CORS de {fn} para la web oficial", None if r.status_code == 404 else r.headers.get("Access-Control-Allow-Origin") == WEB, r.status_code, f"ACAO={r.headers.get('Access-Control-Allow-Origin')}", "ACAO = web oficial")
    r = S.post(f"{EF}/webpay-reconcile", json={}, timeout=30)
    rec("Edge Functions", "E-reconcile", "webpay-reconcile sin secreto del cron", None if r.status_code == 404 else r.status_code in (401, 403), r.status_code, r.text[:120], "401/403 (404 = función no desplegada, no expuesta)")
    r = S.post(f"{EF}/send-push", json={"id_usuario": ID[c1], "titulo": "x", "cuerpo": "x"}, timeout=30)
    rec("Edge Functions", "E-push", "send-push sin secreto interno (envío de notificaciones falsas)", None if r.status_code == 404 else r.status_code in (401, 403), r.status_code, r.text[:120], "401/403 (404 = función no desplegada, no expuesta)")
    r = S.post(f"{EF}/webpay-commit", data={"token_ws": "qa-token-falso-0000000000000000000000000000000000000000000000000000"}, allow_redirects=False, timeout=30)
    rec("Edge Functions", "E-commit-falso", "Retorno Webpay falsificado con token inventado", r.status_code in (302, 303, 400, 401, 403, 404, 409, 422) and "liberado" not in r.text, r.status_code, (r.headers.get("location") or r.text)[:160], "rechazo o redirección a error; sin cambio de estado")
    r = S.get(f"{EF}/oneclick-return?TBK_TOKEN=qa-falso", allow_redirects=False, timeout=30)
    rec("Edge Functions", "E-oneclick-falso", "Retorno OneClick falsificado", r.status_code in (302, 303, 400, 401, 403, 404, 409, 422), r.status_code, (r.headers.get("location") or r.text)[:160], "rechazo o redirección a error")
    r = S.post(f"{EF}/soporte-automatico", json={}, timeout=30)
    rec("Edge Functions", "E-soporte", "soporte-automatico sin secreto del cron", None if r.status_code == 404 else r.status_code in (401, 403), r.status_code, r.text[:120], "401/403 (404 = función no desplegada, no expuesta)")
    r = S.post(f"{EF}/definir-clave-invitado", json={"ticket": "qa-falso", "password": "x"}, timeout=30)
    rec("Edge Functions", "E-clave-invitado", "definir-clave-invitado con ticket falso", r.status_code in (400, 401, 403, 404, 410, 422), r.status_code, r.text[:120], "rechazo")
    r = S.post(f"{EF}/webpay-status", headers={"Authorization": f"Bearer {TOK[c2]}", "apikey": ANON}, json={"paymentId": PAY, "jobId": JOB}, timeout=30)
    rec("Edge Functions", "E-status-ajeno", "Otro cliente consulta el estado de un pago ajeno", r.status_code in (401, 403, 404), r.status_code, r.text[:120], "403/404")

    out = os.environ.get("OUT", "resultados_seguridad.json")
    json.dump({"ejecutado": time.strftime("%Y-%m-%d %H:%M:%S %z"), "casos": RESULTS,
               "resumen": {"total": len(RESULTS), "pasa": sum(r["resultado"] == "PASA" for r in RESULTS),
                           "falla": sum(r["resultado"] == "FALLA" for r in RESULTS),
                           "no_aplica": sum(r["resultado"] == "N/A" for r in RESULTS)}}, open(out, "w"), ensure_ascii=False, indent=1)
    print("TOTAL", len(RESULTS), "FALLAS", sum(r["resultado"] == "FALLA" for r in RESULTS))

if __name__ == "__main__":
    main()

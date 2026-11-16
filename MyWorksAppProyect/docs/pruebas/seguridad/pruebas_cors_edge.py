#!/usr/bin/env python3
"""Reprueba de CORS y autenticación de las Edge Functions tras el redespliegue.

No necesita usuarios: solo la URL y la clave anon pública (SB_URL, SB_ANON).
Para cada función se envía un preflight con un origen ajeno, con Origin: null
y con la web oficial. Un origen ajeno o "null" nunca debe recibirse de vuelta
en Access-Control-Allow-Origin, ni "*" ni el literal "null".
"""
import json, os, time, requests
URL = os.environ["SB_URL"]; ANON = os.environ["SB_ANON"]
WEB = "https://myworksapp-cl.vercel.app"
EF = f"{URL}/functions/v1"
FUNCS = ["webpay-create", "webpay-status", "webpay-commit", "webpay-refund", "webpay-release",
         "webpay-resolve-dispute", "webpay-refund-rejection", "webpay-refund-cancellation",
         "webpay-create-transaction", "webpay-commit-transaction", "webpay-reconcile",
         "guest-checkout", "oneclick-charge", "oneclick-return", "invitar-colaborador",
         "definir-clave-invitado"]
NOAUTH = ["webpay-create", "webpay-status", "webpay-refund", "webpay-release", "webpay-resolve-dispute",
          "oneclick-charge", "invitar-colaborador", "webpay-refund-cancellation", "webpay-refund-rejection"]
R = []
def rec(cid, caso, ok, http, det, esp):
    R.append({"categoria": "Edge Functions", "id": cid, "caso": caso, "esperado": esp, "http": http,
              "resultado": "PASA" if ok else "FALLA", "detalle": det})
    print("PASA " if ok else "FALLA", cid, http, det)
for fn in FUNCS:
    for lab, o in [("ajeno", "https://evil.example.com"), ("null", "null")]:
        r = requests.options(f"{EF}/{fn}", headers={"Origin": o, "Access-Control-Request-Method": "POST"}, timeout=30)
        a = r.headers.get("Access-Control-Allow-Origin")
        rec(f"E-cors-{lab}-{fn}", f"CORS de {fn} con Origin {o}", a in (None, "", WEB), r.status_code, f"ACAO={a}", "no refleja el origen; nunca * ni null")
    r = requests.options(f"{EF}/{fn}", headers={"Origin": WEB, "Access-Control-Request-Method": "POST"}, timeout=30)
    a = r.headers.get("Access-Control-Allow-Origin")
    rec(f"E-cors-ok-{fn}", f"CORS de {fn} para la web oficial", a == WEB, r.status_code, f"ACAO={a}", "ACAO = web oficial")
for fn in NOAUTH:
    r = requests.post(f"{EF}/{fn}", headers={"Content-Type": "application/json"}, json={}, timeout=30)
    rec(f"E-noauth-{fn}", f"{fn} sin token de sesión", r.status_code == 401, r.status_code, r.text[:100], "401")
r = requests.post(f"{EF}/webpay-reconcile", json={}, timeout=30)
rec("E-reconcile", "webpay-reconcile sin secreto del cron", r.status_code in (401, 403), r.status_code, r.text[:100], "401/403")
r = requests.post(f"{EF}/webpay-commit", data={"token_ws": "qa-token-falso-" + "0"*50}, allow_redirects=False, timeout=30)
rec("E-commit-falso", "Retorno Webpay falsificado", r.status_code in (302, 303, 400, 401, 403, 404, 409, 422) and "liberado" not in r.text, r.status_code, (r.headers.get("location") or r.text)[:120], "rechazo o redirección a error")
r = requests.get(f"{EF}/oneclick-return?TBK_TOKEN=qa-falso", allow_redirects=False, timeout=30)
rec("E-oneclick-falso", "Retorno OneClick falsificado", r.status_code in (302, 303, 400, 401, 403, 404, 409, 422), r.status_code, (r.headers.get("location") or r.text)[:120], "rechazo o redirección a error")
r = requests.post(f"{EF}/definir-clave-invitado", json={"ticket": "qa-falso", "password": "x"}, timeout=30)
rec("E-clave-invitado", "definir-clave-invitado con ticket falso", r.status_code in (400, 401, 403, 404, 410, 422), r.status_code, r.text[:100], "rechazo")
out = os.environ.get("OUT", "resultados_cors_edge.json")
json.dump({"ejecutado": time.strftime("%Y-%m-%d %H:%M:%S %z"), "casos": R,
           "resumen": {"total": len(R), "pasa": sum(x["resultado"] == "PASA" for x in R), "falla": sum(x["resultado"] == "FALLA" for x in R)}},
          open(out, "w"), ensure_ascii=False, indent=1)
print("TOTAL", len(R), "FALLAS", sum(x["resultado"] == "FALLA" for x in R))

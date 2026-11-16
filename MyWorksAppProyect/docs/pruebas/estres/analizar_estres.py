#!/usr/bin/env python3
"""Análisis de la prueba de estrés de la base de datos (k6 -> CSV).

Lee resultados/series_k6.csv (salida --out csv de k6) y produce:
  - resultados/resumen_por_etapa.csv  (requests, throughput, latencias, errores)
  - resultados/p95_por_operacion.csv  (p95 por operación y etapa)
  - graficos/estres_01_linea_tiempo.png, estres_02_percentiles_etapa.png,
    estres_03_p95_operacion.png, estres_04_escalabilidad.png
y contrasta los totales con resultados/resumen_k6.json (resumen oficial de k6).
Uso: python3 analizar_estres.py [carpeta_base]
"""
import json
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

BASE = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent
RES = BASE / "resultados"
GRAF = BASE.parent / "graficos"  # docs/pruebas/graficos, junto a los demás gráficos
GRAF.mkdir(exist_ok=True)
ETAPAS = {"E010": (10, 60), "E050": (50, 60), "E100": (100, 60), "E200": (200, 60), "R020": (20, 30), "PICO": (200, 30)}
ORDEN = list(ETAPAS)

df = pd.read_csv(RES / "series_k6.csv", usecols=["metric_name", "timestamp", "metric_value", "status", "group", "extra_tags"], low_memory=False)
df = df[df["group"].fillna("") != "::setup"]
tags = df["extra_tags"].fillna("").str.extract(r"etapa=(?P<etapa>[^&]+)").join(
    df["extra_tags"].fillna("").str.extract(r"op=(?P<op>[^&]+)"))
df = pd.concat([df, tags], axis=1)
t0 = df["timestamp"].min()
df["t"] = df["timestamp"] - t0

dur = df[df.metric_name == "http_req_duration"].copy()
fail = df[df.metric_name == "http_req_failed"].copy()
vus = df[df.metric_name == "vus"].groupby("t")["metric_value"].max()

filas = []
for e in ORDEN:
    d = dur[dur.etapa == e]["metric_value"]
    f = fail[fail.etapa == e]["metric_value"]
    vu, seg = ETAPAS[e]
    filas.append({
        "etapa": e, "vus": vu, "segundos": seg, "requests": len(d),
        "rps": round(len(d) / seg, 1),
        "avg_ms": round(d.mean(), 1), "p50_ms": round(d.quantile(.50), 1), "p90_ms": round(d.quantile(.90), 1),
        "p95_ms": round(d.quantile(.95), 1), "p99_ms": round(d.quantile(.99), 1), "max_ms": round(d.max(), 1),
        "errores": int(f.sum()), "tasa_error_pct": round(100 * f.mean(), 3) if len(f) else 0.0,
    })
res = pd.DataFrame(filas)
res.to_csv(RES / "resumen_por_etapa.csv", index=False)
print(res.to_string(index=False))

op = dur[dur.etapa.isin(ORDEN)].groupby(["op", "etapa"])["metric_value"].quantile(.95).unstack()[ORDEN].round(1)
op.to_csv(RES / "p95_por_operacion.csv")
print("\np95 por operación (ms)\n", op.to_string())

st = df[df.metric_name == "http_reqs"].groupby("status").size()
print("\nCódigos HTTP:", st.to_dict())

# Doble verificación con el resumen oficial de k6.
k6 = json.load(open(RES / "resumen_k6.json"))
m = k6["metrics"]
tot_csv = len(dur)
tot_k6 = int(m["http_reqs"]["count"])
print(f"\nTotal requests CSV={tot_csv} k6={tot_k6} (incluye setup en k6: {tot_k6 - tot_csv})")
for e in ORDEN:
    key = f"http_req_duration{{etapa:{e}}}"
    if key in m:
        p95k = m[key].get("p(95)")
        p95c = float(res.loc[res.etapa == e, "p95_ms"].iloc[0])
        print(f"  {e}: p95 CSV={p95c:.1f} ms  k6={p95k:.1f} ms  dif={abs(p95c - p95k):.1f} ms")

# Gráfico 1: línea de tiempo.
por_seg = dur.groupby("t")["metric_value"]
rps = por_seg.size()
p95_5s = dur.assign(v=(dur.t // 5) * 5).groupby("v")["metric_value"].quantile(.95)
err_5s = fail.assign(v=(fail.t // 5) * 5).groupby("v")["metric_value"].mean() * 100
fig, ax = plt.subplots(3, 1, figsize=(11, 8.5), sharex=True)
ax[0].plot(vus.index, vus.values, color="#1F4E79"); ax[0].set_ylabel("Usuarios virtuales")
ax[0].set_title("Prueba de estrés de la base de datos: carga, throughput y latencia en el tiempo")
ax[1].plot(rps.index, rps.values, color="#2E7D32", lw=.8); ax[1].set_ylabel("Requests por segundo")
ax[2].plot(p95_5s.index, p95_5s.values, color="#C62828", label="p95 (ventanas de 5 s)")
ax2 = ax[2].twinx(); ax2.bar(err_5s.index, err_5s.values, width=4, color="#FF9800", alpha=.4, label="% error")
ax2.set_ylabel("% error"); ax2.set_ylim(0, max(1.0, float(err_5s.max()) * 1.2)); ax[2].set_ylabel("Latencia p95 (ms)"); ax[2].set_xlabel("Segundos desde el inicio")
for e, (a, b) in {"E010": (30, 90), "E050": (120, 180), "E100": (210, 270), "E200": (300, 360), "R020": (390, 420), "PICO": (430, 460)}.items():
    for x in ax: x.axvspan(a, b, color="#90A4AE", alpha=.12)
    ax[0].text((a + b) / 2, vus.max() * 1.02, e, ha="center", fontsize=8)
fig.tight_layout(); fig.savefig(GRAF / "estres_01_linea_tiempo.png", dpi=150); plt.close(fig)

# Gráfico 2: percentiles por etapa.
fig, ax = plt.subplots(figsize=(10, 5))
x = range(len(res)); w = .25
for i, (c, col) in enumerate([("p50_ms", "#1F4E79"), ("p95_ms", "#F57C00"), ("p99_ms", "#C62828")]):
    ax.bar([k + (i - 1) * w for k in x], res[c], w, label=c.replace("_ms", ""), color=col)
ax.set_xticks(list(x)); ax.set_xticklabels([f"{e}\n({v} VU)" for e, v in zip(res.etapa, res.vus)])
ax.set_ylabel("Latencia (ms)"); ax.set_title("Latencia por etapa (p50, p95, p99)"); ax.legend()
fig.tight_layout(); fig.savefig(GRAF / "estres_02_percentiles_etapa.png", dpi=150); plt.close(fig)

# Gráfico 3: p95 por operación.
fig, ax = plt.subplots(figsize=(11, 5.5))
for o in op.index:
    ax.plot(ORDEN, op.loc[o].values, marker="o", label=o)
ax.set_ylabel("p95 (ms)"); ax.set_title("p95 por operación y etapa"); ax.legend(ncol=2, fontsize=8)
fig.tight_layout(); fig.savefig(GRAF / "estres_03_p95_operacion.png", dpi=150); plt.close(fig)

# Gráfico 4: escalabilidad (throughput vs usuarios).
esc = res[res.etapa.isin(["E010", "E050", "E100", "E200"])]
fig, ax = plt.subplots(figsize=(8, 5))
ax.plot(esc.vus, esc.rps, marker="o", color="#2E7D32", label="Throughput medido")
ideal = esc.rps.iloc[0] / esc.vus.iloc[0]
ax.plot(esc.vus, esc.vus * ideal, "--", color="#9E9E9E", label="Escalamiento lineal ideal")
ax.set_xlabel("Usuarios virtuales"); ax.set_ylabel("Requests por segundo")
ax3 = ax.twinx(); ax3.plot(esc.vus, esc.p95_ms, marker="s", color="#C62828", label="p95"); ax3.set_ylabel("p95 (ms)")
ax.set_title("Escalabilidad: throughput y p95 según usuarios"); ax.legend(loc="upper left"); ax3.legend(loc="lower right")
fig.tight_layout(); fig.savefig(GRAF / "estres_04_escalabilidad.png", dpi=150); plt.close(fig)
print("\nGráficos en", GRAF)

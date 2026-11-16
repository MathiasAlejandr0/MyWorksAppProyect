#!/usr/bin/env python3
"""Gráficos de la auditoría de base de datos (rendimiento y seguridad).

Lee rendimiento/escala_sintetica_resultados.json y
seguridad/resultados_seguridad_{antes,despues}.json, y escribe en graficos/:
  - rend_01_prueba_sintetica.png  (antes vs. después, escala logarítmica)
  - seg_01_resultados_categoria.png (casos que pasan por categoría)
Uso, desde docs/pruebas:  python3 graficos_auditoria_bd.py
"""
import json
from collections import Counter
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE = Path(__file__).resolve().parent
GRAF = BASE / "graficos"
GRAF.mkdir(exist_ok=True)

# Rendimiento: prueba sintética con 200.000 filas.
r = json.load(open(BASE / "rendimiento" / "escala_sintetica_resultados.json"))
casos = [
    ("R2: uuid comparado\ncomo texto vs. uuid", r["R2_cast_texto"], r["R2_uuid"]),
    ("R5: liquidaciones\nsin vs. con índice", r["R4_liq_sin_indice"], r["R4_liq_con_indice"]),
    ("R3: is_admin() por fila\nvs. InitPlan", r["R1_funcion_por_fila"], r["R1_initplan"]),
]
fig, ax = plt.subplots(figsize=(9, 4.8))
x = range(len(casos))
a = [c[1]["ms_mediana"] for c in casos]
d = [c[2]["ms_mediana"] for c in casos]
b1 = ax.bar([i - 0.2 for i in x], a, 0.4, label="Antes", color="#c0392b")
b2 = ax.bar([i + 0.2 for i in x], d, 0.4, label="Después", color="#27ae60")
ax.set_yscale("log")
ax.set_xticks(list(x)); ax.set_xticklabels([c[0] for c in casos])
ax.set_ylabel("Tiempo de ejecución, mediana (ms, escala log)")
ax.set_title("Prueba sintética con 200.000 filas: antes y después de las correcciones")
for bars in (b1, b2):
    for bar in bars:
        v = bar.get_height()
        ax.annotate(f"{v:,.3f} ms".replace(",", "X").replace(".", ",").replace("X", "."),
                    (bar.get_x() + bar.get_width() / 2, v), ha="center", va="bottom", fontsize=8)
ax.legend(); ax.grid(axis="y", alpha=0.3)
fig.tight_layout(); fig.savefig(GRAF / "rend_01_prueba_sintetica.png", dpi=150); plt.close(fig)

# Seguridad: casos por categoría antes y después.
orden = ["Control", "RLS horizontal", "Escalada", "Vertical", "Anónimo", "Inyección SQL", "Edge Functions"]
res = {}
for k in ("antes", "despues"):
    casos_s = json.load(open(BASE / "seguridad" / f"resultados_seguridad_{k}.json"))["casos"]
    res[k] = Counter((c["categoria"], c["resultado"]) for c in casos_s)
fig, axs = plt.subplots(1, 2, figsize=(11, 4.8), sharey=True)
for ax, k, titulo in ((axs[0], "antes", "Antes de las correcciones"), (axs[1], "despues", "Después de las correcciones")):
    pasa = [res[k][(c, "PASA")] for c in orden]
    falla = [res[k][(c, "FALLA")] for c in orden]
    na = [res[k][(c, "N/A")] for c in orden]
    ax.barh(orden, pasa, color="#27ae60", label="Pasa")
    ax.barh(orden, falla, left=pasa, color="#c0392b", label="Falla")
    ax.barh(orden, na, left=[p + f for p, f in zip(pasa, falla)], color="#95a5a6", label="No aplica")
    for i, (p, f, n) in enumerate(zip(pasa, falla, na)):
        ax.text(p + f + n + 0.8, i, f"{p}/{p + f + n}", va="center", fontsize=8)
    tot = sum(pasa), sum(pasa) + sum(falla) + sum(na)
    ax.set_title(f"{titulo}: {tot[0]}/{tot[1]} pasan")
    ax.set_xlabel("Casos"); ax.set_xlim(0, 75); ax.grid(axis="x", alpha=0.3)
axs[0].invert_yaxis(); axs[1].legend(loc="lower right")
fig.tight_layout(); fig.savefig(GRAF / "seg_01_resultados_categoria.png", dpi=150); plt.close(fig)
print("OK", sorted(p.name for p in GRAF.glob("*_01_*.png")))

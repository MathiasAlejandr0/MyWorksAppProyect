#!/usr/bin/env python3
"""Isolation Forest pequeño sobre eventos agregados.

No escribe en producción. Con pocos datos, o con la bandera apagada,
termina sin alertas: siguen valiendo solo las reglas SQL.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import os
import random
from pathlib import Path

PRODUCCION = "wxqrfcqifkfgawrnqmnj"
MIN_FILAS = 50
UMBRAL = 0.65


def _partir(filas: list[dict], columna: str, corte: float) -> tuple[list[dict], list[dict]]:
    izq = [fila for fila in filas if float(fila[columna]) < corte]
    der = [fila for fila in filas if float(fila[columna]) >= corte]
    return izq, der


def _arbol(filas: list[dict], columnas: list[str], alto: int, rng: random.Random) -> dict | None:
    if alto <= 0 or len(filas) < 2:
        return {"n": len(filas)}
    columna = rng.choice(columnas)
    valores = [float(fila[columna]) for fila in filas]
    minimo, maximo = min(valores), max(valores)
    if minimo == maximo:
        return {"n": len(filas)}
    corte = rng.uniform(minimo, maximo)
    izq, der = _partir(filas, columna, corte)
    if not izq or not der:
        return {"n": len(filas)}
    return {
        "columna": columna,
        "corte": corte,
        "izq": _arbol(izq, columnas, alto - 1, rng),
        "der": _arbol(der, columnas, alto - 1, rng),
    }


def _profundidad(nodo: dict | None, fila: dict, nivel: int = 0) -> float:
    if nodo is None or "columna" not in nodo:
        n = max(int((nodo or {}).get("n", 1)), 1)
        return nivel + (0 if n <= 1 else 2 * (math.log(n - 1) + 0.5772156649) - 2 * (n - 1) / n)
    if float(fila[nodo["columna"]]) < nodo["corte"]:
        return _profundidad(nodo.get("izq"), fila, nivel + 1)
    return _profundidad(nodo.get("der"), fila, nivel + 1)


def puntajes(filas: list[dict], columnas: list[str], arboles: int = 40, semilla: int = 7) -> list[float]:
    if len(filas) < 2:
        return [0.0 for _ in filas]
    rng = random.Random(semilla)
    alto = max(1, math.ceil(math.log2(len(filas))))
    bosque = [_arbol(filas, columnas, alto, rng) for _ in range(arboles)]
    c = 2 * (math.log(len(filas) - 1) + 0.5772156649) - 2 * (len(filas) - 1) / len(filas)
    if c == 0:
        c = 1
    salida = []
    for fila in filas:
        media = sum(_profundidad(arbol, fila) for arbol in bosque) / len(bosque)
        salida.append(round(2 ** (-media / c), 4))
    return salida


def leer_csv(ruta: Path) -> tuple[list[dict], list[str]]:
    with ruta.open(newline="", encoding="utf-8") as archivo:
        lector = csv.DictReader(archivo)
        filas = list(lector)
        columnas = [c for c in (lector.fieldnames or []) if c != "user_id"]
    return filas, columnas


def decidir(filas: list[dict], columnas: list[str], activa: bool) -> dict:
    if not activa or len(filas) < MIN_FILAS:
        return {
            "modo": "solo_reglas",
            "filas": len(filas),
            "activa": activa,
            "alertas": [],
            "motivo": "pocos datos o bandera apagada",
        }
    scores = puntajes(filas, columnas)
    alertas = []
    for fila, score in zip(filas, scores):
        if score >= UMBRAL:
            alertas.append({
                "user_id": fila.get("user_id"),
                "score": score,
                "propuesta": True,
            })
    return {"modo": "isolation_forest", "filas": len(filas), "activa": True, "alertas": alertas}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--entrada", required=True)
    parser.add_argument("--salida", required=True)
    args = parser.parse_args()
    url = os.environ.get("SUPABASE_URL", "")
    if PRODUCCION in url:
        raise SystemExit("Esta herramienta no escribe en la base de producción.")
    activa = os.environ.get("IA_ANOMALIAS_ACTIVAS", "0") == "1"
    filas, columnas = leer_csv(Path(args.entrada))
    informe = decidir(filas, columnas, activa)
    Path(args.salida).write_text(json.dumps(informe, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"modo": informe["modo"], "alertas": len(informe["alertas"])}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

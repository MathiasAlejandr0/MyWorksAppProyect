# -*- coding: utf-8 -*-
"""Genera el modelo entidad-relación de MyWorksApp desde el esquema vivo.

Entrada : MyWorksAppProyect/docs/_schema_public.json, el mismo snapshot del
          esquema real (solo lectura, proyecto Supabase wxqrfcqifkfgawrnqmnj)
          que usa el diccionario de datos. Una sola fuente para ambos.
Salida  : figuras/er_*.png|svg (Graphviz), fuentes/er_*.dot, modelo_er.dbml,
          modelo_er_postgres.sql, modelo_er_mysql_workbench.sql y
          validacion_modelo_er.txt (conteos y chequeos).

Uso (desde la raíz del repo grupal):
    python3 "Fase 2/modelo_entidad_relacion/_gen_modelo_er.py"
Requiere Graphviz (dot) en el PATH o en /workspace/tools/graphviz/bin.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCHEMA = HERE.parent.parent / "MyWorksAppProyect" / "docs" / "_schema_public.json"
FIG = HERE / "figuras"
SRC = HERE / "fuentes"
FONT = "DejaVu Sans"

# ---------------------------------------------------------------- dominios
DOMINIOS = [
    ("01_usuarios_territorio", "Usuarios, autenticación y territorio", "#1F4E79", "#DCE8F5", [
        "perfiles", "codigos_restablecimiento", "consentimientos_usuario", "dispositivos_push",
        "verificacion_eventos", "suscripciones", "bloqueos_usuario", "paises", "regiones", "comunas"]),
    ("02_profesionales_catalogo", "Profesionales, servicios y precios", "#8A5A12", "#F6EBD6", [
        "trabajadores", "trabajador_precios", "trabajador_servicios", "trabajador_servicios_extra",
        "trabajador_horarios", "portafolio_trabajador", "impulsos", "servicios", "configuraciones_servicio"]),
    ("03_trabajos_reservas", "Trabajos, reservas, reprogramación y PIN", "#A24A1C", "#F8E1D6", [
        "trabajos", "propuestas_cotizacion", "acuerdos_trabajo", "cancelaciones_trabajo",
        "reprogramaciones_trabajo", "pines_inicio_trabajo", "bloqueos_pin_inicio", "intentos_pin_inicio",
        "fotos_trabajo", "ubicacion_en_vivo"]),
    ("04_pagos_escrow", "Pagos, escrow, liquidaciones y cuentas bancarias", "#5C4578", "#E9E1F2", [
        "pagos", "ordenes_cambio", "liquidaciones", "metodos_pago_oneclick", "cuentas_bancarias"]),
    ("05_comunicacion_disputas", "Comunicación, notificaciones, disputas y soporte", "#1B6B4A", "#DAF0E5", [
        "mensajes", "notificaciones", "disputas", "disputa_mensajes", "tickets_soporte"]),
    ("06_calificaciones_ranking", "Calificaciones y ranking", "#2C4A6E", "#DDE5F0", [
        "calificaciones", "calificaciones_cliente", "senales_resena", "eventos_ranking",
        "ranking_aprendizaje", "ranking_config"]),
    ("07_admin_auditoria", "Administración, moderación y auditoría", "#6B2737", "#F3DDE2", [
        "acciones_pendientes", "reportes", "eventos_abuso", "registros_error_app", "eventos_analitica",
        "banderas_funcionalidad", "app_config"]),
]

CORTO = {
    "01_usuarios_territorio": "Usuarios y territorio", "02_profesionales_catalogo": "Profesionales y catálogo",
    "03_trabajos_reservas": "Trabajos y reservas", "04_pagos_escrow": "Pagos y escrow",
    "05_comunicacion_disputas": "Comunicación y disputas", "06_calificaciones_ranking": "Calificaciones y ranking",
    "07_admin_auditoria": "Administración y auditoría",
}

# Relaciones lógicas: columnas que apuntan a otra tabla sin FOREIGN KEY física.
# (tabla, columnas, tabla destino, columnas destino, explicación)
LOGICAS = [
    ("liquidaciones", ["id_trabajador"], "perfiles", ["id"],
     "profesional liquidado; text que guarda el uuid del perfil"),
    ("liquidaciones", ["id_operador"], "perfiles", ["id"],
     "administrador que confirmó la transferencia; text con uuid o 'sistema'"),
    ("metodos_pago_oneclick", ["id_trabajo_pendiente"], "trabajos", ["id"],
     "trabajo que espera la inscripción Oneclick para cobrarse"),
    ("bloqueos_pin_inicio", ["pin_ok_usuario"], "perfiles", ["id"],
     "usuario que validó el PIN (ventana pin_ok_hasta)"),
    ("trabajos", ["id_trabajador", "id_sku_servicio"], "trabajador_precios", ["id_usuario", "codigo"],
     "SKU de precio elegido; también admite 'tier_<n>', por eso no es FK"),
    ("trabajador_servicios", ["categoria_servicio"], "servicios", ["categoria"],
     "categoría ofrecida; servicios.categoria no es única"),
]
POLIMORFICAS = [
    ("notificaciones", "id_relacionado", "id de trabajo, pago, disputa u otra entidad según notificaciones.tipo"),
    ("acciones_pendientes", "id_entidad", "id de la entidad indicada en tipo_entidad (cola offline)"),
    ("tickets_soporte", "nombre_cliente / nombre_trabajador", "nombres copiados (instantánea) para el ticket"),
    ("pagos", "id_transaccion / buy_order / token_tbk", "identificadores externos de Transbank"),
    ("calificaciones", "id_calificado", "FK a perfiles; la dirección cliente→pro o pro→cliente va en direccion"),
]

# ---------------------------------------------------------------- modelo
def _fmt_tipo(c):
    dt = c["data_type"]
    if dt == "numeric" and c["numeric_precision"] is not None:
        return f"numeric({c['numeric_precision']},{c['numeric_scale']})"
    if dt == "character varying" and c["character_maximum_length"]:
        return f"character varying({c['character_maximum_length']})"
    if dt == "ARRAY":
        return c["udt_name"].lstrip("_") + "[]"
    return dt


def _lista(v):
    return [x for x in (v or "").strip("{}").split(",") if x and x != "NULL"]


def leer_snapshot():
    """Convierte _schema_public.json al formato compacto que usa este script."""
    snap = json.loads(SCHEMA.read_text(encoding="utf-8"))
    tipo = {"PRIMARY KEY": "p", "FOREIGN KEY": "f", "UNIQUE": "u"}
    cons = []
    for k in snap["constraints"]:
        if k["constraint_type"] not in tipo:
            continue
        item = {"t": k["table_name"], "name": k["constraint_name"], "type": tipo[k["constraint_type"]],
                "cols": _lista(k["columns"])}
        if item["type"] == "f":
            m = re.search(r"ON DELETE (CASCADE|SET NULL|RESTRICT|SET DEFAULT|NO ACTION)", k["definition"])
            item.update(rt=k["foreign_table"], rs=k["foreign_schema"],
                        rcols=[x.strip() for x in (k["foreign_column"] or "").split(",")],
                        **{"del": {"CASCADE": "c", "SET NULL": "n", "RESTRICT": "r", "SET DEFAULT": "d"}.get(m.group(1) if m else "", "a")})
        cons.append(item)
    return {
        "migr": snap["latest_migration_version"],
        "migr_nombre": snap.get("latest_migration_name"),
        "tables": sorted(t["name"] for t in snap["tables"]),
        "cols": [{"t": c["table_name"], "c": c["column_name"], "ty": _fmt_tipo(c), "nn": c["is_nullable"] == "NO",
                  "n": c["ordinal_position"]} for c in snap["columns"]],
        "cons": cons,
        "uidx": [{"t": i["table_name"], "i": i["index_name"], "def": i["definition"]}
                 for i in snap["indexes"] if i["is_unique"] and not i["is_primary"]],
    }


def cargar():
    d = leer_snapshot()
    cols = defaultdict(list)
    for c in sorted(d["cols"], key=lambda x: (x["t"], x["n"])):
        cols[c["t"]].append(c)
    pk, fks, uq = {}, [], defaultdict(list)
    for k in d["cons"]:
        if k["type"] == "p":
            pk[k["t"]] = k["cols"]
        elif k["type"] == "u":
            uq[k["t"]].append(k["cols"])
        elif k["type"] == "f":
            fks.append(k)
    for u in d.get("uidx") or []:
        if " WHERE " in u["def"]:
            continue  # índice único parcial: no cambia la cardinalidad general
        m = re.search(r"USING btree \((.*)\)$", u["def"])
        if m and "(" not in m.group(1):
            uq[u["t"]].append([x.strip().strip('"') for x in m.group(1).split(",")])
    for t in list(uq):
        seen, out = set(), []
        for u in uq[t]:
            if tuple(u) not in seen:
                seen.add(tuple(u)); out.append(u)
        uq[t] = out
    return d, cols, pk, fks, uq


def es_unico(t, colset, pk, uq):
    s = set(colset)
    return set(pk.get(t, [])) == s or any(set(u) == s for u in uq.get(t, []))


def cardinalidad(fk, cols, pk, uq):
    """Devuelve (lado_hijo, lado_padre) como texto y flechas Graphviz."""
    t = fk["t"]
    nn = all(next(c for c in cols[t] if c["c"] == x)["nn"] for x in fk["cols"])
    uni = es_unico(t, fk["cols"], pk, uq)
    padre = ("1", "teetee") if nn else ("0..1", "teeodot")
    hijo = ("0..1", "teeodot") if uni else ("0..N", "crowodot")
    return hijo, padre


TYPE_SHORT = {
    "timestamp with time zone": "timestamptz",
    "time without time zone": "time",
    "double precision": "float8",
    "character varying": "varchar",
}


def tshort(ty):
    for a, b in TYPE_SHORT.items():
        ty = ty.replace(a, b)
    return ty


def esc(s):
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


DOM_OF = {}
for _k, _n, _c, _bg, _ts in DOMINIOS:
    for _t in _ts:
        DOM_OF[_t] = (_k, _n, _c, _bg)

# ---------------------------------------------------------------- DOT
def dot_bin():
    for c in [shutil.which("dot"), "/workspace/tools/graphviz/bin/dot"]:
        if c and Path(c).exists():
            return c
    sys.exit("Falta Graphviz (dot).")


def nodo_completo(t, cols, pk, fkcols, logcols, color, bg, fs=18):
    rows = [f'<tr><td colspan="3" bgcolor="{color}" align="left" cellpadding="6">'
            f'<font color="white" point-size="{fs+3}"><b>{esc(t)}</b></font></td></tr>']
    for c in cols[t]:
        tags = []
        if c["c"] in pk.get(t, []):
            tags.append("PK")
        if c["c"] in fkcols.get(t, set()):
            tags.append("FK")
        if c["c"] in logcols.get(t, set()):
            tags.append("FK*")
        tag = ",".join(tags)
        name = esc(c["c"])
        if "PK" in tags:
            name = f"<b><u>{name}</u></b>"
        elif "FK" in tags:
            name = f"<i>{name}</i>"
        nn = "" if c["nn"] or "PK" in tags else "?"
        cbg = bg if tags else "white"
        tagtxt = f'<font point-size="{fs-2}" color="#555555">{tag}</font>' if tag else " "
        rows.append(
            f'<tr><td port="{c["c"]}_w" align="left" bgcolor="{cbg}">{tagtxt}</td>'
            f'<td align="left" bgcolor="{cbg}"><font point-size="{fs}">{name}</font></td>'
            f'<td port="{c["c"]}_e" align="left" bgcolor="{cbg}"><font point-size="{fs-1}" color="#444444">{esc(tshort(c["ty"]))}{nn}</font></td></tr>')
    return (f'"{t}" [label=<<table border="1" cellborder="0" cellspacing="0" cellpadding="3" color="{color}">'
            + "".join(rows) + "</table>>];")


def nodo_externo(t, pk, color="#7F7F7F", fs=18):
    pks = ", ".join(pk.get(t, []))
    return (f'"{t}" [label=<<table border="1" cellborder="0" cellspacing="0" cellpadding="5" color="{color}" style="dashed">'
            f'<tr><td bgcolor="#EFEFEF"><font point-size="{fs+1}" color="#333333"><b>{esc(t)}</b></font></td></tr>'
            f'<tr><td><font point-size="{fs-2}" color="#555555">PK {esc(pks)} · otro dominio</font></td></tr></table>>];')


def nodo_resumen(t, pk, color, bg, fs=34):
    pks = ", ".join(pk.get(t, []))
    return (f'"{t}" [label=<<table border="1" cellborder="0" cellspacing="0" cellpadding="5" color="{color}">'
            f'<tr><td bgcolor="{color}"><font color="white" point-size="{fs}"><b>{esc(t)}</b></font></td></tr>'
            f'<tr><td bgcolor="white"><font point-size="{fs-4}" color="#333333">PK {esc(pks)}</font></td></tr></table>>];')


def diagrama_dominios(cols, pk, fks):
    """Mapa de dominios: cada dominio con sus tablas y las FK que cruzan dominios."""
    out = ['digraph dominios {', GRAPH_ATTR, 'rankdir="TB"; nodesep="0.35"; ranksep="0.9"; concentrate="false"; splines="spline";',
           '<font point-size="34"><b>MyWorksApp · Mapa de dominios del modelo de datos</b></font>'
           '<br/><font point-size="22" color="#555555">52 tablas en 7 dominios · el número en cada flecha = claves foráneas que cruzan de un dominio a otro</font>'.join(['label=<', '>;'])]
    nfk = defaultdict(int)
    for key, nombre, color, bg, ts in DOMINIOS:
        n_int = sum(1 for f in fks if f["rs"] == "public" and f["t"] in ts and f["rt"] in ts)
        filas = "".join(f'<tr><td align="left" bgcolor="white"><font point-size="22">{esc(t)}</font></td></tr>' for t in ts)
        out.append(f'"{key}" [label=<<table border="2" cellborder="0" cellspacing="0" cellpadding="5" color="{color}">'
                   f'<tr><td bgcolor="{color}" align="left"><font color="white" point-size="26"><b>{esc(CORTO[key])}</b></font></td></tr>'
                   f'<tr><td bgcolor="{bg}" align="left"><font point-size="20">{len(ts)} tablas · {n_int} FK internas</font></td></tr>'
                   f'{filas}</table>>];')
    for f in fks:
        if f["rs"] != "public":
            continue
        a, b = DOM_OF[f["t"]][0], DOM_OF[f["rt"]][0]
        if a != b:
            nfk[(a, b)] += 1
    for (a, b), n in sorted(nfk.items()):
        col = next(c for k, _n, c, _b, _t in DOMINIOS if k == a)
        out.append(f'"{a}" -> "{b}" [label=<<font point-size="24"><b> {n} </b></font>>, dir="forward", '
                   f'arrowhead="teetee", arrowtail="none", color="{col}", fontcolor="{col}", penwidth="{1.5 + n * 0.25:.2f}"];')
    out.append('auth [label=<<table border="1" cellborder="0" cellpadding="6" color="#7F7F7F" style="dashed">'
               '<tr><td bgcolor="#EFEFEF"><font point-size="24"><b>auth.users</b> (Supabase)</font></td></tr></table>>];')
    out.append('{rank="same"; "04_pagos_escrow"; "03_trabajos_reservas"; "05_comunicacion_disputas"; "06_calificaciones_ranking";}')
    out.append('{rank="same"; "07_admin_auditoria"; "01_usuarios_territorio"; "02_profesionales_catalogo"; auth;}')
    out.append('"01_usuarios_territorio" -> auth [label=<<font point-size="24"><b> 1 </b></font>>, dir="forward", arrowhead="teetee", color="#7F7F7F"];')
    out.append("}")
    return "\n".join(out)


def render(name, dot_text, width_px):
    SRC.mkdir(exist_ok=True)
    FIG.mkdir(exist_ok=True)
    src = SRC / f"er_{name}.dot"
    src.write_text(dot_text, encoding="utf-8")
    dot = dot_bin()
    svg = FIG / f"er_{name}.svg"
    subprocess.run([dot, "-Tsvg", str(src), "-o", str(svg)], check=True)
    # tamaño natural (pt) para fijar dpi y lograr el ancho deseado
    head = svg.read_text(encoding="utf-8")[:2000]
    wpt = float(re.search(r'width="([\d.]+)pt"', head).group(1))
    dpi = max(72, round(width_px / (wpt / 72.0)))
    png = FIG / f"er_{name}.png"
    subprocess.run([dot, "-Tpng", f"-Gdpi={dpi}", str(src), "-o", str(png)], check=True)
    try:  # paleta de 128 colores: ~3 veces más liviano, sin pérdida visible en texto y líneas
        from PIL import Image
        im = Image.open(png).convert("RGB")
        im.quantize(colors=128, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(png, optimize=True)
    except ImportError:
        pass
    return png, wpt


GRAPH_ATTR = (f'graph [fontname="{FONT}", bgcolor="white", pad="0.3", nodesep="0.3", ranksep="0.9", '
              f'splines="spline", labelloc="t", labeljust="l"];\n'
              f'node [shape=plaintext, fontname="{FONT}"];\n'
              f'edge [fontname="{FONT}", color="#444444", penwidth="1.6", arrowsize="1.3", dir="both"];\n')


def leyenda(fs=16):
    return (f'leyenda [label=<<table border="1" cellborder="0" cellspacing="0" cellpadding="4" color="#999999">'
            f'<tr><td align="left"><font point-size="{fs+1}"><b>Leyenda</b></font></td></tr>'
            f'<tr><td align="left"><font point-size="{fs}">PK clave primaria (subrayada) · FK clave foránea física (cursiva)</font></td></tr>'
            f'<tr><td align="left"><font point-size="{fs}">FK* relación lógica sin FOREIGN KEY (línea punteada)</font></td></tr>'
            f'<tr><td align="left"><font point-size="{fs}">? columna que admite NULL · caja gris = tabla de otro dominio</font></td></tr>'
            f'<tr><td align="left"><font point-size="{fs}">Pata de gallo = muchos · ┼ = uno · o = opcional (notación crow\'s foot)</font></td></tr>'
            f'</table>>];\n')


def diagrama_dominio(key, nombre, color, bg, tablas, cols, pk, fks, uq):
    fkcols = defaultdict(set)
    for f in fks:
        fkcols[f["t"]].update(f["cols"])
    logcols = defaultdict(set)
    for t, cs, *_ in LOGICAS:
        for c in cs:
            if c not in fkcols[t]:
                logcols[t].add(c)
    out = [f'digraph "{key}" {{', GRAPH_ATTR, 'rankdir="LR";',
           f'label=<<font point-size="26" color="{color}"><b>Modelo ER · {esc(nombre)}</b></font>'
           f'<br/><font point-size="15" color="#555555">{len(tablas)} tablas · columnas, tipos, PK/FK y cardinalidad</font>>;']
    externos = set()
    edges = []
    cnt = defaultdict(set)
    for f in fks:
        if f["rs"] == "public" and f["t"] in tablas and f["t"] != f["rt"]:
            cnt[f["rt"]].add(f["t"])
    hub = max(cnt, key=lambda k: len(cnt[k])) if cnt else None
    derecha = set()
    if hub and len(cnt[hub]) >= 5:
        hijos = [t for t in tablas if t in cnt[hub]]
        derecha = set(hijos[1::2])
    entrantes = defaultdict(set)   # tabla del dominio -> tablas de otros dominios que la referencian
    for f in fks:
        if f["rs"] != "public":
            continue
        a, b = f["t"], f["rt"]
        if a not in tablas:
            if b in tablas:
                entrantes[b].add(a)
            continue
        (hl, ha), (pl, pa) = cardinalidad(f, cols, pk, uq)
        if b not in tablas:
            externos.add(b)
        if a in derecha and b == hub:
            tp = f'"{a}":"{f["cols"][0]}_w":w'
            hp = f'"{b}":"{f["rcols"][0]}_e":e' if b in tablas else f'"{b}":e'
            edges.append(f'{hp} -> {tp} [arrowtail="{pa}", arrowhead="{ha}", color="{color}"];  // {a}.{f["cols"][0]} FK')
        else:
            tp = f'"{a}":"{f["cols"][0]}_e":e'
            hp = f'"{b}":"{f["rcols"][0]}_w":w' if b in tablas else f'"{b}":w'
            edges.append(f'{tp} -> {hp} [arrowtail="{ha}", arrowhead="{pa}", color="{color}"];')
    for t, cs, rt, rcs, _ in LOGICAS:
        if t not in tablas:
            if rt in tablas:
                entrantes[rt].add(t + " (lógica)")
            continue
        if rt not in tablas:
            externos.add(rt)
        tp = f'"{t}":"{cs[-1]}_e":e'
        hp = f'"{rt}":"{rcs[-1]}_w":w' if rt in tablas else f'"{rt}":w'
        edges.append(f'{tp} -> {hp} [style="dashed", arrowtail="crowodot", arrowhead="teeodot", color="#999999"];')
    if entrantes:
        def _wrap(items, n=3):
            items = sorted(items)
            return "<br align=\"left\"/>".join(esc(", ".join(items[i:i+n])) for i in range(0, len(items), n))
        filas = "".join(
            f'<tr><td align="left"><font point-size="16"><b>{esc(t)}</b> ← {len(v)} tabla(s):<br align="left"/>'
            f'{_wrap(v)}<br align="left"/></font></td></tr>'
            for t, v in sorted(entrantes.items()))
        out.append(f'entrantes [label=<<table border="1" cellborder="0" cellspacing="0" cellpadding="4" color="#999999">'
                   f'<tr><td align="left"><font point-size="17"><b>Referencias desde otros dominios</b><br align="left"/>(ver diagrama general)<br align="left"/></font></td></tr>'
                   f'{filas}</table>>];')
    for t in tablas:
        out.append(nodo_completo(t, cols, pk, fkcols, logcols, color, bg))
    for t in sorted(externos):
        out.append(nodo_externo(t, pk))
    out += edges
    out.append(leyenda())
    out.append("}")
    return "\n".join(out)


def diagrama_general(cols, pk, fks, uq):
    out = [f'digraph general {{', GRAPH_ATTR,
           'rankdir="LR"; nodesep="0.15"; ranksep="0.6"; concentrate="true";',
           f'label=<<font point-size="56"><b>MyWorksApp · Modelo entidad-relación general</b></font>'
           f'<br/><font point-size="34" color="#555555">52 tablas del esquema public agrupadas en 7 dominios · '
           f'líneas = claves foráneas (pata de gallo = muchos) · punteadas = relaciones lógicas</font>>;']
    for key, nombre, color, bg, ts in DOMINIOS:
        out.append(f'subgraph "cluster_{key}" {{ style="rounded,filled"; fillcolor="{bg}"; color="{color}"; penwidth="2.5";'
                   f'label=<<font point-size="42" color="{color}"><b>{esc(nombre)}</b></font>>;')
        for t in ts:
            out.append(nodo_resumen(t, pk, color, bg))
        out.append("}")
    for f in fks:
        if f["rs"] != "public":
            continue
        (hl, ha), (pl, pa) = cardinalidad(f, cols, pk, uq)
        col = DOM_OF[f["t"]][2]
        out.append(f'"{f["t"]}" -> "{f["rt"]}" [arrowtail="{ha}", arrowhead="{pa}", color="{col}", penwidth="2"];')
    for t, cs, rt, rcs, _ in LOGICAS:
        out.append(f'"{t}" -> "{rt}" [style="dashed", arrowtail="crowodot", arrowhead="teeodot", color="#888888", penwidth="2"];')
    out.append('auth_users [label=<<table border="1" cellborder="0" cellpadding="6" color="#7F7F7F" style="dashed">'
               '<tr><td bgcolor="#EFEFEF"><font point-size="22"><b>auth.users</b></font></td></tr>'
               '<tr><td><font point-size="18" color="#555555">esquema auth (Supabase)</font></td></tr></table>>];')
    out.append('"perfiles" -> auth_users [arrowtail="teetee", arrowhead="teetee", color="#7F7F7F", penwidth="2"];')
    out.append("}")
    return "\n".join(out)


# ---------------------------------------------------------------- DBML / SQL
def write_dbml(d, cols, pk, fks, uq):
    L = ["// MyWorksApp — modelo entidad-relación generado desde la BD viva",
         f"// Proyecto wxqrfcqifkfgawrnqmnj · migración {d['migr']} · abrir en https://dbdiagram.io",
         "Project MyWorksApp { database_type: 'PostgreSQL' }", ""]
    for t in sorted(cols):
        L.append(f"Table {t} {{")
        multi = len(pk.get(t, [])) > 1
        for c in cols[t]:
            s = []
            if c["c"] in pk.get(t, []) and not multi:
                s.append("pk")
            if c["nn"] and "pk" not in s:
                s.append("not null")
            ty = c["ty"].replace(" ", "_") if " " in c["ty"] else c["ty"]
            ty = f'"{c["ty"]}"' if (" " in c["ty"] or "(" in c["ty"]) else c["ty"]
            L.append(f"  {c['c']} {ty}" + (f" [{', '.join(s)}]" if s else ""))
        idx = []
        if multi:
            idx.append(f"    ({', '.join(pk[t])}) [pk]")
        for u in uq.get(t, []):
            idx.append(f"    ({', '.join(u)}) [unique]")
        if idx:
            L += ["  indexes {"] + idx + ["  }"]
        L += ["}", ""]
    dl = {"c": "cascade", "n": "set null", "a": "no action", "r": "restrict", "d": "set default"}
    for f in fks:
        if f["rs"] != "public":
            continue
        a = f"{f['t']}.{f['cols'][0]}" if len(f["cols"]) == 1 else f"{f['t']}.({', '.join(f['cols'])})"
        b = f"{f['rt']}.{f['rcols'][0]}" if len(f["rcols"]) == 1 else f"{f['rt']}.({', '.join(f['rcols'])})"
        op = "-" if es_unico(f["t"], f["cols"], pk, uq) else ">"
        L.append(f"Ref: {a} {op} {b} [delete: {dl[f['del']]}]")
    L.append("// perfiles.id referencia auth.users.id (esquema auth de Supabase, ON DELETE CASCADE)")
    L.append("")
    L.append("// Relaciones lógicas (sin FOREIGN KEY física):")
    for t, cs, rt, rcs, why in LOGICAS:
        L.append(f"//   {t}.({', '.join(cs)}) -> {rt}.({', '.join(rcs)}) — {why}")
    L.append("")
    for key, nombre, *_rest in DOMINIOS:
        L.append(f"TableGroup {key[3:]} {{ // {nombre}")
        L += [f"  {t}" for t in _rest[-1]]
        L.append("}")
    (HERE / "modelo_er.dbml").write_text("\n".join(L) + "\n", encoding="utf-8")


MYSQL_TYPES = [
    (r"^uuid$", "CHAR(36)"), (r"^text$", "VARCHAR(255)"), (r"^integer$", "INT"), (r"^smallint$", "SMALLINT"),
    (r"^bigint$", "BIGINT"), (r"^boolean$", "TINYINT(1)"), (r"^numeric\((\d+),(\d+)\)$", r"DECIMAL(\1,\2)"),
    (r"^numeric$", "DECIMAL(14,4)"), (r"^double precision$", "DOUBLE"), (r"^jsonb?$", "JSON"),
    (r"^timestamp with time zone$", "DATETIME(6)"), (r"^time without time zone$", "TIME"), (r"^bytea$", "LONGBLOB"),
]
LONG_TEXT = re.compile(r"(descripcion|comentario|cuerpo|contenido|mensaje|traza|datos|metadatos|nota|detalle|aviso|esquema_config|desglose|instantanea|valor|resolucion|url|horarios)")


def mysql_type(c):
    for pat, rep in MYSQL_TYPES:
        if re.match(pat, c["ty"]):
            r = re.sub(pat, rep, c["ty"])
            if r == "VARCHAR(255)" and LONG_TEXT.search(c["c"]):
                return "TEXT"
            return r
    return "TEXT"


def write_sql(d, cols, pk, fks, uq):
    dl = {"c": "CASCADE", "n": "SET NULL", "a": "NO ACTION", "r": "RESTRICT", "d": "SET DEFAULT"}
    for dialect in ("postgres", "mysql_workbench"):
        my = dialect != "postgres"
        q = (lambda s: f"`{s}`") if my else (lambda s: f'"{s}"' if not re.match(r"^[a-z_][a-z0-9_]*$", s) else s)
        L = [f"-- MyWorksApp — modelo entidad-relación ({'MySQL 8 / MySQL Workbench' if my else 'PostgreSQL'})",
             f"-- Generado desde la BD viva wxqrfcqifkfgawrnqmnj (migración {d['migr']}).",
             "-- Solo estructura (tablas, PK, UNIQUE, FK). Sin RLS, funciones ni datos.",
             ("-- Para el diagrama: MySQL Workbench > File > Import > Reverse Engineer MySQL Create Script."
              if my else "-- Esquema de referencia: no ejecutar contra producción."), ""]
        if my:
            L += ["CREATE DATABASE IF NOT EXISTS myworksapp;", "USE myworksapp;", "SET FOREIGN_KEY_CHECKS = 0;", ""]
        else:
            L += ["-- perfiles.id referencia auth.users(id) en Supabase; aquí se omite esa FK externa.", ""]
        for t in sorted(cols):
            body = []
            for c in cols[t]:
                ty = mysql_type(c) if my else c["ty"]
                body.append(f"  {q(c['c'])} {ty}{' NOT NULL' if c['nn'] else ''}")
            body.append(f"  PRIMARY KEY ({', '.join(q(x) for x in pk[t])})")
            for i, u in enumerate(uq.get(t, [])):
                body.append(f"  {'UNIQUE KEY ' + q(f'uq_{t}_{i+1}') if my else 'UNIQUE'} ({', '.join(q(x) for x in u)})")
            L.append(f"CREATE TABLE {q(t)} (\n" + ",\n".join(body) + f"\n){' ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' if my else ''};\n")
        for f in fks:
            if f["rs"] != "public":
                continue
            L.append(f"ALTER TABLE {q(f['t'])} ADD CONSTRAINT {q(f['name'][:60])} FOREIGN KEY ({', '.join(q(x) for x in f['cols'])}) "
                     f"REFERENCES {q(f['rt'])} ({', '.join(q(x) for x in f['rcols'])}) ON DELETE {dl[f['del']]};")
        L.append("")
        L.append("-- Relaciones lógicas (sin FOREIGN KEY física en la BD real):")
        for t, cs, rt, rcs, why in LOGICAS:
            L.append(f"--   {t}({', '.join(cs)}) -> {rt}({', '.join(rcs)}): {why}")
        if my:
            L += ["", "SET FOREIGN_KEY_CHECKS = 1;"]
        (HERE / f"modelo_er_{dialect}.sql").write_text("\n".join(L) + "\n", encoding="utf-8")


# ---------------------------------------------------------------- validación
def validar(d, cols, pk, fks, uq, pngs):
    V = []
    tablas = set(d["tables"])
    asignadas = [t for *_x, ts in DOMINIOS for t in ts]
    falt = tablas - set(asignadas)
    dup = {t for t in asignadas if asignadas.count(t) > 1}
    extra = set(asignadas) - tablas
    fk_pub = [f for f in fks if f["rs"] == "public"]
    V.append(f"Migración más reciente en la BD: {d['migr']}")
    V.append(f"Tablas public: {len(tablas)} · columnas: {sum(len(v) for v in cols.values())} · PK: {len(pk)} · "
             f"FK: {len(fks)} ({len(fk_pub)} internas + {len(fks)-len(fk_pub)} a auth.users) · UNIQUE: {sum(len(v) for v in uq.values())}")
    V.append(f"Tablas sin dominio: {sorted(falt) or 'ninguna'} · repetidas: {sorted(dup) or 'ninguna'} · inexistentes: {sorted(extra) or 'ninguna'}")
    V.append(f"Tablas sin PK: {sorted(tablas - set(pk)) or 'ninguna'}")
    # cada FK dibujada en al menos un diagrama de dominio (lo garantiza la construcción): se verifica en los .dot
    dots = "".join(p.read_text(encoding="utf-8") for p in SRC.glob("er_0[1-9]_*.dot"))
    miss = [f"{f['t']}.{f['cols'][0]}" for f in fk_pub
            if f'"{f["t"]}":"{f["cols"][0]}_e":e -> "{f["rt"]}' not in dots
            and f'// {f["t"]}.{f["cols"][0]} FK' not in dots]
    V.append(f"FK internas ausentes de los diagramas por dominio: {miss or 'ninguna'}")
    gen = (SRC / "er_00_general.dot").read_text(encoding="utf-8")
    missg = [f"{f['t']}->{f['rt']}" for f in fk_pub if f'"{f["t"]}" -> "{f["rt"]}"' not in gen]
    V.append(f"FK internas ausentes del diagrama general: {missg or 'ninguna'}")
    for t, cs, rt, rcs, _ in LOGICAS:
        okc = all(any(c["c"] == x for c in cols[t]) for x in cs) and all(any(c["c"] == x for c in cols[rt]) for x in rcs)
        tiene_fk = any(f["t"] == t and f["cols"] == cs for f in fks)
        V.append(f"Lógica {t}.({','.join(cs)}) -> {rt}.({','.join(rcs)}): columnas {'OK' if okc else 'NO EXISTEN'}"
                 f"{' · YA TIENE FK FÍSICA (quitar de LOGICAS)' if tiene_fk else ''}")
    for p, wpt in pngs:
        from PIL import Image
        w, h = Image.open(p).size
        V.append(f"{p.name}: {w}x{h}px · ancho natural {wpt:.0f} pt · letra de columnas a 16,5 cm de ancho ≈ "
                 f"{(34 if 'general' in p.name else (22 if 'dominios' in p.name else 18)) * 467.7 / wpt:.1f} pt; a 24,7 cm (hoja horizontal) ≈ "
                 f"{(34 if 'general' in p.name else (22 if 'dominios' in p.name else 18)) * 700 / wpt:.1f} pt")
    (HERE / "validacion_modelo_er.txt").write_text("\n".join(V) + "\n", encoding="utf-8")
    return V


def main():
    d, cols, pk, fks, uq = cargar()
    pngs = []
    pngs.append(render("00_general", diagrama_general(cols, pk, fks, uq), 4200))
    pngs.append(render("00_dominios", diagrama_dominios(cols, pk, fks), 2400))
    for key, nombre, color, bg, ts in DOMINIOS:
        pngs.append(render(key, diagrama_dominio(key, nombre, color, bg, ts, cols, pk, fks, uq), 2400))
    write_dbml(d, cols, pk, fks, uq)
    write_sql(d, cols, pk, fks, uq)
    for line in validar(d, cols, pk, fks, uq, pngs):
        print(line)


if __name__ == "__main__":
    main()

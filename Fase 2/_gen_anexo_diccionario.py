# -*- coding: utf-8 -*-
"""Arma el diccionario del Anexo A: una tabla con cada tabla y sus atributos.

Fuente: Fase 2/modelo_entidad_relacion.dbml (modelo lógico v2.3).
"""
import importlib.util
import re
import zipfile
from pathlib import Path

from lxml import etree

ROOT = Path(__file__).resolve().parent
DBML = ROOT / "modelo_entidad_relacion.dbml"
OUT_DOCX = ROOT / "Anexo_A_Diccionario_de_tablas.docx"
OUT_MD = ROOT / "Anexo_A_Diccionario_de_tablas.md"
GEN = ROOT.parent / "MyWorksAppProyect" / "docs" / "_gen_diccionario_docx.py"

NOTAS = {
    "regiones": "Región administrativa de un país.",
    "comunas": "Comuna de cobertura. Su identificador es el slug usado por trabajos y trabajadores.",
    "notificaciones": "Aviso dentro de la aplicación dirigido a un usuario.",
    "suscripciones": "Plan de suscripción contratado por un usuario.",
    "codigos_restablecimiento": "Código temporal para restablecer la contraseña.",
    "consentimientos_usuario": "Registro de aceptación de una versión de consentimiento.",
    "bloqueos_usuario": "Bloqueo de un usuario hacia otro.",
    "reportes": "Denuncia de un usuario contra otro.",
    "eventos_abuso": "Detección de abuso y la acción que se tomó.",
    "acciones_pendientes": "Acción hecha sin conexión, pendiente de sincronizar.",
    "registros_error_app": "Error de la aplicación informado por un cliente.",
    "eventos_analitica": "Evento de uso registrado por la aplicación.",
    "banderas_funcionalidad": "Interruptor de una función por versión, rol o usuario.",
    "portafolio_trabajador": "Foto o medio del portafolio de un profesional.",
    "impulsos": "Promoción temporal de visibilidad de un profesional.",
    "servicios": "Catálogo de oficios que la plataforma ofrece.",
    "configuraciones_servicio": "Esquema de configuración asociado a un servicio.",
    "mensajes": "Mensaje del chat de un trabajo.",
    "fotos_trabajo": "Evidencia fotográfica o de video de un trabajo.",
    "disputas": "Disputa abierta sobre un trabajo y su resolución.",
    "tickets_soporte": "Ticket de soporte asociado a un trabajo.",
    "propuestas_cotizacion": "Cotización que un profesional envía para un trabajo.",
    "ordenes_cambio": "Cambio de alcance o de precio durante un trabajo.",
    "ranking_aprendizaje": "Ajuste de los pesos del ranking y las métricas de ese cambio.",
    "eventos_ranking": "Evento que alimenta el ranking de un profesional.",
}


def load_parser():
    spec = importlib.util.spec_from_file_location("gen_diccionario", GEN)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def fk_map(refs):
    out = {}
    for ref in refs:
        m = re.match(r"(\w+)\.(\w+)\s+[><-]\s+(\w+)\.(\w+)", ref)
        if m:
            out[(m.group(1), m.group(2))] = f"{m.group(3)}.{m.group(4)}"
    return out


def pk_columns(table):
    names = set()
    for col in table["columns"]:
        flags = col["flags"].lower()
        if re.search(r"\bpk\b", flags):
            names.add(col["name"])
    for idx in table["indexes"]:
        if re.search(r"\bpk\b", idx.lower()):
            cols = re.match(r"\(([^)]+)\)", idx.strip())
            if cols:
                for name in cols.group(1).split(","):
                    names.add(name.strip().strip('"'))
    return names


GRUPOS = {
    "identidad": "Identidad y cuenta",
    "territorio": "Territorio",
    "catalogo_4nf": "Catálogo del profesional",
    "pedido": "Pedido y servicio",
    "cobro": "Cobro",
    "ranking": "Ranking y reputación",
}

INTRO = (
    "A continuación se describe cada una de las 43 tablas del esquema public. "
    "Los atributos se listan con su tipo de dato y su restricción. "
    "PK indica la clave primaria y FK la clave foránea. "
    "perfiles.id coincide con el identificador de autenticación de Supabase (auth.users.id)."
)


def restriccion(col, pks, fk):
    partes = []
    flags = col["flags"].lower()
    if col["name"] in pks:
        partes.append("PK")
    if fk:
        partes.append(f"FK → {fk}")
    if "not null" in flags or col["name"] in pks:
        partes.append("Obligatorio")
    else:
        partes.append("Opcional")
    if re.search(r"\bunique\b", flags):
        partes.append("Único")
    texto = ", ".join(partes)
    nota = col["note"].strip()
    if nota:
        texto = f"{texto}. {nota}"
    return texto


def notas_de_tabla(text):
    """La nota de tabla que va después de un bloque indexes no la toma el parser."""
    notes = {}
    for match in re.finditer(r"^Table\s+(\w+)\s*\{", text, re.M):
        name = match.group(1)
        i = match.end()
        depth = 1
        start = i
        while i < len(text) and depth:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        found = re.findall(r"(?m)^[ \t]*Note:\s*'([^']*)'", text[start:i - 1])
        if found:
            notes[name] = found[-1]
    return notes


def entradas(ordered, groups, fks, notas_dbml):
    grupo_de = {}
    for nombre, miembros in groups.items():
        for tabla in miembros:
            grupo_de[tabla] = nombre
    items = []
    for i, table in enumerate(ordered, 1):
        pks = pk_columns(table)
        columnas = []
        for col in table["columns"]:
            columnas.append((
                col["name"],
                col["type"],
                restriccion(col, pks, fks.get((table["name"], col["name"]))),
            ))
        nota = (
            table["note"].strip()
            or notas_dbml.get(table["name"], "").strip()
            or NOTAS.get(table["name"], "")
        )
        items.append({
            "n": i,
            "grupo": grupo_de.get(table["name"], ""),
            "nombre": table["name"],
            "nota": nota,
            "columnas": columnas,
        })
    return items


INFORME = ROOT / "Myworksapp_Informe_Final - APT.docx"
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
WIDTHS = ("2500", "2100", "4805")


def q(tag):
    return f"{{{W}}}{tag}"


def E(tag, **attrs):
    el = etree.Element(q(tag))
    for key, value in attrs.items():
        el.set(q(key), value)
    return el


def rpr(size="20", bold=False, color=None):
    node = E("rPr")
    node.append(E("rFonts", ascii="Arial", hAnsi="Arial", cs="Arial"))
    if bold:
        node.append(E("b"))
        node.append(E("bCs"))
    if color:
        node.append(E("color", val=color))
    node.append(E("sz", val=size))
    node.append(E("szCs", val=size))
    return node


def paragraph(text, size="20", bold=False, before="0", after="80",
              keep_next=False, color=None, page_break=False):
    node = E("p")
    pPr = E("pPr")
    if page_break:
        pPr.append(E("pageBreakBefore"))
    if keep_next:
        pPr.append(E("keepNext"))
        pPr.append(E("keepLines"))
    pPr.append(E("spacing", before=before, after=after, line="240", lineRule="auto"))
    pPr.append(rpr(size, bold, color))
    node.append(pPr)
    if text:
        run = E("r")
        run.append(rpr(size, bold, color))
        t = E("t")
        t.text = text
        run.append(t)
        node.append(run)
    return node


def borde(tag):
    return E(tag, val="single", sz="4", space="0", color="9CC2E5")


def celda(texto, ancho, encabezado=False):
    tc = E("tc")
    tcPr = E("tcPr")
    tcPr.append(E("tcW", w=ancho, type="dxa"))
    if encabezado:
        tcPr.append(E("shd", val="clear", color="auto", fill="D9EAF7"))
    tc.append(tcPr)
    node = E("p")
    pPr = E("pPr")
    pPr.append(E("spacing", before="20", after="20", line="240", lineRule="auto"))
    pPr.append(rpr("18", encabezado))
    node.append(pPr)
    run = E("r")
    run.append(rpr("18", encabezado))
    t = E("t")
    t.text = texto
    run.append(t)
    node.append(run)
    tc.append(node)
    return tc


def tabla_atributos(columnas):
    tbl = E("tbl")
    tblPr = E("tblPr")
    tblPr.append(E("tblW", w="9405", type="dxa"))
    tblPr.append(E("jc", val="left"))
    tblPr.append(E("tblLayout", type="fixed"))
    borders = E("tblBorders")
    for lado in ("top", "left", "bottom", "right", "insideH", "insideV"):
        borders.append(borde(lado))
    tblPr.append(borders)
    tbl.append(tblPr)
    grid = E("tblGrid")
    for ancho in WIDTHS:
        grid.append(E("gridCol", w=ancho))
    tbl.append(grid)

    def fila(valores, encabezado=False):
        tr = E("tr")
        trPr = E("trPr")
        trPr.append(E("cantSplit"))
        if encabezado:
            trPr.append(E("tblHeader"))
        tr.append(trPr)
        for valor, ancho in zip(valores, WIDTHS):
            tr.append(celda(valor, ancho, encabezado))
        return tr

    tbl.append(fila(("Atributo", "Tipo de dato", "Restricción"), True))
    for nombre, tipo, restr in columnas:
        tbl.append(fila((nombre, tipo, restr)))
    return tbl


def bloques(items):
    nodos = [
        paragraph(INTRO, size="20", before="200", after="60", page_break=True),
        paragraph(
            "Fuente: elaboración propia a partir del modelo entidad-relación v2.3.",
            size="18", before="0", after="160", color="595959",
        ),
    ]
    grupo_actual = None
    for item in items:
        if item["grupo"] != grupo_actual:
            grupo_actual = item["grupo"]
            nodos.append(paragraph(
                GRUPOS.get(grupo_actual, grupo_actual),
                size="22", bold=True, before="280", after="80", keep_next=True,
            ))
        nodos.append(paragraph(
            f"Tabla A-{item['n']}. {item['nombre']}",
            size="20", bold=True, before="160", after="20", keep_next=True,
        ))
        if item["nota"]:
            nodos.append(paragraph(
                item["nota"],
                size="18", before="0", after="60", keep_next=True, color="595959",
            ))
        nodos.append(tabla_atributos(item["columnas"]))
        nodos.append(paragraph("", size="18", before="0", after="40"))
    return nodos


def texto_parrafo(node):
    return "".join(node.itertext())


def insertar_en_informe(items):
    import shutil
    import tempfile

    respaldo = Path(tempfile.gettempdir()) / "informe-apt-antes-diccionario.docx"
    shutil.copy2(INFORME, respaldo)
    with zipfile.ZipFile(INFORME) as z:
        infos = z.infolist()
        archivos = {info.filename: z.read(info.filename) for info in infos}
    root = etree.fromstring(archivos["word/document.xml"])
    for prefijo, uri in root.nsmap.items():
        if prefijo:
            etree.register_namespace(prefijo, uri)
    body = root.find(q("body"))
    ancla = None
    for child in body:
        if child.tag == q("p") and texto_parrafo(child).startswith("ANEXO B:"):
            ancla = child
            break
    if ancla is None:
        raise SystemExit("No se encontró el Anexo B en el informe")
    marca = None
    for child in body:
        if child.tag == q("p") and texto_parrafo(child).startswith(INTRO[:40]):
            marca = child
            break
    if marca is not None:
        actual = marca
        while actual is not None and actual is not ancla:
            siguiente = actual.getnext()
            body.remove(actual)
            actual = siguiente
    for nodo in bloques(items):
        ancla.addprevious(nodo)
    nuevo = etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)
    etree.fromstring(nuevo)
    tmp = INFORME.with_suffix(".tmp.docx")
    with zipfile.ZipFile(tmp, "w") as z:
        for info in infos:
            data = nuevo if info.filename == "word/document.xml" else archivos[info.filename]
            copia = zipfile.ZipInfo(filename=info.filename, date_time=info.date_time)
            copia.compress_type = info.compress_type
            copia.external_attr = info.external_attr
            z.writestr(copia, data)
    tmp.replace(INFORME)
    return respaldo


def write_md(items):
    lines = [
        "# Anexo A. Diccionario de datos",
        "",
        INTRO,
        "",
        "Fuente: elaboración propia a partir del modelo entidad-relación v2.3.",
        "",
    ]
    grupo_actual = None
    for item in items:
        if item["grupo"] != grupo_actual:
            grupo_actual = item["grupo"]
            lines.append(f"## {GRUPOS.get(grupo_actual, grupo_actual)}")
            lines.append("")
        lines.append(f"### Tabla A-{item['n']}. {item['nombre']}")
        lines.append("")
        if item["nota"]:
            lines.append(item["nota"])
            lines.append("")
        lines.append("| Atributo | Tipo de dato | Restricción |")
        lines.append("|----------|--------------|-------------|")
        for nombre, tipo, restr in item["columnas"]:
            def cell(s):
                return s.replace("|", "\\|")
            lines.append(f"| `{cell(nombre)}` | {cell(tipo)} | {cell(restr)} |")
        lines.append("")
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")


def main():
    mod = load_parser()
    text = DBML.read_text(encoding="utf-8")
    _note, tables, groups, refs = mod.parse_dbml(text)
    by_name = {t["name"]: t for t in tables}
    order = [name for members in groups.values() for name in members]
    ordered = [by_name[n] for n in order if n in by_name]
    ordered += [t for t in tables if t["name"] not in order]
    items = entradas(ordered, groups, fk_map(refs), notas_de_tabla(text))
    if len(items) != 43:
        raise SystemExit(f"Se esperaban 43 tablas y hay {len(items)}")
    respaldo = insertar_en_informe(items)
    write_md(items)
    print(f"{len(items)} tablas insertadas en {INFORME.name}")
    print(f"respaldo {respaldo}")


if __name__ == "__main__":
    main()

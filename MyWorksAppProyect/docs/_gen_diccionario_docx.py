# -*- coding: utf-8 -*-
"""Genera docs/DICCIONARIO_BASE_DATOS.docx y .md desde el modelo ER (DBML).

Fuente única: Fase 2/modelo_entidad_relacion.dbml (raíz del repo grupal).
No agrega tablas ni columnas que no estén en el DBML.

Uso: python docs/_gen_diccionario_docx.py
"""
import re
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn, nsdecls
from docx.oxml import parse_xml
from docx.shared import Cm, Pt, RGBColor

DOCS = Path(__file__).resolve().parent
OUT = DOCS / "DICCIONARIO_BASE_DATOS.docx"
OUT_MD = DOCS / "DICCIONARIO_BASE_DATOS.md"
DBML_CANDIDATES = [
    DOCS.parent.parent / "Fase 2" / "modelo_entidad_relacion.dbml",
    DOCS.parent / "proyecto de titulo" / "Fase 2" / "modelo_entidad_relacion.dbml",
]


def set_run_font(run, name="Calibri", size=11, bold=False, color=None):
    run.font.name = name
    run._element.rPr.rFonts.set(qn("w:eastAsia"), name)
    run.font.size = Pt(size)
    run.bold = bold
    if color is not None:
        run.font.color.rgb = color


def set_paragraph_format(p, space_after=8, space_before=0, line=1.15, align=None):
    pf = p.paragraph_format
    pf.space_after = Pt(space_after)
    pf.space_before = Pt(space_before)
    pf.line_spacing = line
    if align is not None:
        pf.alignment = align


def shade_header_row(row, fill="1F4E79"):
    for cell in row.cells:
        tcPr = cell._tc.get_or_add_tcPr()
        shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill}" w:val="clear"/>')
        tcPr.append(shd)
        for p in cell.paragraphs:
            for r in p.runs:
                r.font.color.rgb = RGBColor(255, 255, 255)
                r.bold = True


def add_heading(doc, text, level=1):
    sizes = {0: 22, 1: 16, 2: 13, 3: 12}
    p = doc.add_paragraph()
    set_paragraph_format(p, space_before=14 if level else 0, space_after=10, line=1.15)
    run = p.add_run(text)
    set_run_font(run, size=sizes.get(level, 12), bold=True, color=RGBColor(31, 78, 121))
    return p


def add_body(doc, text, bold=False):
    p = doc.add_paragraph()
    set_paragraph_format(p, space_after=8, line=1.15, align=WD_ALIGN_PARAGRAPH.JUSTIFY)
    run = p.add_run(text)
    set_run_font(run, size=11, bold=bold)
    return p


def add_table(doc, headers, rows):
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    hdr = table.rows[0]
    for i, h in enumerate(headers):
        cell = hdr.cells[i]
        cell.text = ""
        p = cell.paragraphs[0]
        set_paragraph_format(p, space_after=2, space_before=2, line=1.0)
        run = p.add_run(h)
        set_run_font(run, size=10, bold=True)
    shade_header_row(hdr)
    for r_i, row_data in enumerate(rows):
        for c_i, val in enumerate(row_data):
            cell = table.rows[r_i + 1].cells[c_i]
            cell.text = ""
            p = cell.paragraphs[0]
            set_paragraph_format(p, space_after=2, space_before=2, line=1.0)
            run = p.add_run(str(val))
            set_run_font(run, size=10)
    doc.add_paragraph()
    return table

def _strip_quotes(s):
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in "'\"":
        return s[1:-1]
    return s


def _split_settings(raw):
    """Separa '[pk, not null, note: 'x, y']' respetando comillas."""
    parts, cur, quote = [], "", None
    for ch in raw:
        if quote:
            cur += ch
            if ch == quote:
                quote = None
        elif ch in "'\"":
            quote = ch
            cur += ch
        elif ch == ",":
            parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur.strip())
    return parts


def parse_dbml(text):
    project_note = ""
    m = re.search(r"Project\s+\w+\s*\{.*?Note:\s*'([^']*)'", text, re.S)
    if m:
        project_note = m.group(1)
    tables, groups, refs = [], {}, []
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        mt = re.match(r"Table\s+(\w+)\s*\{", line)
        mg = re.match(r"TableGroup\s+(\w+)\s*\{", line)
        if mt:
            table = {"name": mt.group(1), "columns": [], "note": "", "indexes": []}
            i += 1
            in_idx = False
            while i < len(lines) and lines[i].strip() != "}":
                ln = lines[i].strip()
                i += 1
                if not ln or ln.startswith("//"):
                    continue
                if ln.startswith("indexes"):
                    in_idx = True
                    continue
                if in_idx:
                    if ln == "}":
                        in_idx = False
                    else:
                        table["indexes"].append(ln)
                    continue
                mn = re.match(r"Note:\s*(.*)$", ln)
                if mn:
                    table["note"] = _strip_quotes(mn.group(1))
                    continue
                mc = re.match(r"(\"?[\w]+\"?)\s+([^\s\[]+(?:\([^)]*\))?)\s*(\[(.*)\])?\s*$", ln)
                if mc:
                    settings = _split_settings(mc.group(4) or "")
                    note = ""
                    flags = []
                    for st in settings:
                        if st.lower().startswith("note:"):
                            note = _strip_quotes(st[5:])
                        else:
                            flags.append(st)
                    table["columns"].append({
                        "name": mc.group(1).strip('"'),
                        "type": mc.group(2),
                        "flags": ", ".join(flags),
                        "note": note,
                    })
            tables.append(table)
        elif mg:
            name = mg.group(1)
            groups[name] = []
            i += 1
            while i < len(lines) and lines[i].strip() != "}":
                ln = lines[i].strip()
                if ln and not ln.startswith("//"):
                    groups[name].append(ln)
                i += 1
        elif line.startswith("Ref:"):
            refs.append(line[4:].strip())
        i += 1
    return project_note, tables, groups, refs


def load_model():
    for path in DBML_CANDIDATES:
        if path.exists():
            return path, parse_dbml(path.read_text(encoding="utf-8"))
    raise SystemExit("No se encontró modelo_entidad_relacion.dbml")


def group_of(groups, table):
    for g, members in groups.items():
        if table in members:
            return g
    return "-"


def md_cell(s):
    return str(s).replace("|", "\\|").replace("\n", " ")


def build_md(path, project_note, tables, groups, refs):
    out = []
    out.append("# Diccionario de base de datos — My Works App")
    out.append("")
    out.append("> Generado por `docs/_gen_diccionario_docx.py` desde "
               "`Fase 2/modelo_entidad_relacion.dbml`. No editar a mano: "
               "cambia el DBML y vuelve a generar.")
    out.append("")
    out.append("| Campo | Valor |")
    out.append("|-------|-------|")
    out.append("| Proyecto | My Works App |")
    out.append("| Motor | PostgreSQL (Supabase), esquema `public` |")
    out.append("| Convención | Nombres en español, `snake_case` |")
    out.append(f"| Modelo fuente | {md_cell(project_note)} |")
    out.append(f"| Tablas en el modelo | {len(tables)} |")
    out.append(f"| Relaciones (Ref) | {len(refs)} |")
    out.append("")
    out.append("`perfiles.id` coincide con `auth.users.id` (Auth de Supabase, fuera de `public`).")
    out.append("")
    out.append("## 1. Índice de tablas por grupo")
    out.append("")
    out.append("| # | Grupo | Tabla | Columnas | Descripción |")
    out.append("|---|-------|-------|----------|-------------|")
    n = 0
    order = [t for g in groups.values() for t in g]
    by_name = {t["name"]: t for t in tables}
    ordered = [by_name[t] for t in order if t in by_name] + \
        [t for t in tables if t["name"] not in order]
    for t in ordered:
        n += 1
        out.append(f"| {n} | {group_of(groups, t['name'])} | `{t['name']}` | "
                   f"{len(t['columns'])} | {md_cell(t['note'])} |")
    out.append("")
    out.append("## 2. Columnas por tabla")
    for idx, t in enumerate(ordered, 1):
        out.append("")
        out.append(f"### 2.{idx} {t['name']}")
        out.append("")
        if t["note"]:
            out.append(t["note"])
            out.append("")
        out.append("| Columna | Tipo | Restricciones | Nota |")
        out.append("|---------|------|---------------|------|")
        for c in t["columns"]:
            out.append(f"| `{c['name']}` | `{c['type']}` | {md_cell(c['flags'])} | {md_cell(c['note'])} |")
        if t["indexes"]:
            out.append("")
            out.append("Índices: " + "; ".join(f"`{md_cell(x)}`" for x in t["indexes"]))
    out.append("")
    out.append("## 3. Relaciones")
    out.append("")
    out.append("`>` muchos a uno · `-` uno a uno · `<` uno a muchos.")
    out.append("")
    for r in refs:
        out.append(f"- `{r}`")
    out.append("")
    out.append("## 4. Dónde está el SQL")
    out.append("")
    out.append("- Modelo lógico: `Fase 2/modelo_entidad_relacion.dbml` y `.sql`.")
    out.append("- Migraciones: `myworksapp_app/supabase/migrations/`.")
    out.append("- Detalle narrativo del modelo: `proyecto de titulo/Fase 2/MODELO_ENTIDAD_RELACION.md`.")
    out.append("")
    return "\n".join(out), ordered


def main():
    path, (project_note, tables, groups, refs) = load_model()
    md, ordered = build_md(path, project_note, tables, groups, refs)
    OUT_MD.write_text(md, encoding="utf-8")

    doc = Document()
    for section in doc.sections:
        section.top_margin = Cm(2.5)
        section.bottom_margin = Cm(2.5)
        section.left_margin = Cm(2.5)
        section.right_margin = Cm(2.5)

    for _ in range(3):
        doc.add_paragraph()
    t = doc.add_paragraph()
    set_paragraph_format(t, align=WD_ALIGN_PARAGRAPH.CENTER, space_after=6)
    r = t.add_run("MY WORKS APP")
    set_run_font(r, size=28, bold=True, color=RGBColor(31, 78, 121))
    st = doc.add_paragraph()
    set_paragraph_format(st, align=WD_ALIGN_PARAGRAPH.CENTER, space_after=18)
    r = st.add_run("Diccionario de Base de Datos")
    set_run_font(r, size=18, bold=True, color=RGBColor(70, 70, 70))
    meta = doc.add_paragraph()
    set_paragraph_format(meta, align=WD_ALIGN_PARAGRAPH.CENTER, space_after=4)
    r = meta.add_run("Documento técnico de esquema · PostgreSQL / Supabase\n" + project_note)
    set_run_font(r, size=11, color=RGBColor(90, 90, 90))
    doc.add_page_break()

    add_heading(doc, "1. Identificación del documento", 1)
    add_table(doc, ["Campo", "Valor"], [
        ["Proyecto", "My Works App"],
        ["Motor", "PostgreSQL (Supabase), esquema public"],
        ["Convención de nombres", "Español + snake_case"],
        ["Modelo fuente", "Fase 2/modelo_entidad_relacion.dbml"],
        ["Nota del modelo", project_note],
        ["Tablas", str(len(tables))],
        ["Relaciones", str(len(refs))],
    ])

    add_heading(doc, "2. Índice de tablas por grupo", 1)
    add_table(doc, ["#", "Grupo", "Tabla", "Columnas", "Descripción"], [
        [str(i), group_of(groups, tb["name"]), tb["name"], str(len(tb["columns"])), tb["note"]]
        for i, tb in enumerate(ordered, 1)
    ])

    add_heading(doc, "3. Columnas por tabla", 1)
    for i, tb in enumerate(ordered, 1):
        add_heading(doc, f"3.{i} {tb['name']}", 2)
        if tb["note"]:
            add_body(doc, tb["note"])
        add_table(doc, ["Columna", "Tipo", "Restricciones", "Nota"],
                  [[c["name"], c["type"], c["flags"], c["note"]] for c in tb["columns"]])
        if tb["indexes"]:
            add_body(doc, "Índices: " + "; ".join(tb["indexes"]))

    add_heading(doc, "4. Relaciones", 1)
    add_body(doc, "> muchos a uno · - uno a uno · < uno a muchos.")
    for ref in refs:
        add_body(doc, ref)

    doc.save(OUT)
    print(f"OK {OUT.name} y {OUT_MD.name}: {len(tables)} tablas, {len(refs)} relaciones")


if __name__ == "__main__":
    main()

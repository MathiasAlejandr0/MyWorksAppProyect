# -*- coding: utf-8 -*-
"""Exporta el diagrama entidad-relación v2.3 e lo inserta en el informe."""
import importlib.util
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.enum.text import WD_LINE_SPACING
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

ROOT = Path(__file__).resolve().parent
DBML = ROOT / "modelo_entidad_relacion.dbml"
GEN = ROOT.parent / "MyWorksAppProyect" / "docs" / "_gen_diccionario_docx.py"
OUT_DIR = ROOT / "figuras"
INFORME = ROOT / "Myworksapp_Informe_Final - APT.docx"
PARSER = ROOT / "_gen_anexo_diccionario.py"

GRUPOS = [
    ("identidad", "Identidad y cuenta", (31, 78, 121)),
    ("territorio", "Territorio", (27, 107, 74)),
    ("catalogo_4nf", "Catálogo del profesional", (138, 90, 18)),
    ("pedido", "Pedido y servicio", (162, 74, 28)),
    ("cobro", "Cobro", (92, 69, 120)),
    ("ranking", "Ranking y reputación", (44, 74, 110)),
]

W = 1800
MARGIN = 48
GAP = 16
COLS = 2


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def pk_list(table, pk_columns):
    ordered = []
    names = pk_columns(table)
    for col in table["columns"]:
        if col["name"] in names and col["name"] not in ordered:
            ordered.append(col["name"])
    for name in names:
        if name not in ordered:
            ordered.append(name)
    return ordered


def font(size, bold=False):
    path = r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf"
    return ImageFont.truetype(path, size)


def wrap(draw, text, fnt, width):
    words = text.split(" ")
    lines, cur = [], ""
    for word in words:
        trial = word if not cur else cur + " " + word
        if draw.textlength(trial, font=fnt) <= width:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines or [""]


def draw_group(title, color, cards):
    name_f = font(34, True)
    body_f = font(26)
    head_f = font(32, True)
    draw_probe = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    inner = (W - MARGIN * 2 - GAP) // COLS
    text_w = inner - 36
    prepared = []
    for card in cards:
        lines = [("name", card["nombre"])]
        lines.append(("pk", "PK  " + ", ".join(card["pks"])))
        for fk in card["fks"]:
            for line in wrap(draw_probe, "FK  " + fk, body_f, text_w):
                lines.append(("fk", line))
        if not card["fks"]:
            lines.append(("fk", card.get("nota") or "Sin clave foránea"))
        prepared.append(lines)
    heights = []
    for lines in prepared:
        h = 22
        for kind, _ in lines:
            h += 42 if kind == "name" else 34
        h += 16
        heights.append(h)
    rows = (len(cards) + COLS - 1) // COLS
    row_h = []
    for r in range(rows):
        chunk = heights[r * COLS:(r + 1) * COLS]
        row_h.append(max(chunk) if chunk else 0)
    height = MARGIN + 64 + sum(row_h) + GAP * max(rows - 1, 0) + MARGIN
    img = Image.new("RGB", (W, height), "white")
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((MARGIN, 28, W - MARGIN, 78), radius=8, fill=color)
    d.text((MARGIN + 18, 40), title, font=head_f, fill="white")
    y = 28 + 64
    for r in range(rows):
        x = MARGIN
        for c in range(COLS):
            i = r * COLS + c
            if i >= len(prepared):
                break
            h = row_h[r]
            d.rounded_rectangle((x, y, x + inner, y + h), radius=10, outline=color, width=3, fill="#F7F9FB")
            d.rectangle((x, y, x + 8, y + h), fill=color)
            ty = y + 14
            for kind, text in prepared[i]:
                if kind == "name":
                    d.text((x + 22, ty), text, font=name_f, fill=color)
                    ty += 42
                else:
                    d.text((x + 22, ty), text, font=body_f, fill="#243040")
                    ty += 34
            x += inner + GAP
        y += row_h[r] + GAP
    return img


def build():
    anexo = load("anexo", PARSER)
    dic = load("dic", GEN)
    note, tables, groups, refs = dic.parse_dbml(DBML.read_text(encoding="utf-8"))
    by_name = {t["name"]: t for t in tables}
    fks = anexo.fk_map(refs)
    by_table = {}
    for (tabla, col), dest in fks.items():
        by_table.setdefault(tabla, []).append(f"{col} → {dest}")
    OUT_DIR.mkdir(exist_ok=True)
    paths = []
    for n, (key, title, color) in enumerate(GRUPOS, 1):
        cards = []
        for name in groups.get(key, []):
            table = by_name[name]
            nota = ""
            if name == "perfiles":
                nota = "Coincide con auth.users.id"
            cards.append({
                "nombre": name,
                "pks": pk_list(table, anexo.pk_columns),
                "fks": by_table.get(name, []),
                "nota": nota,
            })
        img = draw_group(f"{title}  ·  {len(cards)} tablas", color, cards)
        path = OUT_DIR / f"diagrama_er_{n:02d}_{key}.png"
        img.save(path, "PNG", dpi=(220, 220))
        paths.append((n, title, path, len(cards)))
    return paths


def set_run(run, size, bold=False, color=None):
    run.font.name = "Arial"
    run._element.rPr.rFonts.set(qn("w:eastAsia"), "Arial")
    run.font.size = Pt(size)
    run.bold = bold
    if color is not None:
        run.font.color.rgb = color


def style_p(p, before=8, after=4, keep=False):
    pf = p.paragraph_format
    pf.space_before = Pt(before)
    pf.space_after = Pt(after)
    pf.line_spacing_rule = WD_LINE_SPACING.SINGLE
    if keep:
        pf.keep_together = True
        pf.keep_with_next = True


def insert_after(paragraph, text, size=11, bold=False):
    from docx.oxml import OxmlElement
    from docx.text.paragraph import Paragraph
    new_p = OxmlElement("w:p")
    paragraph._p.addnext(new_p)
    created = Paragraph(new_p, paragraph._parent)
    run = created.add_run(text)
    set_run(run, size, bold=bold)
    style_p(created, before=0, after=2)
    return created


def insert(paths):
    doc = Document(INFORME)
    anchor = indice = modelo = None
    for p in doc.paragraphs:
        if anchor is None and p.text.startswith("A continuación se describe cada una de las 43 tablas"):
            anchor = p
        if indice is None and "el informe no contiene figuras" in p.text:
            indice = p
        if modelo is None and p.text.startswith("Tabla. Grupos de tablas del modelo"):
            modelo = p
    if anchor is None or indice is None or modelo is None:
        raise SystemExit("No encontré el punto de inserción en el informe")

    nota = modelo.insert_paragraph_before(
        "El diagrama entidad-relación, separado por grupo, está en el Anexo A "
        "(figuras A-1 a A-6)."
    )
    for run in nota.runs:
        set_run(run, 11)
    style_p(nota, before=6, after=8)

    for n, title, path, count in paths:
        cap = anchor.insert_paragraph_before("")
        style_p(cap, before=14, after=2, keep=True)
        run = cap.add_run(f"Figura A-{n}. {title} del modelo entidad-relación v2.3.")
        set_run(run, 11, bold=True)
        pic = anchor.insert_paragraph_before("")
        style_p(pic, before=2, after=2, keep=True)
        pic.add_run().add_picture(str(path), width=Cm(16.2))
        src = anchor.insert_paragraph_before("")
        style_p(src, before=0, after=10)
        run = src.add_run(
            "Fuente: elaboración propia a partir del modelo entidad-relación v2.3 "
            f"({count} tablas)."
        )
        set_run(run, 9, color=RGBColor(0x59, 0x59, 0x59))

    indice.clear()
    run = indice.add_run("Figura A-1. Identidad y cuenta del modelo entidad-relación v2.3.")
    set_run(run, 11)
    style_p(indice, before=0, after=2)
    cursor = indice
    for label in (
        "Figura A-2. Territorio del modelo entidad-relación v2.3.",
        "Figura A-3. Catálogo del profesional del modelo entidad-relación v2.3.",
        "Figura A-4. Pedido y servicio del modelo entidad-relación v2.3.",
        "Figura A-5. Cobro del modelo entidad-relación v2.3.",
        "Figura A-6. Ranking y reputación del modelo entidad-relación v2.3.",
        "Pendiente: capturas del flujo crítico en las tres interfaces.",
    ):
        cursor = insert_after(cursor, label)
    doc.save(INFORME)


if __name__ == "__main__":
    figs = build()
    insert(figs)
    for item in figs:
        print(item[0], item[2].name)

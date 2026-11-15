# -*- coding: utf-8 -*-
"""Informe de pruebas de carga — formato académico Duoc UC."""
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn, nsdecls
from docx.oxml import parse_xml
from docx.shared import Cm, Pt, RGBColor, Inches

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "INFORME_PRUEBAS_CARGA_CAPACIDAD.docx"
LOGO = ROOT / "brand" / "duoc-uc-logo.png"

# Colores aproximados identidad Duoc (azul institucional + acento)
DUOC_BLUE = RGBColor(0, 51, 102)       # #003366
DUOC_ORANGE = RGBColor(230, 81, 0)     # acento
GRAY = RGBColor(64, 64, 64)


def set_run_font(run, name="Calibri", size=11, bold=False, color=None):
    run.font.name = name
    run._element.rPr.rFonts.set(qn("w:eastAsia"), name)
    run.font.size = Pt(size)
    run.bold = bold
    if color is not None:
        run.font.color.rgb = color


def pf(p, after=8, before=0, line=1.15, align=None, first_line=None):
    fmt = p.paragraph_format
    fmt.space_after = Pt(after)
    fmt.space_before = Pt(before)
    fmt.line_spacing = line
    if align is not None:
        fmt.alignment = align
    if first_line is not None:
        fmt.first_line_indent = Cm(first_line)


def shade_header_row(row, fill="003366"):
    for cell in row.cells:
        tcPr = cell._tc.get_or_add_tcPr()
        tcPr.append(parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill}" w:val="clear"/>'))
        for p in cell.paragraphs:
            for r in p.runs:
                r.font.color.rgb = RGBColor(255, 255, 255)
                r.bold = True


def add_h(doc, text, level=1):
    sizes = {1: 14, 2: 12, 3: 11}
    p = doc.add_paragraph()
    pf(p, before=14 if level == 1 else 10, after=8)
    r = p.add_run(text)
    set_run_font(r, size=sizes.get(level, 11), bold=True, color=DUOC_BLUE)
    return p


def add_p(doc, text, *, bold=False, justify=True, size=11):
    p = doc.add_paragraph()
    pf(
        p,
        after=8,
        line=1.15,
        align=WD_ALIGN_PARAGRAPH.JUSTIFY if justify else WD_ALIGN_PARAGRAPH.LEFT,
        first_line=0.75 if justify else None,
    )
    r = p.add_run(text)
    set_run_font(r, size=size, bold=bold, color=GRAY)
    return p


def add_table(doc, headers, rows):
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(headers):
        cell = table.rows[0].cells[i]
        cell.text = ""
        p = cell.paragraphs[0]
        pf(p, after=2, before=2, line=1.0)
        r = p.add_run(h)
        set_run_font(r, size=9, bold=True)
    shade_header_row(table.rows[0])
    for ri, row in enumerate(rows):
        for ci, val in enumerate(row):
            cell = table.rows[ri + 1].cells[ci]
            cell.text = ""
            p = cell.paragraphs[0]
            pf(p, after=2, before=2, line=1.0)
            r = p.add_run(str(val))
            set_run_font(r, size=9, color=GRAY)
    doc.add_paragraph()
    return table


def add_footer(section):
    footer = section.footer
    footer.is_linked_to_previous = False
    p = footer.paragraphs[0] if footer.paragraphs else footer.add_paragraph()
    p.clear()
    pf(p, after=0, align=WD_ALIGN_PARAGRAPH.CENTER)
    r = p.add_run(
        "Duoc UC — Sede Puerto Montt  ·  Capstone PTY4614  ·  www.duoc.cl  ·  "
        "My Works App — Informe de capacidad"
    )
    set_run_font(r, size=8, color=RGBColor(120, 120, 120))


def main():
    doc = Document()
    for section in doc.sections:
        section.top_margin = Cm(2.5)
        section.bottom_margin = Cm(2.5)
        section.left_margin = Cm(3.0)
        section.right_margin = Cm(2.5)
        section.page_width = Cm(21.0)
        section.page_height = Cm(29.7)
        add_footer(section)

    # ----- Portada estilo institucional -----
    if LOGO.exists():
        p_logo = doc.add_paragraph()
        pf(p_logo, align=WD_ALIGN_PARAGRAPH.RIGHT, after=6)
        run = p_logo.add_run()
        run.add_picture(str(LOGO), width=Cm(4.2))

    p = doc.add_paragraph()
    pf(p, align=WD_ALIGN_PARAGRAPH.CENTER, before=36, after=4)
    r = p.add_run("DUOC UC")
    set_run_font(r, size=16, bold=True, color=DUOC_BLUE)

    p = doc.add_paragraph()
    pf(p, align=WD_ALIGN_PARAGRAPH.CENTER, after=4)
    r = p.add_run("Sede Puerto Montt")
    set_run_font(r, size=12, color=GRAY)

    p = doc.add_paragraph()
    pf(p, align=WD_ALIGN_PARAGRAPH.CENTER, after=18)
    r = p.add_run("Capstone / Proyecto de Título Profesional — PTY4614 (APT)")
    set_run_font(r, size=11, color=GRAY)

    line = doc.add_paragraph()
    pf(line, align=WD_ALIGN_PARAGRAPH.CENTER, after=18)
    r = line.add_run("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    set_run_font(r, size=10, color=DUOC_ORANGE)

    p = doc.add_paragraph()
    pf(p, align=WD_ALIGN_PARAGRAPH.CENTER, after=8)
    r = p.add_run("INFORME TÉCNICO")
    set_run_font(r, size=14, bold=True, color=DUOC_ORANGE)

    p = doc.add_paragraph()
    pf(p, align=WD_ALIGN_PARAGRAPH.CENTER, after=6)
    r = p.add_run("Pruebas de carga y estimación de capacidad")
    set_run_font(r, size=18, bold=True, color=DUOC_BLUE)

    p = doc.add_paragraph()
    pf(p, align=WD_ALIGN_PARAGRAPH.CENTER, after=24)
    r = p.add_run("Proyecto: My Works App")
    set_run_font(r, size=14, bold=True, color=GRAY)

    meta_rows = [
        ("Asignatura / programa", "Capstone PTY4614 (APT)"),
        ("Institución", "Duoc UC — Sede Puerto Montt"),
        ("Equipo", "Mathias Alejandro Jara Alvarado · Nicolas Chiguay · Gabriel Valderas"),
        ("Fecha de las pruebas", "20 de septiembre de 2026"),
        ("Herramienta", "Grafana k6 v2.2.0"),
        ("Ambiente", "Supabase (proyecto de integración / demo)"),
        ("Versión del informe", "1.0"),
    ]
    for label, val in meta_rows:
        p = doc.add_paragraph()
        pf(p, align=WD_ALIGN_PARAGRAPH.CENTER, after=2, line=1.1)
        r = p.add_run(f"{label}: ")
        set_run_font(r, size=10, bold=True, color=DUOC_BLUE)
        r2 = p.add_run(val)
        set_run_font(r2, size=10, color=GRAY)

    doc.add_page_break()

    # ----- 1. Resumen ejecutivo -----
    add_h(doc, "1. Resumen ejecutivo (lenguaje claro)", 1)
    add_p(
        doc,
        "Este informe responde una pregunta práctica del proyecto de título: "
        "¿cuánta gente puede usar a la vez el backend de My Works App hoy, "
        "y qué falta para crecer hacia una base de al menos 20.000 personas?",
    )
    add_p(
        doc,
        "Se ejecutaron pruebas de carga (stress) con la herramienta k6 sobre el API "
        "de Supabase. Se midió la lectura del catálogo de profesionales (lo que ve "
        "un visitante en la app o la web). No se martilló Transbank ni se crearon "
        "usuarios masivos, para no dañar el ambiente de integración.",
    )
    add_p(
        doc,
        "Resultado principal: con hasta 200 usuarios virtuales concurrentes leyendo "
        "profesionales, el sistema respondió sin errores (0 %) y con tiempo de respuesta "
        "bajo medio segundo (percentil 95 ≈ 0,22 s). Eso supera con holgura una demo "
        "académica y un piloto regional pequeño.",
    )
    add_p(
        doc,
        "Importante: “20.000 personas” se interpreta aquí como usuarios de la plataforma "
        "(cuentas / base de clientes potenciales), no como 20.000 personas conectadas "
        "exactamente al mismo segundo. En productos reales, solo una fracción está "
        "activa a la vez. El plan de escala de este informe apunta a sostener esa base "
        "con picos de cientos a unos pocos miles de concurrentes, con margen.",
    )

    # ----- 2. Objetivo y alcance -----
    add_h(doc, "2. Objetivo y alcance de las pruebas", 1)
    add_h(doc, "2.1 Objetivo", 2)
    add_p(
        doc,
        "Obtener un estimado medible de capacidad de lectura del backend actual "
        "y documentar hallazgos, limitaciones y una hoja de ruta hacia 20.000 usuarios.",
    )
    add_h(doc, "2.2 Qué se midió", 2)
    add_table(
        doc,
        ["Escenario", "Descripción"],
        [
            ["Smoke (5 VUs)", "Comprobación rápida de que el API responde"],
            ["Baseline (hasta 50 VUs)", "Carga típica de una demo / piloto chico"],
            ["Stress (hasta 200 VUs)", "Presión alta de usuarios mirando el catálogo"],
            ["Techo de RPS", "Hasta ~100 peticiones por segundo sostenidas"],
        ],
    )
    add_h(doc, "2.3 Qué no se midió (a propósito)", 2)
    add_table(
        doc,
        ["Fuera de alcance", "Motivo"],
        [
            ["Pagos Webpay / Transbank", "No saturar la pasarela ni crear cobros falsos"],
            ["Guest-checkout masivo", "Crearía cuentas reales en Auth"],
            ["Chat, GPS, escritorio UI", "No son el cuello de botella del servidor hoy"],
        ],
    )

    # ----- 3. Resultados -----
    add_h(doc, "3. Resultados de la corrida (20-09-2026)", 1)
    add_p(
        doc,
        "Primera batería: la tabla servicios (oficios) respondía error 401 con clave "
        "anónima; trabajadores (profesionales) respondía bien. Se corrigió el script "
        "para medir el marketplace que sí funcionaba y se re-ejecutó la batería completa. "
        "El error de servicios quedó registrado como hallazgo a reparar en base de datos "
        "(política RLS / privilegios).",
    )
    add_h(doc, "3.1 Tabla de resultados (corrida válida)", 2)
    add_table(
        doc,
        ["Prueba", "VUs máx.", "Peticiones", "Errores", "p95 latencia", "Umbrales"],
        [
            ["Smoke", "5", "202", "0 %", "473 ms", "OK"],
            ["Baseline", "50", "8.548", "0 %", "248 ms", "OK"],
            ["Stress", "200", "63.198", "0 %", "222 ms", "OK"],
            ["Techo RPS", "≈100 req/s", "13.875", "0 %", "221 ms", "OK"],
        ],
    )
    add_h(doc, "3.2 Cómo leer estos números (para evaluadores no informáticos)", 2)
    add_p(
        doc,
        "Usuarios virtuales (VUs): personas simuladas usando la app al mismo tiempo. "
        "p95: el 95 % de las respuestas fue más rápido que ese tiempo. "
        "0 % de errores: ninguna petición falló en la corrida válida. "
        "En conjunto: el listado de profesionales aguanta al menos doscientas personas "
        "concurrentes con buena fluidez.",
    )

    # ----- 4. Hallazgos -----
    add_h(doc, "4. Hallazgos", 1)
    add_h(doc, "4.1 Positivos", 2)
    add_p(
        doc,
        "Latencia estable (~200–250 ms en p95) incluso a 200 VUs. Cero errores en la "
        "corrida corregida. El techo de ~100 lecturas/segundo se sostuvo sin fallos. "
        "Para un MVP Capstone, la capacidad de lectura ya está por encima de la demanda "
        "esperada de las primeras etapas.",
    )
    add_h(doc, "4.2 Problema detectado: catálogo de oficios (servicios)", 2)
    add_p(
        doc,
        "Con la misma clave pública (anon), la tabla servicios devolvía HTTP 401 "
        "(no autorizado), mientras trabajadores devolvía 200. Eso indica un problema "
        "de permisos o de política de seguridad (RLS) en servicios, no un límite de "
        "capacidad. Impacto: el home que lista oficios podía fallar para visitantes "
        "sin sesión.",
    )
    add_p(
        doc,
        "Estado al cierre de este informe: se aplicó la migración "
        "20260925000001_fix_servicios_anon_scale_indexes.sql (política pública sin "
        "is_admin() + GRANT SELECT + índices). Verificación posterior: servicios "
        "responde HTTP 200 y el smoke k6 con oficios + profesionales pasó al 100 % "
        "(0 % errores, p95 ≈ 220 ms).",
    )
    add_h(doc, "4.3 Interpretación de “20.000 personas”", 2)
    add_table(
        doc,
        ["Concepto", "Qué significa", "Meta orientativa"],
        [
            [
                "Usuarios registrados",
                "Cuentas en la plataforma (clientes + profesionales)",
                "≥ 20.000",
            ],
            [
                "Concurrentes en punta",
                "Personas usando la app en el mismo minuto pico",
                "≈ 1–5 % de activos → cientos a ~1.000",
            ],
            [
                "Medido hoy (lectura)",
                "VUs en k6 sobre listado de profesionales",
                "200 VUs OK; ~100 RPS OK",
            ],
        ],
    )

    # ----- 5. Hoja de ruta 20k -----
    add_h(doc, "5. Hoja de ruta para soportar ≥ 20.000 usuarios", 1)
    add_p(
        doc,
        "Orden práctico: primero arreglar lo que está roto, luego ganar capacidad "
        "barata (índices, caché, plan), después arquitectura más robusta.",
    )
    add_table(
        doc,
        ["Fase", "Acción", "Para qué"],
        [
            [
                "0 — Ya",
                "Reparar RLS/GRANT de servicios; índices de lectura",
                "Catálogo público sano + consultas más baratas",
            ],
            [
                "1 — Corto plazo",
                "Plan Supabase Pro; connection pooling; caché web del catálogo",
                "Más CPU/conexiones; menos hits a la base en el home",
            ],
            [
                "2 — Medio plazo",
                "Rate-limit Edge; colas para liquidaciones; monitoreo (latencia/errores)",
                "Proteger pagos y ver cuellos antes de tumbar el servicio",
            ],
            [
                "3 — Crecimiento",
                "CDN, réplicas de lectura, separar tráfico lectura/escritura",
                "Escalar hacia picos mayores sin reescribir el producto",
            ],
        ],
    )
    add_p(
        doc,
        "Con la medición actual (200 concurrentes en lectura sin error), el salto a "
        "20.000 cuentas es viable si se ejecutan las fases 0–2 antes de campañas de "
        "marketing masivas. Los pagos seguirán limitados por Transbank y por el plan "
        "de Edge Functions: se validan con pruebas funcionales controladas, no con "
        "stress agresivo sobre la pasarela.",
    )

    # ----- 6. Conclusiones -----
    add_h(doc, "6. Conclusiones", 1)
    add_p(
        doc,
        "1) El backend de lecturas del MVP demuestra holgura para demos y piloto "
        "(≥ 200 usuarios concurrentes en catálogo de profesionales).",
    )
    add_p(
        doc,
        "2) Existe un defecto de autorización en la tabla servicios que debe "
        "corregirse de inmediato para el flujo público de oficios.",
    )
    add_p(
        doc,
        "3) La meta de 20.000 personas es alcanzable con un plan de escala por fases "
        "(índices, plan Pro, caché, monitoreo), sin confundir usuarios registrados "
        "con usuarios concurrentes.",
    )
    add_p(
        doc,
        "4) Este informe forma parte de la evidencia Capstone de calidad y operación "
        "profesional del producto My Works App.",
    )

    add_h(doc, "7. Referencias técnicas en el repositorio", 1)
    add_p(doc, "docs/RUNBOOK_CAPACIDAD_CARGA.md — cómo repetir las pruebas.", justify=False, size=10)
    add_p(doc, "scripts/load/k6/ — scripts Grafana k6.", justify=False, size=10)
    add_p(doc, "scripts/load/results/ — resúmenes JSON de las corridas.", justify=False, size=10)
    add_p(
        doc,
        "myworksapp_app/supabase/migrations/20260925000001_fix_servicios_anon_scale_indexes.sql — fix + índices.",
        justify=False,
        size=10,
    )

    p = doc.add_paragraph()
    pf(p, before=24, align=WD_ALIGN_PARAGRAPH.CENTER)
    r = p.add_run("— Fin del informe —")
    set_run_font(r, size=10, color=RGBColor(120, 120, 120))

    doc.save(OUT)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()

# -*- coding: utf-8 -*-
"""Informe explicado de la corrida de pruebas del 15 de noviembre de 2026."""
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls, qn
from docx.shared import Cm, Pt, RGBColor

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "anexos" / "2026-11-15-pruebas" / "Informe_pruebas_15_noviembre_2026.docx"
LOGO = ROOT / "brand" / "duoc-uc-logo.png"

BLUE = RGBColor(0, 51, 102)
GRAY = RGBColor(64, 64, 64)
ORANGE = RGBColor(230, 81, 0)


def set_run_font(run, name="Calibri", size=11, bold=False, color=None):
    run.font.name = name
    run._element.rPr.rFonts.set(qn("w:eastAsia"), name)
    run.font.size = Pt(size)
    run.bold = bold
    if color is not None:
        run.font.color.rgb = color


def pf(p, after=8, before=0, line=1.15, align=None):
    fmt = p.paragraph_format
    fmt.space_after = Pt(after)
    fmt.space_before = Pt(before)
    fmt.line_spacing = line
    if align is not None:
        fmt.alignment = align


def shade_header_row(row, fill="003366"):
    for cell in row.cells:
        tc_pr = cell._tc.get_or_add_tcPr()
        tc_pr.append(parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill}" w:val="clear"/>'))
        for p in cell.paragraphs:
            for r in p.runs:
                r.font.color.rgb = RGBColor(255, 255, 255)
                r.bold = True


def set_cell_width(cell, cm):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_w = parse_xml(f'<w:tcW {nsdecls("w")} w:w="{int(cm * 567)}" w:type="dxa"/>')
    tc_pr.append(tc_w)


def add_h(doc, text, level=1):
    sizes = {1: 16, 2: 13}
    p = doc.add_paragraph()
    pf(p, before=16 if level == 1 else 12, after=6)
    r = p.add_run(text)
    set_run_font(r, size=sizes.get(level, 12), bold=True, color=BLUE)
    return p


def add_p(doc, text):
    p = doc.add_paragraph()
    pf(p, after=8, line=1.15, align=WD_ALIGN_PARAGRAPH.JUSTIFY)
    r = p.add_run(text)
    set_run_font(r, size=11, color=GRAY)
    return p


def add_note(doc, text):
    p = doc.add_paragraph()
    pf(p, before=2, after=10, line=1.15, align=WD_ALIGN_PARAGRAPH.JUSTIFY)
    label = p.add_run("Por qué. ")
    set_run_font(label, size=11, bold=True, color=ORANGE)
    body = p.add_run(text)
    set_run_font(body, size=11, color=GRAY)
    return p


def add_table(doc, headers, rows, widths=None):
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    if widths:
        table.allow_autofit = False
        tbl = table._tbl
        tbl_pr = tbl.tblPr if tbl.tblPr is not None else parse_xml(f'<w:tblPr {nsdecls("w")}/>')
        tbl_w = parse_xml(
            f'<w:tblW {nsdecls("w")} w:w="{int(sum(widths) * 567)}" w:type="dxa"/>'
        )
        tbl_pr.append(tbl_w)
    for i, h in enumerate(headers):
        cell = table.rows[0].cells[i]
        cell.text = ""
        p = cell.paragraphs[0]
        pf(p, after=2, before=2, line=1.0)
        r = p.add_run(h)
        set_run_font(r, size=9, bold=True)
        if widths:
            set_cell_width(cell, widths[i])
    shade_header_row(table.rows[0])
    for ri, row in enumerate(rows):
        for ci, val in enumerate(row):
            cell = table.rows[ri + 1].cells[ci]
            cell.text = ""
            p = cell.paragraphs[0]
            pf(p, after=2, before=2, line=1.0)
            r = p.add_run(str(val))
            set_run_font(r, size=9, color=GRAY)
            if widths:
                set_cell_width(cell, widths[ci])
    doc.add_paragraph()
    return table


def add_footer(section):
    footer = section.footer
    footer.is_linked_to_previous = False
    p = footer.paragraphs[0]
    pf(p, after=0, align=WD_ALIGN_PARAGRAPH.CENTER)
    r = p.add_run(
        "Duoc UC — Sede Puerto Montt  ·  My Works App  ·  Pruebas del 15 de noviembre de 2026"
    )
    set_run_font(r, size=8, color=RGBColor(120, 120, 120))


def main():
    doc = Document()
    for section in doc.sections:
        section.top_margin = Cm(2.2)
        section.bottom_margin = Cm(2.2)
        section.left_margin = Cm(2.2)
        section.right_margin = Cm(2.2)
        section.page_width = Cm(21.0)
        section.page_height = Cm(29.7)
        add_footer(section)

    if LOGO.exists():
        p_logo = doc.add_paragraph()
        pf(p_logo, align=WD_ALIGN_PARAGRAPH.RIGHT, after=4)
        p_logo.add_run().add_picture(str(LOGO), width=Cm(3.6))

    p = doc.add_paragraph()
    pf(p, align=WD_ALIGN_PARAGRAPH.CENTER, before=6, after=2)
    set_run_font(p.add_run("DUOC UC  ·  Sede Puerto Montt"), size=12, bold=True, color=BLUE)

    p = doc.add_paragraph()
    pf(p, align=WD_ALIGN_PARAGRAPH.CENTER, after=10)
    set_run_font(p.add_run("Proyecto de título  ·  My Works App"), size=11, color=GRAY)

    p = doc.add_paragraph()
    pf(p, align=WD_ALIGN_PARAGRAPH.CENTER, after=4)
    set_run_font(
        p.add_run("Informe de pruebas"),
        size=22,
        bold=True,
        color=BLUE,
    )

    p = doc.add_paragraph()
    pf(p, align=WD_ALIGN_PARAGRAPH.CENTER, after=12)
    set_run_font(
        p.add_run("15 de noviembre de 2026  ·  qué se midió, el dato y la razón"),
        size=12,
        color=ORANGE,
    )

    add_p(
        doc,
        "Este informe resume la corrida hecha ese día en el proyecto wxqrfcqifkfgawrnqmnj. "
        "Cada tabla muestra el número medido. El párrafo que sigue explica para qué sirve ese número "
        "y qué decisión permite tomar. Los archivos crudos están en la misma carpeta: "
        "docs/anexos/2026-11-15-pruebas/.",
    )

    add_h(doc, "1. Cómo leer los números")
    add_table(
        doc,
        ["Término", "Qué significa aquí"],
        [
            ["p95", "El 95 % de las respuestas llegó en ese tiempo o menos. El 5 % restante fue más lento."],
            ["Usuario virtual", "Una persona simulada que repite lecturas. No es un usuario real ni un pago."],
            ["RPS", "Peticiones por segundo, promedio de toda la prueba, incluida la subida y la bajada."],
            ["LCP", "Momento en que aparece el contenido principal de la portada."],
            ["Error %", "Porcentaje de peticiones HTTP que no respondieron bien. En esta corrida fue 0."],
        ],
        widths=[3.6, 12.8],
    )
    add_note(
        doc,
        "El informe final pide estos datos para los requisitos de rapidez, de error bajo carga y de "
        "regresión. Un solo número suelto no dice si el sistema aguanta: hay que ver el p95, el error "
        "y cuántas personas simuladas había al mismo tiempo.",
    )

    add_h(doc, "2. Condiciones")
    add_table(
        doc,
        ["Dato", "Valor"],
        [
            ["Fecha y hora", "15 de noviembre de 2026, de 12:13 a 12:52, hora de Chile"],
            ["Código medido", "Commit 8fa913e, más el ajuste del test de GPS. Main siguió hasta 2f3925c y eso no se volvió a medir"],
            ["Cliente", "Esta máquina, k6 2.2.0 y Node 22.15.0"],
            ["Qué se leyó", "Catálogo, oficios, huecos de agenda y portada web"],
            ["Qué se dejó fuera", "Pagos, altas de cuenta y escrituras masivas"],
        ],
        widths=[4.2, 12.2],
    )
    add_note(
        doc,
        "La carga solo lee. El runbook deja fuera Webpay y el alta de invitados para no crear cobros "
        "ni cuentas durante una prueba de estrés. La clave usada es la publicable del cliente. "
        "No se usó la clave de servicio.",
    )

    add_h(doc, "3. Pruebas automáticas del código")
    add_table(
        doc,
        ["Suite", "Resultado", "Qué revisa"],
        [
            ["Flutter", "174 aprobadas, 0 fallas", "Pantallas, GPS y reglas de la app"],
            ["Módulo compartido", "110 aprobadas, 39 grupos", "Webpay, chat, estados y pago manual"],
            ["Escritorio", "2 aprobadas", "El hub solo deja entrar al administrador"],
            ["Web (Playwright)", "17 aprobadas, 1 omitida", "Portada, catálogo, pedido y tamaños de ventana"],
        ],
        widths=[3.8, 5.2, 7.4],
    )
    add_note(
        doc,
        "Sirven para el requisito de regresión (RNF-09): si alguien cambia el código, estas pruebas "
        "avisan antes de una demo. La primera pasada de Flutter dio 173 y una falla. El mapa del "
        "selector de ubicación dejaba un temporizador abierto al cerrar la pantalla. Se soltó ese "
        "temporizador y la suite quedó en 174. La prueba omitida de la web es la invitación de RRHH: "
        "necesita el programa de escritorio abierto y ese día no estaba levantado.",
    )
    add_p(
        doc,
        "Dentro de las 174 de Flutter está el caso del GPS colgado. Si el teléfono no entrega "
        "posición, la solicitud usa Puerto Montt y no se queda en el texto «Obteniendo…». "
        "Dentro de las 110 del módulo compartido está el filtro del chat: bloquea correo, teléfono, "
        "enlace y formas de evadirlos, y deja pasar el texto del trabajo (RNF-07).",
    )

    add_h(doc, "4. Rapidez con un solo usuario")
    add_p(
        doc,
        "Treinta lecturas seguidas por endpoint, con cinco de calentamiento que no entran al cálculo. "
        "Un solo cliente, pausa de 200 ms. Medido de 12:13 a 12:15.",
    )
    add_table(
        doc,
        ["Lectura", "p95", "Respuesta", "Qué se obtuvo"],
        [
            ["Servicios activos", "247 ms", "200", "13 servicios"],
            ["Trabajadores por la tabla, visitante", "228 ms", "200", "0 filas"],
            ["Ficha completa de un trabajador", "231 ms", "401", "Rechazada las 30 veces"],
            ["Oficios con cupo", "222 ms", "200", "12 oficios"],
            ["Catálogo de gasfitería", "233 ms", "200", "9 profesionales"],
            ["Catálogo de plomería", "383 ms", "200", "3 profesionales"],
            ["Huecos de agenda, 14 días", "228 y 232 ms", "200", "50 cupos en cada profesional"],
        ],
        widths=[5.4, 2.4, 2.2, 6.4],
    )
    add_note(
        doc,
        "Estas lecturas dicen si la base responde rápido cuando hay una sola persona. El catálogo "
        "que ve el usuario es el procedimiento (RPC), no la tabla. Por eso la tabla de trabajadores "
        "responde bien y aun así trae cero filas: el visitante no tiene permiso para listarla. "
        "La ficha completa responde 401 a propósito. Desde el cierre del 15 de noviembre el visitante "
        "no puede leer la latitud exacta, la longitud exacta ni la nota interna. El mapa usa el "
        "procedimiento, que entrega la base redondeada.",
    )
    add_p(
        doc,
        "La portada, en el preview local a 1366×768, mostró el contenido principal en 424 ms. "
        "El JavaScript comprimido pesa 211451 bytes (206,5 KB) y el CSS comprimido 16217 bytes "
        "(15,8 KB). El tiempo hasta el primer byte fue 2,5 ms porque el sitio estaba en esta misma "
        "máquina. El 8 de noviembre el mismo script midió 3192 ms, con otras imágenes. "
        "La meta del informe es menos de 2 segundos (RNF-01). Esta cifra cumple en el preview local. "
        "No describe una página servida desde internet.",
    )

    add_h(doc, "5. Carga: muchas lecturas a la vez")
    add_p(
        doc,
        "Nueve corridas, de 12:16 a 12:52. Todas terminaron sin error HTTP y con las comprobaciones "
        "internas en verde. El p95 de la tabla es el de todas las peticiones de esa corrida.",
    )
    add_table(
        doc,
        ["Prueba", "Personas", "p95", "RPS", "Peticiones", "Para qué se hace"],
        [
            ["Catálogo, humo", "5", "244 ms", "6,7", "208", "Ver que el script responde"],
            ["Catálogo, base", "50", "232 ms", "47,5", "8608", "Uso cotidiano del listado"],
            ["Catálogo, estrés", "200", "235 ms", "175", "63002", "Ver si el p95 se dispara"],
            ["Reserva, humo", "5", "286 ms", "8,9", "270", "Probar oficios, ficha y huecos"],
            ["Reserva, base", "30", "237 ms", "35,9", "6522", "El camino real de elegir hora"],
            ["Reserva, estrés", "80", "247 ms", "95,1", "24369", "Umbral del informe (RNF-04)"],
            ["Techo del plan gratis", "300", "236 ms", "308", "92542", "Tope histórico de septiembre"],
            ["Llegadas crecientes", "63", "224 ms", "58", "13857", "Subir el ritmo, no solo la gente"],
            ["Resistencia, 10 min", "40", "229 ms", "56", "33706", "Ver si se degrada con el tiempo"],
        ],
        widths=[3.5, 1.8, 1.7, 1.4, 1.8, 6.2],
    )
    add_note(
        doc,
        "El humo existe para detectar un fallo grosero antes de gastar una prueba larga. "
        "La base y el estrés comparan el mismo camino con más gente. Si el p95 casi no sube, "
        "la base aguanta esa lectura. Aquí el catálogo pasó de 232 ms con 50 personas a 235 ms "
        "con 200. La reserva, que es la que usa el cliente al elegir hora, quedó en 247 ms con "
        "80 personas. La meta del informe es menos de 2000 ms (RNF-04). El hueco de agenda más "
        "lento de esa corrida tardó 1381 ms, también bajo ese límite.",
    )
    add_p(
        doc,
        "El techo de 300 personas repite la prueba de septiembre, cuando el plan gratis se midió "
        "con p95 menor a 500 ms y error menor a 1 %. Hoy el p95 fue 236 ms y el error 0. "
        "Esa corrida recibió unos 85 MB. El total de las nueve pruebas se queda en lecturas de "
        "catálogo: no representa a 300 personas pagando. La prueba de llegadas sube la cantidad "
        "de peticiones por segundo. Llegó a 63 personas simultáneas y a un promedio de 58 peticiones "
        "por segundo, con p95 de 224 ms. El umbral de esa prueba es 3000 ms. "
        "Los 10 minutos a 40 personas revisan si el tiempo empeora al sostener la carga (RNF-05). "
        "El p95 quedó en 229 ms y el error en 0. La meta de error es menos de 5 %.",
    )
    add_p(
        doc,
        "No se corrió la mezcla de catálogo anónimo y trabajos de una sesión iniciada. "
        "Esa prueba pide el token de un usuario de demostración y no se fabricó uno. "
        "La última vez que sí se corrió fue el 8 de noviembre, con la sesión de Camila: "
        "p95 de 240 ms, error 0, unos 44 peticiones por segundo.",
    )

    add_h(doc, "6. Quién puede leer qué")
    add_p(
        doc,
        "Los scripts SQL comprueban las reglas de fila y de columna. Cuando el script abre una "
        "transacción, al final hace marcha atrás y no deja filas nuevas.",
    )
    add_table(
        doc,
        ["Script", "Qué pasó", "Cómo leerlo"],
        [
            [
                "10 de octubre",
                "Terminó con el mensaje de ok",
                "Las reglas de ese día siguen vigentes",
            ],
            [
                "11 de octubre",
                "Pasan privilegios, catálogo verificado y tarifa",
                "El archivo literal se detiene: ya no existe la frase «no está verificado»",
            ],
            [
                "9 de octubre",
                "Se detiene en un índice que cambió de nombre",
                "El índice único ahora es por trabajo y dirección, no por trabajo y usuario",
            ],
            [
                "8 de octubre",
                "No se volvió a correr entero",
                "Pide que el visitante ejecute el listado demo, y eso se cerró a propósito",
            ],
        ],
        widths=[3.2, 6.4, 6.8],
    )
    add_note(
        doc,
        "Un script viejo que falla no siempre indica un agujero. A veces el producto cambió y la "
        "prueba sigue exigiendo el comportamiento anterior. El 15 de noviembre se cerraron dos cosas: "
        "el visitante ya no ejecuta el listado de cuentas demo, y la base exacta del profesional "
        "solo la lee el dueño. Por eso el script del 8 de octubre, que exige lo contrario, quedaría "
        "en rojo si se copia tal cual. El del 9 de octubre también se detiene más adelante porque "
        "prohíbe redondear coordenadas, y el redondeo es ahora la regla del catálogo.",
    )
    add_p(
        doc,
        "Medido aparte, a la misma hora: ni el visitante ni un usuario autenticado pueden leer "
        "la columna de latitud exacta. El visitante tampoco puede ejecutar el listado demo. "
        "El script que se hace pasar por Camila, Pedro y el administrador no se corrió en esta pasada.",
    )

    add_h(doc, "7. Flujo crítico")
    add_p(
        doc,
        "La guía pide ver el camino completo en la app, en la web y en el escritorio: registro, "
        "catálogo, solicitud, evidencia y cobro. Esta corrida cubrió la web automática y una "
        "búsqueda real. El cobro, el teléfono y el hub no se repitieron.",
    )
    add_table(
        doc,
        ["Caso", "Dónde", "Resultado"],
        [
            ["Portada y buscador", "Playwright", "Se ve el nombre y «Buscar servicio»"],
            ["Ingresar", "Playwright", "Abre el modal vacío"],
            ["Oficio sin profesionales", "Playwright", "Se oculta y la búsqueda vacía se explica"],
            ["Pedido sin pedir la tarjeta en el sitio", "Playwright", "El pago y el invitado no piden el número"],
            ["Ventana ancha y teléfono (1280 y 390)", "Playwright", "Ingreso, reserva, monto y chat quedan dentro"],
            ["Contraseña y correo sin confirmar", "Playwright", "Pide 8 caracteres, letra y número, y ofrece reenviar"],
            ["Buscar plomería", "Navegador local", "3 profesionales y el mapa"],
            ["Cobro Webpay de punta a punta", "App, web y escritorio", "No se repitió hoy"],
            ["Mismo flujo en el teléfono", "App", "No se abrió un dispositivo"],
            ["Hub de escritorio", "Programa de escritorio", "No se abrió. El test de rol sí pasó"],
        ],
        widths=[5.6, 4.2, 6.6],
    )
    add_note(
        doc,
        "Playwright recorre la web sin una persona haciendo clic, así que esas filas se pueden "
        "repetir. La búsqueda de plomería se miró en el navegador de esta máquina: la lista mostró "
        "tres profesionales y el mapa. El cobro con tarjeta de integración ya se había hecho en una "
        "demo anterior y está descrito en DEMO.md. No se inventa una pasada nueva. "
        "El teléfono y el escritorio siguen pendientes para la evidencia de las tres interfaces.",
    )

    add_h(doc, "8. Requisitos del informe")
    add_table(
        doc,
        ["Requisito", "Meta", "Esta corrida"],
        [
            ["RNF-01", "Pantalla bajo 2 s", "424 ms en el preview local. No es una medición en internet"],
            ["RNF-02", "Cada rol ve solo lo suyo", "Script del 10 de octubre en verde. Falta la pasada con usuarios demo"],
            ["RNF-03", "Fechas y montos en español de Chile", "No se recorrieron agenda, detalle ni pagos a mano"],
            ["RNF-04", "Reserva bajo 2 s con 80 personas", "247 ms. Cumple"],
            ["RNF-05", "Error de lecturas bajo 5 %", "Error 0, incluidos los 10 minutos. Cumple en lecturas"],
            ["RNF-06", "Dirección exacta solo tras aceptar", "No se probó con dos sesiones"],
            ["RNF-07", "El chat no deja pasar contacto", "Cubierto en las 110 pruebas del módulo compartido"],
            ["RNF-08", "La misma base en varios tamaños", "Playwright cubre 1280 y 390. Faltan teléfonos físicos"],
            ["RNF-09", "Volver a correr las suites", "174, 17, 110 y 2 en verde, con la omisión ya dicha"],
            ["RNF-10", "Poder repetir la carga", "Mismos scripts del runbook. Resultados en esta carpeta"],
        ],
        widths=[2.2, 6.2, 8.0],
    )
    add_note(
        doc,
        "La tabla separa lo que esta fecha demuestra de lo que el informe todavía no puede dar "
        "por cerrado. Marcar como cumplido el teléfono, el español de las pantallas o la dirección "
        "exacta sería inventar una prueba que no se hizo.",
    )

    add_h(doc, "9. Cierre")
    add_p(
        doc,
        "El código automático quedó en verde y la lectura del catálogo se mantuvo cerca de "
        "un cuarto de segundo desde 5 hasta 300 personas simuladas. La reserva a 80 personas, "
        "que es el número que pide el informe, quedó en 247 ms con error 0. "
        "El rechazo 401 de la ficha completa y la lista vacía de la tabla confirman el cierre "
        "de la base exacta: el visitante ve profesionales por el procedimiento, no por la tabla.",
    )
    add_p(
        doc,
        "Para el informe todavía faltan tres evidencias que esta corrida no reemplaza: "
        "el flujo en un teléfono, el hub de escritorio abierto, y un cobro de integración "
        "repetido ese mismo día. También falta la prueba SQL que entra con las cuentas demo "
        "y la revisión a mano de fechas, montos y dirección exacta.",
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()

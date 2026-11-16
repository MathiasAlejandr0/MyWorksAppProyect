# -*- coding: utf-8 -*-
"""Sección «Modelo entidad-relación» del diccionario de datos.

La usa `_gen_diccionario_desde_schema.py` (MD, DOCX y referencia en el
Anexo A). Toma dominios, relaciones lógicas y cardinalidades del generador
de diagramas `Fase 2/modelo_entidad_relacion/_gen_modelo_er.py`, que lee el
mismo snapshot `_schema_public.json`. Así el texto y las figuras no se
desalinean.
"""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path

DOCS = Path(__file__).resolve().parent
REPO = DOCS.parent.parent
ER_DIR = REPO / "Fase 2" / "modelo_entidad_relacion"
FIG = ER_DIR / "figuras"
FIG_MD = "../../Fase%202/modelo_entidad_relacion/figuras"


def _er():
    spec = importlib.util.spec_from_file_location("_gen_modelo_er", ER_DIR / "_gen_modelo_er.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


EXPLICA = {
    "01_usuarios_territorio": (
        "Centro del modelo. `perfiles` es 1:1 con `auth.users` de Supabase (misma clave, borrado en cascada) "
        "y guarda el rol (`usuario` = cliente, `trabajador`, `administrador`, `soporte` o `qa`). Casi todas las tablas cuelgan de "
        "`perfiles`: códigos de restablecimiento, consentimientos, dispositivos push, suscripciones, bloqueos "
        "entre usuarios y el historial de verificación (`verificacion_eventos`, con el administrador que actuó "
        "en `id_actor`). El territorio es una jerarquía estricta `paises` 1─N `regiones` 1─N `comunas`, "
        "usada por trabajos y profesionales."
    ),
    "02_profesionales_catalogo": (
        "`trabajadores` extiende a `perfiles` 1:1 (PK = `id_usuario`) con la ficha pública, la base de atención, "
        "el radio, la verificación y los agregados de ranking. Del profesional dependen sus precios por código "
        "(`trabajador_precios`, PK compuesta), los servicios extra, la plantilla semanal de horarios (una fila "
        "por día), el portafolio, los impulsos y las categorías que atiende. `servicios` es el catálogo global "
        "y `configuraciones_servicio` su esquema de preguntas (1:0..1)."
    ),
    "03_trabajos_reservas": (
        "`trabajos` es la entidad transaccional: une a un cliente (`id_usuario`), un profesional "
        "(`id_trabajador`, opcional hasta que se asigna), un servicio y una comuna. Alrededor están las "
        "cotizaciones (0..N por trabajo; la elegida queda en `id_cotizacion_seleccionada`), acuerdos, "
        "la cancelación (0..1), las reprogramaciones (CU-33, solo una pendiente a la vez por índice único "
        "parcial), el PIN de inicio (`pines_inicio_trabajo` y `bloqueos_pin_inicio`, 1:0..1, más los intentos "
        "auditados), las fotos y la ubicación en vivo del profesional (1:0..1)."
    ),
    "04_pagos_escrow": (
        "Cada trabajo tiene 0..N `pagos`, pero solo un pago principal activo (índice único parcial). Las "
        "`ordenes_cambio` agregan alcance o precio y generan su propio pago (`tipo_pago = 'orden_cambio'`). "
        "La liberación del escrow fija una `liquidaciones` por pago (1:0..1 por índice único). La tarjeta "
        "Oneclick (`metodos_pago_oneclick`) y la cuenta bancaria (`cuentas_bancarias`) son 1:0..1 con el "
        "perfil y solo las leen el dueño, un administrador o el backend."
    ),
    "05_comunicacion_disputas": (
        "El chat del trabajo (`mensajes`, con remitente y destinatario), las notificaciones in-app por usuario, "
        "las disputas de un trabajo con su hilo (`disputa_mensajes`) y los tickets de soporte, que guardan una "
        "instantánea de nombres y del monto en escrow."
    ),
    "06_calificaciones_ranking": (
        "`calificaciones` es bidireccional (`direccion`) y única por trabajo y dirección; `calificaciones_cliente` "
        "es la nota del profesional al cliente (1:0..1 por trabajo). Las reseñas dudosas generan `senales_resena`. "
        "`eventos_ranking` alimenta el puntaje del profesional; `ranking_config` (una fila) y "
        "`ranking_aprendizaje` guardan los pesos y su historial. La nota y el número de trabajos que muestra la "
        "app se recalculan desde estas tablas (fuente única, migración 20261116044049)."
    ),
    "07_admin_auditoria": (
        "Tablas de operación: cola de acciones pendientes del modo sin conexión, reportes entre usuarios, eventos "
        "de abuso, errores de la app, analítica, banderas de funcionalidad y `app_config` (clave/valor, solo "
        "backend). Todas, salvo `app_config`, referencian a `perfiles`."
    ),
}

FLUJO_PAGO = [
    "El cliente crea un `trabajos` (estado `pendiente` o `esperando_cotizaciones`, con su `modalidad_cobro`). "
    "En cotización abierta, cada profesional envía una `propuestas_cotizacion` y la elegida queda en "
    "`trabajos.id_cotizacion_seleccionada`.",
    "`crear_intencion_pago` inserta un `pagos` con `tipo_pago = 'principal'`, `estado = 'pendiente'` y "
    "`monto` en CLP. Con Webpay se guardan `token_tbk`, `url_tbk` y `buy_order`. Con Oneclick se usa la "
    "tarjeta de `metodos_pago_oneclick` (`tbk_user`); si aún no está inscrita, `id_trabajo_pendiente` "
    "recuerda qué trabajo cobrar al terminar la inscripción.",
    "Transbank autoriza y el pago pasa a `retenido` (escrow). `sincronizar_estado_pago_trabajo` copia ese "
    "estado a `trabajos.estado_pago`.",
    "Si cambia el alcance, el profesional crea una `ordenes_cambio`. Al aceptarla se cobra un segundo pago "
    "(`tipo_pago = 'orden_cambio'`), enlazado en ambos sentidos (`pagos.id_orden_cambio` y "
    "`ordenes_cambio.id_pago`).",
    "El trabajo se inicia con el PIN del cliente (`pines_inicio_trabajo`, `intentos_pin_inicio` y "
    "`bloqueos_pin_inicio`) y se termina. Con la conformidad del cliente o la liberación automática, "
    "`liberar_escrow` deja el pago en `liberado` y `fijar_liquidacion_desde_pago` crea la `liquidaciones` "
    "(una por pago), con `monto_clp`, `proveedor` y `estado_transferencia` (`pendiente` → `transferido`). "
    "La transferencia usa la `cuentas_bancarias` del profesional.",
    "Si hay una `disputas`, la decisión (`liberar`, `reembolsar` o `humano`) termina en `liberar_escrow` o "
    "`reembolsar_escrow` (`reembolso_pendiente` → `reembolsado`).",
]


def _contexto():
    er = _er()
    d, cols, pk, fks, uq = er.cargar()
    snap = json.loads(er.SCHEMA.read_text(encoding="utf-8"))
    n_def = sum(1 for f in snap["functions"] if f["security"] == "SECURITY DEFINER")
    rls = sum(1 for t in snap["tables"] if t["rls_enabled"])
    pk_tipos = {}
    for t, cs in pk.items():
        if len(cs) > 1:
            pk_tipos.setdefault("compuesta", []).append(t)
        else:
            ty = next(c["ty"] for c in cols[t] if c["c"] == cs[0])
            pk_tipos.setdefault(ty, []).append(t)
    relaciones = []
    for f in fks:
        (hl, _), (pl, _) = er.cardinalidad(f, cols, pk, uq) if f["rs"] == "public" else ((("0..1", ""), ("1", "")))
        dl = {"c": "CASCADE", "n": "SET NULL", "a": "NO ACTION", "r": "RESTRICT", "d": "SET DEFAULT"}[f["del"]]
        destino = f"{'auth.' if f['rs'] != 'public' else ''}{f['rt']}"
        relaciones.append((f"{f['t']}.{', '.join(f['cols'])}", f"{destino}.{', '.join(f['rcols'])}", f"{pl} ─ {hl}", dl,
                           er.DOM_OF[f["t"]][1]))
    return er, d, cols, pk, fks, uq, snap, n_def, rls, pk_tipos, relaciones


def _decisiones(er, d, pk, snap, n_def, rls, pk_tipos):
    txt = [
        "Claves primarias. `perfiles.id` es `uuid` porque es la misma clave de `auth.users`. La mayoría de las "
        f"tablas usa `id text` ({len(pk_tipos.get('text', []))} tablas): la app y las funciones generan el "
        "identificador (un UUID en texto, un slug como `comunas.id` o un código como `paises.id`). Tienen PK `uuid` "
        f"{', '.join(sorted(pk_tipos.get('uuid', [])))}; `intentos_pin_inicio` usa `bigint` identidad. "
        "Las tablas 1:1 usan la FK como PK (`trabajadores`, `cuentas_bancarias`, `metodos_pago_oneclick`, "
        "`pines_inicio_trabajo`, `bloqueos_pin_inicio`, `ubicacion_en_vivo`), y las de catálogo del profesional "
        f"usan PK compuesta ({', '.join(sorted(pk_tipos.get('compuesta', [])))}).",
        f"Seguridad por filas. RLS está activo en {rls} de {len(snap['tables'])} tablas, con "
        f"{len(snap['policies'])} políticas. Las tablas sensibles (`app_config`, `bloqueos_pin_inicio`, "
        "`intentos_pin_inicio`, `metodos_pago_oneclick`) no tienen políticas para el cliente: solo se acceden con "
        "funciones o con service_role.",
        f"Funciones SECURITY DEFINER. {n_def} de las {len(snap['functions'])} funciones de public son "
        "SECURITY DEFINER. Las escrituras con reglas de negocio (transiciones de trabajo, PIN, pagos, escrow, "
        "reseñas, reprogramación) pasan por estas RPC, que validan al usuario con auth.uid() antes de escribir. "
        "Así una tabla no queda abierta a un UPDATE directo.",
        "Columnas id_usuario de texto. Hasta la migración 20261115234447, `trabajador_precios.id_usuario` y "
        "`trabajador_servicios_extra.id_usuario` eran `text` sin FK. La auditoría 20261116042559 las pasó a "
        "`uuid` con FK a `trabajadores.id_usuario` (ON DELETE CASCADE), y hoy son relaciones físicas. Quedan como "
        "relaciones lógicas, dibujadas con línea punteada, las columnas de la tabla siguiente.",
        "Fechas. Varias columnas `creado_en` y `actualizado_en` son `text`, herencia de la primera versión del esquema. La auditoría agregó CHECK `es_marca_tiempo_iso(...)` para que siempre guarden ISO 8601. "
        "Las tablas nuevas usan `timestamptz`.",
        "Estados. No hay ENUM. Los conjuntos cerrados (estado del trabajo, del pago, de la disputa, etc.) se "
        "restringen con CHECK, que se amplía en una migración sin recrear tipos.",
    ]
    return txt


def md_lineas():
    er, d, cols, pk, fks, uq, snap, n_def, rls, pk_tipos, relaciones = _contexto()
    L = []
    a = L.append
    n_fk_pub = sum(1 for f in fks if f["rs"] == "public")
    a("## 2b. Modelo entidad-relación")
    a("")
    a(f"El modelo tiene **{len(d['tables'])} tablas**, {sum(len(v) for v in cols.values())} columnas, {len(pk)} claves "
      f"primarias y **{len(fks)} claves foráneas** ({n_fk_pub} entre tablas de public y 1 de `perfiles` a "
      f"`auth.users`), hasta la migración `{d['migr']}`. Las figuras salen del mismo snapshot que este "
      "diccionario. Fuentes editables (DBML, SQL PostgreSQL, SQL MySQL Workbench y Graphviz) y el LEEME: "
      "[`Fase 2/modelo_entidad_relacion/`](../../Fase%202/modelo_entidad_relacion/LEEME.txt).")
    a("")
    a("Notación crow's foot: la pata de gallo es «muchos», la barra es «uno» y el círculo es «opcional». "
      "PK subrayada, FK en cursiva y FK* para una relación lógica sin FOREIGN KEY (línea punteada). `?` marca una "
      "columna que admite NULL.")
    a("")
    a("### 2b.1 Dominios")
    a("")
    a("| Dominio | Tablas |")
    a("|---|---|")
    for key, nombre, _c, _bg, ts in er.DOMINIOS:
        a(f"| {nombre} | {', '.join(f'`{t}`' for t in ts)} |")
    a("")
    a(f"![Mapa de dominios]({FIG_MD}/er_00_dominios.png)")
    a("")
    a("*Figura ER-1. Mapa de dominios: tablas de cada dominio y número de FK entre dominios.*")
    a("")
    a(f"![Modelo ER general]({FIG_MD}/er_00_general.png)")
    a("")
    a("*Figura ER-2. Modelo ER general: las 52 tablas con su PK y todas las FK. Para leer el detalle, "
      "abrir el SVG (`er_00_general.svg`) o ver el diagrama del dominio.*")
    a("")
    for i, (key, nombre, _c, _bg, ts) in enumerate(er.DOMINIOS, 1):
        a(f"### 2b.{i + 1} {nombre}")
        a("")
        a(EXPLICA[key])
        a("")
        a(f"![{nombre}]({FIG_MD}/er_{key}.png)")
        a("")
        a(f"*Figura ER-{i + 2}. {nombre}: columnas, tipos, PK/FK y cardinalidad.*")
        a("")
    a("### 2b.9 Flujo de pago y escrow en el modelo")
    a("")
    for j, paso in enumerate(FLUJO_PAGO, 1):
        a(f"{j}. {paso}")
    a("")
    a("### 2b.10 Decisiones de diseño")
    a("")
    for t in _decisiones(er, d, pk, snap, n_def, rls, pk_tipos):
        tit, cuerpo = t.split(". ", 1)
        a(f"- **{tit}.** {cuerpo}")
    a("")
    a("| Relación lógica (sin FK) | Apunta a | Motivo |")
    a("|---|---|---|")
    for t, cs, rt, rcs, why in er.LOGICAS:
        a(f"| `{t}.{', '.join(cs)}` | `{rt}.{', '.join(rcs)}` | {why} |")
    for t, c, why in er.POLIMORFICAS:
        if t == "calificaciones":
            continue
        a(f"| `{t}.{c}` | (varias) | {why} |")
    a("")
    a("### 2b.11 Cardinalidad de cada clave foránea")
    a("")
    a("Se lee «padre ─ hijo»: `1 ─ 0..N` es un padre obligatorio con cero o más hijos; `0..1 ─ 0..N` es un padre "
      "opcional (FK que admite NULL); `1 ─ 0..1` es una relación uno a uno.")
    a("")
    a("| Dominio | FK (hija) | Referencia (padre) | Cardinalidad | ON DELETE |")
    a("|---|---|---|---|---|")
    for src, dst, card, dl, dom in sorted(relaciones, key=lambda r: (r[4], r[0])):
        a(f"| {dom} | `{src}` | `{dst}` | {card} | {dl} |")
    a("")
    return L


def anexo_lineas():
    return [
        "Modelo entidad-relación: las figuras (mapa de dominios, diagrama general con las 52 tablas y un "
        "diagrama por dominio con columnas, tipos, PK/FK y cardinalidad) están en "
        "`Fase 2/modelo_entidad_relacion/figuras/`, con fuentes editables y un LEEME en la misma carpeta. "
        "La explicación de cada dominio, el flujo de pago y las decisiones de diseño están en la sección 2b "
        "de `MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md`.",
        "",
    ]


def agregar_docx(doc, add_heading, add_body, add_table):
    from docx.enum.section import WD_ORIENT, WD_SECTION
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    from docx.shared import Cm, Emu
    from PIL import Image

    er, d, cols, pk, fks, uq, snap, n_def, rls, pk_tipos, relaciones = _contexto()
    n_fk_pub = sum(1 for f in fks if f["rs"] == "public")

    def figura(nombre_png, pie, reserva_cm=2.2):
        sec = doc.sections[-1]
        ancho = sec.page_width - sec.left_margin - sec.right_margin
        alto = sec.page_height - sec.top_margin - sec.bottom_margin - Cm(reserva_cm)
        w, h = Image.open(FIG / nombre_png).size
        if w / h >= ancho / alto:
            kw = {"width": Emu(int(ancho))}
        else:
            kw = {"height": Emu(int(alto))}
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.add_run().add_picture(str(FIG / nombre_png), **kw)
        c = doc.add_paragraph()
        c.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = c.add_run(pie)
        r.italic = True

    def orientar(horizontal):
        sec = doc.add_section(WD_SECTION.NEW_PAGE)
        w, h = sec.page_width, sec.page_height
        if horizontal != (w > h):
            sec.page_width, sec.page_height = h, w
        sec.orientation = WD_ORIENT.LANDSCAPE if horizontal else WD_ORIENT.PORTRAIT
        return sec

    add_heading(doc, "3b. Modelo entidad-relación", 1)
    add_body(doc, f"El modelo tiene {len(d['tables'])} tablas, {sum(len(v) for v in cols.values())} columnas, "
                  f"{len(pk)} claves primarias y {len(fks)} claves foráneas ({n_fk_pub} entre tablas de public y 1 de "
                  f"perfiles a auth.users), hasta la migración {d['migr']}. Las figuras salen del mismo snapshot que "
                  "este diccionario. Las fuentes editables (DBML, SQL PostgreSQL, SQL MySQL Workbench y Graphviz) y "
                  "el LEEME.txt están en Fase 2/modelo_entidad_relacion/.")
    add_body(doc, "Notación crow's foot: la pata de gallo es «muchos», la barra es «uno» y el círculo es «opcional». "
                  "PK subrayada, FK en cursiva y FK* para una relación lógica sin FOREIGN KEY (línea punteada). "
                  "«?» marca una columna que admite NULL.")
    add_heading(doc, "3b.1 Dominios", 2)
    add_table(doc, ["Dominio", "Tablas"], [[n, ", ".join(ts)] for _k, n, _c, _b, ts in er.DOMINIOS])

    def horizontal(png):
        w, h = Image.open(FIG / png).size
        return w / h > 1.1

    orientar(horizontal("er_00_dominios.png"))
    figura("er_00_dominios.png", "Figura ER-1. Mapa de dominios: tablas de cada dominio y número de FK entre dominios.")
    orientar(horizontal("er_00_general.png"))
    figura("er_00_general.png", "Figura ER-2. Modelo ER general: las 52 tablas con su PK y todas las FK "
                                "(detalle en el SVG o en el diagrama de cada dominio).")
    for i, (key, nombre, _c, _bg, ts) in enumerate(er.DOMINIOS, 1):
        orientar(horizontal(f"er_{key}.png"))
        add_heading(doc, f"3b.{i + 1} {nombre}", 2)
        add_body(doc, EXPLICA[key].replace("`", ""))
        figura(f"er_{key}.png", f"Figura ER-{i + 2}. {nombre}: columnas, tipos, PK/FK y cardinalidad.", reserva_cm=6.5)
    orientar(False)

    add_heading(doc, "3b.9 Flujo de pago y escrow en el modelo", 2)
    for j, paso in enumerate(FLUJO_PAGO, 1):
        add_body(doc, f"{j}. {paso.replace('`', '')}")
    add_heading(doc, "3b.10 Decisiones de diseño", 2)
    for t in _decisiones(er, d, pk, snap, n_def, rls, pk_tipos):
        add_body(doc, t.replace("`", ""))
    filas = [[f"{t}.{', '.join(cs)}", f"{rt}.{', '.join(rcs)}", why] for t, cs, rt, rcs, why in er.LOGICAS]
    filas += [[f"{t}.{c}", "(varias)", why] for t, c, why in er.POLIMORFICAS if t != "calificaciones"]
    add_table(doc, ["Relación lógica (sin FK)", "Apunta a", "Motivo"], filas)
    add_heading(doc, "3b.11 Cardinalidad de cada clave foránea", 2)
    add_body(doc, "Se lee «padre ─ hijo»: 1 ─ 0..N es un padre obligatorio con cero o más hijos; 0..1 ─ 0..N es un "
                  "padre opcional (FK que admite NULL); 1 ─ 0..1 es una relación uno a uno.")
    add_table(doc, ["Dominio", "FK (hija)", "Referencia (padre)", "Cardinalidad", "ON DELETE"],
              [[dom, s, t, c, dl] for s, t, c, dl, dom in sorted(relaciones, key=lambda r: (r[4], r[0]))])

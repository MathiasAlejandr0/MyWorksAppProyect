# -*- coding: utf-8 -*-
"""Genera docs/DICCIONARIO_BASE_DATOS.docx en español neutro (formato profesional)."""
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn, nsdecls
from docx.oxml import parse_xml
from docx.shared import Cm, Pt, RGBColor

OUT = Path(__file__).resolve().parent / "DICCIONARIO_BASE_DATOS.docx"


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


def main():
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
    r = meta.add_run(
        "Documento técnico de esquema · PostgreSQL / Supabase\n"
        "Versión 1.5 · 19 de septiembre de 2026\n"
        "Español neutro · snake_case"
    )
    set_run_font(r, size=11, color=RGBColor(90, 90, 90))

    note = doc.add_paragraph()
    set_paragraph_format(note, align=WD_ALIGN_PARAGRAPH.CENTER, space_before=24)
    r = note.add_run(
        "Uso académico y de desarrollo. Describe el esquema public "
        "consumido por las aplicaciones móvil, web y escritorio. "
        "Redacción en español neutro (sin regionalismos)."
    )
    set_run_font(r, size=10, color=RGBColor(100, 100, 100))

    doc.add_page_break()

    add_heading(doc, "1. Identificación del documento", 1)
    add_table(
        doc,
        ["Campo", "Valor"],
        [
            ["Proyecto", "My Works App"],
            ["Proyecto Supabase", "wxqrfcqifkfgawrnqmnj"],
            ["Motor", "PostgreSQL (Supabase)"],
            ["Esquema", "public"],
            ["Convención de nombres", "Español + snake_case"],
            ["Idioma del documento", "Español neutro"],
            ["Versión del documento", "1.5"],
            ["Fecha", "2026-09-19"],
            [
                "Estado de migraciones",
                "Rename, RLS, catálogo, hardening y las correcciones del 19 de septiembre "
                "aplicados en el servidor.",
            ],
            [
                "Tipado observado",
                "Híbrido: IDs uuid y text; booleanos como int 0/1; fechas a menudo text ISO.",
            ],
        ],
    )

    add_heading(doc, "2. Propósito", 1)
    add_body(
        doc,
        "Este diccionario constituye el contrato canónico de datos de negocio del sistema "
        "My Works App. Documenta tablas, columnas, significados, códigos de dominio, "
        "relaciones lógicas, artefactos de seguridad (triggers, RLS, RPC) y los clientes "
        "que consumen cada entidad. Está orientado a defensa académica, incorporación técnica "
        "y control de cambios tras el rename del esquema a español.",
    )
    add_body(
        doc,
        "Cómo leerlo: la sección 3 es el índice de las 28 tablas. La sección 4 lista los textos "
        "exactos de estado; hay que copiarlos tal cual. La sección 7 explica quién puede leer o "
        "cambiar cada dato, incluidas las funciones corregidas el 19 de septiembre de 2026.",
    )

    add_heading(doc, "3. Inventario de tablas (28)", 1)
    add_body(
        doc,
        "Todas las tablas de negocio listadas pertenecen al esquema public. "
        "La columna «Origen EN» indica el nombre previo al rename. Las primeras 10 son las de "
        "uso cotidiano; del 11 al 16 cubren cotización, evidencia y cancelación; del 17 al 28 "
        "soportan cumplimiento, flags y funciones de producto.",
    )
    tablas = [
        ("1", "perfiles", "profiles", "Identidad de aplicación ligada a Auth"),
        ("2", "trabajadores", "workers", "Perfil profesional 1:1 con usuario"),
        ("3", "servicios", "services", "Catálogo de oficios"),
        ("4", "trabajos", "jobs", "Solicitud y ciclo de vida del servicio"),
        ("5", "pagos", "payments", "Escrow / pagos (pasarela simulada en clientes)"),
        ("6", "mensajes", "messages", "Chat asociado a un trabajo"),
        ("7", "disputas", "disputes", "Conflictos y mediación"),
        ("8", "notificaciones", "notifications", "Bandeja in-app / Realtime"),
        ("9", "calificaciones", "ratings", "Puntaje 1–5 post-servicio"),
        ("10", "reportes", "reports", "Denuncias entre usuarios"),
        ("11", "propuestas_cotizacion", "quote_proposals", "Cotizaciones abiertas"),
        ("12", "ordenes_cambio", "change_orders", "Cambios de alcance / extras"),
        ("13", "fotos_trabajo", "job_photos", "Evidencia fotográfica o video"),
        ("14", "portafolio_trabajador", "worker_portfolio", "Galería del profesional"),
        ("15", "trabajador_servicios", "worker_services", "Relación N:M categorías"),
        ("16", "cancelaciones_trabajo", "job_cancellations", "Auditoría de cancelación"),
        ("17", "registros_error_app", "app_error_logs", "Telemetría de errores"),
        ("18", "eventos_abuso", "abuse_events", "Detección antiabuso"),
        ("19", "acciones_pendientes", "pending_actions", "Cola de sync offline"),
        ("20", "bloqueos_usuario", "user_blocks", "Bloqueos mutuos"),
        ("21", "consentimientos_usuario", "user_consents", "Términos / GDPR"),
        ("22", "banderas_funcionalidad", "feature_flags", "Feature flags"),
        ("23", "suscripciones", "subscriptions", "Planes de monetización"),
        ("24", "impulsos", "boosts", "Impulso de visibilidad"),
        ("25", "eventos_analitica", "analytics_events", "Analítica de producto"),
        ("26", "configuraciones_servicio", "service_configs", "Schema UI por servicio"),
        ("27", "codigos_restablecimiento", "password_reset_codes", "Códigos de restablecimiento"),
        ("28", "tickets_soporte", "tickets", "Mesa de soporte / ayuda"),
    ]
    add_table(doc, ["#", "Tabla", "Origen EN", "Propósito"], tablas)

    add_heading(doc, "4. Glosario de códigos de dominio", 1)
    add_body(
        doc,
        "Los valores siguientes son los códigos almacenados en base de datos tras la migración a español. "
        "Las aplicaciones deben usar estos literales (no los antiguos en inglés). "
        "Al programar filtros o condiciones, deben utilizarse exactamente estos valores.",
    )
    glosario = [
        ("Rol", "usuario | trabajador | administrador (is_admin también acepta admin)"),
        ("Estado de cuenta", "activo | suspendido | bloqueado | eliminado"),
        (
            "Estado de trabajo",
            "pendiente | aceptado | en_curso | completado | cancelado | expirado | "
            "no_asistio | esperando_pago | esperando_cotizaciones | cotizacion_seleccionada | "
            "pausado_orden_cambio | esperando_aprobacion_cliente",
        ),
        ("Estado de pago", "ninguno | pendiente | autorizado | retenido | liberado | reembolsado"),
        ("Modalidad de cobro", "legado | precio_fijo | bloque_horas | cotizacion_abierta"),
        ("Tipo de pago", "principal | orden_cambio | horas_extra"),
        ("Disputa (estado)", "abierta | en_revision | resuelta"),
        ("Disputa (motivo)", "calidad | pago | conducta | otro"),
        ("Reporte", "pendiente | revisado | resuelto | descartado"),
        (
            "Categoría de servicio",
            "construccion | plomeria | electricidad | limpieza | ensamblaje | "
            "soporte_tecnico | jardinera | mudanza | general",
        ),
        ("Modelo de precio", "por_hora | fijo | por_item"),
        ("Cotización", "enviada | retirada | aceptada | rechazada"),
        ("Orden de cambio", "pendiente_cliente | aprobada | rechazada | pagada | cancelada"),
        ("Mensaje / medio", "texto | imagen · foto | video"),
        ("Error de app", "nuevo | reconocido | resuelto | ignorado"),
        ("Sync offline", "pendiente_sync | sincronizando | sincronizado | fallido"),
        ("Suscripción", "activa | cancelada | expirada · planes: gratuito | basico | premium | empresarial"),
        ("Impulso", "visibilidad | prioridad | destacado"),
        ("Ticket soporte", "pendiente | resuelto"),
    ]
    add_table(doc, ["Dominio", "Valores permitidos"], glosario)
    add_body(
        doc,
        "Uso habitual: el cliente ingresa como usuario; el profesional como trabajador; "
        "la consola de escritorio solo admite administrador. El estado de pago en clientes "
        "es simulación académica hasta integrar una pasarela real; tras el hardening, las "
        "transiciones deben realizarse mediante RPC (simular_transicion_pago).",
    )

    add_heading(doc, "5. Detalle de tablas núcleo", 1)

    add_heading(doc, "5.1 perfiles", 2)
    add_body(
        doc,
        "Perfil de aplicación vinculado a auth.users. La clave primaria coincide con el identificador de Auth. "
        "Aquí se guardan nombre, correo, rol y si la cuenta es usable.",
    )
    add_table(
        doc,
        ["Columna", "Tipo lógico", "Nulo", "Descripción"],
        [
            ("id", "uuid (típico)", "No", "PK = auth.users.id"),
            ("nombre", "text", "No", "Nombre visible"),
            ("correo", "text", "No", "Correo electrónico"),
            ("rol", "text", "No", "Ver glosario de roles"),
            ("estado_cuenta", "text", "No", "Ver glosario de estados"),
            ("ruta_foto_perfil", "text", "Sí", "URL o ruta de foto"),
            ("creado_en", "text / timestamptz", "No", "Fecha de alta"),
        ],
    )
    add_body(
        doc,
        "Índice: idx_perfiles_rol. Triggers: handle_new_user (alta segura sin auto-administrador); "
        "protect_profiles_sensitive (impide cambio de rol/estado_cuenta sin is_admin).",
    )

    add_heading(doc, "5.2 trabajadores", 2)
    add_body(
        doc,
        "Solo los perfiles que ofrecen oficios tienen fila aquí (relación 1:1 con id_usuario). "
        "disponible = 1 indica que puede recibir contacto; precios_configurados = 1 indica que "
        "completó la configuración de tarifas; niveles_precio es JSON para paquetes por oficio.",
    )
    add_table(
        doc,
        ["Columna", "Tipo", "Descripción"],
        [
            ("id_usuario", "PK / FK → perfiles", "Identificador del profesional"),
            ("profesion", "text", "Oficio declarado"),
            ("descripcion", "text", "Biografía profesional"),
            ("calificacion", "numeric", "Rating agregado"),
            ("disponible", "int 0/1", "Disponibilidad para nuevos trabajos"),
            ("tarifa_visita", "numeric", "Tarifa de visita en CLP"),
            ("categoria_servicio", "text", "Categoría principal"),
            ("niveles_precio", "json", "Niveles de precio"),
            ("servicios_personalizados", "json", "Servicios adicionales"),
            ("precios_configurados", "int 0/1", "Indica si completó la configuración de precios"),
            ("zona_trabajo", "text", "Comuna o zona de cobertura"),
            ("conteo_rechazos", "int", "Penaliza el orden en listados"),
        ],
    )
    add_body(doc, "FK documentada: trabajadores_id_usuario_fkey. Índice: idx_trabajadores_categoria.")

    add_heading(doc, "5.3 servicios", 2)
    add_body(
        doc,
        "Catálogo de oficios: id, nombre, descripcion, categoria, activo, requiere_certificacion, "
        "modelo_precio (por_hora | fijo | por_item), aviso_legal, creado_en, actualizado_en. "
        "Si la tabla está vacía, el inicio del cliente no tiene qué listar; por eso existe el seed de la migración 06. "
        "La política pública no invoca is_admin() para evitar el error 42501 con el rol anon.",
    )

    add_heading(doc, "5.4 trabajos", 2)
    add_body(
        doc,
        "Entidad operativa central. Columnas: id (frecuentemente text), id_usuario, id_trabajador, "
        "id_servicio, estado, direccion, latitud, longitud, descripcion, fecha_programada, "
        "metadatos_servicio, modalidad_cobro, estado_pago, id_comuna, instantanea_precio, "
        "id_sku_servicio, horas_bloque, id_cotizacion_seleccionada, creado_en, actualizado_en. "
        "Índices: estado, id_usuario, id_trabajador, creado_en. "
        "Las transiciones de estado deben realizarse mediante RPC transicionar_trabajo tras el hardening.",
    )

    add_heading(doc, "5.5 pagos", 2)
    add_body(
        doc,
        "id, id_trabajo, id_orden_cambio, tipo_pago, monto, moneda (CLP), estado, metodo_pago, "
        "id_transaccion, autorizado_en, liberado_en, reembolsado_en, creado_en, actualizado_en. "
        "No hay pasarela real. El cambio de estado se hace con simular_transicion_pago. "
        "El cliente y el administrador usan la matriz completa. El profesional solo retiene "
        "el cobro, libera si el trabajo ya está completado y reembolsa si ya está cancelado.",
    )

    add_heading(doc, "5.6 mensajes", 2)
    add_body(
        doc,
        "Chat por trabajo (no bandeja global): id_trabajo, id_remitente, id_destinatario, contenido, "
        "tipo (texto|imagen), ruta_imagen, leido, creado_en. El remitente debe coincidir con el usuario autenticado.",
    )

    add_heading(doc, "5.7 disputas", 2)
    add_body(
        doc,
        "id_trabajo, abierta_por, motivo, descripcion, estado, resolucion, resuelta_por, "
        "resuelta_en, creado_en, actualizado_en. Actualización de resolución reservada a administradores "
        "(política + RPC admin_actualizar_estado_disputa).",
    )

    add_heading(doc, "5.8 notificaciones", 2)
    add_body(
        doc,
        "id_usuario, tipo (códigos de evento aún en inglés, por ejemplo job_accepted), titulo, cuerpo, "
        "id_relacionado, leido, creado_en. Canal Realtime: notificaciones.",
    )

    add_heading(doc, "5.9 calificaciones", 2)
    add_body(doc, "id_trabajo, id_usuario, puntaje (1–5), comentario, creado_en.")

    add_heading(doc, "5.10 reportes", 2)
    add_body(
        doc,
        "id_reportante, id_usuario_reportado, motivo, descripcion, estado, creado_en. "
        "Denuncias entre usuarios para moderación.",
    )

    add_heading(doc, "6. Tablas secundarias", 1)
    add_table(
        doc,
        ["Tabla", "Columnas clave / nota"],
        [
            ("propuestas_cotizacion", "id_trabajo, id_trabajador, monto_total_clp, estado, validez_hasta"),
            ("ordenes_cambio", "id_trabajo, id_trabajador, monto_clp, estado, id_pago"),
            ("fotos_trabajo", "id_trabajo, ruta_foto, tipo_medio"),
            ("portafolio_trabajador", "id_trabajador, ruta_foto, tipo_medio"),
            ("trabajador_servicios", "N:M id_trabajador + categoria_servicio"),
            ("cancelaciones_trabajo", "id_trabajo, cancelado_por, motivo, cancelado_en"),
            ("registros_error_app", "Telemetría; política INSERT autenticado"),
            ("eventos_abuso", "Antiabuso; códigos de tipo aún EN en modelo"),
            ("acciones_pendientes", "Cola sync offline"),
            ("bloqueos_usuario", "id_bloqueador, id_bloqueado"),
            ("consentimientos_usuario", "GDPR / versión de consentimiento"),
            ("banderas_funcionalidad", "Feature flags por rol/versión"),
            ("suscripciones / impulsos", "Monetización e impulso de visibilidad"),
            ("eventos_analitica", "Analítica de producto"),
            ("configuraciones_servicio", "esquema_config por servicio"),
            ("codigos_restablecimiento", "Restablecimiento de contraseña (sin model Dart dedicado)"),
            ("tickets_soporte", "Mesa de ayuda; interfaz de escritorio parcialmente DEMO"),
        ],
    )

    add_heading(doc, "7. Seguridad y funciones", 1)
    add_body(
        doc,
        "La migración 20260914000005_rls_politicas_negocio.sql habilita Row Level Security "
        "en las tablas de negocio y define helpers y RPC administrativas. "
        "Debido al tipado híbrido uuid/text, las comparaciones de identidad usan ::text en ambos lados. "
        "El hardening 20260915000001 endurece pagos, mensajes y trabajos, elimina políticas EN residuales "
        "y expone RPC mock de escrow hasta integrar una pasarela real.",
    )
    add_table(
        doc,
        ["Artefacto", "Efecto"],
        [
            ("is_admin()", "Verdadero si el perfil autenticado es admin/administrador y la cuenta está activa"),
            ("es_parte_trabajo(text)", "Cliente o trabajador del trabajo, o administrador"),
            ("RLS policies", "Lectura/escritura restringida a propio, parte del trabajo, administrador o marketplace"),
            ("admin_metricas_resumen()", "JSON de métricas; solo administradores"),
            ("admin_actualizar_estado_disputa(...)", "Cambia estado/resolución de disputa; solo administrador"),
            ("transicionar_trabajo(...)", "Cambia estado de trabajo con matriz validada en servidor"),
            ("es_rol_trabajador(text)", "La persona es profesional activo (incluye alias worker, especialista, specialist)"),
            ("simular_transicion_pago(...)", "Pago simulado. El profesional no libera ni reembolsa si el trabajo sigue abierto"),
            ("asignar_trabajador_trabajo(...)", "Acepta el trabajo. El destino debe ser profesional activo. Un cliente no puede autoasignarse"),
            ("rechazar_trabajo_pendiente(...)", "Cancela un pendiente. Si no hay profesional asignado, se detiene"),
            ("handle_new_user", "Crea perfiles en el registro; no permite autoasignarse administrador"),
            ("protect_profile_sensitive_fields", "Bloquea cambio de rol/estado_cuenta sin administrador"),
        ],
    )
    add_body(
        doc,
        "Regla del pago simulado: el cliente y el administrador pueden autorizar, retener, "
        "liberar y reembolsar según la matriz. El profesional asignado solo retiene el cobro; "
        "libera únicamente si el trabajo ya está completado y reembolsa únicamente si ya está "
        "cancelado. Un cliente no puede aceptar un trabajo a su nombre.",
    )

    add_heading(doc, "8. Aplicaciones consumidoras", 1)
    add_table(
        doc,
        ["Aplicación", "Consumo principal"],
        [
            ("Flutter (móvil)", "Repositories sobre casi todas las tablas de negocio"),
            ("Web (React)", "Catálogo, trabajadores, trabajos; checkout de pago simulado"),
            ("Escritorio (Tauri/React)", "Disputas y métricas vía RPC; paneles DEMO etiquetados"),
            ("Paquete shared", "Auth tipada, repositorios TS, métricas y disputas de administrador"),
        ],
    )
    add_body(
        doc,
        "Flutter es el cliente completo. Web es marketplace y reserva. Escritorio es operaciones "
        "(soporte/ejecutivo) con paneles demo académicos aparte: no deben confundirse con datos productivos.",
    )

    add_heading(doc, "9. Limitaciones y gaps conocidos", 1)
    add_table(
        doc,
        ["Gap", "Severidad", "Comentario"],
        [
            (
                "Autorización de trabajo y pago",
                "Alta",
                "Cerrado en el servidor el 19 de septiembre de 2026.",
            ),
            (
                "Tipado híbrido uuid / text",
                "Media",
                "Políticas y RPC usan casts ::text. Falta dump CREATE TABLE histórico versionado.",
            ),
            (
                "Códigos de notificación / abuso en inglés",
                "Baja",
                "No migrados a español en datos.",
            ),
            (
                "Tabla service_pricing",
                "Baja",
                "Existe model/TODO en código sin tabla en el rename.",
            ),
            (
                "Pasarela de pago real",
                "Alta (diferida)",
                "Empresa aún no constituida; mock solo vía RPC en servidor.",
            ),
        ],
    )

    add_heading(doc, "10. Referencias", 1)
    add_body(
        doc,
        "docs/mapa_esquema_en_es.md · docs/APLICAR_MIGRACION_ES.md · docs/APLICAR_HARDENING_20260915.md · "
        "docs/AUDITORIA_PROYECTO.md · docs/DICCIONARIO_BASE_DATOS.md · "
        "myworksapp_app/supabase/migrations/20260914000004_aplicar_rename_es.sql · "
        "20260914000005_rls_politicas_negocio.sql · 20260914000006_seed_servicios_marketplace.sql · "
        "20260915000001_hardening_seguridad_sin_psp.sql · "
        "20260919000001_fix_rpc_autorizacion.sql · 20260919000002_pago_al_cerrar_trabajo.sql",
    )

    fin = doc.add_paragraph()
    set_paragraph_format(fin, space_before=18, align=WD_ALIGN_PARAGRAPH.CENTER)
    r = fin.add_run(
        "— Fin del diccionario · My Works App · Español neutro · Documento de proyecto —"
    )
    set_run_font(r, size=9, color=RGBColor(120, 120, 120))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()

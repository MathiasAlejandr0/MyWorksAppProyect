# -*- coding: utf-8 -*-
"""Genera el diccionario de base de datos desde un snapshot del esquema real.

Fuente: docs/_schema_public.json (information_schema / pg_catalog de
wxqrfcqifkfgawrnqmnj, solo lectura, 2026-11-16 America/Santiago).

Uso, desde la raíz del repo grupal (primero los diagramas ER, que se
incrustan en la sección «Modelo entidad-relación»):
    python3 "Fase 2/modelo_entidad_relacion/_gen_modelo_er.py"
    python3 MyWorksAppProyect/docs/_gen_diccionario_desde_schema.py
"""
from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls, qn
from docx.shared import Cm, Pt, RGBColor
from PIL import Image, ImageDraw, ImageFont

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from _normalizacion_bd import METODO as NF_METODO, forma_normal, relaciones_en_palabras  # noqa: E402

DOCS = Path(__file__).resolve().parent
ROOT_DOCS = DOCS
REPO = DOCS.parent.parent
FASE2 = REPO / "Fase 2"
SNAPSHOT = DOCS / "_schema_public.json"
if not SNAPSHOT.exists():
    SNAPSHOT = Path("/workspace/mwa_dict/schema_public.json")

OUT_MD = ROOT_DOCS / "DICCIONARIO_BASE_DATOS.md"
OUT_DOCX = ROOT_DOCS / "DICCIONARIO_BASE_DATOS.docx"
OUT_ANEXO = FASE2 / "Anexo_A_Diccionario_de_tablas.md"
OUT_DBML = FASE2 / "modelo_entidad_relacion.dbml"
OUT_SQL = FASE2 / "modelo_entidad_relacion.sql"
OUT_FIG = FASE2 / "figuras"

GENERATED_AT = "2026-11-16"
TZ_LABEL = "America/Santiago"
MODEL_VERSION = "v2.5"
PROJECT_ID = "wxqrfcqifkfgawrnqmnj"

GROUPS = {
    "identidad": [
        "perfiles",
        "notificaciones",
        "suscripciones",
        "codigos_restablecimiento",
        "consentimientos_usuario",
        "bloqueos_usuario",
        "reportes",
        "eventos_abuso",
        "acciones_pendientes",
        "registros_error_app",
        "eventos_analitica",
        "banderas_funcionalidad",
        "dispositivos_push",
        "verificacion_eventos",
    ],
    "territorio": ["paises", "regiones", "comunas"],
    "catalogo_4nf": [
        "trabajadores",
        "trabajador_precios",
        "trabajador_servicios_extra",
        "trabajador_servicios",
        "trabajador_horarios",
        "portafolio_trabajador",
        "impulsos",
        "servicios",
        "configuraciones_servicio",
    ],
    "pedido": [
        "trabajos",
        "mensajes",
        "fotos_trabajo",
        "calificaciones",
        "calificaciones_cliente",
        "disputas",
        "disputa_mensajes",
        "acuerdos_trabajo",
        "cancelaciones_trabajo",
        "tickets_soporte",
        "ubicacion_en_vivo",
        "reprogramaciones_trabajo",
        "pines_inicio_trabajo",
        "bloqueos_pin_inicio",
        "intentos_pin_inicio",
    ],
    "cobro": [
        "propuestas_cotizacion",
        "pagos",
        "ordenes_cambio",
        "liquidaciones",
        "metodos_pago_oneclick",
        "cuentas_bancarias",
        "app_config",
    ],
    "ranking": [
        "ranking_config",
        "senales_resena",
        "ranking_aprendizaje",
        "eventos_ranking",
    ],
}

GROUP_LABELS = {
    "identidad": "Identidad y cuenta",
    "territorio": "Territorio",
    "catalogo_4nf": "Catálogo del profesional",
    "pedido": "Pedido y servicio",
    "cobro": "Cobro",
    "ranking": "Ranking y reputación",
}

GROUP_COLORS = {
    "identidad": (31, 78, 121),
    "territorio": (27, 107, 74),
    "catalogo_4nf": (138, 90, 18),
    "pedido": (162, 74, 28),
    "cobro": (92, 69, 120),
    "ranking": (44, 74, 110),
}

TABLE_NOTES = {
    "perfiles": (
        "Identidad de la aplicación: perfiles.id coincide con auth.users.id "
        "(esquema auth de Supabase, fuera de public; clave foránea con ON DELETE "
        "CASCADE desde la auditoría 2026-11-16). El default de rol es 'usuario' y "
        "el de estado_cuenta es 'activo'. Los CHECK perfiles_rol_chk y "
        "perfiles_estado_cuenta_chk cierran los conjuntos: usuario, trabajador, "
        "administrador, soporte y qa; activo, suspendido, bloqueado y eliminado. "
        "Los roles privilegiados (administrador, "
        "soporte, qa) no se pueden autoasignar: el trigger "
        "perfiles_rol_inicial_seguro y protect_profile_sensitive_fields lo impiden. "
        "reputacion_cliente y calificaciones_cliente los calcula calificar_cliente(); "
        "el usuario no puede editarlos (trigger protect_profile_sensitive_fields)."
    ),
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
    "dispositivos_push": "Token del dispositivo del usuario para avisos push (FCM u otra plataforma). El alta y el baja se hacen por RPC.",
    "verificacion_eventos": "Historial de cambios del estado de verificación de un profesional (pendiente, en revisión, verificado, rechazado).",
    "paises": "País operativo. Hoy solo CL.",
    "regiones": "Región administrativa de un país.",
    "comunas": "Comuna de cobertura. Su identificador es el slug usado por trabajos y trabajadores.",
    "trabajadores": (
        "Ficha 1:1 del profesional (PK = perfiles.id). La oferta en 4NF vive en "
        "tablas hijas; los JSON niveles_precio y servicios_personalizados son "
        "solo formato de escritura (un trigger los parte a filas). "
        "es_elite es una columna GENERATED. La agenda semanal está en "
        "trabajador_horarios; usa_horario enciende el filtro. "
        "pausa_por_trabajo queda en true cuando un trabajo activo dejó "
        "disponible = 0, y se restablece al terminar."
    ),
    "trabajador_precios": (
        "Precio por código de servicio del profesional. id_usuario es uuid "
        "con clave foránea a trabajadores (ON DELETE CASCADE) desde la "
        "auditoría 2026-11-16; antes era text sin FK."
    ),
    "trabajador_servicios_extra": (
        "Servicio adicional definido por el profesional. id_usuario es uuid "
        "con clave foránea a trabajadores, igual que en trabajador_precios."
    ),
    "trabajador_servicios": "Oficios del catálogo que el profesional declara atender.",
    "trabajador_horarios": (
        "Plantilla semanal: una fila por día (1 = lunes … 7 = domingo), "
        "única por (id_usuario, dia_semana). Solo el dueño lee y escribe (RLS). "
        "El cliente consulta los huecos con la RPC horarios_libres_profesional. "
        "usa_horario en trabajadores enciende el filtro."
    ),
    "portafolio_trabajador": "Foto o medio del portafolio de un profesional.",
    "impulsos": "Promoción temporal de visibilidad de un profesional.",
    "servicios": "Catálogo de oficios que la plataforma ofrece.",
    "configuraciones_servicio": "Esquema de configuración asociado a un servicio.",
    "trabajos": (
        "Pedido de un cliente a un profesional (o abierto a cotizaciones). "
        "estado_pago es una copia derivada del pago principal. La fecha "
        "programada se guarda como texto y, desde CU-33, solo cambia por las "
        "RPC de reagendamiento (trabajos_fecha_solo_por_rpc). Hay un índice "
        "único que impide dos trabajos activos del mismo profesional en el "
        "mismo minuto (minuto_utc de fecha_programada)."
    ),
    "mensajes": "Mensaje del chat de un trabajo.",
    "fotos_trabajo": "Evidencia fotográfica o de video de un trabajo (bucket de evidencias).",
    "calificaciones": (
        "Valoración de un trabajo. Desde la calificación bidireccional admite "
        "direccion cliente_a_trabajador o trabajador_a_cliente, con unicidad "
        "por (id_trabajo, direccion). Alimenta trabajadores.calificacion."
    ),
    "calificaciones_cliente": (
        "El profesional nota al cliente. 1:1 con el trabajo. Alimenta "
        "perfiles.reputacion_cliente. puntaje es smallint en la base viva."
    ),
    "disputas": "Disputa abierta sobre un trabajo y su resolución (incluye sugerencia automática y vencimiento).",
    "disputa_mensajes": "Mensajes del hilo de una disputa, de las partes o de soporte.",
    "acuerdos_trabajo": "Acuerdo entre cliente y profesional para rehacer, aceptar o anular un trabajo. Como máximo un acuerdo pendiente por trabajo.",
    "cancelaciones_trabajo": "Como máximo una cancelación por trabajo.",
    "tickets_soporte": "Ticket de soporte asociado a un trabajo.",
    "ubicacion_en_vivo": "GPS en vivo durante el trabajo. 1:1 con el trabajo.",
    "reprogramaciones_trabajo": (
        "Historial de propuestas para reagendar un trabajo (CU-33). "
        "Como máximo una propuesta pendiente por trabajo. Solo se escribe "
        "por las RPC proponer_reprogramacion, responder_reprogramacion y "
        "retirar_reprogramacion."
    ),
    "pines_inicio_trabajo": (
        "PIN que el cliente muestra al profesional para iniciar el trabajo "
        "(aceptado o en_camino → en_curso). El cliente (o un administrador) "
        "puede leerlo; el profesional lo valida con intentar_pin_inicio o "
        "transicionar_trabajo. Lo crea el trigger trabajos_crear_pin_inicio."
    ),
    "bloqueos_pin_inicio": (
        "Contador de intentos fallidos del PIN, bloqueo temporal (15 minutos "
        "tras 5 fallos) y ventana en la que el PIN ya fue validado. "
        "Escriben solo las funciones SECURITY DEFINER o service_role; "
        "un administrador puede leerla."
    ),
    "intentos_pin_inicio": (
        "Auditoría de cada intento de PIN de inicio. Escriben solo funciones "
        "SECURITY DEFINER; un administrador puede leerla."
    ),
    "propuestas_cotizacion": "Cotización que un profesional envía para un trabajo.",
    "pagos": (
        "Cobro asociado a un trabajo o a una orden de cambio, con retención "
        "(escrow) vía Transbank Webpay / Oneclick. Las columnas alta_nonce_hash, "
        "alta_jti y alta_consumido_en sustentan el alta del invitado después "
        "del pago: el nonce solo lo tiene el navegador y el jti es de un solo uso. "
        "El default de tipo_pago es 'primary' (inglés legado); el índice de un "
        "solo pago principal activo busca el valor 'principal'."
    ),
    "ordenes_cambio": "Cambio de alcance o de precio durante un trabajo.",
    "liquidaciones": "Un pago → una liquidación al profesional. manual = transferencia externa confirmada por admin; khipu/fintoc = PSP futuro.",
    "metodos_pago_oneclick": "Tarjeta inscrita Oneclick. RLS niega el acceso a anon y authenticated: solo service_role (Edge Functions).",
    "cuentas_bancarias": "Datos bancarios del profesional para pagar la liquidación. RLS: solo el dueño y un administrador. No es un dato público.",
    "app_config": "Pares clave/valor de configuración (demo_modo, admin_requiere_aal2, etc.). RLS niega el acceso a clientes; lo lee el backend.",
    "ranking_config": "Una fila default. Pesos del listado de profesionales.",
    "senales_resena": "Señales de reseña dudosa. Un falso positivo baja el peso de esa señal.",
    "ranking_aprendizaje": "Ajuste de los pesos del ranking y las métricas de ese cambio.",
    "eventos_ranking": "Evento que alimenta el ranking de un profesional.",
}

# typo fix: privileados -> privilegiados in perfiles note
TABLE_NOTES["perfiles"] = TABLE_NOTES["perfiles"].replace("privileados", "privilegiados")

RLS_SUMMARY = {
    "acciones_pendientes": "El dueño ve y gestiona sus propias acciones pendientes; un administrador ve todas.",
    "acuerdos_trabajo": "Solo lectura para las partes del trabajo (es_parte_trabajo) o un administrador. El alta y la respuesta se hacen por RPC (proponer_acuerdo, responder_acuerdo).",
    "app_config": "Política ALL con USING/CHECK false para anon y authenticated. Nadie del cliente lee ni escribe; solo service_role (bypass RLS) o funciones definer.",
    "banderas_funcionalidad": "Lectura restringida a banderas activas aplicables al usuario, o a un administrador.",
    "bloqueos_pin_inicio": "Solo un administrador puede leer (política agregada en la auditoría 2026-11-16). Nadie escribe por la API; lo hacen funciones SECURITY DEFINER (intentar_pin_inicio, transicionar_trabajo) o service_role.",
    "bloqueos_usuario": "El usuario ve los bloqueos en los que participa; solo él (o un administrador) puede crearlos.",
    "calificaciones": "Se inserta una calificación propia, con direccion e id_calificado coherentes con el trabajo terminado. Se leen las de cliente_a_trabajador (públicas para el listado) y las propias o de un administrador.",
    "calificaciones_cliente": "El profesional califica a su cliente en un trabajo 1:1; leen las partes o un administrador.",
    "cancelaciones_trabajo": "Las partes del trabajo o un administrador leen la cancelación; se inserta según las reglas del flujo de cancelar.",
    "codigos_restablecimiento": "Acceso acotado al dueño o al backend; no es un dato de catálogo.",
    "comunas": "Lectura pública del catálogo geográfico (comunas activas). La escritura es de administración o servicio.",
    "configuraciones_servicio": "Lectura del esquema de configuración del catálogo; escritura restringida.",
    "consentimientos_usuario": "El usuario ve y registra sus propios consentimientos.",
    "cuentas_bancarias": "ALL para el dueño o un administrador. No es un dato público.",
    "dispositivos_push": "El usuario solo lee sus propios tokens. El alta y la baja se hacen por RPC.",
    "disputa_mensajes": "Lectura para las partes del trabajo en disputa o un administrador. Los comentarios de soporte se insertan por RPC.",
    "disputas": "Las partes del trabajo o un administrador leen la disputa. La apertura y los cambios de estado van por RPC.",
    "eventos_abuso": "Restringido a administración o al backend de moderación.",
    "eventos_analitica": "El usuario o el backend registra eventos de uso; no es un listado público.",
    "eventos_ranking": "Lectura de administración; la escritura la hacen triggers y funciones definer.",
    "fotos_trabajo": "Las partes del trabajo o un administrador ven la evidencia. Hay reglas extra sobre el formato (p. ej. exigir webp/video).",
    "impulsos": "Lectura para usuarios con sesión (el catálogo muestra los vigentes). Crear, cambiar o borrar un impulso es solo de administración: antes de la auditoría 2026-11-16 un profesional podía darse un impulso sin pagar.",
    "intentos_pin_inicio": "Solo un administrador puede leer la bitácora (política agregada en la auditoría 2026-11-16). La escritura la hacen funciones SECURITY DEFINER.",
    "liquidaciones": "El profesional ve la liquidación de sus pagos; un administrador ve todas. La confirmación de transferencia es por RPC de admin.",
    "mensajes": "Solo las partes del chat (remitente o destinatario) o un administrador. Un trigger bloquea datos de contacto en el cuerpo.",
    "metodos_pago_oneclick": "Política ALL con USING/CHECK false para anon y authenticated. Las tarjetas solo las maneja service_role (Edge Functions).",
    "notificaciones": "El usuario lee y marca las suyas.",
    "ordenes_cambio": "Las partes del trabajo o un administrador leen y proponen según el flujo; el cobro asociado va por RPC de pago.",
    "pagos": "El cliente dueño del trabajo, el profesional asignado o un administrador pueden leer el pago. Tokens, URL de Webpay y datos de alta de invitado no se exponen al cliente (columnas acotadas o solo service_role en la práctica de las Edge Functions). La creación de la intención de pago es por RPC.",
    "paises": "Lectura pública del catálogo. Hoy solo CL.",
    "perfiles": "El usuario lee su ficha y, con límites, fichas públicas (nombre y foto) de otros; no ve correo ajeno por esta vía. La escritura de campos sensibles (rol, estado_cuenta, reputacion_cliente, calificaciones_cliente) está protegida por trigger. El contacto completo solo se entrega con perfil_contacto_si_trabajo_activo.",
    "pines_inicio_trabajo": "SELECT para el cliente dueño del trabajo o un administrador (obtener_pin_inicio). El profesional no lee el PIN: lo valida por RPC. La inserción la hace el trigger trabajos_crear_pin_inicio.",
    "portafolio_trabajador": "El profesional gestiona su portafolio; hay lectura de catálogo de los ítems visibles.",
    "propuestas_cotizacion": "El cliente del trabajo, el profesional autor o un administrador leen la cotización. El monto no lo cambia el cliente (trigger).",
    "ranking_aprendizaje": "Lectura de administración. La escritura la hace el aprendizaje de pesos.",
    "ranking_config": "La lectura de la fila default está permitida a autenticados (para el listado). Solo un administrador la actualiza por RPC.",
    "regiones": "Lectura pública del catálogo geográfico.",
    "registros_error_app": "El cliente informa sus propios errores; un administrador puede revisarlos.",
    "reportes": "El reportante ve los suyos; un administrador gestiona la cola.",
    "reprogramaciones_trabajo": "SELECT para las partes del trabajo. El alta, la respuesta y el retiro se hacen solo por RPC (CU-33).",
    "senales_resena": "Cola de reseñas dudosas: la ve y resuelve un administrador.",
    "servicios": "Lectura pública del catálogo de oficios. La escritura es de administración.",
    "suscripciones": "El usuario ve solo su plan; crear o cambiar una suscripción es de administración o del backend (antes de la auditoría 2026-11-16 un usuario podía activarse un plan premium).",
    "tickets_soporte": "Las partes del trabajo o un administrador ven el ticket.",
    "trabajador_horarios": "SELECT y escritura solo para el dueño de la ficha (o un administrador). El cliente no lee esta tabla: usa horarios_libres_profesional.",
    "trabajador_precios": "El dueño y el catálogo (según política de precios) leen los montos ya publicados; la escritura es del dueño o de un trigger que parte el JSON.",
    "trabajador_servicios": "Oficios declarados: lectura de catálogo y escritura del dueño.",
    "trabajador_servicios_extra": "Servicios extra del profesional; misma idea que los precios.",
    "trabajadores": "El listado público solo muestra fichas disponibles con precios configurados. El dueño, un administrador o el cliente con un trabajo conjunto también pueden leer la ficha. El UPDATE es del dueño o de un administrador; campos como verificación, score y pausa están protegidos por trigger.",
    "trabajos": "SELECT y UPDATE para el cliente, el profesional asignado o un administrador. El INSERT lo hace el cliente (o un admin) con reglas: sin cotización preseleccionada y con estado de pago inicial pendiente o ninguno. Varios triggers cuidan el PIN, la evidencia, la fecha (solo RPC) y la disponibilidad.",
    "ubicacion_en_vivo": "El cliente del trabajo o un administrador leen la posición. El profesional la publica por RPC publicar_ubicacion_trabajo. Un trigger borra el GPS al cerrar el trabajo.",
    "verificacion_eventos": "El profesional ve su propio historial; un administrador ve todos. La escritura la hace el trigger al cambiar el estado de verificación.",
}

FUNC_PURPOSE = {
    "_evaluar_resena_trigger": "Disparador que encola la evaluación automática de una reseña nueva.",
    "_hora_santiago": "Convierte un timestamptz a la hora oficial de Chile (America/Santiago), con horario de verano.",
    "_normalizar_pesos_ranking": "Normaliza los pesos del ranking para que sumen 1.",
    "_notificar_reprogramacion": "Crea la notificación de una propuesta, respuesta o retiro de reagendamiento.",
    "_ranking_cfg": "Lee la fila default de ranking_config.",
    "_registrar_evento_ranking": "Inserta un evento en eventos_ranking.",
    "abrir_disputa": "El cliente o el profesional abre una disputa sobre un trabajo activo.",
    "acuerdo_pendiente": "Devuelve el acuerdo aún pendiente de un trabajo, si existe.",
    "admin_actualizar_estado_disputa": "Un administrador cambia el estado o la resolución de una disputa.",
    "admin_metricas_resumen": "Métricas del panel ejecutivo (solo administrador).",
    "aplicar_cierre_disputa": "Aplica la decisión de cierre de una disputa (uso interno / servicio).",
    "aprender_pesos_ranking": "Ajusta los pesos del ranking a partir de las señales (interno).",
    "aprender_pesos_ranking_admin": "Un administrador dispara el aprendizaje de pesos.",
    "asegurar_pin_inicio": "Crea el PIN de un trabajo si todavía no existe (interno).",
    "asignar_trabajador_trabajo": "Acepta un trabajo abierto. El destino tiene que tener rol trabajador. Un cliente no puede autoasignarse.",
    "base_publica_profesional": "Ficha pública de un profesional para el catálogo (sin datos sensibles). Disponible también para anon.",
    "borrar_gps_si_trabajo_cerrado": "Trigger: borra ubicacion_en_vivo cuando el trabajo deja de estar activo.",
    "calificar_cliente": "El profesional califica al cliente al terminar el trabajo.",
    "categorias_con_disponibles": "Categorías del catálogo que hoy tienen profesionales disponibles. También para anon.",
    "cerrar_trabajo_conforme": "El cliente cierra el trabajo conforme y habilita la liberación del pago retenido.",
    "clasificar_disputa": "Clasificación automática de una disputa (soporte automático, interno).",
    "comentar_disputa": "Una de las partes agrega un comentario al hilo de la disputa.",
    "confirmar_trabajo_tras_captura": "Tras capturar el pago (Webpay/Oneclick), confirma el trabajo. Lo llama el backend.",
    "consola_disputas_abiertas": "Cola de disputas para la consola de escritorio (administrador, soporte o qa). qa no ve la evidencia del domicilio.",
    "copiar_estado_pago_trabajo": "Trigger: copia el estado del pago principal a trabajos.estado_pago.",
    "crear_intencion_pago": "Crea la intención de pago (Webpay) del trabajo, con el monto que fija el servidor.",
    "crear_intencion_pago_orden_cambio": "Crea la intención de pago de una orden de cambio.",
    "crear_intencion_pago_servicio": "Variante de servicio (Edge Function / service_role) para crear la intención de pago.",
    "disputa_esta_activa": "Indica si el estado de una disputa se considera activo.",
    "enviar_verificacion_profesional": "El profesional envía o reenvía su solicitud de verificación.",
    "es_parte_trabajo": "True si el usuario autenticado es el cliente o el profesional del trabajo.",
    "es_rol_trabajador": "True si el perfil indicado tiene rol de profesional.",
    "evaluar_resena": "Evalúa una reseña y genera señales si parece dudosa (interno).",
    "evidencia_disputa": "Devuelve la evidencia del trabajo en disputa. Administrador o soporte; qa no la ve.",
    "expirar_pagos_abandonados": "Marca o limpia pagos abandonados (tarea de servicio / cron).",
    "explotar_oferta_trabajador": "Parte los JSON de oferta a las tablas 4NF (trigger).",
    "fichas_sensibles_admin": "Lectura de fichas con datos sensibles, solo administrador.",
    "fijar_correo_codigo": "Trigger de apoyo para códigos de restablecimiento.",
    "fijar_geo_trabajador": "Normaliza la geografía (comuna, región, base) de la ficha del profesional.",
    "fijar_liquidacion_desde_pago": "Trigger: crea o actualiza la liquidación cuando el pago queda liberado.",
    "fijar_prioridad_trabajador": "Un administrador ajusta prioridad_manual (−50 a 50).",
    "fijar_ticket_desde_trabajo": "Trigger: abre o actualiza el ticket de soporte asociado.",
    "fijar_verificacion_profesional": "Un administrador cambia el estado de verificación y deja nota.",
    "fotos_trabajo_exigir_webp": "Trigger: valida el formato de la evidencia.",
    "guardar_config_ranking": "Un administrador guarda los pesos y umbrales de ranking_config.",
    "guardar_horarios_propios": "El profesional guarda su plantilla semanal (reemplazo atómico).",
    "handle_new_user": "Trigger de auth: crea el perfil public al registrarse un usuario.",
    "horarios_disponibles_propios": "El profesional lee su propia plantilla semanal.",
    "horarios_libres_profesional": "Huecos libres de un profesional en los próximos n días (también anon). No expone la tabla trabajador_horarios.",
    "intentar_pin_inicio": "El profesional prueba el PIN del cliente. Tras 5 fallos, bloquea 15 minutos.",
    "is_admin": "True si el usuario autenticado tiene rol admin o administrador.",
    "km_entre_puntos": "Distancia en kilómetros entre dos coordenadas (uso interno de recargo).",
    "liberar_escrow": "Libera el pago retenido al profesional (backend, service_role).",
    "liberar_escrow_manual": "Liberación manual de un pago retenido, con referencia y notas de un operador.",
    "liberar_trabajo_sistema": "El sistema libera o cierra un trabajo (tarea interna).",
    "limpiar_alta_trabajo": "Limpia los datos de alta de invitado ya consumidos o vencidos (servicio).",
    "limpiar_invitados_sin_pago": "Borra cuentas de invitado sin cobro retenido, liberado ni autorizado, pasadas 24 h (service_role).",
    "listar_cuentas_demo_acceso": "Lista las cuentas demo permitidas (servicio / modo demo cerrado).",
    "listar_profesionales_catalogo": "Listado paginado del marketplace (también anon): cercanía, luego nota, luego precio.",
    "listar_senales_resena": "Cola de señales de reseña para un administrador.",
    "listar_trabajos_marketplace": "Trabajos abiertos que un profesional puede tomar.",
    "marcar_orden_cambio_pagada": "Asocia el pago a la orden de cambio cuando Webpay confirma el cobro.",
    "marcar_pago_liberado": "Marca un pago como liberado (operación de backend / admin).",
    "marcar_reembolso_automatico": "Registra un reembolso automático pedido a Transbank.",
    "mensajes_bloquear_contacto": "Trigger: rechaza mensajes que parecen contener teléfono o correo.",
    "mensajes_solo_marcar_leido": "Trigger: un destinatario solo puede marcar leído, no editar el cuerpo.",
    "metadatos_sin_pin": "Quita el PIN de un JSON de metadatos antes de guardarlo o devolverlo.",
    "mi_ficha_propia": "Devuelve la ficha del profesional autenticado, incluyendo campos no públicos.",
    "minuto_utc": "Normaliza una fecha-hora en texto al minuto UTC; se usa en el índice único de agenda.",
    "monto_esperado_trabajo": "Calcula el monto que el servidor espera para el trabajo (no lo fija el cliente).",
    "normalizar_bloques_horario": "Normaliza el JSON de bloques horarios antes de guardarlo.",
    "obtener_config_ranking": "Lee la configuración actual del ranking.",
    "obtener_pin_inicio": "El cliente (o un administrador) obtiene el PIN para mostrárselo al profesional.",
    "obtener_trabajo_sin_direccion": "Detalle de un trabajo sin exponer la dirección al que no corresponde.",
    "perfil_contacto_si_trabajo_activo": "Entrega datos de contacto de un perfil solo si hay un trabajo activo conjunto.",
    "perfiles_publicos_por_ids": "Nombre y foto públicos de una lista de perfiles.",
    "perfiles_rol_inicial_seguro": "Trigger: impide que un alta o un update se autoasigne rol administrador, soporte o qa.",
    "profesional_tiene_trabajo_activo": "True si el profesional tiene un trabajo que aún no termina.",
    "profesionales_ocupados": "Indica, de una lista de profesionales, cuáles están ocupados ahora.",
    "proponer_acuerdo": "Una de las partes propone rehacer, aceptar o anular un trabajo.",
    "proponer_reprogramacion": "El cliente o el profesional propone una nueva fecha (CU-33). Queda una sola pendiente por trabajo.",
    "protect_profile_sensitive_fields": "Trigger: impide que el usuario se cambie rol o estado_cuenta.",
    "proteger_campos_trabajador": "Trigger: impide que el profesional altere score, verificación o pausa por su cuenta.",
    "proteger_campos_trabajo": "Trigger: impide cambios de estado o de pago que no vayan por RPC.",
    "proteger_monto_cotizacion": "Trigger: el monto de la cotización no lo cambia el cliente.",
    "proteger_verificacion_profesional": "Trigger: el estado de verificación solo lo cambia un administrador o la RPC.",
    "publicar_ubicacion_trabajo": "El profesional publica su GPS durante un trabajo activo.",
    "quitar_dispositivo_push": "El usuario elimina un token de notificaciones push.",
    "recargo_traslado_clp": "Calcula el recargo de traslado según el radio urbano y la tarifa fuera de radio.",
    "rechazar_trabajo_pendiente": "Cancela un trabajo pendiente. Solo un administrador o el profesional ya asignado.",
    "reclamar_cobro_oneclick": "Inicia o registra una autorización Oneclick (backend).",
    "reconcile_secret_valido": "Valida el secreto de la reconciliación Webpay (vault, service_role).",
    "reembolsar_escrow": "Pide la devolución del pago retenido (backend).",
    "refrescar_calificacion_trabajador": "Trigger: recalcula trabajadores.calificacion al cambiar una reseña.",
    "refrescar_ranking_ficha": "Recalcula el score de una ficha (trigger).",
    "refrescar_ranking_por_impulso": "Recalcula el score cuando cambia un impulso.",
    "refrescar_ranking_todos": "Recalcula el ranking de todos (interno / cron).",
    "refrescar_ranking_todos_admin": "Un administrador dispara el recálculo global del ranking.",
    "refrescar_ranking_trabajador": "Recalcula el ranking de un profesional concreto.",
    "registrar_dispositivo_push": "Registra o actualiza el token push del dispositivo del usuario.",
    "registrar_disputa_ranking": "Trigger: registra en el ranking el efecto de una disputa.",
    "registrar_evento_verificacion": "Trigger: inserta una fila en verificacion_eventos.",
    "registrar_resultado_trabajo": "Trigger: actualiza completados, rechazos u otras señales al terminar un trabajo.",
    "registrar_transferencia_profesional": "Un administrador confirma la transferencia de una liquidación (estado_transferencia).",
    "resolver_senal_resena": "Un administrador resuelve una señal de reseña dudosa.",
    "resolver_soporte_automatico": "Intenta resolver una disputa con las reglas automáticas (interno).",
    "responder_acuerdo": "La contraparte acepta o rechaza un acuerdo pendiente.",
    "responder_reprogramacion": "La contraparte acepta o rechaza la nueva fecha (CU-33). Si acepta, actualiza trabajos.fecha_programada.",
    "resumen_calificacion_clientes": "Promedio y conteo de reputación de una lista de clientes.",
    "retirar_reprogramacion": "Quien propuso el cambio de fecha retira la propuesta pendiente (CU-33).",
    "rls_auto_enable": "Utilidad interna para asegurar RLS en tablas nuevas.",
    "rol_consola": "Devuelve administrador, soporte o qa si el usuario autenticado tiene un rol de la consola de escritorio; si no, null.",
    "seleccionar_cotizacion": "El cliente elige una cotización y queda asociada al trabajo.",
    "simular_transicion_pago": "LEGACY — no usar desde clientes. Las transiciones del PSP van por las Edge Functions webpay-commit y liberar_escrow.",
    "sincronizar_estado_pago_trabajo": "Fuerza la copia del estado del pago principal al trabajo.",
    "slug_geo": "Normaliza un texto a slug geográfico (comuna/región). También anon.",
    "soporte_comentar_disputa": "Un administrador o soporte deja una nota visible para las partes en el hilo de la disputa. qa no puede.",
    "soporte_numero": "Lee un número de configuración de soporte automático.",
    "texto_a_timestamptz": "Interpreta un texto de fecha/hora como timestamptz (agenda y CU-33).",
    "texto_tiene_contacto": "Detecta si un texto parece incluir teléfono o correo. También anon (validación de formularios).",
    "trabajador_horarios_desde_alta": "Trigger de apoyo al crear la plantilla semanal en el alta.",
    "trabajador_horarios_normalizar": "Trigger: normaliza día y horas al guardar un horario.",
    "trabajador_reservable": "True si el profesional puede tomarse en la fecha consultada (horario y ocupación).",
    "trabajadores_marcar_pausa_por_trabajo": "Trigger: enciende o apaga pausa_por_trabajo y disponible según los trabajos activos.",
    "trabajo_admite_disputa": "True si el estado del trabajo permite abrir una disputa.",
    "trabajo_tiene_evidencia": "True si el trabajo ya tiene evidencia cargada.",
    "trabajos_bloquear_en_curso_directo": "Trigger: no se puede pasar a en_curso sin el flujo del PIN.",
    "trabajos_contar_completados": "Trigger: mantiene trabajadores.trabajos_completados.",
    "trabajos_crear_pin_inicio": "Trigger: genera el PIN al quedar el trabajo en un estado que lo requiere.",
    "trabajos_exigir_evidencia": "Trigger: exige evidencia antes de ciertos cierres.",
    "trabajos_fecha_solo_por_rpc": "Trigger CU-33: la fecha programada solo cambia por las RPC de reagendamiento.",
    "trabajos_horario_unico": "Apoyo al índice único de un trabajo activo por profesional y minuto.",
    "trabajos_restablecer_disponibilidad": "Trigger: devuelve la disponibilidad del profesional al terminar o cancelar.",
    "trabajos_vencer_reprogramaciones": "Marca como vencidas las propuestas de reagendamiento que ya no aplican (interno / al cambiar el trabajo).",
    "transicion_trabajo_permitida": "Valida si un cambio de estado es legal según el estado actual y la modalidad.",
    "transicionar_trabajo": "Cambia el estado del trabajo. Iniciar (aceptado o en_camino → en_curso) exige el PIN del cliente al profesional asignado. El administrador no lo exige. Tras 5 PIN malos, 15 minutos de bloqueo.",
    "transiciones_trabajo_posibles": "Lista los estados siguientes permitidos desde el estado y la modalidad actuales.",
    "ver_reputacion_cliente": "Devuelve la reputación pública de un cliente (promedio y conteo).",
    "vincular_trabajador_cotizacion": "Asocia un profesional a un trabajo que está en cotización.",
    "vincular_trabajador_solicitud": "Asocia un profesional a una solicitud de trabajo abierta.",
}


def _seccion_er():
    """Sección 2b/3b «Modelo entidad-relación» (figuras de Fase 2/modelo_entidad_relacion)."""
    import importlib.util

    spec = importlib.util.spec_from_file_location("_seccion_modelo_er", DOCS / "_seccion_modelo_er.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def load_schema():
    return json.loads(SNAPSHOT.read_text(encoding="utf-8"))


def fmt_type(col):
    dt = col["data_type"]
    udt = col["udt_name"]
    if dt == "numeric" and col.get("numeric_precision") is not None:
        return f"numeric({col['numeric_precision']},{col['numeric_scale']})"
    if dt in ("character varying", "varchar") and col.get("character_maximum_length"):
        return f"varchar({col['character_maximum_length']})"
    if dt == "character" and col.get("character_maximum_length"):
        return f"char({col['character_maximum_length']})"
    if dt == "timestamp with time zone":
        return "timestamptz"
    if dt == "timestamp without time zone":
        return "timestamp"
    if dt == "time without time zone":
        return "time"
    if dt == "time with time zone":
        return "timetz"
    if dt == "double precision":
        return "double precision"
    if dt == "ARRAY":
        # udt _text -> text[]
        base = udt[1:] if udt.startswith("_") else udt
        return f"{base}[]"
    if dt == "USER-DEFINED":
        return udt
    if dt == "integer":
        return "integer"
    if dt == "smallint":
        return "smallint"
    if dt == "bigint":
        return "bigint"
    if dt == "boolean":
        return "boolean"
    if dt in ("text", "uuid", "jsonb", "json", "date", "bytea", "inet", "interval"):
        return dt
    return dt


def clean_default(raw):
    if raw is None:
        return None
    s = str(raw).strip()
    # Solo se quita un cast final de un literal. No se toca to_char(...), now(), etc.
    if re.match(r"^'(?:''|[^'])*'::[a-zA-Z_][\w\s]*$", s):
        return s.rsplit("::", 1)[0]
    if re.match(r"^-?\d+(?:\.\d+)?::[a-zA-Z_][\w\s]*$", s):
        return s.rsplit("::", 1)[0]
    return s


def pg_cols(raw):
    if raw is None:
        return []
    if isinstance(raw, list):
        return [c for c in raw if c]
    s = str(raw).strip()
    if s.startswith("{") and s.endswith("}"):
        s = s[1:-1]
    if not s:
        return []
    return [p.strip() for p in s.split(",") if p.strip() and p.strip() != "NULL"]


def build_model(schema):
    tables = {}
    for t in schema["tables"]:
        tables[t["name"]] = {
            "name": t["name"],
            "kind": t["kind"],
            "rls_enabled": t["rls_enabled"],
            "rls_forced": t["rls_forced"],
            "db_comment": t.get("comment") or "",
            "note": TABLE_NOTES.get(t["name"]) or t.get("comment") or "",
            "columns": [],
            "pk": [],
            "fks": [],
            "uniques": [],
            "checks": [],
            "indexes": [],
            "policies": [],
        }
    cols_by = defaultdict(list)
    for c in schema["columns"]:
        cols_by[c["table_name"]].append(c)
    for name, cols in cols_by.items():
        if name not in tables:
            continue
        for c in sorted(cols, key=lambda x: x["ordinal_position"]):
            note = c.get("comment") or ""
            generated = c.get("is_generated") in ("ALWAYS", "BY DEFAULT", "YES")
            tables[name]["columns"].append({
                "name": c["column_name"],
                "type": fmt_type(c),
                "nullable": c["is_nullable"] == "YES",
                "default": clean_default(c.get("column_default")),
                "identity": c.get("is_identity") == "YES",
                "generated": generated,
                "generation": c.get("generation_expression"),
                "db_comment": note,
                "note": note,
            })

    for cons in schema["constraints"]:
        tb = tables.get(cons["table_name"])
        if not tb:
            continue
        typ = cons["constraint_type"]
        definition = cons["definition"]
        cols = pg_cols(cons.get("columns"))
        if typ == "PRIMARY KEY":
            tb["pk"] = cols or tb["pk"]
            tb["pk_def"] = definition
        elif typ == "FOREIGN KEY":
            # parse REFERENCES
            m = re.search(
                r"FOREIGN KEY\s*\(([^)]+)\)\s*REFERENCES\s+(?:(\w+)\.)?(\w+)\s*\(([^)]+)\)(?:\s+ON DELETE\s+([A-Z ]+))?",
                definition,
                re.I,
            )
            if m:
                src = [x.strip() for x in m.group(1).split(",")]
                fsch = m.group(2) or cons.get("foreign_schema") or "public"
                ft = m.group(3)
                fc = [x.strip() for x in m.group(4).split(",")]
                ondel = (m.group(5) or "").strip() or None
            else:
                src = cols
                fsch = cons.get("foreign_schema") or "public"
                ft = cons.get("foreign_table")
                fc = [cons.get("foreign_column")] if cons.get("foreign_column") else []
                ondel = None
            tb["fks"].append({
                "columns": src,
                "schema": fsch,
                "table": ft,
                "ref_columns": fc,
                "on_delete": ondel,
                "definition": definition,
            })
        elif typ == "UNIQUE":
            tb["uniques"].append({"columns": cols, "definition": definition, "name": cons["constraint_name"]})
        elif typ == "CHECK":
            expr = definition
            if expr.upper().startswith("CHECK"):
                expr = expr[5:].strip()
                if expr.startswith("(") and expr.endswith(")"):
                    # keep full expression, just strip CHECK
                    pass
            tb["checks"].append({"name": cons["constraint_name"], "definition": definition, "expr": expr})

    for idx in schema["indexes"]:
        tb = tables.get(idx["table_name"])
        if not tb:
            continue
        if idx.get("is_primary"):
            continue
        tb["indexes"].append({
            "name": idx["index_name"],
            "definition": idx["definition"],
            "unique": bool(idx["is_unique"]),
            "columns": pg_cols(idx.get("columns")),
        })

    for p in schema["policies"]:
        tb = tables.get(p["tablename"])
        if not tb:
            continue
        roles = p.get("roles") or []
        if isinstance(roles, str):
            roles = [roles.strip("{}")]
            if len(roles) == 1 and "," in roles[0]:
                roles = [r.strip() for r in roles[0].split(",")]
        tb["policies"].append({
            "name": p["policyname"],
            "cmd": p["cmd"],
            "roles": roles,
            "permissive": p.get("permissive"),
            "using": p.get("qual"),
            "check": p.get("with_check"),
        })

    # mark pk/fk on columns
    for tb in tables.values():
        pkset = set(tb["pk"])
        fkmap = {}
        for fk in tb["fks"]:
            for a, b in zip(fk["columns"], fk["ref_columns"]):
                dest = f"{fk['table']}.{b}"
                if fk["schema"] and fk["schema"] != "public":
                    dest = f"{fk['schema']}.{dest}"
                fkmap[a] = dest
        for c in tb["columns"]:
            flags = []
            if c["name"] in pkset:
                flags.append("pk")
            if c["name"] in fkmap:
                flags.append(f"fk → {fkmap[c['name']]}")
            if not c["nullable"]:
                flags.append("not null")
            if c["generated"]:
                flags.append("generated always")
                if c["generation"]:
                    c["note"] = (c["note"] + " " if c["note"] else "") + f"GENERATED ALWAYS AS {c['generation']}"
            if c["identity"]:
                flags.append("identity")
            if c["default"] is not None and not c["generated"] and not c["identity"]:
                flags.append(f"default: {c['default']}")
            # unique if single-column unique
            for u in tb["uniques"] + [i for i in tb["indexes"] if i["unique"]]:
                cols = u.get("columns") or []
                if cols == [c["name"]]:
                    flags.append("unique")
                    break
            c["flags"] = ", ".join(flags)
            c["fk_dest"] = fkmap.get(c["name"])

    functions = schema["functions"]
    return tables, functions, schema


def short_note(note, limit=180):
    text = " ".join((note or "").split())
    if len(text) <= limit:
        return text
    return text[:limit].rsplit(" ", 1)[0] + "…"


def group_of(name):
    for g, members in GROUPS.items():
        if name in members:
            return g
    return "otros"


def ordered_tables(tables):
    seen = set()
    out = []
    for members in GROUPS.values():
        for n in members:
            if n in tables:
                out.append(tables[n])
                seen.add(n)
    for n in sorted(tables):
        if n not in seen:
            out.append(tables[n])
    return out


def changelog(tables):
    # Previous published dictionary (v2.3, 2026-11-08, 43 tables, hasta 20261108000005)
    old_path = None  # computed from current files before overwrite; caller may pass
    added = [
        "acuerdos_trabajo",
        "bloqueos_pin_inicio",
        "cuentas_bancarias",
        "dispositivos_push",
        "disputa_mensajes",
        "intentos_pin_inicio",
        "pines_inicio_trabajo",
        "reprogramaciones_trabajo",
        "verificacion_eventos",
    ]
    removed = []
    modified = [
        ("calificaciones", "Se agregan `direccion` (cliente_a_trabajador | trabajador_a_cliente) e `id_calificado`. Unicidad por (id_trabajo, direccion)."),
        ("calificaciones_cliente", "`puntaje` pasa de integer a smallint."),
        ("disputas", "Se agregan `decision_sugerida`, `motivo_regla`, `origen` y `vence_en` (soporte automático)."),
        ("liquidaciones", "Se agrega `estado_transferencia` para el seguimiento de la transferencia al profesional."),
        ("trabajador_horarios", "Deja de ser una fila 1:1 con tres columnas. Ahora es una plantilla semanal: `id`, `dia_semana`, `hora_inicio`, `hora_fin`, `activo`, `creado_en`, única por (id_usuario, dia_semana)."),
        ("trabajador_precios", "`id_usuario` pasa de text a uuid con FK a trabajadores (auditoría 2026-11-16)."),
        ("trabajador_servicios_extra", "Igual que precios: `id_usuario` pasa a uuid con FK."),
        ("metodos_pago_oneclick", "`id_usuario` pasa de text a uuid con FK a perfiles (auditoría 2026-11-16)."),
        ("trabajadores", "Se agregan `usa_horario` y `pausa_por_trabajo`. `es_elite` se documenta como columna GENERATED ALWAYS."),
        ("perfiles", "Defaults en español (`'usuario'`, `'activo'`), CHECK de rol y estado, FK a auth.users y reputación protegida contra edición del propio usuario (auditoría 2026-11-16)."),
        ("pagos", "Las columnas de alta de invitado (`alta_nonce_hash`, `alta_jti`, `alta_consumido_en`) ya estaban en el v2.3 (26 columnas). Se aclara su papel y el índice único de `alta_jti`."),
        ("trabajos", "Sigue con 20 columnas. Cambia el comportamiento: la fecha programada solo se altera por las RPC de CU-33 y hay un índice único de agenda por profesional y minuto."),
    ]
    return added, removed, modified


def nf_paragraph(tb):
    fn, why, den = forma_normal(tb["name"])
    txt = f"**Forma normal: {fn}.** {why}"
    if den:
        txt += f" Dato repetido a propósito: {den}"
    return txt


def rls_text(tb):
    bits = []
    if tb["rls_enabled"]:
        bits.append("RLS activo" + (" y forzado (FORCE ROW LEVEL SECURITY)" if tb["rls_forced"] else "") + ".")
    else:
        bits.append("RLS no está activo.")
    summary = RLS_SUMMARY.get(tb["name"])
    if summary:
        bits.append(summary)
    if not tb["policies"] and tb["rls_enabled"]:
        if not summary or "sin políticas" not in summary:
            bits.append("No hay políticas: solo acceden service_role o funciones SECURITY DEFINER.")
    else:
        names = ", ".join(f"{p['cmd']} «{p['name']}»" for p in tb["policies"])
        if names:
            bits.append(f"Políticas: {names}.")
    return " ".join(bits)


def index_text(tb):
    parts = []
    for u in tb["uniques"]:
        parts.append(u["definition"])
    for i in tb["indexes"]:
        # skip unique indexes that already appear as UNIQUE constraints with same def
        defn = i["definition"]
        if any(u["definition"] in defn or defn.endswith(u["definition"]) for u in tb["uniques"]):
            # still include partial unique indexes which may only appear as indexes
            if "WHERE" in defn.upper() or i["unique"]:
                if defn not in parts:
                    parts.append(defn)
            continue
        parts.append(defn)
    # dedup
    seen = set()
    out = []
    for p in parts:
        if p not in seen:
            seen.add(p)
            out.append(p)
    return out


def md_escape(s):
    return (s or "").replace("|", "\\|").replace("\n", " ")


def project_note(schema):
    return (
        f"Modelo lógico {MODEL_VERSION} · {len(schema['tables'])} tablas public · "
        f"{GENERATED_AT} ({TZ_LABEL}) · alineado a la BD viva {PROJECT_ID} "
        f"hasta la migración {schema['latest_migration_version']} "
        f"({schema['latest_migration_name']}). "
        f"Archivo de migración en el repo: {schema['latest_migration_file']}. "
        "Diccionario generado desde information_schema y pg_catalog (solo lectura). "
        "No hay tipos ENUM ni vistas en public: los estados se restringen con CHECK. "
        "No ejecutar el SQL de consulta contra producción."
    )

def write_md(schema, tables, functions, ordered):
    note = project_note(schema)
    added, removed, modified = changelog(tables)
    n_fk = sum(len(t["fks"]) for t in tables.values())
    n_cols = sum(len(t["columns"]) for t in tables.values())
    lines = []
    a = lines.append
    a("# Diccionario de base de datos — My Works App")
    a("")
    a(f"> Generado por `docs/_gen_diccionario_desde_schema.py` el {GENERATED_AT} ({TZ_LABEL}) desde el esquema real de Supabase `{PROJECT_ID}`. No editar a mano: actualizar el snapshot o volver a introspectar y regenerar.")
    a("")
    a("| Campo | Valor |")
    a("|-------|-------|")
    a("| Proyecto | My Works App |")
    a("| Motor | PostgreSQL (Supabase), esquema `public` |")
    a("| Convención | Nombres en español, `snake_case` |")
    a(f"| Modelo fuente | {note} |")
    a(f"| Tablas en el esquema | {len(tables)} |")
    a(f"| Columnas | {n_cols} |")
    a(f"| Claves foráneas físicas | {n_fk} |")
    a(f"| Políticas RLS | {sum(len(t['policies']) for t in tables.values())} |")
    a(f"| Funciones public | {len(functions)} |")
    a(f"| Última migración aplicada | `{schema['latest_migration_version']}` — {schema['latest_migration_name']} |")
    a(f"| Archivo de migración (repo) | `{schema['latest_migration_file']}` |")
    a(f"| Fecha de generación | {GENERATED_AT} ({TZ_LABEL}) |")
    a("")
    a("`perfiles.id` coincide con `auth.users.id` (Auth de Supabase, fuera de `public`). No hay tipos ENUM ni vistas en `public`.")
    a("")
    a("## 1. Cambios respecto del diccionario v2.3 (2026-11-08, 43 tablas, hasta 20261108000005)")
    a("")
    a(f"**Tablas agregadas ({len(added)}):** " + ", ".join(f"`{n}`" for n in added) + ".")
    a("")
    if removed:
        a("**Tablas eliminadas:** " + ", ".join(f"`{n}`" for n in removed) + ".")
    else:
        a("**Tablas eliminadas:** ninguna.")
    a("")
    a("**Tablas modificadas:**")
    a("")
    for name, desc in modified:
        a(f"- `{name}`: {desc}")
    a("")
    a("Además se documentan, por primera vez en este diccionario, las políticas RLS (resumen en lenguaje natural), los CHECK, los índices únicos parciales y las funciones RPC / SECURITY DEFINER relevantes (reagendamiento CU-33, PIN de inicio, roles soporte/qa, alta de invitado, escrow Webpay).")
    a("")
    a("## 2. Índice de tablas por grupo")
    a("")
    a("| # | Grupo | Tabla | Columnas | RLS | Descripción |")
    a("|---|-------|-------|----------|-----|-------------|")
    for i, tb in enumerate(ordered, 1):
        rls = "sí" if tb["rls_enabled"] else "no"
        if tb["rls_enabled"] and not tb["policies"]:
            rls = "sí (sin políticas)"
        desc = md_escape(short_note(tb["note"]))
        a(f"| {i} | {group_of(tb['name'])} | `{tb['name']}` | {len(tb['columns'])} | {rls} | {desc} |")
    a("")
    lines.extend(_seccion_er().md_lineas())
    a("## 3. Columnas por tabla")
    a("")
    for i, tb in enumerate(ordered, 1):
        a(f"### 3.{i} {tb['name']}")
        a("")
        if tb["note"]:
            a(tb["note"])
            a("")
        a("| Columna | Tipo | Restricciones | Nota |")
        a("|---------|------|---------------|------|")
        for c in tb["columns"]:
            a(f"| `{c['name']}` | `{c['type']}` | {md_escape(c['flags'])} | {md_escape(c['note'])} |")
        a("")
        if tb["checks"]:
            a("CHECK:")
            a("")
            for ch in tb["checks"]:
                a(f"- `{ch['name']}`: `{ch['definition']}`")
            a("")
        idxs = index_text(tb)
        if idxs:
            a("Índices:")
            a("")
            for d in idxs:
                a(f"- `{d}`")
            a("")
        a("**RLS.** " + rls_text(tb))
        a("")
        a(nf_paragraph(tb))
        a("")
        rel = relaciones_en_palabras(tb)
        if rel:
            a("**Relaciones en palabras.** " + "; ".join(rel) + ".")
            a("")

    a("## 4. Relaciones (claves foráneas físicas)")
    a("")
    a("Se listan las FK declaradas en Postgres. La auditoría 2026-11-16 agregó las que faltaban (todas con 0 huérfanos verificados antes de validarlas). Las únicas referencias sin FK física son polimórficas (`notificaciones.id_relacionado`) o libros contables con id en texto (`liquidaciones.id_trabajador`).")
    a("")
    a("| Tabla | Columnas | Referencia | ON DELETE |")
    a("|-------|----------|------------|-----------|")
    for tb in ordered:
        for fk in tb["fks"]:
            src = ", ".join(fk["columns"])
            dest_sch = "" if fk["schema"] == "public" else fk["schema"] + "."
            dest = dest_sch + fk["table"] + "(" + ", ".join(fk["ref_columns"]) + ")"
            a(f"| `{tb['name']}` | `{src}` | `{dest}` | {fk['on_delete'] or '—'} |")
    a("")
    a("## 4b. Normalización (auditoría 2026-11-16)")
    a("")
    a(NF_METODO)
    a("")
    a("| Tabla | Forma normal | Dato repetido a propósito y cómo se mantiene |")
    a("|-------|--------------|-----------------------------------------------|")
    for tb in ordered:
        fn, _, den = forma_normal(tb["name"])
        a(f"| `{tb['name']}` | {fn} | {md_escape(den or '—')} |")
    a("")
    a("Detalle del método, consultas de verificación y migraciones: `docs/pruebas/auditoria_base_datos.md`.")
    a("")
    a("## 5. Enums y vistas")
    a("")
    a("El esquema `public` no define tipos ENUM ni vistas (ni materializadas). Los estados y conjuntos cerrados (rol de una reprogramación, tipo de acuerdo, estado de verificación, etc.) se restringen con CHECK sobre columnas `text` o `boolean`.")
    a("")
    a("## 6. Funciones RPC y SECURITY DEFINER")
    a("")
    auth = [f for f in functions if f.get("auth_exec") or f.get("anon_exec")]
    svc = [f for f in functions if not f.get("auth_exec") and not f.get("anon_exec")]
    a(f"Hay {len(functions)} funciones (o procedimientos) en `public`. {sum(1 for f in functions if f['security']=='SECURITY DEFINER')} son SECURITY DEFINER. A continuación se documentan las que forman la API de cliente (GRANT a `anon` o `authenticated`) y, en un segundo listado, las de backend / disparadores (solo `service_role` o uso interno).")
    a("")
    a("### 6.1 API de cliente (`anon` / `authenticated`)")
    a("")
    a("| Función | Argumentos | Retorno | Seguridad | Quién ejecuta | Propósito |")
    a("|---------|------------|---------|-----------|---------------|-----------|")
    for f in sorted(auth, key=lambda x: x["name"]):
        who = []
        if f.get("anon_exec"):
            who.append("anon")
        if f.get("auth_exec"):
            who.append("authenticated")
        purpose = f.get("comment") or FUNC_PURPOSE.get(f["name"], "Función de apoyo de la aplicación.")
        a(f"| `{f['name']}` | {md_escape(f['args'] or '—')} | {md_escape(f['result'] or '—')} | {f['security']} | {', '.join(who)} | {md_escape(purpose)} |")
    a("")
    a("### 6.2 Backend, cron y disparadores (principalmente `service_role`)")
    a("")
    a("| Función | Argumentos | Retorno | Seguridad | Propósito |")
    a("|---------|------------|---------|-----------|-----------|")
    for f in sorted(svc, key=lambda x: x["name"]):
        purpose = f.get("comment") or FUNC_PURPOSE.get(f["name"], "Función interna, disparador o tarea de servicio.")
        a(f"| `{f['name']}` | {md_escape(f['args'] or '—')} | {md_escape(f['result'] or '—')} | {f['security']} | {md_escape(purpose)} |")
    a("")
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    return n_cols, n_fk


def write_anexo(schema, tables, ordered):
    lines = []
    a = lines.append
    a("# Anexo A. Diccionario de datos")
    a("")
    a(
        f"A continuación se describe cada una de las {len(ordered)} tablas del esquema public, "
        f"alineadas a la base viva de Supabase (`{PROJECT_ID}`) al {GENERATED_AT} ({TZ_LABEL}), "
        f"migración `{schema['latest_migration_version']}` ({schema['latest_migration_name']}). "
        "Los atributos se listan con su tipo de dato y su restricción. PK indica la clave primaria y FK la clave foránea. "
        "perfiles.id coincide con el identificador de autenticación de Supabase (auth.users.id). "
        "No hay tipos ENUM ni vistas en public; los conjuntos cerrados se restringen con CHECK."
    )
    a("")
    a(f"Fuente: elaboración propia a partir del esquema real (modelo entidad-relación {MODEL_VERSION}).")
    a("")
    lines.extend(_seccion_er().anexo_lineas())
    a(
        "Respecto del anexo v2.3 (43 tablas, 2026-11-08) se agregan nueve tablas: "
        "acuerdos_trabajo, disputa_mensajes, reprogramaciones_trabajo (CU-33), pines_inicio_trabajo, "
        "bloqueos_pin_inicio, intentos_pin_inicio, cuentas_bancarias, dispositivos_push y verificacion_eventos. "
        "También se documentan los roles de consola soporte y qa, el alta de invitado (columnas de pagos) y los cambios de calificación bidireccional, horarios semanales y soporte automático de disputas."
    )
    a("")
    n = 0
    grupo_actual = None
    for tb in ordered:
        g = group_of(tb["name"])
        if g != grupo_actual:
            grupo_actual = g
            a(f"## {GROUP_LABELS.get(g, g)}")
            a("")
        n += 1
        a(f"### Tabla A-{n}. {tb['name']}")
        a("")
        if tb["note"]:
            a(tb["note"])
            a("")
        a("| Atributo | Tipo de dato | Restricción |")
        a("|----------|--------------|-------------|")
        for c in tb["columns"]:
            restr = []
            if "pk" in c["flags"].split(", "):
                restr.append("PK")
            if c.get("fk_dest"):
                restr.append(f"FK → {c['fk_dest']}")
            restr.append("Opcional" if c["nullable"] else "Obligatorio")
            if c["generated"]:
                restr.append("GENERATED ALWAYS")
            if c["default"] is not None and not c["generated"]:
                restr.append(f"Default {c['default']}")
            extra = c["note"]
            cell = ", ".join(restr)
            if extra:
                cell = f"{cell}. {extra}"
            def esc(s):
                return s.replace("|", "\\|")
            a(f"| `{esc(c['name'])}` | {esc(c['type'])} | {esc(cell)} |")
        a("")
        if tb["checks"]:
            a("Restricciones CHECK: " + "; ".join(f"`{ch['name']}` {ch['definition']}" for ch in tb["checks"]) + ".")
            a("")
        a(rls_text(tb))
        a("")
        a(nf_paragraph(tb))
        a("")
        rel = relaciones_en_palabras(tb)
        if rel:
            a("Relaciones: " + "; ".join(rel) + ".")
            a("")
    a("## Funciones relevantes")
    a("")
    a(
        "La API de la aplicación no escribe en varias de estas tablas de forma directa: el reagendamiento (CU-33), "
        "el PIN de inicio, el escrow Webpay, el alta de invitado y la consola de soporte/qa se exponen como funciones "
        "SECURITY DEFINER. El detalle (nombre, argumentos y propósito) está en el diccionario "
        "`MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md`, sección 6."
    )
    a("")
    OUT_ANEXO.write_text("\n".join(lines), encoding="utf-8")


def write_dbml(schema, tables, ordered):
    lines = []
    a = lines.append
    note = project_note(schema).replace("'", "''")
    a("Project MyWorksApp {")
    a("  database_type: 'PostgreSQL'")
    a("  Note: '" + note + "'")
    a("}")
    a("")

    def qname(n):
        return n

    def esc_note(s):
        return (s or "").replace("\\", "").replace("'", "’")

    for tb in ordered:
        a(f"Table {tb['name']} {{")
        pkset = set(tb["pk"])
        for c in tb["columns"]:
            attrs = []
            if c["name"] in pkset and len(pkset) == 1:
                attrs.append("pk")
            if not c["nullable"]:
                attrs.append("not null")
            if c["generated"]:
                attrs.append("note: 'GENERATED ALWAYS AS " + esc_note(c["generation"] or "") + "'")
            elif c["default"] is not None:
                d = c["default"]
                if any(ch in d for ch in ",[]'\""):
                    d = '"' + d.replace("\\", "\\\\").replace('"', '\\"') + '"'
                attrs.append(f"default: {d}")
            if c["note"] and not c["generated"]:
                attrs.append(f"note: '{esc_note(c['note'])}'")
            attr = f" [{', '.join(attrs)}]" if attrs else ""
            a(f"  {c['name']} {c['type']}{attr}")
        if len(tb["pk"]) > 1:
            a("")
            a("  indexes {")
            a(f"    ({', '.join(tb['pk'])}) [pk]")
            a("  }")
        extra_idx = []
        for u in tb["uniques"]:
            if u["columns"] and set(u["columns"]) != set(tb["pk"]):
                extra_idx.append((u["columns"], True, u["definition"]))
        for i in tb["indexes"]:
            if i["unique"] and "WHERE" in i["definition"].upper():
                extra_idx.append((i["columns"], True, i["definition"]))
            elif i["unique"] and i["columns"] and set(i["columns"]) != set(tb["pk"]):
                # may already be in uniques
                if not any(x[0] == i["columns"] and x[1] for x in extra_idx):
                    extra_idx.append((i["columns"], True, i["definition"]))
        if extra_idx and not (len(tb["pk"]) > 1):
            a("")
            a("  indexes {")
            seen = set()
            for cols, uniq, defn in extra_idx:
                key = tuple(cols) + (defn,)
                if key in seen:
                    continue
                seen.add(key)
                flag = "unique"
                if "WHERE" in defn.upper():
                    m = re.search(r"WHERE\s+\((.*)\)\s*$", defn, re.I)
                    note = defn
                    a(f"    ({', '.join(cols) if cols else defn}) [unique, note: '{esc_note(note)}']")
                else:
                    a(f"    ({', '.join(cols)}) [unique]")
            a("  }")
        elif extra_idx and len(tb["pk"]) > 1:
            # indexes block already opened... actually we closed it. reopen if needed - skip, rare
            pass
        if tb["note"]:
            a("")
            a(f"  Note: '{esc_note(tb['note'])}'")
        a("}")
        a("")

    a("// ---------------------------------------------------------------------------")
    a("// Relaciones (solo FK físicas de la BD viva)")
    a("// ---------------------------------------------------------------------------")
    a("")
    for tb in ordered:
        for fk in tb["fks"]:
            # 1:1 if unique or pk on the src columns covering the fk
            one = False
            if set(fk["columns"]) == set(tb["pk"]) and len(fk["columns"]) == 1:
                one = True
            rel = "-" if one else ">"
            left = f"{tb['name']}.{fk['columns'][0]}" if len(fk["columns"]) == 1 else f"{tb['name']}.({', '.join(fk['columns'])})"
            dest_tbl = fk["table"] if fk["schema"] == "public" else f"{fk['schema']}.{fk['table']}"
            right = f"{dest_tbl}.{fk['ref_columns'][0]}" if len(fk["ref_columns"]) == 1 else f"{dest_tbl}.({', '.join(fk['ref_columns'])})"
            extra = ""
            if fk["on_delete"]:
                # SET NULL, CASCADE, RESTRICT, NO ACTION
                key = fk["on_delete"].lower().replace(" ", "_")
                extra = f" [delete: {key}]"
            a(f"Ref: {left} {rel} {right}{extra}")
    a("")
    a("// Grupos para el lienzo de dbdiagram.io")
    a("")
    for g, members in GROUPS.items():
        a(f"TableGroup {g} {{")
        for n in members:
            if n in tables:
                a(f"  {n}")
        a("}")
        a("")
    OUT_DBML.write_text("\n".join(lines), encoding="utf-8")

def sql_ident(n):
    return n


def write_sql(schema, tables, ordered):
    lines = []
    a = lines.append
    a("-- MyWorksApp — modelo entidad-relación (PostgreSQL)")
    a(f"-- Versión {MODEL_VERSION[1:]} · {len(tables)} tablas public · generado {GENERATED_AT} ({TZ_LABEL})")
    a("--")
    a(f"-- Documentación del esquema REAL de {PROJECT_ID}")
    a(f"-- hasta {schema['latest_migration_version']}_{schema['latest_migration_name']}.")
    a("-- Incluye tipos, nulos, defaults, PK, FK, UNIQUE, CHECK e índices.")
    a("-- No incluye RLS, triggers ni el cuerpo de las funciones (van en el diccionario).")
    a("-- No es un script de restauración completa. No ejecutar contra producción.")
    a("--")
    a("-- perfiles.id coincide con auth.users.id.")
    a("-- No hay ENUM ni vistas en public.")
    a("-- trabajador_precios.id_usuario y trabajador_servicios_extra.id_usuario son uuid")
    a("-- con FK a trabajadores.id_usuario (auditoría 2026-11-16).")
    a("")
    a("BEGIN;")
    a("")
    # create tables without FK first
    for tb in ordered:
        a(f"CREATE TABLE {tb['name']} (")
        col_sql = []
        for c in tb["columns"]:
            bits = [c["name"], c["type"]]
            if c["generated"] and c["generation"]:
                bits.append(f"GENERATED ALWAYS AS ({c['generation']}) STORED")
            else:
                if not c["nullable"]:
                    bits.append("NOT NULL")
                if c["identity"]:
                    bits.append("GENERATED BY DEFAULT AS IDENTITY")
                elif c["default"] is not None:
                    bits.append("DEFAULT " + c["default"])
            col_sql.append("  " + " ".join(bits))
        if tb["pk"]:
            col_sql.append(f"  PRIMARY KEY ({', '.join(tb['pk'])})")
        for ch in tb["checks"]:
            col_sql.append(f"  CONSTRAINT {ch['name']} {ch['definition']}")
        a(",\n".join(col_sql))
        a(");")
        a("")
        if tb["note"]:
            note = tb["note"].replace("'", "''")
            a(f"COMMENT ON TABLE {tb['name']} IS '{note}';")
        for c in tb["columns"]:
            if c["db_comment"]:
                note = c["db_comment"].replace("'", "''")
                a(f"COMMENT ON COLUMN {tb['name']}.{c['name']} IS '{note}';")
        if tb["note"] or any(c["db_comment"] for c in tb["columns"]):
            a("")
    # FKs and uniques and indexes after all tables exist
    a("-- Claves foráneas, únicos e índices")
    a("")
    for tb in ordered:
        for fk in tb["fks"]:
            dest = fk["table"] if fk["schema"] == "public" else f"{fk['schema']}.{fk['table']}"
            ondel = f" ON DELETE {fk['on_delete']}" if fk["on_delete"] else ""
            a(
                f"ALTER TABLE {tb['name']} ADD {fk['definition']};"
                if fk.get("definition") else
                f"ALTER TABLE {tb['name']} ADD FOREIGN KEY ({', '.join(fk['columns'])}) REFERENCES {dest} ({', '.join(fk['ref_columns'])}){ondel};"
            )
        for u in tb["uniques"]:
            a(f"ALTER TABLE {tb['name']} ADD CONSTRAINT {u['name']} {u['definition']};")
        for i in tb["indexes"]:
            # definition already contains CREATE ...
            defn = i["definition"]
            if not defn.rstrip().endswith(";"):
                defn = defn + ";"
            a(defn)
        if tb["fks"] or tb["uniques"] or tb["indexes"]:
            a("")
    a("COMMIT;")
    a("")
    OUT_SQL.write_text("\n".join(lines), encoding="utf-8")


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
            set_run_font(run, size=9)
    doc.add_paragraph()
    return table


def write_docx(schema, tables, functions, ordered):
    doc = Document()
    for section in doc.sections:
        section.top_margin = Cm(1.8)
        section.bottom_margin = Cm(1.8)
        section.left_margin = Cm(1.8)
        section.right_margin = Cm(1.8)
    title = doc.add_paragraph()
    set_paragraph_format(title, space_after=4, line=1.0)
    r = title.add_run("Diccionario de base de datos")
    set_run_font(r, size=22, bold=True, color=RGBColor(31, 78, 121))
    sub = doc.add_paragraph()
    set_paragraph_format(sub, space_after=2, line=1.0)
    r = sub.add_run("My Works App")
    set_run_font(r, size=16, bold=True, color=RGBColor(31, 78, 121))
    meta = doc.add_paragraph()
    set_paragraph_format(meta, space_after=12, line=1.15)
    r = meta.add_run("Documento técnico de esquema · PostgreSQL / Supabase\n" + project_note(schema))
    set_run_font(r, size=11, color=RGBColor(90, 90, 90))
    doc.add_page_break()

    added, removed, modified = changelog(tables)
    n_fk = sum(len(t["fks"]) for t in tables.values())
    n_cols = sum(len(t["columns"]) for t in tables.values())

    add_heading(doc, "1. Identificación del documento", 1)
    add_table(doc, ["Campo", "Valor"], [
        ["Proyecto", "My Works App"],
        ["Motor", "PostgreSQL (Supabase), esquema public"],
        ["Proyecto Supabase", PROJECT_ID],
        ["Convención de nombres", "Español + snake_case"],
        ["Modelo fuente", project_note(schema)],
        ["Tablas", str(len(tables))],
        ["Columnas", str(n_cols)],
        ["Claves foráneas físicas", str(n_fk)],
        ["Última migración aplicada", f"{schema['latest_migration_version']} ({schema['latest_migration_name']})"],
        ["Archivo de migración (repo)", schema["latest_migration_file"]],
        ["Fecha de generación", f"{GENERATED_AT} ({TZ_LABEL})"],
    ])

    add_heading(doc, "2. Cambios respecto del diccionario v2.3", 1)
    add_body(doc, f"Tablas agregadas ({len(added)}): " + ", ".join(added) + ".")
    add_body(doc, "Tablas eliminadas: ninguna." if not removed else "Tablas eliminadas: " + ", ".join(removed) + ".")
    add_body(doc, "Tablas modificadas:")
    for name, desc in modified:
        add_body(doc, f"{name}: {desc}")

    add_heading(doc, "3. Índice de tablas por grupo", 1)
    add_table(doc, ["#", "Grupo", "Tabla", "Columnas", "RLS", "Descripción"], [
        [
            str(i),
            group_of(tb["name"]),
            tb["name"],
            str(len(tb["columns"])),
            "sí (sin políticas)" if tb["rls_enabled"] and not tb["policies"] else ("sí" if tb["rls_enabled"] else "no"),
            short_note(tb["note"]),
        ]
        for i, tb in enumerate(ordered, 1)
    ])

    _seccion_er().agregar_docx(doc, add_heading, add_body, add_table)

    add_heading(doc, "4. Columnas por tabla", 1)
    for i, tb in enumerate(ordered, 1):
        add_heading(doc, f"4.{i} {tb['name']}", 2)
        if tb["note"]:
            add_body(doc, tb["note"])
        add_table(doc, ["Columna", "Tipo", "Restricciones", "Nota"],
                  [[c["name"], c["type"], c["flags"], c["note"]] for c in tb["columns"]])
        if tb["checks"]:
            add_body(doc, "CHECK: " + "; ".join(f"{ch['name']}: {ch['definition']}" for ch in tb["checks"]))
        idxs = index_text(tb)
        if idxs:
            add_body(doc, "Índices: " + "; ".join(idxs))
        add_body(doc, "RLS. " + rls_text(tb))
        add_body(doc, nf_paragraph(tb).replace("**", ""))
        rel = relaciones_en_palabras(tb)
        if rel:
            add_body(doc, "Relaciones en palabras: " + "; ".join(rel) + ".")

    add_heading(doc, "5. Relaciones (claves foráneas físicas)", 1)
    add_body(doc, "Solo se listan las FK declaradas en Postgres.")
    rows = []
    for tb in ordered:
        for fk in tb["fks"]:
            dest = ("" if fk["schema"] == "public" else fk["schema"] + ".") + fk["table"] + "(" + ", ".join(fk["ref_columns"]) + ")"
            rows.append([tb["name"], ", ".join(fk["columns"]), dest, fk["on_delete"] or "—"])
    add_table(doc, ["Tabla", "Columnas", "Referencia", "ON DELETE"], rows)

    add_heading(doc, "5b. Normalización (auditoría 2026-11-16)", 1)
    add_body(doc, NF_METODO)
    add_table(doc, ["Tabla", "Forma normal", "Dato repetido a propósito y cómo se mantiene"],
              [[tb["name"], forma_normal(tb["name"])[0], forma_normal(tb["name"])[2] or "—"] for tb in ordered])
    add_heading(doc, "6. Enums y vistas", 1)
    add_body(doc, "El esquema public no define tipos ENUM ni vistas. Los estados se restringen con CHECK sobre columnas text o boolean.")

    add_heading(doc, "7. Funciones RPC y SECURITY DEFINER", 1)
    auth = [f for f in functions if f.get("auth_exec") or f.get("anon_exec")]
    svc = [f for f in functions if not f.get("auth_exec") and not f.get("anon_exec")]
    add_body(doc, f"Hay {len(functions)} funciones en public. {sum(1 for f in functions if f['security']=='SECURITY DEFINER')} son SECURITY DEFINER.")
    add_heading(doc, "7.1 API de cliente (anon / authenticated)", 2)
    def purpose_of(f):
        return f.get("comment") or FUNC_PURPOSE.get(f["name"], "Función de apoyo de la aplicación.")
    add_table(doc, ["Función", "Argumentos", "Retorno", "Seguridad", "Quién ejecuta", "Propósito"], [
        [
            f["name"],
            f["args"] or "—",
            f["result"] or "—",
            f["security"],
            ", ".join([w for w, ok in (("anon", f.get("anon_exec")), ("authenticated", f.get("auth_exec"))) if ok]),
            purpose_of(f),
        ]
        for f in sorted(auth, key=lambda x: x["name"])
    ])
    add_heading(doc, "7.2 Backend, cron y disparadores", 2)
    add_table(doc, ["Función", "Argumentos", "Retorno", "Seguridad", "Propósito"], [
        [f["name"], f["args"] or "—", f["result"] or "—", f["security"], purpose_of(f)]
        for f in sorted(svc, key=lambda x: x["name"])
    ])
    doc.save(OUT_DOCX)


def pick_font(size, bold=False):
    candidates = [
        r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def wrap_text(draw, text, fnt, width):
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
    name_f = pick_font(34, True)
    body_f = pick_font(26)
    head_f = pick_font(32, True)
    W, MARGIN, GAP, COLS = 1800, 48, 16, 2
    draw_probe = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    inner = (W - MARGIN * 2 - GAP) // COLS
    text_w = inner - 36
    prepared = []
    for card in cards:
        lines = [("name", card["nombre"])]
        lines.append(("pk", "PK  " + ", ".join(card["pks"])))
        for fk in card["fks"]:
            for line in wrap_text(draw_probe, "FK  " + fk, body_f, text_w):
                lines.append(("fk", line))
        if not card["fks"]:
            for line in wrap_text(draw_probe, card.get("nota") or "Sin clave foránea física", body_f, text_w):
                lines.append(("fk", line))
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


def write_er(tables):
    OUT_FIG.mkdir(parents=True, exist_ok=True)
    paths = []
    for n, (key, title) in enumerate(GROUP_LABELS.items(), 1):
        color = GROUP_COLORS[key]
        cards = []
        for name in GROUPS[key]:
            tb = tables.get(name)
            if not tb:
                continue
            fks = [f"{', '.join(fk['columns'])} → {fk['table']}.{', '.join(fk['ref_columns'])}" for fk in tb["fks"]]
            nota = ""
            if name == "perfiles":
                nota = "Coincide con auth.users.id"
            elif name in ("trabajador_precios", "trabajador_servicios_extra"):
                nota = "4FN: lista separada de la ficha"
            elif name in ("bloqueos_pin_inicio", "intentos_pin_inicio"):
                nota = "Escribe solo el servidor; lee administración"
            cards.append({"nombre": name, "pks": tb["pk"] or ["—"], "fks": fks, "nota": nota})
        img = draw_group(f"{title}  ·  {len(cards)} tablas", color, cards)
        path = OUT_FIG / f"diagrama_er_{n:02d}_{key}.png"
        img.save(path, "PNG", dpi=(220, 220))
        paths.append(path)
    return paths


def main():
    schema = load_schema()
    tables, functions, schema = build_model(schema)
    ordered = ordered_tables(tables)
    # sanity: every live table is grouped
    missing = sorted(set(tables) - {n for ms in GROUPS.values() for n in ms})
    if missing:
        raise SystemExit(f"Tablas sin grupo: {missing}")
    extra = [n for ms in GROUPS.values() for n in ms if n not in tables]
    if extra:
        raise SystemExit(f"Tablas agrupadas que no existen en la BD: {extra}")
    n_cols, n_fk = write_md(schema, tables, functions, ordered)
    write_anexo(schema, tables, ordered)
    write_dbml(schema, tables, ordered)
    write_sql(schema, tables, ordered)
    write_docx(schema, tables, functions, ordered)
    figs = write_er(tables)
    print(
        f"OK {len(tables)} tablas, {n_cols} columnas, {n_fk} FK, "
        f"{len(functions)} funciones. "
        f"Escritos: {OUT_MD}, {OUT_DOCX}, {OUT_ANEXO}, {OUT_DBML}, {OUT_SQL} y {len(figs)} figuras."
    )


if __name__ == "__main__":
    main()

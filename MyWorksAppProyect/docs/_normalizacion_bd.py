# -*- coding: utf-8 -*-
"""Análisis de formas normales por tabla (auditoría de base de datos 2026-11-16).

Lo usa _gen_diccionario_desde_schema.py para escribir, en cada tabla del
diccionario y del Anexo A, la forma normal alcanzada y por qué, en palabras
simples. El detalle del método está en docs/pruebas/auditoria_base_datos.md.

Cada entrada: (forma normal, explicación, desnormalización aceptada o None).
"BCNF" implica 1FN, 2FN y 3FN. "4FN" se indica en las tablas que nacen de
separar un atributo multivaluado.
"""

METODO = (
    "Cada tabla se revisó con las dependencias funcionales reales (qué columna "
    "determina a cuál). 1FN: cada celda guarda un solo valor y hay clave primaria. "
    "2FN: ninguna columna depende solo de una parte de una clave compuesta. 3FN: "
    "ninguna columna que no es clave depende de otra columna que tampoco es clave. "
    "BCNF: todo lo que determina a otra columna es una clave candidata. 4FN: no se "
    "mezclan en una tabla dos listas independientes del mismo dueño. Las columnas "
    "JSON/text con un documento completo (payload de sincronización, "
    "configuración) se tratan como un valor atómico: la base no consulta su interior "
    "por separado. Cuando una tabla repite un dato de otra a propósito, se indica "
    "por qué y cómo se mantiene consistente; en todas se verificó 0 diferencias."
)

_SIMPLE = ("BCNF", "La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.", None)


def _s(texto):
    return ("BCNF", texto, None)


NORMAL_FORMS = {
    "acciones_pendientes": ("BCNF", "Una fila por acción hecha sin conexión. `datos` guarda el contenido completo de la acción como un solo documento: la base no lo consulta por partes, así que cuenta como un valor atómico.", None),
    "acuerdos_trabajo": _s("Cada acuerdo depende solo de su id; el índice único parcial impide dos acuerdos pendientes en el mismo trabajo."),
    "app_config": _s("Tabla clave-valor: la clave determina el valor y nada más."),
    "banderas_funcionalidad": _SIMPLE,
    "bloqueos_pin_inicio": _s("Extensión 1:1 de trabajos (la clave es id_trabajo). Guarda el contador de PIN fallidos de ese trabajo."),
    "bloqueos_usuario": _s("Clave propia id y además clave candidata (id_bloqueador, id_bloqueado), única. No hay otras dependencias."),
    "calificaciones": ("BCNF", "Claves candidatas: id y (id_trabajo, direccion). id_calificado depende de esa clave compuesta, por lo que la tabla cumple BCNF.", "id_calificado repite a quién se calificó, dato que también se deduce de trabajos. Se guarda para filtrar reseñas por persona con índice y en RLS; lo fija la función que crea la reseña. Diferencias verificadas: 0."),
    "calificaciones_cliente": ("BCNF", "Una calificación por trabajo; todas las columnas dependen del id.", "id_trabajador también se deduce de trabajos; se guarda para RLS (el profesional ve lo que escribió). Diferencias: 0."),
    "cancelaciones_trabajo": _SIMPLE,
    "codigos_restablecimiento": ("BCNF", "Cada código depende de su id.", "correo copia el correo al que se envió el código: es un registro histórico, no se actualiza si el usuario cambia su correo."),
    "comunas": _s("La clave es el slug de la comuna. Desde la auditoría hay un índice único (región, nombre) entre las comunas activas, para que no existan dos comunas iguales visibles."),
    "configuraciones_servicio": ("BCNF", "esquema_config es el formulario completo de un servicio, guardado como un documento.", None),
    "consentimientos_usuario": _SIMPLE,
    "cuentas_bancarias": _s("Extensión 1:1 del perfil (la clave es id_usuario)."),
    "dispositivos_push": _s("La clave es el token del dispositivo; usuario y plataforma dependen de él."),
    "disputa_mensajes": _SIMPLE,
    "disputas": _SIMPLE,
    "eventos_abuso": _SIMPLE,
    "eventos_analitica": ("BCNF", "Registro de eventos. rol es el rol que tenía el usuario cuando ocurrió el evento (dato histórico), no una copia que deba seguir al perfil.", None),
    "eventos_ranking": ("BCNF", "Registro de eventos; factores es la foto de los factores al momento del evento.", None),
    "fotos_trabajo": _SIMPLE,
    "impulsos": _SIMPLE,
    "intentos_pin_inicio": _s("Bitácora de intentos de PIN; cada fila es un intento."),
    "liquidaciones": ("BCNF", "id_pago es único (clave candidata) y determina el trabajo y el profesional, así que la tabla cumple BCNF. id_trabajador e id_operador son uuid con clave foránea a perfiles; liberada_por_sistema marca las liberaciones automáticas, que no tienen operador.", "id_trabajo e id_trabajador repiten datos del pago y del trabajo. Es un libro contable: debe conservar a quién se pagó aunque el trabajo cambie. Diferencias: 0."),
    "mensajes": ("2FN con desnormalización controlada", "Cada mensaje depende de su id. id_destinatario se puede deducir del trabajo y del remitente (el otro participante): es una dependencia transitiva, así que en rigor la tabla no llega a 3FN.", "Se guarda id_destinatario para filtrar en tiempo real (Realtime) y en RLS sin unir con trabajos; lo valida la política de inserción. Diferencias verificadas: 0."),
    "metodos_pago_oneclick": _s("Extensión 1:1 del perfil (una tarjeta OneClick por usuario). Desde la auditoría id_usuario es uuid con clave foránea a perfiles."),
    "notificaciones": ("BCNF", "Cada aviso depende de su id.", "id_relacionado apunta a un trabajo u otro objeto según el tipo de aviso (referencia polimórfica), por eso no tiene clave foránea física."),
    "ordenes_cambio": _SIMPLE,
    "pagos": _s("Muchas columnas, pero todas describen el mismo cobro (montos, estado, datos de Transbank, alta de invitado). No hay columnas que dependan de otra que no sea clave."),
    "paises": _SIMPLE,
    "perfiles": ("BCNF", "La clave es el id de Auth. Los conjuntos de rol y estado están cerrados con CHECK y los valores por defecto ahora son los mismos que usa la aplicación (usuario, activo).", "correo repite el correo de auth.users para mostrarlo y buscarlo sin salir de public (diferencias: 0). reputacion_cliente y calificaciones_cliente son totales calculados por calificar_cliente(); desde la auditoría un usuario no puede editarlos."),
    "pines_inicio_trabajo": _s("Extensión 1:1 de trabajos con el PIN de inicio."),
    "portafolio_trabajador": _SIMPLE,
    "propuestas_cotizacion": ("BCNF", "Guarda el total (monto_total_clp) y las horas estimadas; el detalle de la cotización está en propuesta_cotizacion_items, una fila por línea.", None),
    "propuesta_cotizacion_items": ("BCNF", "Clave (id_propuesta, linea): concepto y monto describen esa línea de esa cotización y nada más.", None),
    "ranking_aprendizaje": _s("Bitácora: pesos antes y después de cada ajuste."),
    "ranking_config": _s("Una sola fila de configuración del ranking."),
    "regiones": _SIMPLE,
    "registros_error_app": _SIMPLE,
    "reportes": _SIMPLE,
    "reprogramaciones_trabajo": ("BCNF", "fecha_anterior es la fecha que tenía el trabajo antes de la propuesta: dato histórico de la solicitud.", None),
    "senales_resena": _SIMPLE,
    "servicios": ("BCNF", "La clave es el id del servicio; la categoría es una clave foránea a categorias_servicio.", None),
    "categorias_servicio": _s("La clave es el id de la categoría; nombre y activa dependen solo de ella."),
    "encuestas_testing": _s("Una fila por encuesta. El puntaje SUS no se guarda: lo calculan la función sus_puntaje y la vista encuestas_testing_con_puntaje."),
    "encuesta_testing_respuestas": _s("Clave (id_encuesta, item): el valor depende de la encuesta y del ítem."),
    "suscripciones": _SIMPLE,
    "tickets_soporte": ("2FN con desnormalización controlada", "Cada ticket depende de su id. Los nombres y el monto se pueden deducir del trabajo (dependencia transitiva id → id_trabajo → nombre).", "nombre_cliente, nombre_trabajador y monto_escrow son la foto del caso al abrir el ticket (trigger fijar_ticket_desde_trabajo), para que la consola de soporte no cambie si después cambia el perfil o el pago."),
    "trabajador_horarios": ("BCNF", "Una fila por día de la semana (id_usuario, dia_semana) con hora de inicio y de fin: la clave candidata determina el resto de la fila.", None),
    "trabajador_horas_publicadas": ("4FN", "Lista de horas reservables del profesional, separada de su ventana diaria. Clave (id_usuario, dia_semana, hora).", None),
    "trabajador_precios": ("4FN", "Lista de precios del profesional separada de su ficha. Clave (id_usuario, codigo); id_usuario es uuid con clave foránea a trabajadores.", None),
    "trabajador_servicios": ("4FN", "Lista de oficios del profesional separada de su ficha: un profesional atiende varios oficios, independiente de sus precios. Clave (id_trabajador, categoria_servicio); cada oficio es una categoría de categorias_servicio.", None),
    "trabajador_servicios_extra": ("4FN", "Servicios adicionales del profesional, separados de su ficha. id_usuario es uuid con clave foránea a trabajadores.", None),
    "trabajadores": ("BCNF con valores calculados documentados", "Ficha 1:1 del profesional. Los precios, los servicios extra y los oficios viven en tablas hijas en 4FN; la región se obtiene desde la comuna.", "calificacion, trabajos_completados, score_listado y es_elite son valores calculados para ordenar el catálogo sin recalcular en cada consulta."),
    "trabajos": ("BCNF con una copia mantenida por trigger", "Cada columna describe el pedido. instantanea_precio es la foto del precio al pedir (dato histórico).", "estado_pago copia el estado del pago principal (trigger copiar_estado_pago_trabajo) para filtrar listas sin unir con pagos. Diferencias: 0."),
    "ubicacion_en_vivo": ("BCNF", "Extensión 1:1 de trabajos (clave id_trabajo).", "id_trabajador repite el profesional del trabajo para autorizar la publicación en tiempo real. Diferencias: 0."),
    "verificacion_eventos": _s("Bitácora de cambios del estado de verificación."),
}


def forma_normal(tabla):
    return NORMAL_FORMS.get(tabla, _SIMPLE)


def relaciones_en_palabras(tb):
    """Describe las claves foráneas de una tabla en lenguaje simple."""
    frases = []
    for fk in tb.get("fks", []):
        cols = ", ".join(fk["columns"])
        dest = fk["table"] if fk["schema"] == "public" else f"{fk['schema']}.{fk['table']}"
        od = (fk.get("on_delete") or "").upper()
        if "CASCADE" in od:
            efecto = f"si se borra la fila de {dest}, también se borran las filas que la usan"
        elif "SET NULL" in od:
            efecto = f"si se borra la fila de {dest}, la columna queda vacía y el registro se conserva"
        elif "RESTRICT" in od or "NO ACTION" in od or not od:
            efecto = f"no se puede borrar la fila de {dest} mientras tenga registros asociados"
        else:
            efecto = od.lower()
        frases.append(f"{cols} apunta a {dest} ({efecto})")
    return frases

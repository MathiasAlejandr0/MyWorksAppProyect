# Anexo A. Diccionario de datos

A continuación se describe cada una de las 52 tablas del esquema public, alineadas a la base viva de Supabase (`wxqrfcqifkfgawrnqmnj`) al 2026-11-16 (America/Santiago), migración `20261116044049` (stats_profesional_fuente_unica). Los atributos se listan con su tipo de dato y su restricción. PK indica la clave primaria y FK la clave foránea. perfiles.id coincide con el identificador de autenticación de Supabase (auth.users.id). No hay tipos ENUM ni vistas en public; los conjuntos cerrados se restringen con CHECK.

Fuente: elaboración propia a partir del esquema real (modelo entidad-relación v2.5).

Modelo entidad-relación: las figuras (mapa de dominios, diagrama general con las 52 tablas y un diagrama por dominio con columnas, tipos, PK/FK y cardinalidad) están en `Fase 2/modelo_entidad_relacion/figuras/`, con fuentes editables y un LEEME en la misma carpeta. La explicación de cada dominio, el flujo de pago y las decisiones de diseño están en la sección 2b de `MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md`.

Respecto del anexo v2.3 (43 tablas, 2026-11-08) se agregan nueve tablas: acuerdos_trabajo, disputa_mensajes, reprogramaciones_trabajo (CU-33), pines_inicio_trabajo, bloqueos_pin_inicio, intentos_pin_inicio, cuentas_bancarias, dispositivos_push y verificacion_eventos. También se documentan los roles de consola soporte y qa, el alta de invitado (columnas de pagos) y los cambios de calificación bidireccional, horarios semanales y soporte automático de disputas.

## Identidad y cuenta

### Tabla A-1. perfiles

Identidad de la aplicación: perfiles.id coincide con auth.users.id (esquema auth de Supabase, fuera de public; clave foránea con ON DELETE CASCADE desde la auditoría 2026-11-16). El default de rol es 'usuario' y el de estado_cuenta es 'activo'. Los CHECK perfiles_rol_chk y perfiles_estado_cuenta_chk cierran los conjuntos: usuario, trabajador, administrador, soporte y qa; activo, suspendido, bloqueado y eliminado. Los roles privilegiados (administrador, soporte, qa) no se pueden autoasignar: el trigger perfiles_rol_inicial_seguro y protect_profile_sensitive_fields lo impiden. reputacion_cliente y calificaciones_cliente los calcula calificar_cliente(); el usuario no puede editarlos (trigger protect_profile_sensitive_fields).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | uuid | PK, FK → auth.users.id, Obligatorio, Default gen_random_uuid() |
| `nombre` | text | Obligatorio, Default '' |
| `correo` | text | Opcional |
| `rol` | text | Obligatorio, Default 'usuario'. usuario \| trabajador \| administrador |
| `estado_cuenta` | text | Obligatorio, Default 'activo'. activo \| suspendido \| bloqueado \| eliminado |
| `ruta_foto_perfil` | text | Opcional |
| `creado_en` | text | Obligatorio, Default to_char((now() AT TIME ZONE 'utc'::text), 'YYYY-MM-DD"T"HH24:MI:SS.US'::text) |
| `reputacion_cliente` | numeric(3,2) | Opcional |
| `calificaciones_cliente` | integer | Obligatorio, Default 0 |

Restricciones CHECK: `perfiles_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `perfiles_estado_cuenta_chk` CHECK ((estado_cuenta = ANY (ARRAY['activo'::text, 'suspendido'::text, 'bloqueado'::text, 'eliminado'::text]))); `perfiles_reputacion_cliente_chk` CHECK (((reputacion_cliente IS NULL) OR ((reputacion_cliente >= (1)::numeric) AND (reputacion_cliente <= (5)::numeric)))); `perfiles_rol_chk` CHECK ((rol = ANY (ARRAY['usuario'::text, 'trabajador'::text, 'administrador'::text, 'soporte'::text, 'qa'::text]))).

RLS activo. El usuario lee su ficha y, con límites, fichas públicas (nombre y foto) de otros; no ve correo ajeno por esta vía. La escritura de campos sensibles (rol, estado_cuenta, reputacion_cliente, calificaciones_cliente) está protegida por trigger. El contacto completo solo se entrega con perfil_contacto_si_trabajo_activo. Políticas: INSERT «perfiles_insert», SELECT «perfiles_select», UPDATE «perfiles_update».

**Forma normal: BCNF.** La clave es el id de Auth. Los conjuntos de rol y estado están cerrados con CHECK y los valores por defecto ahora son los mismos que usa la aplicación (usuario, activo). Dato repetido a propósito: correo repite el correo de auth.users para mostrarlo y buscarlo sin salir de public (diferencias: 0). reputacion_cliente y calificaciones_cliente son totales calculados por calificar_cliente(); desde la auditoría un usuario no puede editarlos.

Relaciones: id apunta a auth.users (si se borra la fila de auth.users, también se borran las filas que la usan).

### Tabla A-2. notificaciones

Aviso dentro de la aplicación dirigido a un usuario.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `tipo` | text | Obligatorio |
| `titulo` | text | Obligatorio |
| `cuerpo` | text | Obligatorio |
| `id_relacionado` | text | Opcional |
| `leido` | integer | Obligatorio, Default 0 |
| `creado_en` | text | Obligatorio |

Restricciones CHECK: `notificaciones_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `notificaciones_leido_bool_chk` CHECK (((leido IS NULL) OR (leido = ANY (ARRAY[0, 1])))).

RLS activo. El usuario lee y marca las suyas. Políticas: DELETE «notificaciones_delete», INSERT «notificaciones_insert_participantes», SELECT «notificaciones_select», UPDATE «notificaciones_update».

**Forma normal: BCNF.** Cada aviso depende de su id. Dato repetido a propósito: id_relacionado apunta a un trabajo u otro objeto según el tipo de aviso (referencia polimórfica), por eso no tiene clave foránea física.

Relaciones: id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-3. suscripciones

Plan de suscripción contratado por un usuario.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `tipo_plan` | text | Obligatorio |
| `estado` | text | Obligatorio |
| `fecha_inicio` | text | Obligatorio |
| `fecha_fin` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

Restricciones CHECK: `suscripciones_actualizado_en_iso_chk` CHECK (es_marca_tiempo_iso(actualizado_en)); `suscripciones_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `suscripciones_fecha_fin_iso_chk` CHECK (es_marca_tiempo_iso(fecha_fin)); `suscripciones_fecha_inicio_iso_chk` CHECK (es_marca_tiempo_iso(fecha_inicio)).

RLS activo. El usuario ve solo su plan; crear o cambiar una suscripción es de administración o del backend (antes de la auditoría 2026-11-16 un usuario podía activarse un plan premium). Políticas: DELETE «suscripciones_admin_delete», INSERT «suscripciones_admin_insert», UPDATE «suscripciones_admin_update», SELECT «suscripciones_select».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-4. codigos_restablecimiento

Código temporal para restablecer la contraseña.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `codigo` | text | Obligatorio |
| `correo` | text | Obligatorio |
| `expira_en` | text | Obligatorio |
| `usado` | integer | Opcional, Default 0 |
| `creado_en` | text | Obligatorio |

Restricciones CHECK: `codigos_restablecimiento_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `codigos_restablecimiento_expira_en_iso_chk` CHECK (es_marca_tiempo_iso(expira_en)); `codigos_restablecimiento_usado_bool_chk` CHECK (((usado IS NULL) OR (usado = ANY (ARRAY[0, 1])))).

RLS activo. Acceso acotado al dueño o al backend; no es un dato de catálogo. Políticas: ALL «codigos_reset_all».

**Forma normal: BCNF.** Cada código depende de su id. Dato repetido a propósito: correo copia el correo al que se envió el código: es un registro histórico, no se actualiza si el usuario cambia su correo.

Relaciones: id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-5. consentimientos_usuario

Registro de aceptación de una versión de consentimiento.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `version_consentimiento` | text | Obligatorio |
| `aceptado` | integer | Obligatorio, Default 0 |
| `aceptado_en` | text | Obligatorio |
| `direccion_ip` | text | Opcional |
| `agente_usuario` | text | Opcional |

Restricciones CHECK: `consentimientos_usuario_aceptado_bool_chk` CHECK (((aceptado IS NULL) OR (aceptado = ANY (ARRAY[0, 1])))); `consentimientos_usuario_aceptado_en_iso_chk` CHECK (es_marca_tiempo_iso(aceptado_en)).

RLS activo. El usuario ve y registra sus propios consentimientos. Políticas: ALL «consentimientos_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-6. bloqueos_usuario

Bloqueo de un usuario hacia otro.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_bloqueador` | uuid | FK → perfiles.id, Obligatorio |
| `id_bloqueado` | uuid | FK → perfiles.id, Obligatorio |
| `creado_en` | text | Obligatorio |

Restricciones CHECK: `bloqueos_usuario_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `bloqueos_usuario_distintos_chk` CHECK ((id_bloqueador <> id_bloqueado)).

RLS activo. El usuario ve los bloqueos en los que participa; solo él (o un administrador) puede crearlos. Políticas: ALL «bloqueos_all».

**Forma normal: BCNF.** Clave propia id y además clave candidata (id_bloqueador, id_bloqueado), única. No hay otras dependencias.

Relaciones: id_bloqueado apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_bloqueador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-7. reportes

Denuncia de un usuario contra otro.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_reportante` | uuid | FK → perfiles.id, Obligatorio |
| `id_usuario_reportado` | uuid | FK → perfiles.id, Obligatorio |
| `motivo` | text | Obligatorio |
| `descripcion` | text | Opcional |
| `estado` | text | Obligatorio, Default 'pendiente' |
| `creado_en` | text | Obligatorio |

Restricciones CHECK: `reportes_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)).

RLS activo. El reportante ve los suyos; un administrador gestiona la cola. Políticas: ALL «reportes_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_reportante apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_usuario_reportado apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-8. eventos_abuso

Detección de abuso y la acción que se tomó.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `tipo_abuso` | text | Obligatorio |
| `conteo` | integer | Obligatorio |
| `detectado_en` | text | Obligatorio |
| `accion_tomada` | text | Opcional |
| `accion_tomada_en` | text | Opcional |
| `resuelto` | integer | Opcional, Default 0 |

Restricciones CHECK: `eventos_abuso_accion_tomada_en_iso_chk` CHECK (es_marca_tiempo_iso(accion_tomada_en)); `eventos_abuso_detectado_en_iso_chk` CHECK (es_marca_tiempo_iso(detectado_en)); `eventos_abuso_resuelto_bool_chk` CHECK (((resuelto IS NULL) OR (resuelto = ANY (ARRAY[0, 1])))).

RLS activo. Restringido a administración o al backend de moderación. Políticas: ALL «eventos_abuso_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-9. acciones_pendientes

Acción hecha sin conexión, pendiente de sincronizar.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `tipo_accion` | text | Obligatorio |
| `tipo_entidad` | text | Obligatorio |
| `id_entidad` | text | Opcional |
| `datos` | text | Obligatorio |
| `estado` | text | Obligatorio, Default 'pending_sync' |
| `conteo_reintentos` | integer | Opcional, Default 0 |
| `mensaje_error` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

Restricciones CHECK: `acciones_pendientes_actualizado_en_iso_chk` CHECK (es_marca_tiempo_iso(actualizado_en)); `acciones_pendientes_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)).

RLS activo. El dueño ve y gestiona sus propias acciones pendientes; un administrador ve todas. Políticas: ALL «acciones_pendientes_all».

**Forma normal: BCNF.** Una fila por acción hecha sin conexión. `datos` guarda el contenido completo de la acción como un solo documento: la base no lo consulta por partes, así que cuenta como un valor atómico.

Relaciones: id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-10. registros_error_app

Error de la aplicación informado por un cliente.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Opcional |
| `tipo_error` | text | Obligatorio, Default 'error' |
| `mensaje` | text | Obligatorio |
| `traza_pila` | text | Opcional |
| `metadatos` | jsonb | Opcional |
| `estado` | text | Obligatorio, Default 'nuevo' |
| `version_app` | text | Opcional |
| `plataforma` | text | Opcional |
| `creado_en` | text | Obligatorio, Default to_char((now() AT TIME ZONE 'utc'::text), 'YYYY-MM-DD"T"HH24:MI:SS.US'::text) |

Restricciones CHECK: `registros_error_app_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)).

RLS activo. El cliente informa sus propios errores; un administrador puede revisarlos. Políticas: INSERT «registros_error_app_insert», SELECT «registros_error_app_select», UPDATE «registros_error_app_update_admin».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_usuario apunta a perfiles (no se puede borrar la fila de perfiles mientras tenga registros asociados).

### Tabla A-11. eventos_analitica

Evento de uso registrado por la aplicación.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `nombre_evento` | text | Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Opcional |
| `rol` | text | Opcional |
| `marca_tiempo` | text | Obligatorio |
| `metadatos` | text | Opcional |

Restricciones CHECK: `eventos_analitica_marca_tiempo_iso_chk` CHECK (es_marca_tiempo_iso(marca_tiempo)).

RLS activo. El usuario o el backend registra eventos de uso; no es un listado público. Políticas: INSERT «analitica_insert», SELECT «analitica_select».

**Forma normal: BCNF.** Registro de eventos. rol es el rol que tenía el usuario cuando ocurrió el evento (dato histórico), no una copia que deba seguir al perfil.

Relaciones: id_usuario apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva).

### Tabla A-12. banderas_funcionalidad

Interruptor de una función por versión, rol o usuario.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `nombre_bandera` | text | Obligatorio |
| `habilitada` | integer | Obligatorio, Default 0 |
| `version_app` | text | Opcional |
| `rol` | text | Opcional |
| `id_usuario` | uuid | FK → perfiles.id, Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

Restricciones CHECK: `banderas_funcionalidad_actualizado_en_iso_chk` CHECK (es_marca_tiempo_iso(actualizado_en)); `banderas_funcionalidad_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `banderas_funcionalidad_habilitada_bool_chk` CHECK (((habilitada IS NULL) OR (habilitada = ANY (ARRAY[0, 1])))).

RLS activo. Lectura restringida a banderas activas aplicables al usuario, o a un administrador. Políticas: DELETE «banderas_funcionalidad_admin_delete», INSERT «banderas_funcionalidad_admin_insert», UPDATE «banderas_funcionalidad_admin_update», SELECT «banderas_select».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-13. dispositivos_push

Token del dispositivo del usuario para avisos push (FCM u otra plataforma). El alta y el baja se hacen por RPC.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `token` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `plataforma` | text | Obligatorio, Default 'android' |
| `creado_en` | timestamptz | Obligatorio, Default now() |
| `actualizado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `dispositivos_push_plataforma_check` CHECK ((plataforma = ANY (ARRAY['android'::text, 'ios'::text, 'web'::text]))); `dispositivos_push_token_largo` CHECK (((char_length(token) >= 20) AND (char_length(token) <= 4096))).

RLS activo. El usuario solo lee sus propios tokens. El alta y la baja se hacen por RPC. Políticas: SELECT «dispositivos_push_select_propios».

**Forma normal: BCNF.** La clave es el token del dispositivo; usuario y plataforma dependen de él.

Relaciones: id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-14. verificacion_eventos

Historial de cambios del estado de verificación de un profesional (pendiente, en revisión, verificado, rechazado).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | uuid | PK, Obligatorio, Default gen_random_uuid() |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `estado` | text | Obligatorio |
| `nota` | text | Opcional |
| `id_actor` | uuid | FK → perfiles.id, Opcional |
| `creado_en` | timestamptz | Obligatorio, Default now() |

RLS activo. El profesional ve su propio historial; un administrador ve todos. La escritura la hace el trigger al cambiar el estado de verificación. Políticas: SELECT «verificacion_eventos_select».

**Forma normal: BCNF.** Bitácora de cambios del estado de verificación.

Relaciones: id_actor apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva); id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

## Territorio

### Tabla A-15. paises

País operativo. Hoy solo CL.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `nombre` | text | Obligatorio |
| `iso2` | text | Obligatorio |

RLS activo. Lectura pública del catálogo. Hoy solo CL. Políticas: DELETE «paises_admin_delete», INSERT «paises_admin_insert», UPDATE «paises_admin_update», SELECT «paises_select».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

### Tabla A-16. regiones

Región administrativa de un país.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_pais` | text | FK → paises.id, Obligatorio |
| `nombre` | text | Obligatorio |
| `codigo_oficial` | text | Opcional |

RLS activo. Lectura pública del catálogo geográfico. Políticas: DELETE «regiones_admin_delete», INSERT «regiones_admin_insert», UPDATE «regiones_admin_update», SELECT «regiones_select».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_pais apunta a paises (no se puede borrar la fila de paises mientras tenga registros asociados).

### Tabla A-17. comunas

Comuna de cobertura. Su identificador es el slug usado por trabajos y trabajadores.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_region` | text | FK → regiones.id, Obligatorio |
| `nombre` | text | Obligatorio |
| `latitud` | double precision | Opcional |
| `longitud` | double precision | Opcional |
| `activa` | integer | Obligatorio, Default 1 |

Restricciones CHECK: `comunas_activa_bool_chk` CHECK (((activa IS NULL) OR (activa = ANY (ARRAY[0, 1])))); `comunas_lat_chk` CHECK (((latitud IS NULL) OR ((latitud >= ('-90'::integer)::double precision) AND (latitud <= (90)::double precision)))); `comunas_lng_chk` CHECK (((longitud IS NULL) OR ((longitud >= ('-180'::integer)::double precision) AND (longitud <= (180)::double precision)))).

RLS activo. Lectura pública del catálogo geográfico (comunas activas). La escritura es de administración o servicio. Políticas: DELETE «comunas_admin_delete», INSERT «comunas_admin_insert», UPDATE «comunas_admin_update», SELECT «comunas_select».

**Forma normal: BCNF.** La clave es el slug de la comuna. Desde la auditoría hay un índice único (región, nombre) entre las comunas activas, para que no existan dos comunas iguales visibles.

Relaciones: id_region apunta a regiones (no se puede borrar la fila de regiones mientras tenga registros asociados).

## Catálogo del profesional

### Tabla A-18. trabajadores

Ficha 1:1 del profesional (PK = perfiles.id). La oferta en 4NF vive en tablas hijas; los JSON niveles_precio y servicios_personalizados son solo formato de escritura (un trigger los parte a filas). es_elite es una columna GENERATED. La agenda semanal está en trabajador_horarios; usa_horario enciende el filtro. pausa_por_trabajo queda en true cuando un trabajo activo dejó disponible = 0, y se restablece al terminar.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_usuario` | uuid | PK, FK → perfiles.id, Obligatorio |
| `profesion` | text | Obligatorio, Default '' |
| `descripcion` | text | Opcional |
| `calificacion` | numeric(4,2) | Obligatorio, Default 0 |
| `disponible` | integer | Obligatorio, Default 1 |
| `tarifa_visita` | numeric(12,0) | Obligatorio, Default 15000 |
| `categoria_servicio` | text | Obligatorio, Default 'general' |
| `niveles_precio` | jsonb | Obligatorio, Default '{}' |
| `conteo_rechazos` | integer | Obligatorio, Default 0. Rechazos de invitaciones; penaliza orden en listados (no visible en UI) |
| `servicios_personalizados` | jsonb | Obligatorio, Default '[]'. Servicios adicionales definidos por el trabajador (JSON array) |
| `precios_configurados` | integer | Obligatorio, Default 0. 1 si el trabajador completó la guía de configuración de precios |
| `zona_trabajo` | text | Opcional. Comuna o zona donde atiende el trabajador |
| `estado_verificacion` | text | Obligatorio, Default 'pendiente' |
| `nota_verificacion` | text | Opcional |
| `latitud_base` | double precision | Opcional. Latitud de la base de servicio. origen_base=comuna es el centro de la comuna declarada; mapa la fijó el profesional. |
| `longitud_base` | double precision | Opcional |
| `radio_servicio_km` | numeric | Obligatorio, Default 15. Radio máximo de matching en kilómetros desde la base. |
| `origen_base` | text | Opcional |
| `score_listado` | numeric(8,4) | Obligatorio, Default 0. Orden de marketplace. Incluye pesos configurables + prioridad_manual*2. |
| `prioridad_manual` | integer | Obligatorio, Default 0. Override de admin (-50..50) para mostrar un profesional antes o después. |
| `score_desglose` | jsonb | Obligatorio, Default '{}' |
| `ranking_actualizado_en` | timestamptz | Opcional |
| `radio_urbano_km` | numeric(5,2) | Obligatorio, Default 5. Kilómetros alrededor de la base donde la movilización es $0. |
| `tarifa_fuera_radio_clp` | integer | Obligatorio, Default 0. Movilización fija si el cliente está fuera del radio urbano. 0 = tampoco cobra fuera. |
| `trabajos_completados` | integer | Obligatorio, Default 0 |
| `es_elite` | boolean | Opcional, GENERATED ALWAYS. Destacado del mes: nota >= 4.7 y al menos 5 trabajos completados. GENERATED ALWAYS AS ((COALESCE(calificacion, (0)::numeric) >= 4.7) AND (trabajos_completados >= 5)) |
| `id_comuna` | text | FK → comunas.id, Opcional. Comuna de cobertura. zona_trabajo sigue como texto de UI. |
| `id_region` | text | FK → regiones.id, Opcional. Cobertura regional (p. ej. RM todas). |
| `usa_horario` | boolean | Obligatorio, Default false |
| `pausa_por_trabajo` | boolean | Obligatorio, Default false. true cuando disponible = 0 lo dejó un trabajo activo; se restablece al terminar. |

Restricciones CHECK: `trabajadores_base_lat_chk` CHECK (((latitud_base IS NULL) OR ((latitud_base >= ('-90'::integer)::double precision) AND (latitud_base <= (90)::double precision)))); `trabajadores_base_lng_chk` CHECK (((longitud_base IS NULL) OR ((longitud_base >= ('-180'::integer)::double precision) AND (longitud_base <= (180)::double precision)))); `trabajadores_calificacion_chk` CHECK (((calificacion >= (0)::numeric) AND (calificacion <= (5)::numeric))); `trabajadores_contadores_chk` CHECK (((trabajos_completados >= 0) AND (conteo_rechazos >= 0))); `trabajadores_disponible_bool_chk` CHECK (((disponible IS NULL) OR (disponible = ANY (ARRAY[0, 1])))); `trabajadores_estado_verificacion_check` CHECK ((estado_verificacion = ANY (ARRAY['pendiente'::text, 'en_revision'::text, 'verificado'::text, 'rechazado'::text]))); `trabajadores_origen_base_chk` CHECK (((origen_base IS NULL) OR (origen_base = ANY (ARRAY['mapa'::text, 'comuna'::text])))); `trabajadores_precios_configurados_bool_chk` CHECK (((precios_configurados IS NULL) OR (precios_configurados = ANY (ARRAY[0, 1])))); `trabajadores_prioridad_manual_chk` CHECK (((prioridad_manual >= '-50'::integer) AND (prioridad_manual <= 50))); `trabajadores_radio_chk` CHECK (((radio_servicio_km >= (1)::numeric) AND (radio_servicio_km <= (80)::numeric))); `trabajadores_radio_urbano_chk` CHECK (((radio_urbano_km >= (1)::numeric) AND (radio_urbano_km <= (40)::numeric))); `trabajadores_tarifa_fuera_radio_chk` CHECK (((tarifa_fuera_radio_clp >= 0) AND (tarifa_fuera_radio_clp <= 200000))); `trabajadores_tarifa_visita_chk` CHECK ((tarifa_visita >= (0)::numeric)).

RLS activo. El listado público solo muestra fichas disponibles con precios configurados. El dueño, un administrador o el cliente con un trabajo conjunto también pueden leer la ficha. El UPDATE es del dueño o de un administrador; campos como verificación, score y pausa están protegidos por trigger. Políticas: INSERT «trabajadores_insert», SELECT «trabajadores_select_authenticated», UPDATE «trabajadores_update».

**Forma normal: 2FN con datos derivados documentados.** Ficha 1:1 del profesional. Las listas (precios, servicios extra, oficios) viven en tablas hijas en 4FN. id_region depende de id_comuna (dependencia transitiva), así que en rigor la ficha no llega a 3FN. Dato repetido a propósito: niveles_precio y servicios_personalizados son el formato de escritura de la app; un trigger los parte en trabajador_precios y trabajador_servicios_extra. calificacion, trabajos_completados, score_listado y es_elite son valores calculados para ordenar el catálogo sin recalcular en cada consulta. id_region se deduce de id_comuna cuando hay comuna (diferencias: 0).

Relaciones: id_comuna apunta a comunas (si se borra la fila de comunas, la columna queda vacía y el registro se conserva); id_region apunta a regiones (si se borra la fila de regiones, la columna queda vacía y el registro se conserva); id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-19. trabajador_precios

Precio por código de servicio del profesional. id_usuario es uuid con clave foránea a trabajadores (ON DELETE CASCADE) desde la auditoría 2026-11-16; antes era text sin FK.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_usuario` | uuid | PK, FK → trabajadores.id_usuario, Obligatorio |
| `codigo` | text | PK, Obligatorio |
| `monto_clp` | numeric(12,0) | Obligatorio |

Restricciones CHECK: `trabajador_precios_monto_clp_check` CHECK ((monto_clp >= (0)::numeric)).

RLS activo. El dueño y el catálogo (según política de precios) leen los montos ya publicados; la escritura es del dueño o de un trigger que parte el JSON. Políticas: ALL «trabajador_precios_propio».

**Forma normal: 4FN.** Nace de separar la lista de precios del profesional (antes un JSON en trabajadores). Clave (id_usuario, codigo). Desde la auditoría id_usuario es uuid con clave foránea a trabajadores.

Relaciones: id_usuario apunta a trabajadores (si se borra la fila de trabajadores, también se borran las filas que la usan).

### Tabla A-20. trabajador_servicios_extra

Servicio adicional definido por el profesional. id_usuario es uuid con clave foránea a trabajadores, igual que en trabajador_precios.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | PK, FK → trabajadores.id_usuario, Obligatorio |
| `titulo` | text | Obligatorio |
| `subtitulo` | text | Obligatorio, Default '' |
| `monto_clp` | numeric(12,0) | Obligatorio |
| `unidad` | text | Obligatorio, Default 'fijo' |

Restricciones CHECK: `trabajador_servicios_extra_monto_clp_check` CHECK ((monto_clp >= (0)::numeric)); `trabajador_servicios_extra_unidad_check` CHECK ((unidad = ANY (ARRAY['fijo'::text, 'por_m2'::text]))).

RLS activo. Servicios extra del profesional; misma idea que los precios. Políticas: ALL «trabajador_servicios_extra_propio».

**Forma normal: 4FN.** Servicios adicionales del profesional, separados del JSON servicios_personalizados. Desde la auditoría id_usuario es uuid con clave foránea.

Relaciones: id_usuario apunta a trabajadores (si se borra la fila de trabajadores, también se borran las filas que la usan).

### Tabla A-21. trabajador_servicios

Oficios del catálogo que el profesional declara atender.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_trabajador` | uuid | PK, FK → perfiles.id, Obligatorio |
| `categoria_servicio` | text | PK, Obligatorio |

RLS activo. Oficios declarados: lectura de catálogo y escritura del dueño. Políticas: DELETE «trabajador_servicios_delete», INSERT «trabajador_servicios_insert», SELECT «trabajador_servicios_select», UPDATE «trabajador_servicios_update».

**Forma normal: 4FN.** Lista de oficios del profesional separada de su ficha: un profesional atiende varios oficios, independiente de sus precios. Clave (id_trabajador, categoria_servicio).

Relaciones: id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-22. trabajador_horarios

Plantilla semanal: una fila por día (1 = lunes … 7 = domingo), única por (id_usuario, dia_semana). Solo el dueño lee y escribe (RLS). El cliente consulta los huecos con la RPC horarios_libres_profesional. usa_horario en trabajadores enciende el filtro.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_usuario` | uuid | FK → trabajadores.id_usuario, Obligatorio |
| `horarios` | jsonb | Obligatorio, Default '[]' |
| `actualizado_en` | timestamptz | Obligatorio, Default now() |
| `id` | uuid | PK, Obligatorio, Default gen_random_uuid() |
| `dia_semana` | smallint | Opcional |
| `hora_inicio` | time | Opcional |
| `hora_fin` | time | Opcional |
| `activo` | boolean | Opcional, Default true |
| `creado_en` | timestamptz | Opcional, Default now() |

Restricciones CHECK: `trabajador_horarios_dia_chk` CHECK (((dia_semana IS NULL) OR ((dia_semana >= 1) AND (dia_semana <= 7)))).

RLS activo. SELECT y escritura solo para el dueño de la ficha (o un administrador). El cliente no lee esta tabla: usa horarios_libres_profesional. Políticas: DELETE «trabajador_horarios_delete», INSERT «trabajador_horarios_insert», SELECT «trabajador_horarios_select», UPDATE «trabajador_horarios_update».

**Forma normal: BCNF con una columna heredada.** La forma actual es una fila por día (id_usuario, dia_semana) con hora de inicio y fin: cumple BCNF. Dato repetido a propósito: horarios (jsonb) es el formato antiguo de la semana completa que aún leen versiones previas de la app; la fuente de verdad son las columnas por día.

Relaciones: id_usuario apunta a trabajadores (si se borra la fila de trabajadores, también se borran las filas que la usan).

### Tabla A-23. portafolio_trabajador

Foto o medio del portafolio de un profesional.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajador` | uuid | FK → perfiles.id, Obligatorio |
| `ruta_foto` | text | Obligatorio |
| `descripcion` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `tipo_medio` | text | Obligatorio, Default 'foto' |

Restricciones CHECK: `portafolio_tipo_medio_chk` CHECK ((tipo_medio = ANY (ARRAY['foto'::text, 'video'::text]))); `portafolio_trabajador_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)).

RLS activo. El profesional gestiona su portafolio; hay lectura de catálogo de los ítems visibles. Políticas: DELETE «portafolio_delete», INSERT «portafolio_insert», SELECT «portafolio_select», UPDATE «portafolio_update».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-24. impulsos

Promoción temporal de visibilidad de un profesional.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajador` | uuid | FK → perfiles.id, Obligatorio |
| `tipo_impulso` | text | Obligatorio |
| `fecha_inicio` | text | Obligatorio |
| `fecha_fin` | text | Obligatorio |
| `creado_en` | text | Obligatorio |

Restricciones CHECK: `impulsos_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `impulsos_fecha_fin_iso_chk` CHECK (es_marca_tiempo_iso(fecha_fin)); `impulsos_fecha_inicio_iso_chk` CHECK (es_marca_tiempo_iso(fecha_inicio)).

RLS activo. Lectura para usuarios con sesión (el catálogo muestra los vigentes). Crear, cambiar o borrar un impulso es solo de administración: antes de la auditoría 2026-11-16 un profesional podía darse un impulso sin pagar. Políticas: DELETE «impulsos_admin_delete», INSERT «impulsos_admin_insert», UPDATE «impulsos_admin_update», SELECT «impulsos_select».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-25. servicios

Catálogo de oficios que la plataforma ofrece.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `nombre` | text | Obligatorio |
| `descripcion` | text | Opcional |
| `categoria` | text | Obligatorio, Default 'general' |
| `activo` | integer | Obligatorio, Default 1 |
| `requiere_certificacion` | integer | Obligatorio, Default 0 |
| `modelo_precio` | text | Obligatorio, Default 'por_hora' |
| `aviso_legal` | text | Opcional |
| `creado_en` | text | Opcional |
| `actualizado_en` | text | Opcional |

Restricciones CHECK: `servicios_activo_bool_chk` CHECK (((activo IS NULL) OR (activo = ANY (ARRAY[0, 1])))); `servicios_actualizado_en_iso_chk` CHECK (es_marca_tiempo_iso(actualizado_en)); `servicios_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `servicios_requiere_certificacion_bool_chk` CHECK (((requiere_certificacion IS NULL) OR (requiere_certificacion = ANY (ARRAY[0, 1])))).

RLS activo. Lectura pública del catálogo de oficios. La escritura es de administración. Políticas: DELETE «servicios_admin_delete», INSERT «servicios_admin_insert», UPDATE «servicios_admin_update», SELECT «servicios_select», SELECT «servicios_select_authenticated».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

### Tabla A-26. configuraciones_servicio

Esquema de configuración asociado a un servicio.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_servicio` | text | FK → servicios.id, Obligatorio |
| `esquema_config` | text | Obligatorio |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

Restricciones CHECK: `configuraciones_servicio_actualizado_en_iso_chk` CHECK (es_marca_tiempo_iso(actualizado_en)); `configuraciones_servicio_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)).

RLS activo. Lectura del esquema de configuración del catálogo; escritura restringida. Políticas: SELECT «config_servicio_select», DELETE «configuraciones_servicio_admin_delete», INSERT «configuraciones_servicio_admin_insert», UPDATE «configuraciones_servicio_admin_update».

**Forma normal: BCNF.** esquema_config es el formulario completo de un servicio, guardado como un documento.

Relaciones: id_servicio apunta a servicios (si se borra la fila de servicios, también se borran las filas que la usan).

## Pedido y servicio

### Tabla A-27. trabajos

Pedido de un cliente a un profesional (o abierto a cotizaciones). estado_pago es una copia derivada del pago principal. La fecha programada se guarda como texto y, desde CU-33, solo cambia por las RPC de reagendamiento (trabajos_fecha_solo_por_rpc). Hay un índice único que impide dos trabajos activos del mismo profesional en el mismo minuto (minuto_utc de fecha_programada).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `id_trabajador` | uuid | FK → perfiles.id, Opcional |
| `id_servicio` | text | FK → servicios.id, Opcional |
| `estado` | text | Obligatorio |
| `direccion` | text | Obligatorio, Default '' |
| `latitud` | double precision | Opcional |
| `longitud` | double precision | Opcional |
| `descripcion` | text | Opcional |
| `fecha_programada` | text | Opcional |
| `metadatos_servicio` | text | Opcional |
| `modalidad_cobro` | text | Opcional |
| `estado_pago` | text | Opcional |
| `id_comuna` | text | FK → comunas.id, Opcional. FK a comunas.id (slug). |
| `instantanea_precio` | text | Opcional |
| `id_sku_servicio` | text | Opcional |
| `horas_bloque` | integer | Opcional |
| `id_cotizacion_seleccionada` | text | FK → propuestas_cotizacion.id, Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

Restricciones CHECK: `trabajos_actualizado_en_iso_chk` CHECK (es_marca_tiempo_iso(actualizado_en)); `trabajos_coordenadas_chk` CHECK ((((latitud IS NULL) OR ((latitud >= ('-90'::integer)::double precision) AND (latitud <= (90)::double precision))) AND ((longitud IS NULL) OR ((longitud >= ('-180'::integer)::double precision) AND (longitud <= (180)::double precision))))); `trabajos_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `trabajos_estado_chk` CHECK ((estado = ANY (ARRAY['pendiente'::text, 'esperando_cotizaciones'::text, 'cotizacion_seleccionada'::text, 'esperando_pago'::text, 'aceptado'::text, 'en_camino'::text, 'en_curso'::text, 'pausado_orden_cambio'::text, 'esperando_aprobacion_cliente'::text, 'completado'::text, 'cancelado'::text, 'expirado'::text, 'no_asistio'::text]))); `trabajos_estado_pago_chk` CHECK (((estado_pago IS NULL) OR (estado_pago = ANY (ARRAY['ninguno'::text, 'pendiente'::text, 'autorizado'::text, 'retenido'::text, 'pagado_por_confirmar'::text, 'liberado'::text, 'reembolso_pendiente'::text, 'reembolsado'::text, 'reembolsado_auto'::text, 'anulado'::text, 'fallido'::text, 'rechazado'::text, 'expirado'::text, 'cancelado'::text])))); `trabajos_fecha_programada_iso_chk` CHECK (es_marca_tiempo_iso(fecha_programada)); `trabajos_horas_bloque_chk` CHECK (((horas_bloque IS NULL) OR ((horas_bloque >= 1) AND (horas_bloque <= 24)))); `trabajos_modalidad_cobro_chk` CHECK (((modalidad_cobro IS NULL) OR (modalidad_cobro = ANY (ARRAY['legado'::text, 'precio_fijo'::text, 'bloque_horas'::text, 'cotizacion_abierta'::text])))).

RLS activo. SELECT y UPDATE para el cliente, el profesional asignado o un administrador. El INSERT lo hace el cliente (o un admin) con reglas: sin cotización preseleccionada y con estado de pago inicial pendiente o ninguno. Varios triggers cuidan el PIN, la evidencia, la fecha (solo RPC) y la disponibilidad. Políticas: INSERT «trabajos_insert», SELECT «trabajos_select», UPDATE «trabajos_update».

**Forma normal: BCNF con una copia mantenida por trigger.** Cada columna describe el pedido. instantanea_precio es la foto del precio al pedir (dato histórico). Dato repetido a propósito: estado_pago copia el estado del pago principal (trigger copiar_estado_pago_trabajo) para filtrar listas sin unir con pagos. Diferencias: 0.

Relaciones: id_servicio apunta a servicios (si se borra la fila de servicios, la columna queda vacía y el registro se conserva); id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajador apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva); id_comuna apunta a comunas (si se borra la fila de comunas, la columna queda vacía y el registro se conserva); id_cotizacion_seleccionada apunta a propuestas_cotizacion (si se borra la fila de propuestas_cotizacion, la columna queda vacía y el registro se conserva).

### Tabla A-28. mensajes

Mensaje del chat de un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_remitente` | uuid | FK → perfiles.id, Obligatorio |
| `id_destinatario` | uuid | FK → perfiles.id, Obligatorio |
| `contenido` | text | Obligatorio |
| `tipo` | text | Obligatorio, Default 'texto' |
| `ruta_imagen` | text | Opcional |
| `leido` | integer | Obligatorio, Default 0 |
| `creado_en` | text | Obligatorio |

Restricciones CHECK: `mensajes_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `mensajes_leido_bool_chk` CHECK (((leido IS NULL) OR (leido = ANY (ARRAY[0, 1])))).

RLS activo. Solo las partes del chat (remitente o destinatario) o un administrador. Un trigger bloquea datos de contacto en el cuerpo. Políticas: INSERT «mensajes_insert», SELECT «mensajes_select», UPDATE «mensajes_update_leido».

**Forma normal: 2FN con desnormalización controlada.** Cada mensaje depende de su id. id_destinatario se puede deducir del trabajo y del remitente (el otro participante): es una dependencia transitiva, así que en rigor la tabla no llega a 3FN. Dato repetido a propósito: Se guarda id_destinatario para filtrar en tiempo real (Realtime) y en RLS sin unir con trabajos; lo valida la política de inserción. Diferencias verificadas: 0.

Relaciones: id_destinatario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_remitente apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### Tabla A-29. fotos_trabajo

Evidencia fotográfica o de video de un trabajo (bucket de evidencias).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `ruta_foto` | text | Obligatorio |
| `creado_en` | text | Obligatorio |
| `tipo_medio` | text | Obligatorio, Default 'foto'. photo or video evidence |
| `imagen_webp` | bytea | Opcional. Imagen de evidencia en WebP. Se guarda en la fila para no depender de archivos locales y ocupar menos espacio que JPEG/PNG. |

Restricciones CHECK: `fotos_trabajo_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `fotos_trabajo_tipo_medio_chk` CHECK ((tipo_medio = ANY (ARRAY['foto'::text, 'video'::text]))).

RLS activo. Las partes del trabajo o un administrador ven la evidencia. Hay reglas extra sobre el formato (p. ej. exigir webp/video). Políticas: ALL «fotos_trabajo_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### Tabla A-30. calificaciones

Valoración de un trabajo. Desde la calificación bidireccional admite direccion cliente_a_trabajador o trabajador_a_cliente, con unicidad por (id_trabajo, direccion). Alimenta trabajadores.calificacion.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Opcional |
| `puntaje` | integer | Obligatorio |
| `comentario` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `peso_confianza` | numeric(4,3) | Obligatorio, Default 1 |
| `estado_revision` | text | Obligatorio, Default 'vigente' |
| `motivo_revision` | text | Opcional |
| `direccion` | text | Obligatorio, Default 'cliente_a_trabajador' |
| `id_calificado` | uuid | FK → perfiles.id, Obligatorio |

Restricciones CHECK: `calificaciones_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `calificaciones_direccion_chk` CHECK ((direccion = ANY (ARRAY['cliente_a_trabajador'::text, 'trabajador_a_cliente'::text]))); `calificaciones_estado_revision_chk` CHECK ((estado_revision = ANY (ARRAY['vigente'::text, 'en_revision'::text, 'excluida'::text]))); `calificaciones_peso_confianza_chk` CHECK (((peso_confianza >= (0)::numeric) AND (peso_confianza <= (1)::numeric))); `calificaciones_puntaje_chk` CHECK (((puntaje >= 1) AND (puntaje <= 5))).

RLS activo. Se inserta una calificación propia, con direccion e id_calificado coherentes con el trabajo terminado. Se leen las de cliente_a_trabajador (públicas para el listado) y las propias o de un administrador. Políticas: INSERT «calificaciones_insert», SELECT «calificaciones_select».

**Forma normal: BCNF.** Claves candidatas: id y (id_trabajo, direccion). id_calificado depende de esa clave compuesta, por lo que la tabla cumple BCNF. Dato repetido a propósito: id_calificado repite a quién se calificó, dato que también se deduce de trabajos. Se guarda para filtrar reseñas por persona con índice y en RLS; lo fija la función que crea la reseña. Diferencias verificadas: 0.

Relaciones: id_calificado apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_usuario apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### Tabla A-31. calificaciones_cliente

El profesional nota al cliente. 1:1 con el trabajo. Alimenta perfiles.reputacion_cliente. puntaje es smallint en la base viva.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_cliente` | uuid | FK → perfiles.id, Obligatorio |
| `id_trabajador` | uuid | FK → perfiles.id, Obligatorio |
| `puntaje` | smallint | Obligatorio |
| `comentario` | text | Opcional |
| `creado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `calificaciones_cliente_puntaje_chk` CHECK (((puntaje >= 1) AND (puntaje <= 5))).

RLS activo. El profesional califica a su cliente en un trabajo 1:1; leen las partes o un administrador. Políticas: SELECT «calificaciones_cliente_select».

**Forma normal: BCNF.** Una calificación por trabajo; todas las columnas dependen del id. Dato repetido a propósito: id_trabajador también se deduce de trabajos; se guarda para RLS (el profesional ve lo que escribió). Diferencias: 0.

Relaciones: id_cliente apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### Tabla A-32. disputas

Disputa abierta sobre un trabajo y su resolución (incluye sugerencia automática y vencimiento).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `abierta_por` | uuid | FK → perfiles.id, Obligatorio |
| `motivo` | text | Obligatorio |
| `descripcion` | text | Opcional |
| `estado` | text | Obligatorio |
| `resolucion` | text | Opcional |
| `resuelta_por` | uuid | FK → perfiles.id, Opcional |
| `resuelta_en` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |
| `origen` | text | Obligatorio, Default 'admin' |
| `decision_sugerida` | text | Opcional |
| `motivo_regla` | text | Opcional |
| `vence_en` | timestamptz | Opcional |

Restricciones CHECK: `disputas_actualizado_en_iso_chk` CHECK (es_marca_tiempo_iso(actualizado_en)); `disputas_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `disputas_decision_chk` CHECK (((decision_sugerida IS NULL) OR (decision_sugerida = ANY (ARRAY['liberar'::text, 'reembolsar'::text, 'humano'::text])))); `disputas_origen_chk` CHECK ((origen = ANY (ARRAY['sistema'::text, 'acuerdo'::text, 'admin'::text]))); `disputas_resuelta_en_iso_chk` CHECK (es_marca_tiempo_iso(resuelta_en)).

RLS activo. Las partes del trabajo o un administrador leen la disputa. La apertura y los cambios de estado van por RPC. Políticas: INSERT «disputas_insert», SELECT «disputas_select», UPDATE «disputas_update».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: abierta_por apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); resuelta_por apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### Tabla A-33. disputa_mensajes

Mensajes del hilo de una disputa, de las partes o de soporte.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_disputa` | text | FK → disputas.id, Obligatorio |
| `id_autor` | uuid | FK → perfiles.id, Opcional |
| `cuerpo` | text | Obligatorio |
| `creado_en` | timestamptz | Obligatorio, Default now() |

RLS activo. Lectura para las partes del trabajo en disputa o un administrador. Los comentarios de soporte se insertan por RPC. Políticas: SELECT «disputa_mensajes_select».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_autor apunta a perfiles (no se puede borrar la fila de perfiles mientras tenga registros asociados); id_disputa apunta a disputas (si se borra la fila de disputas, también se borran las filas que la usan).

### Tabla A-34. acuerdos_trabajo

Acuerdo entre cliente y profesional para rehacer, aceptar o anular un trabajo. Como máximo un acuerdo pendiente por trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `tipo` | text | Obligatorio |
| `propuesto_por` | uuid | FK → perfiles.id, Obligatorio |
| `acepta_cliente` | boolean | Opcional |
| `acepta_trabajador` | boolean | Opcional |
| `estado` | text | Obligatorio, Default 'pendiente' |
| `creado_en` | timestamptz | Obligatorio, Default now() |
| `aplicado_en` | timestamptz | Opcional |

Restricciones CHECK: `acuerdos_estado_chk` CHECK ((estado = ANY (ARRAY['pendiente'::text, 'confirmado'::text, 'rechazado'::text, 'aplicado'::text]))); `acuerdos_tipo_chk` CHECK ((tipo = ANY (ARRAY['rehacer'::text, 'aceptar'::text, 'anular'::text]))).

RLS activo. Solo lectura para las partes del trabajo (es_parte_trabajo) o un administrador. El alta y la respuesta se hacen por RPC (proponer_acuerdo, responder_acuerdo). Políticas: SELECT «acuerdos_trabajo_select».

**Forma normal: BCNF.** Cada acuerdo depende solo de su id; el índice único parcial impide dos acuerdos pendientes en el mismo trabajo.

Relaciones: id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan); propuesto_por apunta a perfiles (no se puede borrar la fila de perfiles mientras tenga registros asociados).

### Tabla A-35. cancelaciones_trabajo

Como máximo una cancelación por trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `cancelado_por` | uuid | FK → perfiles.id, Obligatorio |
| `motivo` | text | Obligatorio |
| `cancelado_en` | text | Obligatorio |

Restricciones CHECK: `cancelaciones_trabajo_cancelado_en_iso_chk` CHECK (es_marca_tiempo_iso(cancelado_en)).

RLS activo. Las partes del trabajo o un administrador leen la cancelación; se inserta según las reglas del flujo de cancelar. Políticas: ALL «cancelaciones_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: cancelado_por apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### Tabla A-36. tickets_soporte

Ticket de soporte asociado a un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio, Default (gen_random_uuid())::text |
| `id_trabajo` | text | FK → trabajos.id, Opcional |
| `nombre_cliente` | text | Obligatorio |
| `nombre_trabajador` | text | Obligatorio |
| `asunto` | text | Obligatorio |
| `monto_escrow` | integer | Obligatorio |
| `estado` | text | Opcional, Default 'Pending' |
| `creado_en` | timestamptz | Opcional, Default now() |

Restricciones CHECK: `tickets_monto_escrow_chk` CHECK ((monto_escrow >= 0)); `tickets_status_check` CHECK ((estado = ANY (ARRAY['Pending'::text, 'Resolved'::text]))).

RLS activo. Las partes del trabajo o un administrador ven el ticket. Políticas: ALL «tickets_soporte_all».

**Forma normal: 2FN con desnormalización controlada.** Cada ticket depende de su id. Los nombres y el monto se pueden deducir del trabajo (dependencia transitiva id → id_trabajo → nombre). Dato repetido a propósito: nombre_cliente, nombre_trabajador y monto_escrow son la foto del caso al abrir el ticket (trigger fijar_ticket_desde_trabajo), para que la consola de soporte no cambie si después cambia el perfil o el pago.

Relaciones: id_trabajo apunta a trabajos (si se borra la fila de trabajos, la columna queda vacía y el registro se conserva).

### Tabla A-37. ubicacion_en_vivo

GPS en vivo durante el trabajo. 1:1 con el trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_trabajo` | text | PK, FK → trabajos.id, Obligatorio |
| `id_trabajador` | uuid | FK → trabajadores.id_usuario, Obligatorio |
| `latitud` | double precision | Obligatorio |
| `longitud` | double precision | Obligatorio |
| `precision_metros` | double precision | Opcional |
| `actualizado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `ubicacion_lat_chk` CHECK (((latitud >= ('-90'::integer)::double precision) AND (latitud <= (90)::double precision))); `ubicacion_lng_chk` CHECK (((longitud >= ('-180'::integer)::double precision) AND (longitud <= (180)::double precision))).

RLS activo. El cliente del trabajo o un administrador leen la posición. El profesional la publica por RPC publicar_ubicacion_trabajo. Un trigger borra el GPS al cerrar el trabajo. Políticas: SELECT «ubicacion_select_cliente_admin».

**Forma normal: BCNF.** Extensión 1:1 de trabajos (clave id_trabajo). Dato repetido a propósito: id_trabajador repite el profesional del trabajo para autorizar la publicación en tiempo real. Diferencias: 0.

Relaciones: id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan); id_trabajador apunta a trabajadores (si se borra la fila de trabajadores, también se borran las filas que la usan).

### Tabla A-38. reprogramaciones_trabajo

Historial de propuestas para reagendar un trabajo (CU-33). Como máximo una propuesta pendiente por trabajo. Solo se escribe por las RPC proponer_reprogramacion, responder_reprogramacion y retirar_reprogramacion.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | uuid | PK, Obligatorio, Default gen_random_uuid() |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `propuesta_por` | uuid | FK → perfiles.id, Obligatorio |
| `rol_proponente` | text | Obligatorio |
| `fecha_anterior` | timestamptz | Obligatorio |
| `fecha_propuesta` | timestamptz | Obligatorio |
| `motivo` | text | Opcional |
| `estado` | text | Obligatorio, Default 'pendiente' |
| `respondida_por` | uuid | FK → perfiles.id, Opcional |
| `respondida_en` | timestamptz | Opcional |
| `creado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `reprogramaciones_trabajo_check` CHECK ((fecha_propuesta <> fecha_anterior)); `reprogramaciones_trabajo_estado_check` CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'retirada'::text, 'vencida'::text]))); `reprogramaciones_trabajo_motivo_check` CHECK (((motivo IS NULL) OR (char_length(motivo) <= 300))); `reprogramaciones_trabajo_rol_proponente_check` CHECK ((rol_proponente = ANY (ARRAY['cliente'::text, 'profesional'::text]))).

RLS activo. SELECT para las partes del trabajo. El alta, la respuesta y el retiro se hacen solo por RPC (CU-33). Políticas: SELECT «reprogramaciones_select».

**Forma normal: BCNF.** fecha_anterior es la fecha que tenía el trabajo antes de la propuesta: dato histórico de la solicitud.

Relaciones: propuesta_por apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); respondida_por apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### Tabla A-39. pines_inicio_trabajo

PIN que el cliente muestra al profesional para iniciar el trabajo (aceptado o en_camino → en_curso). El cliente (o un administrador) puede leerlo; el profesional lo valida con intentar_pin_inicio o transicionar_trabajo. Lo crea el trigger trabajos_crear_pin_inicio.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_trabajo` | text | PK, FK → trabajos.id, Obligatorio |
| `pin` | text | Obligatorio |
| `creado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `pines_inicio_trabajo_pin_check` CHECK ((pin ~ '^[0-9]{4}$'::text)).

RLS activo. SELECT para el cliente dueño del trabajo o un administrador (obtener_pin_inicio). El profesional no lee el PIN: lo valida por RPC. La inserción la hace el trigger trabajos_crear_pin_inicio. Políticas: SELECT «pines_inicio_select_cliente».

**Forma normal: BCNF.** Extensión 1:1 de trabajos con el PIN de inicio.

Relaciones: id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### Tabla A-40. bloqueos_pin_inicio

Contador de intentos fallidos del PIN, bloqueo temporal (15 minutos tras 5 fallos) y ventana en la que el PIN ya fue validado. Escriben solo las funciones SECURITY DEFINER o service_role; un administrador puede leerla.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_trabajo` | text | PK, FK → trabajos.id, Obligatorio |
| `fallos` | integer | Obligatorio, Default 0 |
| `bloqueado_hasta` | timestamptz | Opcional |
| `pin_ok_hasta` | timestamptz | Opcional |
| `pin_ok_usuario` | uuid | Opcional |
| `actualizado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `bloqueos_pin_inicio_fallos_check` CHECK ((fallos >= 0)).

RLS activo. Solo un administrador puede leer (política agregada en la auditoría 2026-11-16). Nadie escribe por la API; lo hacen funciones SECURITY DEFINER (intentar_pin_inicio, transicionar_trabajo) o service_role. Políticas: SELECT «bloqueos_pin_inicio_admin_select».

**Forma normal: BCNF.** Extensión 1:1 de trabajos (la clave es id_trabajo). Guarda el contador de PIN fallidos de ese trabajo.

Relaciones: id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### Tabla A-41. intentos_pin_inicio

Auditoría de cada intento de PIN de inicio. Escriben solo funciones SECURITY DEFINER; un administrador puede leerla.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | bigint | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Opcional |
| `resultado` | text | Obligatorio |
| `intentos_restantes` | integer | Obligatorio |
| `creado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `intentos_pin_inicio_resultado_check` CHECK ((resultado = ANY (ARRAY['correcto'::text, 'incorrecto'::text, 'bloqueado'::text]))).

RLS activo. Solo un administrador puede leer la bitácora (política agregada en la auditoría 2026-11-16). La escritura la hacen funciones SECURITY DEFINER. Políticas: SELECT «intentos_pin_inicio_admin_select».

**Forma normal: BCNF.** Bitácora de intentos de PIN; cada fila es un intento.

Relaciones: id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan); id_usuario apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva).

## Cobro

### Tabla A-42. propuestas_cotizacion

Cotización que un profesional envía para un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_trabajador` | uuid | FK → perfiles.id, Obligatorio |
| `monto_total_clp` | integer | Obligatorio |
| `descripcion` | text | Obligatorio |
| `validez_hasta` | text | Opcional |
| `desglose` | text | Opcional |
| `estado` | text | Obligatorio |
| `creado_en` | text | Obligatorio |

Restricciones CHECK: `propuestas_cotizacion_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `propuestas_cotizacion_validez_hasta_iso_chk` CHECK (es_marca_tiempo_iso(validez_hasta)); `propuestas_monto_chk` CHECK ((monto_total_clp > 0)).

RLS activo. El cliente del trabajo, el profesional autor o un administrador leen la cotización. El monto no lo cambia el cliente (trigger). Políticas: INSERT «propuestas_insert», SELECT «propuestas_select», UPDATE «propuestas_update».

**Forma normal: BCNF.** desglose es el detalle de la cotización como un documento; el total vive en monto_total_clp.

Relaciones: id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan); id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-43. pagos

Cobro asociado a un trabajo o a una orden de cambio, con retención (escrow) vía Transbank Webpay / Oneclick. Las columnas alta_nonce_hash, alta_jti y alta_consumido_en sustentan el alta del invitado después del pago: el nonce solo lo tiene el navegador y el jti es de un solo uso. El default de tipo_pago es 'primary' (inglés legado); el índice de un solo pago principal activo busca el valor 'principal'.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_orden_cambio` | text | FK → ordenes_cambio.id, Opcional |
| `tipo_pago` | text | Obligatorio, Default 'principal' |
| `monto` | numeric(12,0) | Obligatorio |
| `moneda` | text | Obligatorio, Default 'CLP' |
| `estado` | text | Obligatorio |
| `metodo_pago` | text | Opcional |
| `id_transaccion` | text | Opcional |
| `autorizado_en` | text | Opcional |
| `liberado_en` | text | Opcional |
| `reembolsado_en` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |
| `ambiente` | text | Opcional. integration \| production |
| `token_tbk` | text | Opcional. token_ws de Webpay Plus. No guardar aquí la orden Oneclick. |
| `url_tbk` | text | Opcional. URL TBK — solo service_role / Edge Functions |
| `buy_order` | text | Opcional. buy_order Webpay |
| `handoff_consumido_en` | timestamptz | Opcional |
| `reembolso_solicitado_en` | timestamptz | Opcional. Marca que ya se pidió la devolución a Transbank. Un reintento no vuelve a llamar a la tarjeta. |
| `orden_detalle_oneclick` | text | Opcional. buy_order de detalle de Oneclick Mall, para el reembolso. |
| `cobro_reclamado_en` | timestamptz | Opcional. Marca exclusiva de una autorización Oneclick en curso. |
| `origen_retorno` | text | Opcional. Origen del navegador ya contrastado con la allowlist. webpay-commit redirige ahí. |
| `alta_nonce_hash` | text | Opcional. SHA-256 del nonce que solo tiene el navegador del invitado. |
| `alta_jti` | text | Opcional. Identificador de un solo uso del enlace para crear la contraseña. |
| `alta_consumido_en` | timestamptz | Opcional. Cuándo se usó el enlace. Un segundo intento no sirve. |

Restricciones CHECK: `pagos_actualizado_en_iso_chk` CHECK (es_marca_tiempo_iso(actualizado_en)); `pagos_ambiente_chk` CHECK (((ambiente IS NULL) OR (ambiente = ANY (ARRAY['integration'::text, 'production'::text])))); `pagos_autorizado_en_iso_chk` CHECK (es_marca_tiempo_iso(autorizado_en)); `pagos_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `pagos_estado_chk` CHECK ((estado = ANY (ARRAY['pendiente'::text, 'autorizado'::text, 'retenido'::text, 'pagado_por_confirmar'::text, 'liberado'::text, 'reembolso_pendiente'::text, 'reembolsado'::text, 'reembolsado_auto'::text, 'anulado'::text, 'fallido'::text, 'rechazado'::text, 'expirado'::text, 'cancelado'::text]))); `pagos_liberado_en_iso_chk` CHECK (es_marca_tiempo_iso(liberado_en)); `pagos_metodo_pago_chk` CHECK (((metodo_pago IS NULL) OR (metodo_pago = ANY (ARRAY['webpay'::text, 'oneclick'::text])))); `pagos_moneda_chk` CHECK ((moneda = 'CLP'::text)); `pagos_monto_chk` CHECK ((monto >= (0)::numeric)); `pagos_reembolsado_en_iso_chk` CHECK (es_marca_tiempo_iso(reembolsado_en)); `pagos_tipo_pago_chk` CHECK ((tipo_pago = ANY (ARRAY['principal'::text, 'orden_cambio'::text]))).

RLS activo. El cliente dueño del trabajo, el profesional asignado o un administrador pueden leer el pago. Tokens, URL de Webpay y datos de alta de invitado no se exponen al cliente (columnas acotadas o solo service_role en la práctica de las Edge Functions). La creación de la intención de pago es por RPC. Políticas: SELECT «pagos_select».

**Forma normal: BCNF.** Muchas columnas, pero todas describen el mismo cobro (montos, estado, datos de Transbank, alta de invitado). No hay columnas que dependan de otra que no sea clave.

Relaciones: id_orden_cambio apunta a ordenes_cambio (si se borra la fila de ordenes_cambio, la columna queda vacía y el registro se conserva); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### Tabla A-44. ordenes_cambio

Cambio de alcance o de precio durante un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_trabajador` | uuid | FK → perfiles.id, Obligatorio |
| `tipo` | text | Obligatorio |
| `titulo` | text | Obligatorio |
| `descripcion` | text | Obligatorio |
| `monto_clp` | integer | Obligatorio |
| `estado` | text | Obligatorio, Default 'pendiente_cliente' |
| `id_pago` | text | FK → pagos.id, Opcional |
| `creado_en` | text | Obligatorio |
| `respondido_en` | text | Opcional |

Restricciones CHECK: `ordenes_cambio_creado_en_iso_chk` CHECK (es_marca_tiempo_iso(creado_en)); `ordenes_cambio_monto_chk` CHECK ((monto_clp >= 0)); `ordenes_cambio_respondido_en_iso_chk` CHECK (es_marca_tiempo_iso(respondido_en)).

RLS activo. Las partes del trabajo o un administrador leen y proponen según el flujo; el cobro asociado va por RPC de pago. Políticas: ALL «ordenes_cambio_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan); id_pago apunta a pagos (si se borra la fila de pagos, la columna queda vacía y el registro se conserva); id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-45. liquidaciones

Un pago → una liquidación al profesional. manual = transferencia externa confirmada por admin; khipu/fintoc = PSP futuro.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio, Default (gen_random_uuid())::text |
| `id_pago` | text | FK → pagos.id, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_trabajador` | text | Opcional |
| `monto_clp` | numeric | Obligatorio |
| `proveedor` | text | Obligatorio, Default 'manual' |
| `referencia_transferencia` | text | Obligatorio |
| `notas` | text | Opcional |
| `id_operador` | text | Obligatorio |
| `creado_en` | timestamptz | Obligatorio, Default now() |
| `estado_transferencia` | text | Obligatorio, Default 'transferido' |

Restricciones CHECK: `liquidaciones_estado_transferencia_chk` CHECK ((estado_transferencia = ANY (ARRAY['pendiente'::text, 'transferido'::text, 'fallido'::text]))); `liquidaciones_id_trabajador_uuid_chk` CHECK (((id_trabajador IS NULL) OR (id_trabajador ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'::text))); `liquidaciones_monto_clp_check` CHECK ((monto_clp > (0)::numeric)); `liquidaciones_proveedor_check` CHECK ((proveedor = ANY (ARRAY['manual'::text, 'khipu'::text, 'fintoc'::text, 'conformidad'::text]))).

RLS activo. El profesional ve la liquidación de sus pagos; un administrador ve todas. La confirmación de transferencia es por RPC de admin. Políticas: DELETE «liquidaciones_admin_delete», INSERT «liquidaciones_admin_insert», UPDATE «liquidaciones_admin_update», SELECT «liquidaciones_select».

**Forma normal: BCNF.** id_pago es único (clave candidata) y determina el trabajo y el profesional, así que la tabla cumple BCNF. Dato repetido a propósito: id_trabajo e id_trabajador repiten datos del pago y del trabajo. Es un libro contable: debe conservar a quién se pagó aunque el trabajo cambie. Diferencias: 0.

Relaciones: id_pago apunta a pagos (no se puede borrar la fila de pagos mientras tenga registros asociados); id_trabajo apunta a trabajos (no se puede borrar la fila de trabajos mientras tenga registros asociados).

### Tabla A-46. metodos_pago_oneclick

Tarjeta inscrita Oneclick. RLS niega el acceso a anon y authenticated: solo service_role (Edge Functions).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_usuario` | uuid | PK, FK → perfiles.id, Obligatorio |
| `username` | text | Obligatorio |
| `tbk_user` | text | Opcional |
| `tipo_tarjeta` | text | Opcional |
| `ultimos4` | text | Opcional |
| `estado` | text | Obligatorio, Default 'pendiente' |
| `token_inscripcion` | text | Opcional |
| `id_trabajo_pendiente` | text | Opcional |
| `creado_en` | timestamptz | Obligatorio, Default now() |
| `actualizado_en` | timestamptz | Obligatorio, Default now() |
| `url_inscripcion` | text | Opcional |
| `ticket_handoff` | text | Opcional |

Restricciones CHECK: `metodos_pago_oneclick_estado_chk` CHECK ((estado = ANY (ARRAY['pendiente'::text, 'activa'::text, 'rechazada'::text]))).

RLS activo. Política ALL con USING/CHECK false para anon y authenticated. Las tarjetas solo las maneja service_role (Edge Functions). Políticas: ALL «metodos_pago_oneclick_sin_acceso_cliente».

**Forma normal: BCNF.** Extensión 1:1 del perfil (una tarjeta OneClick por usuario). Desde la auditoría id_usuario es uuid con clave foránea a perfiles.

Relaciones: id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-47. cuentas_bancarias

Datos bancarios del profesional para pagar la liquidación. RLS: solo el dueño y un administrador. No es un dato público.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_usuario` | uuid | PK, FK → perfiles.id, Obligatorio |
| `banco` | text | Obligatorio |
| `tipo_cuenta` | text | Obligatorio |
| `numero_cuenta` | text | Obligatorio |
| `rut_titular` | text | Obligatorio |
| `nombre_titular` | text | Obligatorio |
| `actualizado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `cuentas_bancarias_numero_chk` CHECK ((numero_cuenta ~ '^[0-9]{4,20}$'::text)); `cuentas_bancarias_tipo_chk` CHECK ((tipo_cuenta = ANY (ARRAY['vista'::text, 'corriente'::text, 'rut'::text, 'ahorro'::text]))).

RLS activo. ALL para el dueño o un administrador. No es un dato público. Políticas: ALL «cuentas_bancarias_propietario».

**Forma normal: BCNF.** Extensión 1:1 del perfil (la clave es id_usuario).

Relaciones: id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### Tabla A-48. app_config

Pares clave/valor de configuración (demo_modo, admin_requiere_aal2, etc.). RLS niega el acceso a clientes; lo lee el backend.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `clave` | text | PK, Obligatorio |
| `valor` | text | Obligatorio |
| `actualizado_en` | timestamptz | Obligatorio, Default now() |

RLS activo. Política ALL con USING/CHECK false para anon y authenticated. Nadie del cliente lee ni escribe; solo service_role (bypass RLS) o funciones definer. Políticas: ALL «app_config_sin_acceso_cliente».

**Forma normal: BCNF.** Tabla clave-valor: la clave determina el valor y nada más.

## Ranking y reputación

### Tabla A-49. ranking_config

Una fila default. Pesos del listado de profesionales.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio, Default 'default' |
| `peso_calificacion` | numeric | Obligatorio, Default 0.32 |
| `peso_completados` | numeric | Obligatorio, Default 0.18 |
| `peso_rechazos` | numeric | Obligatorio, Default 0.12 |
| `peso_verificacion` | numeric | Obligatorio, Default 0.10 |
| `peso_impulso` | numeric | Obligatorio, Default 0.08 |
| `peso_recencia` | numeric | Obligatorio, Default 0.08 |
| `peso_confianza` | numeric | Obligatorio, Default 0.12 |
| `prior_bayes` | numeric | Obligatorio, Default 3.80 |
| `n_bayes` | numeric | Obligatorio, Default 8 |
| `umbral_revision` | numeric | Obligatorio, Default 0.55 |
| `umbral_auto_excluir` | numeric | Obligatorio, Default 0.90 |
| `aprendizaje_activo` | integer | Obligatorio, Default 1 |
| `tasa_aprendizaje` | numeric | Obligatorio, Default 0.15 |
| `pesos_senal` | jsonb | Obligatorio, Default '{"rafaga": 0.45, "outlier": 0.22, "auto_resena": 1.00, "cuenta_nueva": 0.25, "duplicado_texto": 0.40, "sin_trabajo_valido": 0.95, "texto_vacio_extremo": 0.20, "granja_cinco_estrellas": 0.50}' |
| `actualizado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `ranking_config_aprendizaje_activo_bool_chk` CHECK (((aprendizaje_activo IS NULL) OR (aprendizaje_activo = ANY (ARRAY[0, 1])))); `ranking_config_unica` CHECK ((id = 'default'::text)).

RLS activo. La lectura de la fila default está permitida a autenticados (para el listado). Solo un administrador la actualiza por RPC. Políticas: ALL «ranking_config_admin».

**Forma normal: BCNF.** Una sola fila de configuración del ranking.

### Tabla A-50. senales_resena

Señales de reseña dudosa. Un falso positivo baja el peso de esa señal.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_calificacion` | text | FK → calificaciones.id, Obligatorio |
| `tipo_senal` | text | Obligatorio |
| `puntaje` | numeric | Obligatorio |
| `detalle` | text | Opcional |
| `estado` | text | Obligatorio, Default 'pendiente' |
| `resuelto_por` | uuid | FK → perfiles.id, Opcional |
| `resuelto_en` | timestamptz | Opcional |
| `creado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `senales_resena_estado_chk` CHECK ((estado = ANY (ARRAY['pendiente'::text, 'fraude_confirmado'::text, 'falso_positivo'::text, 'descartada'::text]))).

RLS activo. Cola de reseñas dudosas: la ve y resuelve un administrador. Políticas: SELECT «senales_resena_admin».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

Relaciones: id_calificacion apunta a calificaciones (si se borra la fila de calificaciones, también se borran las filas que la usan); resuelto_por apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva).

### Tabla A-51. ranking_aprendizaje

Ajuste de los pesos del ranking y las métricas de ese cambio.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `motivo` | text | Obligatorio |
| `pesos_antes` | jsonb | Obligatorio |
| `pesos_despues` | jsonb | Obligatorio |
| `metricas` | jsonb | Opcional |
| `creado_en` | timestamptz | Obligatorio, Default now() |

RLS activo. Lectura de administración. La escritura la hace el aprendizaje de pesos. Políticas: SELECT «ranking_aprendizaje_admin».

**Forma normal: BCNF.** Bitácora: pesos antes y después de cada ajuste.

### Tabla A-52. eventos_ranking

Evento que alimenta el ranking de un profesional.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajador` | uuid | FK → perfiles.id, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Opcional |
| `tipo_evento` | text | Obligatorio |
| `factores` | jsonb | Obligatorio, Default '{}' |
| `creado_en` | timestamptz | Obligatorio, Default now() |

RLS activo. Lectura de administración; la escritura la hacen triggers y funciones definer. Políticas: SELECT «eventos_ranking_select_admin».

**Forma normal: BCNF.** Registro de eventos; factores es la foto de los factores al momento del evento.

Relaciones: id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajo apunta a trabajos (si se borra la fila de trabajos, la columna queda vacía y el registro se conserva).

## Funciones relevantes

La API de la aplicación no escribe en varias de estas tablas de forma directa: el reagendamiento (CU-33), el PIN de inicio, el escrow Webpay, el alta de invitado y la consola de soporte/qa se exponen como funciones SECURITY DEFINER. El detalle (nombre, argumentos y propósito) está en el diccionario `MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md`, sección 6.

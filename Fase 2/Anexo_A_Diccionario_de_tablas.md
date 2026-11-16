# Anexo A. Diccionario de datos

A continuación se describe cada una de las 52 tablas del esquema public, alineadas a la base viva de Supabase (`wxqrfcqifkfgawrnqmnj`) al 2026-11-16 (America/Santiago), migración `20261115234447` (catalogo_plomeria_gasfiteria_distintos). Los atributos se listan con su tipo de dato y su restricción. PK indica la clave primaria y FK la clave foránea. perfiles.id coincide con el identificador de autenticación de Supabase (auth.users.id). No hay tipos ENUM ni vistas en public; los conjuntos cerrados se restringen con CHECK.

Fuente: elaboración propia a partir del esquema real (modelo entidad-relación v2.4).

Respecto del anexo v2.3 (43 tablas, 2026-11-08) se agregan nueve tablas: acuerdos_trabajo, disputa_mensajes, reprogramaciones_trabajo (CU-33), pines_inicio_trabajo, bloqueos_pin_inicio, intentos_pin_inicio, cuentas_bancarias, dispositivos_push y verificacion_eventos. También se documentan los roles de consola soporte y qa, el alta de invitado (columnas de pagos) y los cambios de calificación bidireccional, horarios semanales y soporte automático de disputas.

## Identidad y cuenta

### Tabla A-1. perfiles

Identidad de la aplicación: perfiles.id coincide con auth.users.id (esquema auth de Supabase, fuera de public). El default de rol es 'user' y el de estado_cuenta es 'active' (valores en inglés de las primeras migraciones). En la práctica también se usan valores en español: usuario, trabajador, administrador, soporte y qa; activo, suspendido, bloqueado y eliminado. is_admin() reconoce 'admin' y 'administrador'. Los roles privilegiados (administrador, soporte, qa) no se pueden autoasignar: el trigger perfiles_rol_inicial_seguro y protect_profile_sensitive_fields lo impiden. reputacion_cliente la actualiza el trigger al calificar al cliente.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | uuid | PK, Obligatorio, Default gen_random_uuid() |
| `nombre` | text | Obligatorio, Default '' |
| `correo` | text | Opcional |
| `rol` | text | Obligatorio, Default 'user'. usuario \| trabajador \| administrador |
| `estado_cuenta` | text | Obligatorio, Default 'active'. activo \| suspendido \| bloqueado \| eliminado |
| `ruta_foto_perfil` | text | Opcional |
| `creado_en` | text | Obligatorio, Default to_char((now() AT TIME ZONE 'utc'::text), 'YYYY-MM-DD"T"HH24:MI:SS.US'::text) |
| `reputacion_cliente` | numeric(3,2) | Opcional |
| `calificaciones_cliente` | integer | Obligatorio, Default 0 |

Restricciones CHECK: `perfiles_reputacion_cliente_chk` CHECK (((reputacion_cliente IS NULL) OR ((reputacion_cliente >= (1)::numeric) AND (reputacion_cliente <= (5)::numeric)))).

RLS activo. El usuario lee su ficha y, con límites, fichas públicas (nombre y foto) de otros; no ve correo ajeno por esta vía. La escritura de campos sensibles (rol, estado_cuenta) está protegida por trigger. El contacto completo solo se entrega con perfil_contacto_si_trabajo_activo. Políticas: INSERT «perfiles_insert», SELECT «perfiles_select», UPDATE «perfiles_update».

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

RLS activo. El usuario lee y marca las suyas. Políticas: ALL «notificaciones_all», INSERT «notificaciones_insert_participantes».

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

RLS activo. El usuario ve su plan; la escritura la hace el backend de cobro. Políticas: ALL «suscripciones_all».

### Tabla A-4. codigos_restablecimiento

Código temporal para restablecer la contraseña.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | Obligatorio |
| `codigo` | text | Obligatorio |
| `correo` | text | Obligatorio |
| `expira_en` | text | Obligatorio |
| `usado` | integer | Opcional, Default 0 |
| `creado_en` | text | Obligatorio |

RLS activo. Acceso acotado al dueño o al backend; no es un dato de catálogo. Políticas: ALL «codigos_reset_all».

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

RLS activo. El usuario ve y registra sus propios consentimientos. Políticas: ALL «consentimientos_all».

### Tabla A-6. bloqueos_usuario

Bloqueo de un usuario hacia otro.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_bloqueador` | uuid | Obligatorio |
| `id_bloqueado` | uuid | Obligatorio |
| `creado_en` | text | Obligatorio |

RLS activo. El usuario ve los bloqueos en los que participa; solo él (o un administrador) puede crearlos. Políticas: ALL «bloqueos_all».

### Tabla A-7. reportes

Denuncia de un usuario contra otro.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_reportante` | uuid | Obligatorio |
| `id_usuario_reportado` | uuid | Obligatorio |
| `motivo` | text | Obligatorio |
| `descripcion` | text | Opcional |
| `estado` | text | Obligatorio, Default 'pending' |
| `creado_en` | text | Obligatorio |

RLS activo. El reportante ve los suyos; un administrador gestiona la cola. Políticas: ALL «reportes_all».

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

RLS activo. Restringido a administración o al backend de moderación. Políticas: ALL «eventos_abuso_all».

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

RLS activo. El dueño ve y gestiona sus propias acciones pendientes; un administrador ve todas. Políticas: ALL «acciones_pendientes_all».

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
| `estado` | text | Obligatorio, Default 'new' |
| `version_app` | text | Opcional |
| `plataforma` | text | Opcional |
| `creado_en` | text | Obligatorio, Default to_char((now() AT TIME ZONE 'utc'::text), 'YYYY-MM-DD"T"HH24:MI:SS.US'::text) |

RLS activo. El cliente informa sus propios errores; un administrador puede revisarlos. Políticas: INSERT «registros_error_app_insert», SELECT «registros_error_app_select», UPDATE «registros_error_app_update_admin».

### Tabla A-11. eventos_analitica

Evento de uso registrado por la aplicación.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `nombre_evento` | text | Obligatorio |
| `id_usuario` | uuid | Opcional |
| `rol` | text | Opcional |
| `marca_tiempo` | text | Obligatorio |
| `metadatos` | text | Opcional |

RLS activo. El usuario o el backend registra eventos de uso; no es un listado público. Políticas: INSERT «analitica_insert», SELECT «analitica_select».

### Tabla A-12. banderas_funcionalidad

Interruptor de una función por versión, rol o usuario.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `nombre_bandera` | text | Obligatorio |
| `habilitada` | integer | Obligatorio, Default 0 |
| `version_app` | text | Opcional |
| `rol` | text | Opcional |
| `id_usuario` | uuid | Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

RLS activo. Lectura restringida a banderas activas aplicables al usuario, o a un administrador. Políticas: SELECT «banderas_select», ALL «banderas_write».

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

### Tabla A-14. verificacion_eventos

Historial de cambios del estado de verificación de un profesional (pendiente, en revisión, verificado, rechazado).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | uuid | PK, Obligatorio, Default gen_random_uuid() |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `estado` | text | Obligatorio |
| `nota` | text | Opcional |
| `id_actor` | uuid | Opcional |
| `creado_en` | timestamptz | Obligatorio, Default now() |

RLS activo. El profesional ve su propio historial; un administrador ve todos. La escritura la hace el trigger al cambiar el estado de verificación. Políticas: SELECT «verificacion_eventos_select».

## Territorio

### Tabla A-15. paises

País operativo. Hoy solo CL.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `nombre` | text | Obligatorio |
| `iso2` | text | Obligatorio |

RLS activo. Lectura pública del catálogo. Hoy solo CL. Políticas: ALL «paises_admin_write», SELECT «paises_select».

### Tabla A-16. regiones

Región administrativa de un país.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_pais` | text | FK → paises.id, Obligatorio |
| `nombre` | text | Obligatorio |
| `codigo_oficial` | text | Opcional |

RLS activo. Lectura pública del catálogo geográfico. Políticas: ALL «regiones_admin_write», SELECT «regiones_select».

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

Restricciones CHECK: `comunas_lat_chk` CHECK (((latitud IS NULL) OR ((latitud >= ('-90'::integer)::double precision) AND (latitud <= (90)::double precision)))); `comunas_lng_chk` CHECK (((longitud IS NULL) OR ((longitud >= ('-180'::integer)::double precision) AND (longitud <= (180)::double precision)))).

RLS activo. Lectura pública del catálogo geográfico (comunas activas). La escritura es de administración o servicio. Políticas: ALL «comunas_admin_write», SELECT «comunas_select».

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

Restricciones CHECK: `trabajadores_base_lat_chk` CHECK (((latitud_base IS NULL) OR ((latitud_base >= ('-90'::integer)::double precision) AND (latitud_base <= (90)::double precision)))); `trabajadores_base_lng_chk` CHECK (((longitud_base IS NULL) OR ((longitud_base >= ('-180'::integer)::double precision) AND (longitud_base <= (180)::double precision)))); `trabajadores_estado_verificacion_check` CHECK ((estado_verificacion = ANY (ARRAY['pendiente'::text, 'en_revision'::text, 'verificado'::text, 'rechazado'::text]))); `trabajadores_origen_base_chk` CHECK (((origen_base IS NULL) OR (origen_base = ANY (ARRAY['mapa'::text, 'comuna'::text])))); `trabajadores_prioridad_manual_chk` CHECK (((prioridad_manual >= '-50'::integer) AND (prioridad_manual <= 50))); `trabajadores_radio_chk` CHECK (((radio_servicio_km >= (1)::numeric) AND (radio_servicio_km <= (80)::numeric))); `trabajadores_radio_urbano_chk` CHECK (((radio_urbano_km >= (1)::numeric) AND (radio_urbano_km <= (40)::numeric))); `trabajadores_tarifa_fuera_radio_chk` CHECK (((tarifa_fuera_radio_clp >= 0) AND (tarifa_fuera_radio_clp <= 200000))).

RLS activo. El listado público solo muestra fichas disponibles con precios configurados. El dueño, un administrador o el cliente con un trabajo conjunto también pueden leer la ficha. El UPDATE es del dueño o de un administrador; campos como verificación, score y pausa están protegidos por trigger. Políticas: INSERT «trabajadores_insert», SELECT «trabajadores_select_authenticated», UPDATE «trabajadores_update».

### Tabla A-19. trabajador_precios

Precio por código de servicio del profesional. En la base viva id_usuario es text (cast del uuid de trabajadores.id_usuario); no hay clave foránea física.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_usuario` | text | PK, Obligatorio |
| `codigo` | text | PK, Obligatorio |
| `monto_clp` | numeric(12,0) | Obligatorio |

Restricciones CHECK: `trabajador_precios_monto_clp_check` CHECK ((monto_clp >= (0)::numeric)).

RLS activo. El dueño y el catálogo (según política de precios) leen los montos ya publicados; la escritura es del dueño o de un trigger que parte el JSON. Políticas: ALL «trabajador_precios_propio».

### Tabla A-20. trabajador_servicios_extra

Servicio adicional definido por el profesional. id_usuario es text en la base viva, igual que en trabajador_precios.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | text | PK, Obligatorio |
| `titulo` | text | Obligatorio |
| `subtitulo` | text | Obligatorio, Default '' |
| `monto_clp` | numeric(12,0) | Obligatorio |
| `unidad` | text | Obligatorio, Default 'fijo' |

Restricciones CHECK: `trabajador_servicios_extra_monto_clp_check` CHECK ((monto_clp >= (0)::numeric)); `trabajador_servicios_extra_unidad_check` CHECK ((unidad = ANY (ARRAY['fijo'::text, 'por_m2'::text]))).

RLS activo. Servicios extra del profesional; misma idea que los precios. Políticas: ALL «trabajador_servicios_extra_propio».

### Tabla A-21. trabajador_servicios

Oficios del catálogo que el profesional declara atender.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_trabajador` | uuid | PK, FK → perfiles.id, Obligatorio |
| `categoria_servicio` | text | PK, Obligatorio |

RLS activo. Oficios declarados: lectura de catálogo y escritura del dueño. Políticas: SELECT «trabajador_servicios_select», ALL «trabajador_servicios_write».

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

### Tabla A-23. portafolio_trabajador

Foto o medio del portafolio de un profesional.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajador` | uuid | FK → perfiles.id, Obligatorio |
| `ruta_foto` | text | Obligatorio |
| `descripcion` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `tipo_medio` | text | Opcional, Default 'photo' |

RLS activo. El profesional gestiona su portafolio; hay lectura de catálogo de los ítems visibles. Políticas: SELECT «portafolio_select», ALL «portafolio_write».

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

RLS activo. El profesional gestiona sus propios impulsos; el catálogo puede leer los vigentes. Políticas: SELECT «impulsos_select», ALL «impulsos_write».

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
| `modelo_precio` | text | Obligatorio, Default 'hourly' |
| `aviso_legal` | text | Opcional |
| `creado_en` | text | Opcional |
| `actualizado_en` | text | Opcional |

RLS activo. Lectura pública del catálogo de oficios. La escritura es de administración. Políticas: SELECT «servicios_select», SELECT «servicios_select_authenticated», ALL «servicios_write».

### Tabla A-26. configuraciones_servicio

Esquema de configuración asociado a un servicio.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_servicio` | text | FK → servicios.id, Obligatorio |
| `esquema_config` | text | Obligatorio |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

RLS activo. Lectura del esquema de configuración del catálogo; escritura restringida. Políticas: SELECT «config_servicio_select», ALL «config_servicio_write».

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
| `id_cotizacion_seleccionada` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

RLS activo. SELECT y UPDATE para el cliente, el profesional asignado o un administrador. El INSERT lo hace el cliente (o un admin) con reglas: sin cotización preseleccionada y con estado de pago inicial pendiente o ninguno. Varios triggers cuidan el PIN, la evidencia, la fecha (solo RPC) y la disponibilidad. Políticas: INSERT «trabajos_insert», SELECT «trabajos_select», UPDATE «trabajos_update».

### Tabla A-28. mensajes

Mensaje del chat de un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_remitente` | uuid | Obligatorio |
| `id_destinatario` | uuid | Obligatorio |
| `contenido` | text | Obligatorio |
| `tipo` | text | Obligatorio, Default 'text' |
| `ruta_imagen` | text | Opcional |
| `leido` | integer | Obligatorio, Default 0 |
| `creado_en` | text | Obligatorio |

RLS activo. Solo las partes del chat (remitente o destinatario) o un administrador. Un trigger bloquea datos de contacto en el cuerpo. Políticas: INSERT «mensajes_insert», SELECT «mensajes_select», UPDATE «mensajes_update_leido».

### Tabla A-29. fotos_trabajo

Evidencia fotográfica o de video de un trabajo (bucket de evidencias).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `ruta_foto` | text | Obligatorio |
| `creado_en` | text | Obligatorio |
| `tipo_medio` | text | Obligatorio, Default 'photo'. photo or video evidence |
| `imagen_webp` | bytea | Opcional. Imagen de evidencia en WebP. Se guarda en la fila para no depender de archivos locales y ocupar menos espacio que JPEG/PNG. |

RLS activo. Las partes del trabajo o un administrador ven la evidencia. Hay reglas extra sobre el formato (p. ej. exigir webp/video). Políticas: ALL «fotos_trabajo_all».

### Tabla A-30. calificaciones

Valoración de un trabajo. Desde la calificación bidireccional admite direccion cliente_a_trabajador o trabajador_a_cliente, con unicidad por (id_trabajo, direccion). Alimenta trabajadores.calificacion.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_usuario` | uuid | Opcional |
| `puntaje` | integer | Obligatorio |
| `comentario` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `peso_confianza` | numeric(4,3) | Obligatorio, Default 1 |
| `estado_revision` | text | Obligatorio, Default 'vigente' |
| `motivo_revision` | text | Opcional |
| `direccion` | text | Obligatorio, Default 'cliente_a_trabajador' |
| `id_calificado` | uuid | Opcional |

Restricciones CHECK: `calificaciones_direccion_chk` CHECK ((direccion = ANY (ARRAY['cliente_a_trabajador'::text, 'trabajador_a_cliente'::text]))); `calificaciones_estado_revision_chk` CHECK ((estado_revision = ANY (ARRAY['vigente'::text, 'en_revision'::text, 'excluida'::text]))); `calificaciones_peso_confianza_chk` CHECK (((peso_confianza >= (0)::numeric) AND (peso_confianza <= (1)::numeric))).

RLS activo. Se inserta una calificación propia, con direccion e id_calificado coherentes con el trabajo terminado. Se leen las de cliente_a_trabajador (públicas para el listado) y las propias o de un administrador. Políticas: INSERT «calificaciones_insert», SELECT «calificaciones_select».

### Tabla A-31. calificaciones_cliente

El profesional nota al cliente. 1:1 con el trabajo. Alimenta perfiles.reputacion_cliente. puntaje es smallint en la base viva.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | Obligatorio |
| `id_cliente` | uuid | Obligatorio |
| `id_trabajador` | uuid | Obligatorio |
| `puntaje` | smallint | Obligatorio |
| `comentario` | text | Opcional |
| `creado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `calificaciones_cliente_puntaje_chk` CHECK (((puntaje >= 1) AND (puntaje <= 5))).

RLS activo. El profesional califica a su cliente en un trabajo 1:1; leen las partes o un administrador. Políticas: SELECT «calificaciones_cliente_select».

### Tabla A-32. disputas

Disputa abierta sobre un trabajo y su resolución (incluye sugerencia automática y vencimiento).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `abierta_por` | uuid | Obligatorio |
| `motivo` | text | Obligatorio |
| `descripcion` | text | Opcional |
| `estado` | text | Obligatorio |
| `resolucion` | text | Opcional |
| `resuelta_por` | uuid | Opcional |
| `resuelta_en` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |
| `origen` | text | Obligatorio, Default 'admin' |
| `decision_sugerida` | text | Opcional |
| `motivo_regla` | text | Opcional |
| `vence_en` | timestamptz | Opcional |

Restricciones CHECK: `disputas_decision_chk` CHECK (((decision_sugerida IS NULL) OR (decision_sugerida = ANY (ARRAY['liberar'::text, 'reembolsar'::text, 'humano'::text])))); `disputas_origen_chk` CHECK ((origen = ANY (ARRAY['sistema'::text, 'acuerdo'::text, 'admin'::text]))).

RLS activo. Las partes del trabajo o un administrador leen la disputa. La apertura y los cambios de estado van por RPC. Políticas: INSERT «disputas_insert», SELECT «disputas_select», UPDATE «disputas_update».

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

### Tabla A-35. cancelaciones_trabajo

Como máximo una cancelación por trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `cancelado_por` | uuid | Obligatorio |
| `motivo` | text | Obligatorio |
| `cancelado_en` | text | Obligatorio |

RLS activo. Las partes del trabajo o un administrador leen la cancelación; se inserta según las reglas del flujo de cancelar. Políticas: ALL «cancelaciones_all».

### Tabla A-36. tickets_soporte

Ticket de soporte asociado a un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio, Default (gen_random_uuid())::text |
| `id_trabajo` | text | Opcional |
| `nombre_cliente` | text | Obligatorio |
| `nombre_trabajador` | text | Obligatorio |
| `asunto` | text | Obligatorio |
| `monto_escrow` | integer | Obligatorio |
| `estado` | text | Opcional, Default 'Pending' |
| `creado_en` | timestamptz | Opcional, Default now() |

Restricciones CHECK: `tickets_status_check` CHECK ((estado = ANY (ARRAY['Pending'::text, 'Resolved'::text]))).

RLS activo. Las partes del trabajo o un administrador ven el ticket. Políticas: ALL «tickets_soporte_all».

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

### Tabla A-38. reprogramaciones_trabajo

Historial de propuestas para reagendar un trabajo (CU-33). Como máximo una propuesta pendiente por trabajo. Solo se escribe por las RPC proponer_reprogramacion, responder_reprogramacion y retirar_reprogramacion.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | uuid | PK, Obligatorio, Default gen_random_uuid() |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `propuesta_por` | uuid | Obligatorio |
| `rol_proponente` | text | Obligatorio |
| `fecha_anterior` | timestamptz | Obligatorio |
| `fecha_propuesta` | timestamptz | Obligatorio |
| `motivo` | text | Opcional |
| `estado` | text | Obligatorio, Default 'pendiente' |
| `respondida_por` | uuid | Opcional |
| `respondida_en` | timestamptz | Opcional |
| `creado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `reprogramaciones_trabajo_check` CHECK ((fecha_propuesta <> fecha_anterior)); `reprogramaciones_trabajo_estado_check` CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'retirada'::text, 'vencida'::text]))); `reprogramaciones_trabajo_motivo_check` CHECK (((motivo IS NULL) OR (char_length(motivo) <= 300))); `reprogramaciones_trabajo_rol_proponente_check` CHECK ((rol_proponente = ANY (ARRAY['cliente'::text, 'profesional'::text]))).

RLS activo. SELECT para las partes del trabajo. El alta, la respuesta y el retiro se hacen solo por RPC (CU-33). Políticas: SELECT «reprogramaciones_select».

### Tabla A-39. pines_inicio_trabajo

PIN que el cliente muestra al profesional para iniciar el trabajo (aceptado o en_camino → en_curso). El cliente (o un administrador) puede leerlo; el profesional lo valida con intentar_pin_inicio o transicionar_trabajo. Lo crea el trigger trabajos_crear_pin_inicio.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_trabajo` | text | PK, FK → trabajos.id, Obligatorio |
| `pin` | text | Obligatorio |
| `creado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `pines_inicio_trabajo_pin_check` CHECK ((pin ~ '^[0-9]{4}$'::text)).

RLS activo. SELECT para el cliente dueño del trabajo o un administrador (obtener_pin_inicio). El profesional no lee el PIN: lo valida por RPC. La inserción la hace el trigger trabajos_crear_pin_inicio. Políticas: SELECT «pines_inicio_select_cliente».

### Tabla A-40. bloqueos_pin_inicio

Contador de intentos fallidos del PIN, bloqueo temporal (15 minutos tras 5 fallos) y ventana en la que el PIN ya fue validado. RLS está activo y no hay políticas: solo acceden las funciones SECURITY DEFINER o el rol service_role.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_trabajo` | text | PK, FK → trabajos.id, Obligatorio |
| `fallos` | integer | Obligatorio, Default 0 |
| `bloqueado_hasta` | timestamptz | Opcional |
| `pin_ok_hasta` | timestamptz | Opcional |
| `pin_ok_usuario` | uuid | Opcional |
| `actualizado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `bloqueos_pin_inicio_fallos_check` CHECK ((fallos >= 0)).

RLS activo. RLS activo, sin políticas. Nadie accede por la API; solo funciones SECURITY DEFINER (intentar_pin_inicio, transicionar_trabajo, etc.) o service_role.

### Tabla A-41. intentos_pin_inicio

Auditoría de cada intento de PIN de inicio. RLS activo sin políticas: solo funciones SECURITY DEFINER o service_role.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | bigint | PK, Obligatorio |
| `id_trabajo` | text | Obligatorio |
| `id_usuario` | uuid | Opcional |
| `resultado` | text | Obligatorio |
| `intentos_restantes` | integer | Obligatorio |
| `creado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `intentos_pin_inicio_resultado_check` CHECK ((resultado = ANY (ARRAY['correcto'::text, 'incorrecto'::text, 'bloqueado'::text]))).

RLS activo. RLS activo, sin políticas. Auditoría solo visible vía funciones SECURITY DEFINER o service_role.

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

RLS activo. El cliente del trabajo, el profesional autor o un administrador leen la cotización. El monto no lo cambia el cliente (trigger). Políticas: INSERT «propuestas_insert», SELECT «propuestas_select», UPDATE «propuestas_update».

### Tabla A-43. pagos

Cobro asociado a un trabajo o a una orden de cambio, con retención (escrow) vía Transbank Webpay / Oneclick. Las columnas alta_nonce_hash, alta_jti y alta_consumido_en sustentan el alta del invitado después del pago: el nonce solo lo tiene el navegador y el jti es de un solo uso. El default de tipo_pago es 'primary' (inglés legado); el índice de un solo pago principal activo busca el valor 'principal'.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_orden_cambio` | text | Opcional |
| `tipo_pago` | text | Obligatorio, Default 'primary' |
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

RLS activo. El cliente dueño del trabajo, el profesional asignado o un administrador pueden leer el pago. Tokens, URL de Webpay y datos de alta de invitado no se exponen al cliente (columnas acotadas o solo service_role en la práctica de las Edge Functions). La creación de la intención de pago es por RPC. Políticas: SELECT «pagos_select».

### Tabla A-44. ordenes_cambio

Cambio de alcance o de precio durante un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_trabajador` | uuid | Obligatorio |
| `tipo` | text | Obligatorio |
| `titulo` | text | Obligatorio |
| `descripcion` | text | Obligatorio |
| `monto_clp` | integer | Obligatorio |
| `estado` | text | Obligatorio, Default 'pending_client' |
| `id_pago` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `respondido_en` | text | Opcional |

RLS activo. Las partes del trabajo o un administrador leen y proponen según el flujo; el cobro asociado va por RPC de pago. Políticas: ALL «ordenes_cambio_all».

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

Restricciones CHECK: `liquidaciones_estado_transferencia_chk` CHECK ((estado_transferencia = ANY (ARRAY['pendiente'::text, 'transferido'::text, 'fallido'::text]))); `liquidaciones_monto_clp_check` CHECK ((monto_clp > (0)::numeric)); `liquidaciones_proveedor_check` CHECK ((proveedor = ANY (ARRAY['manual'::text, 'khipu'::text, 'fintoc'::text, 'conformidad'::text]))).

RLS activo. El profesional ve la liquidación de sus pagos; un administrador ve todas. La confirmación de transferencia es por RPC de admin. Políticas: DELETE «liquidaciones_admin_delete», INSERT «liquidaciones_admin_insert», UPDATE «liquidaciones_admin_update», SELECT «liquidaciones_select».

### Tabla A-46. metodos_pago_oneclick

Tarjeta inscrita Oneclick. RLS niega el acceso a anon y authenticated: solo service_role (Edge Functions).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_usuario` | text | PK, Obligatorio |
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

### Tabla A-48. app_config

Pares clave/valor de configuración (demo_modo, admin_requiere_aal2, etc.). RLS niega el acceso a clientes; lo lee el backend.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `clave` | text | PK, Obligatorio |
| `valor` | text | Obligatorio |
| `actualizado_en` | timestamptz | Obligatorio, Default now() |

RLS activo. Política ALL con USING/CHECK false para anon y authenticated. Nadie del cliente lee ni escribe; solo service_role (bypass RLS) o funciones definer. Políticas: ALL «app_config_sin_acceso_cliente».

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

Restricciones CHECK: `ranking_config_unica` CHECK ((id = 'default'::text)).

RLS activo. La lectura de la fila default está permitida a autenticados (para el listado). Solo un administrador la actualiza por RPC. Políticas: ALL «ranking_config_admin».

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
| `resuelto_por` | uuid | Opcional |
| `resuelto_en` | timestamptz | Opcional |
| `creado_en` | timestamptz | Obligatorio, Default now() |

Restricciones CHECK: `senales_resena_estado_chk` CHECK ((estado = ANY (ARRAY['pendiente'::text, 'fraude_confirmado'::text, 'falso_positivo'::text, 'descartada'::text]))).

RLS activo. Cola de reseñas dudosas: la ve y resuelve un administrador. Políticas: SELECT «senales_resena_admin».

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

### Tabla A-52. eventos_ranking

Evento que alimenta el ranking de un profesional.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajador` | uuid | Obligatorio |
| `id_trabajo` | text | Opcional |
| `tipo_evento` | text | Obligatorio |
| `factores` | jsonb | Obligatorio, Default '{}' |
| `creado_en` | timestamptz | Obligatorio, Default now() |

RLS activo. Lectura de administración; la escritura la hacen triggers y funciones definer. Políticas: SELECT «eventos_ranking_select_admin».

## Funciones relevantes

La API de la aplicación no escribe en varias de estas tablas de forma directa: el reagendamiento (CU-33), el PIN de inicio, el escrow Webpay, el alta de invitado y la consola de soporte/qa se exponen como funciones SECURITY DEFINER. El detalle (nombre, argumentos y propósito) está en el diccionario `MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md`, sección 6.

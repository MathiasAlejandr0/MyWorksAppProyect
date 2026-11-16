# Diccionario de base de datos — My Works App

> Generado por `docs/_gen_diccionario_desde_schema.py` el 2026-11-16 (America/Santiago) desde el esquema real de Supabase `wxqrfcqifkfgawrnqmnj`. No editar a mano: actualizar el snapshot o volver a introspectar y regenerar.

| Campo | Valor |
|-------|-------|
| Proyecto | My Works App |
| Motor | PostgreSQL (Supabase), esquema `public` |
| Convención | Nombres en español, `snake_case` |
| Modelo fuente | Modelo lógico v2.4 · 52 tablas public · 2026-11-16 (America/Santiago) · alineado a la BD viva wxqrfcqifkfgawrnqmnj hasta la migración 20261115234447 (catalogo_plomeria_gasfiteria_distintos). Archivo de migración en el repo: 20261115234447_catalogo_plomeria_gasfiteria_distintos.sql. Diccionario generado desde information_schema y pg_catalog (solo lectura). No hay tipos ENUM ni vistas en public: los estados se restringen con CHECK. No ejecutar el SQL de consulta contra producción. |
| Tablas en el esquema | 52 |
| Columnas | 437 |
| Claves foráneas físicas | 44 |
| Políticas RLS | 83 |
| Funciones public | 140 |
| Última migración aplicada | `20261115234447` — catalogo_plomeria_gasfiteria_distintos |
| Archivo de migración (repo) | `20261115234447_catalogo_plomeria_gasfiteria_distintos.sql` |
| Fecha de generación | 2026-11-16 (America/Santiago) |

`perfiles.id` coincide con `auth.users.id` (Auth de Supabase, fuera de `public`). No hay tipos ENUM ni vistas en `public`.

## 1. Cambios respecto del diccionario v2.3 (2026-11-08, 43 tablas, hasta 20261108000005)

**Tablas agregadas (9):** `acuerdos_trabajo`, `bloqueos_pin_inicio`, `cuentas_bancarias`, `dispositivos_push`, `disputa_mensajes`, `intentos_pin_inicio`, `pines_inicio_trabajo`, `reprogramaciones_trabajo`, `verificacion_eventos`.

**Tablas eliminadas:** ninguna.

**Tablas modificadas:**

- `calificaciones`: Se agregan `direccion` (cliente_a_trabajador | trabajador_a_cliente) e `id_calificado`. Unicidad por (id_trabajo, direccion).
- `calificaciones_cliente`: `puntaje` pasa de integer a smallint.
- `disputas`: Se agregan `decision_sugerida`, `motivo_regla`, `origen` y `vence_en` (soporte automático).
- `liquidaciones`: Se agrega `estado_transferencia` para el seguimiento de la transferencia al profesional.
- `trabajador_horarios`: Deja de ser una fila 1:1 con tres columnas. Ahora es una plantilla semanal: `id`, `dia_semana`, `hora_inicio`, `hora_fin`, `activo`, `creado_en`, única por (id_usuario, dia_semana).
- `trabajador_precios`: En la base viva `id_usuario` es text (el diccionario v2.3 lo modelaba como uuid con FK). Se documenta el tipo real; no hay FK física.
- `trabajador_servicios_extra`: Igual que precios: `id_usuario` es text en la base viva.
- `trabajadores`: Se agregan `usa_horario` y `pausa_por_trabajo`. `es_elite` se documenta como columna GENERATED ALWAYS.
- `perfiles`: Se documentan los defaults reales (`'user'`, `'active'`) y los roles de consola soporte y qa, que el v2.3 no incluía. El comentario de columna de rol en la BD aún lista solo usuario, trabajador y administrador.
- `pagos`: Las columnas de alta de invitado (`alta_nonce_hash`, `alta_jti`, `alta_consumido_en`) ya estaban en el v2.3 (26 columnas). Se aclara su papel y el índice único de `alta_jti`.
- `trabajos`: Sigue con 20 columnas. Cambia el comportamiento: la fecha programada solo se altera por las RPC de CU-33 y hay un índice único de agenda por profesional y minuto.

Además se documentan, por primera vez en este diccionario, las políticas RLS (resumen en lenguaje natural), los CHECK, los índices únicos parciales y las funciones RPC / SECURITY DEFINER relevantes (reagendamiento CU-33, PIN de inicio, roles soporte/qa, alta de invitado, escrow Webpay).

## 2. Índice de tablas por grupo

| # | Grupo | Tabla | Columnas | RLS | Descripción |
|---|-------|-------|----------|-----|-------------|
| 1 | identidad | `perfiles` | 9 | sí | Identidad de la aplicación: perfiles.id coincide con auth.users.id (esquema auth de Supabase, fuera de public). El default de rol es 'user' y el de estado_cuenta es 'active'… |
| 2 | identidad | `notificaciones` | 8 | sí | Aviso dentro de la aplicación dirigido a un usuario. |
| 3 | identidad | `suscripciones` | 8 | sí | Plan de suscripción contratado por un usuario. |
| 4 | identidad | `codigos_restablecimiento` | 7 | sí | Código temporal para restablecer la contraseña. |
| 5 | identidad | `consentimientos_usuario` | 7 | sí | Registro de aceptación de una versión de consentimiento. |
| 6 | identidad | `bloqueos_usuario` | 4 | sí | Bloqueo de un usuario hacia otro. |
| 7 | identidad | `reportes` | 7 | sí | Denuncia de un usuario contra otro. |
| 8 | identidad | `eventos_abuso` | 8 | sí | Detección de abuso y la acción que se tomó. |
| 9 | identidad | `acciones_pendientes` | 11 | sí | Acción hecha sin conexión, pendiente de sincronizar. |
| 10 | identidad | `registros_error_app` | 10 | sí | Error de la aplicación informado por un cliente. |
| 11 | identidad | `eventos_analitica` | 6 | sí | Evento de uso registrado por la aplicación. |
| 12 | identidad | `banderas_funcionalidad` | 8 | sí | Interruptor de una función por versión, rol o usuario. |
| 13 | identidad | `dispositivos_push` | 5 | sí | Token del dispositivo del usuario para avisos push (FCM u otra plataforma). El alta y el baja se hacen por RPC. |
| 14 | identidad | `verificacion_eventos` | 6 | sí | Historial de cambios del estado de verificación de un profesional (pendiente, en revisión, verificado, rechazado). |
| 15 | territorio | `paises` | 3 | sí | País operativo. Hoy solo CL. |
| 16 | territorio | `regiones` | 4 | sí | Región administrativa de un país. |
| 17 | territorio | `comunas` | 6 | sí | Comuna de cobertura. Su identificador es el slug usado por trabajos y trabajadores. |
| 18 | catalogo_4nf | `trabajadores` | 30 | sí | Ficha 1:1 del profesional (PK = perfiles.id). La oferta en 4NF vive en tablas hijas; los JSON niveles_precio y servicios_personalizados son solo formato de escritura (un trigger… |
| 19 | catalogo_4nf | `trabajador_precios` | 3 | sí | Precio por código de servicio del profesional. En la base viva id_usuario es text (cast del uuid de trabajadores.id_usuario); no hay clave foránea física. |
| 20 | catalogo_4nf | `trabajador_servicios_extra` | 6 | sí | Servicio adicional definido por el profesional. id_usuario es text en la base viva, igual que en trabajador_precios. |
| 21 | catalogo_4nf | `trabajador_servicios` | 2 | sí | Oficios del catálogo que el profesional declara atender. |
| 22 | catalogo_4nf | `trabajador_horarios` | 9 | sí | Plantilla semanal: una fila por día (1 = lunes … 7 = domingo), única por (id_usuario, dia_semana). Solo el dueño lee y escribe (RLS). El cliente consulta los huecos con la RPC… |
| 23 | catalogo_4nf | `portafolio_trabajador` | 6 | sí | Foto o medio del portafolio de un profesional. |
| 24 | catalogo_4nf | `impulsos` | 6 | sí | Promoción temporal de visibilidad de un profesional. |
| 25 | catalogo_4nf | `servicios` | 10 | sí | Catálogo de oficios que la plataforma ofrece. |
| 26 | catalogo_4nf | `configuraciones_servicio` | 5 | sí | Esquema de configuración asociado a un servicio. |
| 27 | pedido | `trabajos` | 20 | sí | Pedido de un cliente a un profesional (o abierto a cotizaciones). estado_pago es una copia derivada del pago principal. La fecha programada se guarda como texto y, desde CU-33,… |
| 28 | pedido | `mensajes` | 9 | sí | Mensaje del chat de un trabajo. |
| 29 | pedido | `fotos_trabajo` | 6 | sí | Evidencia fotográfica o de video de un trabajo (bucket de evidencias). |
| 30 | pedido | `calificaciones` | 11 | sí | Valoración de un trabajo. Desde la calificación bidireccional admite direccion cliente_a_trabajador o trabajador_a_cliente, con unicidad por (id_trabajo, direccion). Alimenta… |
| 31 | pedido | `calificaciones_cliente` | 7 | sí | El profesional nota al cliente. 1:1 con el trabajo. Alimenta perfiles.reputacion_cliente. puntaje es smallint en la base viva. |
| 32 | pedido | `disputas` | 15 | sí | Disputa abierta sobre un trabajo y su resolución (incluye sugerencia automática y vencimiento). |
| 33 | pedido | `disputa_mensajes` | 5 | sí | Mensajes del hilo de una disputa, de las partes o de soporte. |
| 34 | pedido | `acuerdos_trabajo` | 9 | sí | Acuerdo entre cliente y profesional para rehacer, aceptar o anular un trabajo. Como máximo un acuerdo pendiente por trabajo. |
| 35 | pedido | `cancelaciones_trabajo` | 5 | sí | Como máximo una cancelación por trabajo. |
| 36 | pedido | `tickets_soporte` | 8 | sí | Ticket de soporte asociado a un trabajo. |
| 37 | pedido | `ubicacion_en_vivo` | 6 | sí | GPS en vivo durante el trabajo. 1:1 con el trabajo. |
| 38 | pedido | `reprogramaciones_trabajo` | 11 | sí | Historial de propuestas para reagendar un trabajo (CU-33). Como máximo una propuesta pendiente por trabajo. Solo se escribe por las RPC proponer_reprogramacion,… |
| 39 | pedido | `pines_inicio_trabajo` | 3 | sí | PIN que el cliente muestra al profesional para iniciar el trabajo (aceptado o en_camino → en_curso). El cliente (o un administrador) puede leerlo; el profesional lo valida con… |
| 40 | pedido | `bloqueos_pin_inicio` | 6 | sí (sin políticas) | Contador de intentos fallidos del PIN, bloqueo temporal (15 minutos tras 5 fallos) y ventana en la que el PIN ya fue validado. RLS está activo y no hay políticas: solo acceden las… |
| 41 | pedido | `intentos_pin_inicio` | 6 | sí (sin políticas) | Auditoría de cada intento de PIN de inicio. RLS activo sin políticas: solo funciones SECURITY DEFINER o service_role. |
| 42 | cobro | `propuestas_cotizacion` | 9 | sí | Cotización que un profesional envía para un trabajo. |
| 43 | cobro | `pagos` | 26 | sí | Cobro asociado a un trabajo o a una orden de cambio, con retención (escrow) vía Transbank Webpay / Oneclick. Las columnas alta_nonce_hash, alta_jti y alta_consumido_en sustentan… |
| 44 | cobro | `ordenes_cambio` | 11 | sí | Cambio de alcance o de precio durante un trabajo. |
| 45 | cobro | `liquidaciones` | 11 | sí | Un pago → una liquidación al profesional. manual = transferencia externa confirmada por admin; khipu/fintoc = PSP futuro. |
| 46 | cobro | `metodos_pago_oneclick` | 12 | sí | Tarjeta inscrita Oneclick. RLS niega el acceso a anon y authenticated: solo service_role (Edge Functions). |
| 47 | cobro | `cuentas_bancarias` | 7 | sí | Datos bancarios del profesional para pagar la liquidación. RLS: solo el dueño y un administrador. No es un dato público. |
| 48 | cobro | `app_config` | 3 | sí | Pares clave/valor de configuración (demo_modo, admin_requiere_aal2, etc.). RLS niega el acceso a clientes; lo lee el backend. |
| 49 | ranking | `ranking_config` | 16 | sí | Una fila default. Pesos del listado de profesionales. |
| 50 | ranking | `senales_resena` | 9 | sí | Señales de reseña dudosa. Un falso positivo baja el peso de esa señal. |
| 51 | ranking | `ranking_aprendizaje` | 6 | sí | Ajuste de los pesos del ranking y las métricas de ese cambio. |
| 52 | ranking | `eventos_ranking` | 6 | sí | Evento que alimenta el ranking de un profesional. |

## 3. Columnas por tabla

### 3.1 perfiles

Identidad de la aplicación: perfiles.id coincide con auth.users.id (esquema auth de Supabase, fuera de public). El default de rol es 'user' y el de estado_cuenta es 'active' (valores en inglés de las primeras migraciones). En la práctica también se usan valores en español: usuario, trabajador, administrador, soporte y qa; activo, suspendido, bloqueado y eliminado. is_admin() reconoce 'admin' y 'administrador'. Los roles privilegiados (administrador, soporte, qa) no se pueden autoasignar: el trigger perfiles_rol_inicial_seguro y protect_profile_sensitive_fields lo impiden. reputacion_cliente la actualiza el trigger al calificar al cliente.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `uuid` | pk, not null, default: gen_random_uuid() |  |
| `nombre` | `text` | not null, default: '' |  |
| `correo` | `text` |  |  |
| `rol` | `text` | not null, default: 'user' | usuario \| trabajador \| administrador |
| `estado_cuenta` | `text` | not null, default: 'active' | activo \| suspendido \| bloqueado \| eliminado |
| `ruta_foto_perfil` | `text` |  |  |
| `creado_en` | `text` | not null, default: to_char((now() AT TIME ZONE 'utc'::text), 'YYYY-MM-DD"T"HH24:MI:SS.US'::text) |  |
| `reputacion_cliente` | `numeric(3,2)` |  |  |
| `calificaciones_cliente` | `integer` | not null, default: 0 |  |

CHECK:

- `perfiles_reputacion_cliente_chk`: `CHECK (((reputacion_cliente IS NULL) OR ((reputacion_cliente >= (1)::numeric) AND (reputacion_cliente <= (5)::numeric))))`

Índices:

- `CREATE INDEX idx_perfiles_rol ON public.perfiles USING btree (rol)`

**RLS.** RLS activo. El usuario lee su ficha y, con límites, fichas públicas (nombre y foto) de otros; no ve correo ajeno por esta vía. La escritura de campos sensibles (rol, estado_cuenta) está protegida por trigger. El contacto completo solo se entrega con perfil_contacto_si_trabajo_activo. Políticas: INSERT «perfiles_insert», SELECT «perfiles_select», UPDATE «perfiles_update».

### 3.2 notificaciones

Aviso dentro de la aplicación dirigido a un usuario.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id, not null |  |
| `tipo` | `text` | not null |  |
| `titulo` | `text` | not null |  |
| `cuerpo` | `text` | not null |  |
| `id_relacionado` | `text` |  |  |
| `leido` | `integer` | not null, default: 0 |  |
| `creado_en` | `text` | not null |  |

Índices:

- `CREATE INDEX idx_notificaciones_id_usuario ON public.notificaciones USING btree (id_usuario)`

**RLS.** RLS activo. El usuario lee y marca las suyas. Políticas: ALL «notificaciones_all», INSERT «notificaciones_insert_participantes».

### 3.3 suscripciones

Plan de suscripción contratado por un usuario.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id, not null |  |
| `tipo_plan` | `text` | not null |  |
| `estado` | `text` | not null |  |
| `fecha_inicio` | `text` | not null |  |
| `fecha_fin` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

Índices:

- `CREATE INDEX idx_suscripciones_id_usuario_fkey ON public.suscripciones USING btree (id_usuario)`

**RLS.** RLS activo. El usuario ve su plan; la escritura la hace el backend de cobro. Políticas: ALL «suscripciones_all».

### 3.4 codigos_restablecimiento

Código temporal para restablecer la contraseña.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | not null |  |
| `codigo` | `text` | not null |  |
| `correo` | `text` | not null |  |
| `expira_en` | `text` | not null |  |
| `usado` | `integer` | default: 0 |  |
| `creado_en` | `text` | not null |  |

**RLS.** RLS activo. Acceso acotado al dueño o al backend; no es un dato de catálogo. Políticas: ALL «codigos_reset_all».

### 3.5 consentimientos_usuario

Registro de aceptación de una versión de consentimiento.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id, not null |  |
| `version_consentimiento` | `text` | not null |  |
| `aceptado` | `integer` | not null, default: 0 |  |
| `aceptado_en` | `text` | not null |  |
| `direccion_ip` | `text` |  |  |
| `agente_usuario` | `text` |  |  |

Índices:

- `CREATE INDEX idx_consentimientos_usuario_id_usuario_fkey ON public.consentimientos_usuario USING btree (id_usuario)`

**RLS.** RLS activo. El usuario ve y registra sus propios consentimientos. Políticas: ALL «consentimientos_all».

### 3.6 bloqueos_usuario

Bloqueo de un usuario hacia otro.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_bloqueador` | `uuid` | not null |  |
| `id_bloqueado` | `uuid` | not null |  |
| `creado_en` | `text` | not null |  |

Índices:

- `UNIQUE (id_bloqueador, id_bloqueado)`
- `CREATE UNIQUE INDEX "user_blocks_blockerId_blockedUserId_key" ON public.bloqueos_usuario USING btree (id_bloqueador, id_bloqueado)`

**RLS.** RLS activo. El usuario ve los bloqueos en los que participa; solo él (o un administrador) puede crearlos. Políticas: ALL «bloqueos_all».

### 3.7 reportes

Denuncia de un usuario contra otro.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_reportante` | `uuid` | not null |  |
| `id_usuario_reportado` | `uuid` | not null |  |
| `motivo` | `text` | not null |  |
| `descripcion` | `text` |  |  |
| `estado` | `text` | not null, default: 'pending' |  |
| `creado_en` | `text` | not null |  |

**RLS.** RLS activo. El reportante ve los suyos; un administrador gestiona la cola. Políticas: ALL «reportes_all».

### 3.8 eventos_abuso

Detección de abuso y la acción que se tomó.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id, not null |  |
| `tipo_abuso` | `text` | not null |  |
| `conteo` | `integer` | not null |  |
| `detectado_en` | `text` | not null |  |
| `accion_tomada` | `text` |  |  |
| `accion_tomada_en` | `text` |  |  |
| `resuelto` | `integer` | default: 0 |  |

Índices:

- `CREATE INDEX idx_eventos_abuso_id_usuario_fkey ON public.eventos_abuso USING btree (id_usuario)`

**RLS.** RLS activo. Restringido a administración o al backend de moderación. Políticas: ALL «eventos_abuso_all».

### 3.9 acciones_pendientes

Acción hecha sin conexión, pendiente de sincronizar.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id, not null |  |
| `tipo_accion` | `text` | not null |  |
| `tipo_entidad` | `text` | not null |  |
| `id_entidad` | `text` |  |  |
| `datos` | `text` | not null |  |
| `estado` | `text` | not null, default: 'pending_sync' |  |
| `conteo_reintentos` | `integer` | default: 0 |  |
| `mensaje_error` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

Índices:

- `CREATE INDEX idx_acciones_pendientes_id_usuario_fkey ON public.acciones_pendientes USING btree (id_usuario)`

**RLS.** RLS activo. El dueño ve y gestiona sus propias acciones pendientes; un administrador ve todas. Políticas: ALL «acciones_pendientes_all».

### 3.10 registros_error_app

Error de la aplicación informado por un cliente.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id |  |
| `tipo_error` | `text` | not null, default: 'error' |  |
| `mensaje` | `text` | not null |  |
| `traza_pila` | `text` |  |  |
| `metadatos` | `jsonb` |  |  |
| `estado` | `text` | not null, default: 'new' |  |
| `version_app` | `text` |  |  |
| `plataforma` | `text` |  |  |
| `creado_en` | `text` | not null, default: to_char((now() AT TIME ZONE 'utc'::text), 'YYYY-MM-DD"T"HH24:MI:SS.US'::text) |  |

Índices:

- `CREATE INDEX idx_registros_error_app_id_usuario_fkey ON public.registros_error_app USING btree (id_usuario)`

**RLS.** RLS activo. El cliente informa sus propios errores; un administrador puede revisarlos. Políticas: INSERT «registros_error_app_insert», SELECT «registros_error_app_select», UPDATE «registros_error_app_update_admin».

### 3.11 eventos_analitica

Evento de uso registrado por la aplicación.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `nombre_evento` | `text` | not null |  |
| `id_usuario` | `uuid` |  |  |
| `rol` | `text` |  |  |
| `marca_tiempo` | `text` | not null |  |
| `metadatos` | `text` |  |  |

**RLS.** RLS activo. El usuario o el backend registra eventos de uso; no es un listado público. Políticas: INSERT «analitica_insert», SELECT «analitica_select».

### 3.12 banderas_funcionalidad

Interruptor de una función por versión, rol o usuario.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `nombre_bandera` | `text` | not null |  |
| `habilitada` | `integer` | not null, default: 0 |  |
| `version_app` | `text` |  |  |
| `rol` | `text` |  |  |
| `id_usuario` | `uuid` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

**RLS.** RLS activo. Lectura restringida a banderas activas aplicables al usuario, o a un administrador. Políticas: SELECT «banderas_select», ALL «banderas_write».

### 3.13 dispositivos_push

Token del dispositivo del usuario para avisos push (FCM u otra plataforma). El alta y el baja se hacen por RPC.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `token` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id, not null |  |
| `plataforma` | `text` | not null, default: 'android' |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |
| `actualizado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `dispositivos_push_plataforma_check`: `CHECK ((plataforma = ANY (ARRAY['android'::text, 'ios'::text, 'web'::text])))`
- `dispositivos_push_token_largo`: `CHECK (((char_length(token) >= 20) AND (char_length(token) <= 4096)))`

Índices:

- `CREATE INDEX idx_dispositivos_push_usuario ON public.dispositivos_push USING btree (id_usuario)`

**RLS.** RLS activo. El usuario solo lee sus propios tokens. El alta y la baja se hacen por RPC. Políticas: SELECT «dispositivos_push_select_propios».

### 3.14 verificacion_eventos

Historial de cambios del estado de verificación de un profesional (pendiente, en revisión, verificado, rechazado).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `uuid` | pk, not null, default: gen_random_uuid() |  |
| `id_usuario` | `uuid` | fk → perfiles.id, not null |  |
| `estado` | `text` | not null |  |
| `nota` | `text` |  |  |
| `id_actor` | `uuid` |  |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

Índices:

- `CREATE INDEX verificacion_eventos_usuario_idx ON public.verificacion_eventos USING btree (id_usuario, creado_en)`

**RLS.** RLS activo. El profesional ve su propio historial; un administrador ve todos. La escritura la hace el trigger al cambiar el estado de verificación. Políticas: SELECT «verificacion_eventos_select».

### 3.15 paises

País operativo. Hoy solo CL.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `nombre` | `text` | not null |  |
| `iso2` | `text` | not null, unique |  |

Índices:

- `UNIQUE (iso2)`
- `CREATE UNIQUE INDEX paises_iso2_key ON public.paises USING btree (iso2)`

**RLS.** RLS activo. Lectura pública del catálogo. Hoy solo CL. Políticas: ALL «paises_admin_write», SELECT «paises_select».

### 3.16 regiones

Región administrativa de un país.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_pais` | `text` | fk → paises.id, not null |  |
| `nombre` | `text` | not null |  |
| `codigo_oficial` | `text` |  |  |

Índices:

- `CREATE INDEX idx_regiones_id_pais_fkey ON public.regiones USING btree (id_pais)`

**RLS.** RLS activo. Lectura pública del catálogo geográfico. Políticas: ALL «regiones_admin_write», SELECT «regiones_select».

### 3.17 comunas

Comuna de cobertura. Su identificador es el slug usado por trabajos y trabajadores.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_region` | `text` | fk → regiones.id, not null |  |
| `nombre` | `text` | not null |  |
| `latitud` | `double precision` |  |  |
| `longitud` | `double precision` |  |  |
| `activa` | `integer` | not null, default: 1 |  |

CHECK:

- `comunas_lat_chk`: `CHECK (((latitud IS NULL) OR ((latitud >= ('-90'::integer)::double precision) AND (latitud <= (90)::double precision))))`
- `comunas_lng_chk`: `CHECK (((longitud IS NULL) OR ((longitud >= ('-180'::integer)::double precision) AND (longitud <= (180)::double precision))))`

Índices:

- `CREATE INDEX comunas_nombre_idx ON public.comunas USING btree (nombre)`
- `CREATE INDEX comunas_region_idx ON public.comunas USING btree (id_region)`

**RLS.** RLS activo. Lectura pública del catálogo geográfico (comunas activas). La escritura es de administración o servicio. Políticas: ALL «comunas_admin_write», SELECT «comunas_select».

### 3.18 trabajadores

Ficha 1:1 del profesional (PK = perfiles.id). La oferta en 4NF vive en tablas hijas; los JSON niveles_precio y servicios_personalizados son solo formato de escritura (un trigger los parte a filas). es_elite es una columna GENERATED. La agenda semanal está en trabajador_horarios; usa_horario enciende el filtro. pausa_por_trabajo queda en true cuando un trabajo activo dejó disponible = 0, y se restablece al terminar.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_usuario` | `uuid` | pk, fk → perfiles.id, not null |  |
| `profesion` | `text` | not null, default: '' |  |
| `descripcion` | `text` |  |  |
| `calificacion` | `numeric(4,2)` | not null, default: 0 |  |
| `disponible` | `integer` | not null, default: 1 |  |
| `tarifa_visita` | `numeric(12,0)` | not null, default: 15000 |  |
| `categoria_servicio` | `text` | not null, default: 'general' |  |
| `niveles_precio` | `jsonb` | not null, default: '{}' |  |
| `conteo_rechazos` | `integer` | not null, default: 0 | Rechazos de invitaciones; penaliza orden en listados (no visible en UI) |
| `servicios_personalizados` | `jsonb` | not null, default: '[]' | Servicios adicionales definidos por el trabajador (JSON array) |
| `precios_configurados` | `integer` | not null, default: 0 | 1 si el trabajador completó la guía de configuración de precios |
| `zona_trabajo` | `text` |  | Comuna o zona donde atiende el trabajador |
| `estado_verificacion` | `text` | not null, default: 'pendiente' |  |
| `nota_verificacion` | `text` |  |  |
| `latitud_base` | `double precision` |  | Latitud de la base de servicio. origen_base=comuna es el centro de la comuna declarada; mapa la fijó el profesional. |
| `longitud_base` | `double precision` |  |  |
| `radio_servicio_km` | `numeric` | not null, default: 15 | Radio máximo de matching en kilómetros desde la base. |
| `origen_base` | `text` |  |  |
| `score_listado` | `numeric(8,4)` | not null, default: 0 | Orden de marketplace. Incluye pesos configurables + prioridad_manual*2. |
| `prioridad_manual` | `integer` | not null, default: 0 | Override de admin (-50..50) para mostrar un profesional antes o después. |
| `score_desglose` | `jsonb` | not null, default: '{}' |  |
| `ranking_actualizado_en` | `timestamptz` |  |  |
| `radio_urbano_km` | `numeric(5,2)` | not null, default: 5 | Kilómetros alrededor de la base donde la movilización es $0. |
| `tarifa_fuera_radio_clp` | `integer` | not null, default: 0 | Movilización fija si el cliente está fuera del radio urbano. 0 = tampoco cobra fuera. |
| `trabajos_completados` | `integer` | not null, default: 0 |  |
| `es_elite` | `boolean` | generated always | Destacado del mes: nota >= 4.7 y al menos 5 trabajos completados. GENERATED ALWAYS AS ((COALESCE(calificacion, (0)::numeric) >= 4.7) AND (trabajos_completados >= 5)) |
| `id_comuna` | `text` | fk → comunas.id | Comuna de cobertura. zona_trabajo sigue como texto de UI. |
| `id_region` | `text` | fk → regiones.id | Cobertura regional (p. ej. RM todas). |
| `usa_horario` | `boolean` | not null, default: false |  |
| `pausa_por_trabajo` | `boolean` | not null, default: false | true cuando disponible = 0 lo dejó un trabajo activo; se restablece al terminar. |

CHECK:

- `trabajadores_base_lat_chk`: `CHECK (((latitud_base IS NULL) OR ((latitud_base >= ('-90'::integer)::double precision) AND (latitud_base <= (90)::double precision))))`
- `trabajadores_base_lng_chk`: `CHECK (((longitud_base IS NULL) OR ((longitud_base >= ('-180'::integer)::double precision) AND (longitud_base <= (180)::double precision))))`
- `trabajadores_estado_verificacion_check`: `CHECK ((estado_verificacion = ANY (ARRAY['pendiente'::text, 'en_revision'::text, 'verificado'::text, 'rechazado'::text])))`
- `trabajadores_origen_base_chk`: `CHECK (((origen_base IS NULL) OR (origen_base = ANY (ARRAY['mapa'::text, 'comuna'::text]))))`
- `trabajadores_prioridad_manual_chk`: `CHECK (((prioridad_manual >= '-50'::integer) AND (prioridad_manual <= 50)))`
- `trabajadores_radio_chk`: `CHECK (((radio_servicio_km >= (1)::numeric) AND (radio_servicio_km <= (80)::numeric)))`
- `trabajadores_radio_urbano_chk`: `CHECK (((radio_urbano_km >= (1)::numeric) AND (radio_urbano_km <= (40)::numeric)))`
- `trabajadores_tarifa_fuera_radio_chk`: `CHECK (((tarifa_fuera_radio_clp >= 0) AND (tarifa_fuera_radio_clp <= 200000)))`

Índices:

- `CREATE INDEX idx_trabajadores_categoria ON public.trabajadores USING btree (categoria_servicio)`
- `CREATE INDEX idx_trabajadores_id_comuna_fkey ON public.trabajadores USING btree (id_comuna)`
- `CREATE INDEX idx_trabajadores_id_region_fkey ON public.trabajadores USING btree (id_region)`
- `CREATE INDEX trabajadores_base_geo_idx ON public.trabajadores USING btree (latitud_base, longitud_base) WHERE ((latitud_base IS NOT NULL) AND (longitud_base IS NOT NULL))`
- `CREATE INDEX trabajadores_calificacion_idx ON public.trabajadores USING btree (calificacion DESC NULLS LAST) WHERE (COALESCE(disponible, 0) = 1)`
- `CREATE INDEX trabajadores_catalog_list_idx ON public.trabajadores USING btree (categoria_servicio, calificacion DESC NULLS LAST, id_usuario) WHERE ((COALESCE(disponible, 0) = 1) AND (COALESCE(precios_configurados, 0) = 1))`
- `CREATE INDEX trabajadores_disponible_cat_idx ON public.trabajadores USING btree (disponible, categoria_servicio) WHERE (COALESCE(disponible, 0) = 1)`
- `CREATE INDEX trabajadores_score_listado_idx ON public.trabajadores USING btree (score_listado DESC, id_usuario)`
- `CREATE INDEX trabajadores_zona_trabajo_idx ON public.trabajadores USING btree (zona_trabajo) WHERE ((COALESCE(disponible, 0) = 1) AND (zona_trabajo IS NOT NULL))`

**RLS.** RLS activo. El listado público solo muestra fichas disponibles con precios configurados. El dueño, un administrador o el cliente con un trabajo conjunto también pueden leer la ficha. El UPDATE es del dueño o de un administrador; campos como verificación, score y pausa están protegidos por trigger. Políticas: INSERT «trabajadores_insert», SELECT «trabajadores_select_authenticated», UPDATE «trabajadores_update».

### 3.19 trabajador_precios

Precio por código de servicio del profesional. En la base viva id_usuario es text (cast del uuid de trabajadores.id_usuario); no hay clave foránea física.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_usuario` | `text` | pk, not null |  |
| `codigo` | `text` | pk, not null |  |
| `monto_clp` | `numeric(12,0)` | not null |  |

CHECK:

- `trabajador_precios_monto_clp_check`: `CHECK ((monto_clp >= (0)::numeric))`

**RLS.** RLS activo. El dueño y el catálogo (según política de precios) leen los montos ya publicados; la escritura es del dueño o de un trigger que parte el JSON. Políticas: ALL «trabajador_precios_propio».

### 3.20 trabajador_servicios_extra

Servicio adicional definido por el profesional. id_usuario es text en la base viva, igual que en trabajador_precios.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `text` | pk, not null |  |
| `titulo` | `text` | not null |  |
| `subtitulo` | `text` | not null, default: '' |  |
| `monto_clp` | `numeric(12,0)` | not null |  |
| `unidad` | `text` | not null, default: 'fijo' |  |

CHECK:

- `trabajador_servicios_extra_monto_clp_check`: `CHECK ((monto_clp >= (0)::numeric))`
- `trabajador_servicios_extra_unidad_check`: `CHECK ((unidad = ANY (ARRAY['fijo'::text, 'por_m2'::text])))`

**RLS.** RLS activo. Servicios extra del profesional; misma idea que los precios. Políticas: ALL «trabajador_servicios_extra_propio».

### 3.21 trabajador_servicios

Oficios del catálogo que el profesional declara atender.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_trabajador` | `uuid` | pk, fk → perfiles.id, not null |  |
| `categoria_servicio` | `text` | pk, not null |  |

**RLS.** RLS activo. Oficios declarados: lectura de catálogo y escritura del dueño. Políticas: SELECT «trabajador_servicios_select», ALL «trabajador_servicios_write».

### 3.22 trabajador_horarios

Plantilla semanal: una fila por día (1 = lunes … 7 = domingo), única por (id_usuario, dia_semana). Solo el dueño lee y escribe (RLS). El cliente consulta los huecos con la RPC horarios_libres_profesional. usa_horario en trabajadores enciende el filtro.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_usuario` | `uuid` | fk → trabajadores.id_usuario, not null |  |
| `horarios` | `jsonb` | not null, default: '[]' |  |
| `actualizado_en` | `timestamptz` | not null, default: now() |  |
| `id` | `uuid` | pk, not null, default: gen_random_uuid() |  |
| `dia_semana` | `smallint` |  |  |
| `hora_inicio` | `time` |  |  |
| `hora_fin` | `time` |  |  |
| `activo` | `boolean` | default: true |  |
| `creado_en` | `timestamptz` | default: now() |  |

CHECK:

- `trabajador_horarios_dia_chk`: `CHECK (((dia_semana IS NULL) OR ((dia_semana >= 1) AND (dia_semana <= 7))))`

Índices:

- `CREATE UNIQUE INDEX trabajador_horarios_usuario_dia_uidx ON public.trabajador_horarios USING btree (id_usuario, dia_semana)`
- `CREATE INDEX trabajador_horarios_usuario_idx ON public.trabajador_horarios USING btree (id_usuario, dia_semana)`

**RLS.** RLS activo. SELECT y escritura solo para el dueño de la ficha (o un administrador). El cliente no lee esta tabla: usa horarios_libres_profesional. Políticas: DELETE «trabajador_horarios_delete», INSERT «trabajador_horarios_insert», SELECT «trabajador_horarios_select», UPDATE «trabajador_horarios_update».

### 3.23 portafolio_trabajador

Foto o medio del portafolio de un profesional.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajador` | `uuid` | fk → perfiles.id, not null |  |
| `ruta_foto` | `text` | not null |  |
| `descripcion` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `tipo_medio` | `text` | default: 'photo' |  |

Índices:

- `CREATE INDEX idx_portfolio_worker ON public.portafolio_trabajador USING btree (id_trabajador)`

**RLS.** RLS activo. El profesional gestiona su portafolio; hay lectura de catálogo de los ítems visibles. Políticas: SELECT «portafolio_select», ALL «portafolio_write».

### 3.24 impulsos

Promoción temporal de visibilidad de un profesional.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajador` | `uuid` | fk → perfiles.id, not null |  |
| `tipo_impulso` | `text` | not null |  |
| `fecha_inicio` | `text` | not null |  |
| `fecha_fin` | `text` | not null |  |
| `creado_en` | `text` | not null |  |

Índices:

- `CREATE INDEX idx_impulsos_id_trabajador_fkey ON public.impulsos USING btree (id_trabajador)`

**RLS.** RLS activo. El profesional gestiona sus propios impulsos; el catálogo puede leer los vigentes. Políticas: SELECT «impulsos_select», ALL «impulsos_write».

### 3.25 servicios

Catálogo de oficios que la plataforma ofrece.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `nombre` | `text` | not null |  |
| `descripcion` | `text` |  |  |
| `categoria` | `text` | not null, default: 'general' |  |
| `activo` | `integer` | not null, default: 1 |  |
| `requiere_certificacion` | `integer` | not null, default: 0 |  |
| `modelo_precio` | `text` | not null, default: 'hourly' |  |
| `aviso_legal` | `text` |  |  |
| `creado_en` | `text` |  |  |
| `actualizado_en` | `text` |  |  |

Índices:

- `CREATE INDEX idx_servicios_categoria ON public.servicios USING btree (categoria)`
- `CREATE INDEX servicios_activo_categoria_idx ON public.servicios USING btree (activo, categoria) WHERE (COALESCE(activo, 1) = 1)`

**RLS.** RLS activo. Lectura pública del catálogo de oficios. La escritura es de administración. Políticas: SELECT «servicios_select», SELECT «servicios_select_authenticated», ALL «servicios_write».

### 3.26 configuraciones_servicio

Esquema de configuración asociado a un servicio.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_servicio` | `text` | fk → servicios.id, not null, unique |  |
| `esquema_config` | `text` | not null |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

Índices:

- `UNIQUE (id_servicio)`
- `CREATE UNIQUE INDEX "service_configs_serviceId_key" ON public.configuraciones_servicio USING btree (id_servicio)`

**RLS.** RLS activo. Lectura del esquema de configuración del catálogo; escritura restringida. Políticas: SELECT «config_servicio_select», ALL «config_servicio_write».

### 3.27 trabajos

Pedido de un cliente a un profesional (o abierto a cotizaciones). estado_pago es una copia derivada del pago principal. La fecha programada se guarda como texto y, desde CU-33, solo cambia por las RPC de reagendamiento (trabajos_fecha_solo_por_rpc). Hay un índice único que impide dos trabajos activos del mismo profesional en el mismo minuto (minuto_utc de fecha_programada).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id, not null |  |
| `id_trabajador` | `uuid` | fk → perfiles.id, unique |  |
| `id_servicio` | `text` | fk → servicios.id |  |
| `estado` | `text` | not null |  |
| `direccion` | `text` | not null, default: '' |  |
| `latitud` | `double precision` |  |  |
| `longitud` | `double precision` |  |  |
| `descripcion` | `text` |  |  |
| `fecha_programada` | `text` |  |  |
| `metadatos_servicio` | `text` |  |  |
| `modalidad_cobro` | `text` |  |  |
| `estado_pago` | `text` |  |  |
| `id_comuna` | `text` | fk → comunas.id | FK a comunas.id (slug). |
| `instantanea_precio` | `text` |  |  |
| `id_sku_servicio` | `text` |  |  |
| `horas_bloque` | `integer` |  |  |
| `id_cotizacion_seleccionada` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

Índices:

- `CREATE INDEX idx_trabajos_creado_en ON public.trabajos USING btree (creado_en DESC)`
- `CREATE INDEX idx_trabajos_estado ON public.trabajos USING btree (estado)`
- `CREATE INDEX idx_trabajos_id_comuna_fkey ON public.trabajos USING btree (id_comuna)`
- `CREATE INDEX idx_trabajos_id_servicio_fkey ON public.trabajos USING btree (id_servicio)`
- `CREATE INDEX idx_trabajos_id_trabajador ON public.trabajos USING btree (id_trabajador)`
- `CREATE INDEX idx_trabajos_id_usuario ON public.trabajos USING btree (id_usuario)`
- `CREATE INDEX trabajos_trabajador_estado_idx ON public.trabajos USING btree (id_trabajador, estado) WHERE (id_trabajador IS NOT NULL)`
- `CREATE INDEX trabajos_trabajador_fecha_programada_idx ON public.trabajos USING btree (id_trabajador, fecha_programada) WHERE ((fecha_programada IS NOT NULL) AND (id_trabajador IS NOT NULL))`
- `CREATE UNIQUE INDEX trabajos_trabajador_minuto_activo_uidx ON public.trabajos USING btree (id_trabajador, minuto_utc(fecha_programada)) WHERE ((fecha_programada IS NOT NULL) AND (id_trabajador IS NOT NULL) AND (estado <> ALL (ARRAY['cancelado'::text, 'expirado'::text, 'completado'::text, 'no_asistio'::text])))`
- `CREATE INDEX trabajos_usuario_creado_idx ON public.trabajos USING btree (id_usuario, creado_en DESC)`

**RLS.** RLS activo. SELECT y UPDATE para el cliente, el profesional asignado o un administrador. El INSERT lo hace el cliente (o un admin) con reglas: sin cotización preseleccionada y con estado de pago inicial pendiente o ninguno. Varios triggers cuidan el PIN, la evidencia, la fecha (solo RPC) y la disponibilidad. Políticas: INSERT «trabajos_insert», SELECT «trabajos_select», UPDATE «trabajos_update».

### 3.28 mensajes

Mensaje del chat de un trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `id_remitente` | `uuid` | not null |  |
| `id_destinatario` | `uuid` | not null |  |
| `contenido` | `text` | not null |  |
| `tipo` | `text` | not null, default: 'text' |  |
| `ruta_imagen` | `text` |  |  |
| `leido` | `integer` | not null, default: 0 |  |
| `creado_en` | `text` | not null |  |

Índices:

- `CREATE INDEX idx_mensajes_id_trabajo ON public.mensajes USING btree (id_trabajo)`
- `CREATE INDEX idx_messages_receiver ON public.mensajes USING btree (id_destinatario)`

**RLS.** RLS activo. Solo las partes del chat (remitente o destinatario) o un administrador. Un trigger bloquea datos de contacto en el cuerpo. Políticas: INSERT «mensajes_insert», SELECT «mensajes_select», UPDATE «mensajes_update_leido».

### 3.29 fotos_trabajo

Evidencia fotográfica o de video de un trabajo (bucket de evidencias).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `ruta_foto` | `text` | not null |  |
| `creado_en` | `text` | not null |  |
| `tipo_medio` | `text` | not null, default: 'photo' | photo or video evidence |
| `imagen_webp` | `bytea` |  | Imagen de evidencia en WebP. Se guarda en la fila para no depender de archivos locales y ocupar menos espacio que JPEG/PNG. |

Índices:

- `CREATE INDEX idx_job_photos_job ON public.fotos_trabajo USING btree (id_trabajo)`

**RLS.** RLS activo. Las partes del trabajo o un administrador ven la evidencia. Hay reglas extra sobre el formato (p. ej. exigir webp/video). Políticas: ALL «fotos_trabajo_all».

### 3.30 calificaciones

Valoración de un trabajo. Desde la calificación bidireccional admite direccion cliente_a_trabajador o trabajador_a_cliente, con unicidad por (id_trabajo, direccion). Alimenta trabajadores.calificacion.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `id_usuario` | `uuid` |  |  |
| `puntaje` | `integer` | not null |  |
| `comentario` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `peso_confianza` | `numeric(4,3)` | not null, default: 1 |  |
| `estado_revision` | `text` | not null, default: 'vigente' |  |
| `motivo_revision` | `text` |  |  |
| `direccion` | `text` | not null, default: 'cliente_a_trabajador' |  |
| `id_calificado` | `uuid` |  |  |

CHECK:

- `calificaciones_direccion_chk`: `CHECK ((direccion = ANY (ARRAY['cliente_a_trabajador'::text, 'trabajador_a_cliente'::text])))`
- `calificaciones_estado_revision_chk`: `CHECK ((estado_revision = ANY (ARRAY['vigente'::text, 'en_revision'::text, 'excluida'::text])))`
- `calificaciones_peso_confianza_chk`: `CHECK (((peso_confianza >= (0)::numeric) AND (peso_confianza <= (1)::numeric)))`

Índices:

- `CREATE INDEX calificaciones_estado_revision_idx ON public.calificaciones USING btree (estado_revision)`
- `CREATE UNIQUE INDEX calificaciones_trabajo_direccion_uidx ON public.calificaciones USING btree (id_trabajo, direccion)`
- `CREATE INDEX calificaciones_trabajo_idx ON public.calificaciones USING btree (id_trabajo)`

**RLS.** RLS activo. Se inserta una calificación propia, con direccion e id_calificado coherentes con el trabajo terminado. Se leen las de cliente_a_trabajador (públicas para el listado) y las propias o de un administrador. Políticas: INSERT «calificaciones_insert», SELECT «calificaciones_select».

### 3.31 calificaciones_cliente

El profesional nota al cliente. 1:1 con el trabajo. Alimenta perfiles.reputacion_cliente. puntaje es smallint en la base viva.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | not null, unique |  |
| `id_cliente` | `uuid` | not null |  |
| `id_trabajador` | `uuid` | not null |  |
| `puntaje` | `smallint` | not null |  |
| `comentario` | `text` |  |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `calificaciones_cliente_puntaje_chk`: `CHECK (((puntaje >= 1) AND (puntaje <= 5)))`

Índices:

- `UNIQUE (id_trabajo)`
- `CREATE UNIQUE INDEX calificaciones_cliente_trabajo_unica ON public.calificaciones_cliente USING btree (id_trabajo)`

**RLS.** RLS activo. El profesional califica a su cliente en un trabajo 1:1; leen las partes o un administrador. Políticas: SELECT «calificaciones_cliente_select».

### 3.32 disputas

Disputa abierta sobre un trabajo y su resolución (incluye sugerencia automática y vencimiento).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `abierta_por` | `uuid` | not null |  |
| `motivo` | `text` | not null |  |
| `descripcion` | `text` |  |  |
| `estado` | `text` | not null |  |
| `resolucion` | `text` |  |  |
| `resuelta_por` | `uuid` |  |  |
| `resuelta_en` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |
| `origen` | `text` | not null, default: 'admin' |  |
| `decision_sugerida` | `text` |  |  |
| `motivo_regla` | `text` |  |  |
| `vence_en` | `timestamptz` |  |  |

CHECK:

- `disputas_decision_chk`: `CHECK (((decision_sugerida IS NULL) OR (decision_sugerida = ANY (ARRAY['liberar'::text, 'reembolsar'::text, 'humano'::text]))))`
- `disputas_origen_chk`: `CHECK ((origen = ANY (ARRAY['sistema'::text, 'acuerdo'::text, 'admin'::text])))`

Índices:

- `CREATE INDEX idx_disputas_estado ON public.disputas USING btree (estado)`
- `CREATE INDEX idx_disputes_job ON public.disputas USING btree (id_trabajo)`

**RLS.** RLS activo. Las partes del trabajo o un administrador leen la disputa. La apertura y los cambios de estado van por RPC. Políticas: INSERT «disputas_insert», SELECT «disputas_select», UPDATE «disputas_update».

### 3.33 disputa_mensajes

Mensajes del hilo de una disputa, de las partes o de soporte.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_disputa` | `text` | fk → disputas.id, not null |  |
| `id_autor` | `uuid` | fk → perfiles.id |  |
| `cuerpo` | `text` | not null |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

Índices:

- `CREATE INDEX idx_disputa_mensajes_id_autor_fkey ON public.disputa_mensajes USING btree (id_autor)`
- `CREATE INDEX idx_disputa_mensajes_id_disputa_fkey ON public.disputa_mensajes USING btree (id_disputa)`

**RLS.** RLS activo. Lectura para las partes del trabajo en disputa o un administrador. Los comentarios de soporte se insertan por RPC. Políticas: SELECT «disputa_mensajes_select».

### 3.34 acuerdos_trabajo

Acuerdo entre cliente y profesional para rehacer, aceptar o anular un trabajo. Como máximo un acuerdo pendiente por trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null, unique |  |
| `tipo` | `text` | not null |  |
| `propuesto_por` | `uuid` | fk → perfiles.id, not null |  |
| `acepta_cliente` | `boolean` |  |  |
| `acepta_trabajador` | `boolean` |  |  |
| `estado` | `text` | not null, default: 'pendiente' |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |
| `aplicado_en` | `timestamptz` |  |  |

CHECK:

- `acuerdos_estado_chk`: `CHECK ((estado = ANY (ARRAY['pendiente'::text, 'confirmado'::text, 'rechazado'::text, 'aplicado'::text])))`
- `acuerdos_tipo_chk`: `CHECK ((tipo = ANY (ARRAY['rehacer'::text, 'aceptar'::text, 'anular'::text])))`

Índices:

- `CREATE UNIQUE INDEX acuerdos_trabajo_pendiente_uidx ON public.acuerdos_trabajo USING btree (id_trabajo) WHERE (estado = 'pendiente'::text)`
- `CREATE INDEX idx_acuerdos_trabajo_id_trabajo_fkey ON public.acuerdos_trabajo USING btree (id_trabajo)`
- `CREATE INDEX idx_acuerdos_trabajo_propuesto_por_fkey ON public.acuerdos_trabajo USING btree (propuesto_por)`

**RLS.** RLS activo. Solo lectura para las partes del trabajo (es_parte_trabajo) o un administrador. El alta y la respuesta se hacen por RPC (proponer_acuerdo, responder_acuerdo). Políticas: SELECT «acuerdos_trabajo_select».

### 3.35 cancelaciones_trabajo

Como máximo una cancelación por trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null, unique |  |
| `cancelado_por` | `uuid` | not null |  |
| `motivo` | `text` | not null |  |
| `cancelado_en` | `text` | not null |  |

Índices:

- `UNIQUE (id_trabajo)`
- `CREATE UNIQUE INDEX "job_cancellations_jobId_key" ON public.cancelaciones_trabajo USING btree (id_trabajo)`

**RLS.** RLS activo. Las partes del trabajo o un administrador leen la cancelación; se inserta según las reglas del flujo de cancelar. Políticas: ALL «cancelaciones_all».

### 3.36 tickets_soporte

Ticket de soporte asociado a un trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null, default: (gen_random_uuid())::text |  |
| `id_trabajo` | `text` |  |  |
| `nombre_cliente` | `text` | not null |  |
| `nombre_trabajador` | `text` | not null |  |
| `asunto` | `text` | not null |  |
| `monto_escrow` | `integer` | not null |  |
| `estado` | `text` | default: 'Pending' |  |
| `creado_en` | `timestamptz` | default: now() |  |

CHECK:

- `tickets_status_check`: `CHECK ((estado = ANY (ARRAY['Pending'::text, 'Resolved'::text])))`

**RLS.** RLS activo. Las partes del trabajo o un administrador ven el ticket. Políticas: ALL «tickets_soporte_all».

### 3.37 ubicacion_en_vivo

GPS en vivo durante el trabajo. 1:1 con el trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_trabajo` | `text` | pk, fk → trabajos.id, not null |  |
| `id_trabajador` | `uuid` | fk → trabajadores.id_usuario, not null |  |
| `latitud` | `double precision` | not null |  |
| `longitud` | `double precision` | not null |  |
| `precision_metros` | `double precision` |  |  |
| `actualizado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `ubicacion_lat_chk`: `CHECK (((latitud >= ('-90'::integer)::double precision) AND (latitud <= (90)::double precision)))`
- `ubicacion_lng_chk`: `CHECK (((longitud >= ('-180'::integer)::double precision) AND (longitud <= (180)::double precision)))`

Índices:

- `CREATE INDEX idx_ubicacion_en_vivo_id_trabajador_fkey ON public.ubicacion_en_vivo USING btree (id_trabajador)`

**RLS.** RLS activo. El cliente del trabajo o un administrador leen la posición. El profesional la publica por RPC publicar_ubicacion_trabajo. Un trigger borra el GPS al cerrar el trabajo. Políticas: SELECT «ubicacion_select_cliente_admin».

### 3.38 reprogramaciones_trabajo

Historial de propuestas para reagendar un trabajo (CU-33). Como máximo una propuesta pendiente por trabajo. Solo se escribe por las RPC proponer_reprogramacion, responder_reprogramacion y retirar_reprogramacion.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `uuid` | pk, not null, default: gen_random_uuid() |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null, unique |  |
| `propuesta_por` | `uuid` | not null |  |
| `rol_proponente` | `text` | not null |  |
| `fecha_anterior` | `timestamptz` | not null |  |
| `fecha_propuesta` | `timestamptz` | not null |  |
| `motivo` | `text` |  |  |
| `estado` | `text` | not null, default: 'pendiente' |  |
| `respondida_por` | `uuid` |  |  |
| `respondida_en` | `timestamptz` |  |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `reprogramaciones_trabajo_check`: `CHECK ((fecha_propuesta <> fecha_anterior))`
- `reprogramaciones_trabajo_estado_check`: `CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'retirada'::text, 'vencida'::text])))`
- `reprogramaciones_trabajo_motivo_check`: `CHECK (((motivo IS NULL) OR (char_length(motivo) <= 300)))`
- `reprogramaciones_trabajo_rol_proponente_check`: `CHECK ((rol_proponente = ANY (ARRAY['cliente'::text, 'profesional'::text])))`

Índices:

- `CREATE INDEX reprogramaciones_por_trabajo ON public.reprogramaciones_trabajo USING btree (id_trabajo, creado_en DESC)`
- `CREATE UNIQUE INDEX reprogramaciones_una_pendiente ON public.reprogramaciones_trabajo USING btree (id_trabajo) WHERE (estado = 'pendiente'::text)`

**RLS.** RLS activo. SELECT para las partes del trabajo. El alta, la respuesta y el retiro se hacen solo por RPC (CU-33). Políticas: SELECT «reprogramaciones_select».

### 3.39 pines_inicio_trabajo

PIN que el cliente muestra al profesional para iniciar el trabajo (aceptado o en_camino → en_curso). El cliente (o un administrador) puede leerlo; el profesional lo valida con intentar_pin_inicio o transicionar_trabajo. Lo crea el trigger trabajos_crear_pin_inicio.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_trabajo` | `text` | pk, fk → trabajos.id, not null |  |
| `pin` | `text` | not null |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `pines_inicio_trabajo_pin_check`: `CHECK ((pin ~ '^[0-9]{4}$'::text))`

**RLS.** RLS activo. SELECT para el cliente dueño del trabajo o un administrador (obtener_pin_inicio). El profesional no lee el PIN: lo valida por RPC. La inserción la hace el trigger trabajos_crear_pin_inicio. Políticas: SELECT «pines_inicio_select_cliente».

### 3.40 bloqueos_pin_inicio

Contador de intentos fallidos del PIN, bloqueo temporal (15 minutos tras 5 fallos) y ventana en la que el PIN ya fue validado. RLS está activo y no hay políticas: solo acceden las funciones SECURITY DEFINER o el rol service_role.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_trabajo` | `text` | pk, fk → trabajos.id, not null |  |
| `fallos` | `integer` | not null, default: 0 |  |
| `bloqueado_hasta` | `timestamptz` |  |  |
| `pin_ok_hasta` | `timestamptz` |  |  |
| `pin_ok_usuario` | `uuid` |  |  |
| `actualizado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `bloqueos_pin_inicio_fallos_check`: `CHECK ((fallos >= 0))`

**RLS.** RLS activo. RLS activo, sin políticas. Nadie accede por la API; solo funciones SECURITY DEFINER (intentar_pin_inicio, transicionar_trabajo, etc.) o service_role.

### 3.41 intentos_pin_inicio

Auditoría de cada intento de PIN de inicio. RLS activo sin políticas: solo funciones SECURITY DEFINER o service_role.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `bigint` | pk, not null, identity |  |
| `id_trabajo` | `text` | not null |  |
| `id_usuario` | `uuid` |  |  |
| `resultado` | `text` | not null |  |
| `intentos_restantes` | `integer` | not null |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `intentos_pin_inicio_resultado_check`: `CHECK ((resultado = ANY (ARRAY['correcto'::text, 'incorrecto'::text, 'bloqueado'::text])))`

Índices:

- `CREATE INDEX intentos_pin_inicio_trabajo_idx ON public.intentos_pin_inicio USING btree (id_trabajo, creado_en DESC)`

**RLS.** RLS activo. RLS activo, sin políticas. Auditoría solo visible vía funciones SECURITY DEFINER o service_role.

### 3.42 propuestas_cotizacion

Cotización que un profesional envía para un trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `id_trabajador` | `uuid` | fk → perfiles.id, not null |  |
| `monto_total_clp` | `integer` | not null |  |
| `descripcion` | `text` | not null |  |
| `validez_hasta` | `text` |  |  |
| `desglose` | `text` |  |  |
| `estado` | `text` | not null |  |
| `creado_en` | `text` | not null |  |

Índices:

- `CREATE INDEX idx_quotes_job ON public.propuestas_cotizacion USING btree (id_trabajo)`
- `CREATE INDEX idx_quotes_worker ON public.propuestas_cotizacion USING btree (id_trabajador)`

**RLS.** RLS activo. El cliente del trabajo, el profesional autor o un administrador leen la cotización. El monto no lo cambia el cliente (trigger). Políticas: INSERT «propuestas_insert», SELECT «propuestas_select», UPDATE «propuestas_update».

### 3.43 pagos

Cobro asociado a un trabajo o a una orden de cambio, con retención (escrow) vía Transbank Webpay / Oneclick. Las columnas alta_nonce_hash, alta_jti y alta_consumido_en sustentan el alta del invitado después del pago: el nonce solo lo tiene el navegador y el jti es de un solo uso. El default de tipo_pago es 'primary' (inglés legado); el índice de un solo pago principal activo busca el valor 'principal'.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null, unique |  |
| `id_orden_cambio` | `text` |  |  |
| `tipo_pago` | `text` | not null, default: 'primary' |  |
| `monto` | `numeric(12,0)` | not null |  |
| `moneda` | `text` | not null, default: 'CLP' |  |
| `estado` | `text` | not null |  |
| `metodo_pago` | `text` |  |  |
| `id_transaccion` | `text` |  |  |
| `autorizado_en` | `text` |  |  |
| `liberado_en` | `text` |  |  |
| `reembolsado_en` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |
| `ambiente` | `text` |  | integration \| production |
| `token_tbk` | `text` |  | token_ws de Webpay Plus. No guardar aquí la orden Oneclick. |
| `url_tbk` | `text` |  | URL TBK — solo service_role / Edge Functions |
| `buy_order` | `text` |  | buy_order Webpay |
| `handoff_consumido_en` | `timestamptz` |  |  |
| `reembolso_solicitado_en` | `timestamptz` |  | Marca que ya se pidió la devolución a Transbank. Un reintento no vuelve a llamar a la tarjeta. |
| `orden_detalle_oneclick` | `text` |  | buy_order de detalle de Oneclick Mall, para el reembolso. |
| `cobro_reclamado_en` | `timestamptz` |  | Marca exclusiva de una autorización Oneclick en curso. |
| `origen_retorno` | `text` |  | Origen del navegador ya contrastado con la allowlist. webpay-commit redirige ahí. |
| `alta_nonce_hash` | `text` |  | SHA-256 del nonce que solo tiene el navegador del invitado. |
| `alta_jti` | `text` | unique | Identificador de un solo uso del enlace para crear la contraseña. |
| `alta_consumido_en` | `timestamptz` |  | Cuándo se usó el enlace. Un segundo intento no sirve. |

Índices:

- `CREATE INDEX idx_pagos_id_trabajo ON public.pagos USING btree (id_trabajo)`
- `CREATE UNIQUE INDEX pagos_alta_jti_uidx ON public.pagos USING btree (alta_jti) WHERE (alta_jti IS NOT NULL)`
- `CREATE INDEX pagos_buy_order_idx ON public.pagos USING btree (buy_order) WHERE ((buy_order IS NOT NULL) AND (length(TRIM(BOTH FROM buy_order)) > 0))`
- `CREATE INDEX pagos_por_confirmar_idx ON public.pagos USING btree (estado) WHERE (estado = 'pagado_por_confirmar'::text)`
- `CREATE INDEX pagos_token_tbk_idx ON public.pagos USING btree (token_tbk) WHERE ((token_tbk IS NOT NULL) AND (length(TRIM(BOTH FROM token_tbk)) > 0))`
- `CREATE INDEX pagos_trabajo_estado_idx ON public.pagos USING btree (id_trabajo, estado)`
- `CREATE UNIQUE INDEX pagos_un_principal_activo_uidx ON public.pagos USING btree (id_trabajo) WHERE ((tipo_pago = 'principal'::text) AND (estado = ANY (ARRAY['pendiente'::text, 'retenido'::text, 'autorizado'::text])))`

**RLS.** RLS activo. El cliente dueño del trabajo, el profesional asignado o un administrador pueden leer el pago. Tokens, URL de Webpay y datos de alta de invitado no se exponen al cliente (columnas acotadas o solo service_role en la práctica de las Edge Functions). La creación de la intención de pago es por RPC. Políticas: SELECT «pagos_select».

### 3.44 ordenes_cambio

Cambio de alcance o de precio durante un trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `id_trabajador` | `uuid` | not null |  |
| `tipo` | `text` | not null |  |
| `titulo` | `text` | not null |  |
| `descripcion` | `text` | not null |  |
| `monto_clp` | `integer` | not null |  |
| `estado` | `text` | not null, default: 'pending_client' |  |
| `id_pago` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `respondido_en` | `text` |  |  |

Índices:

- `CREATE INDEX idx_change_orders_job ON public.ordenes_cambio USING btree (id_trabajo)`

**RLS.** RLS activo. Las partes del trabajo o un administrador leen y proponen según el flujo; el cobro asociado va por RPC de pago. Políticas: ALL «ordenes_cambio_all».

### 3.45 liquidaciones

Un pago → una liquidación al profesional. manual = transferencia externa confirmada por admin; khipu/fintoc = PSP futuro.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null, default: (gen_random_uuid())::text |  |
| `id_pago` | `text` | fk → pagos.id, not null, unique |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `id_trabajador` | `text` |  |  |
| `monto_clp` | `numeric` | not null |  |
| `proveedor` | `text` | not null, default: 'manual' |  |
| `referencia_transferencia` | `text` | not null |  |
| `notas` | `text` |  |  |
| `id_operador` | `text` | not null |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |
| `estado_transferencia` | `text` | not null, default: 'transferido' |  |

CHECK:

- `liquidaciones_estado_transferencia_chk`: `CHECK ((estado_transferencia = ANY (ARRAY['pendiente'::text, 'transferido'::text, 'fallido'::text])))`
- `liquidaciones_monto_clp_check`: `CHECK ((monto_clp > (0)::numeric))`
- `liquidaciones_proveedor_check`: `CHECK ((proveedor = ANY (ARRAY['manual'::text, 'khipu'::text, 'fintoc'::text, 'conformidad'::text])))`

Índices:

- `CREATE INDEX idx_liquidaciones_id_trabajo_fkey ON public.liquidaciones USING btree (id_trabajo)`
- `CREATE INDEX liquidaciones_creado_idx ON public.liquidaciones USING btree (creado_en DESC)`
- `CREATE UNIQUE INDEX liquidaciones_pago_uidx ON public.liquidaciones USING btree (id_pago)`

**RLS.** RLS activo. El profesional ve la liquidación de sus pagos; un administrador ve todas. La confirmación de transferencia es por RPC de admin. Políticas: DELETE «liquidaciones_admin_delete», INSERT «liquidaciones_admin_insert», UPDATE «liquidaciones_admin_update», SELECT «liquidaciones_select».

### 3.46 metodos_pago_oneclick

Tarjeta inscrita Oneclick. RLS niega el acceso a anon y authenticated: solo service_role (Edge Functions).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_usuario` | `text` | pk, not null |  |
| `username` | `text` | not null |  |
| `tbk_user` | `text` |  |  |
| `tipo_tarjeta` | `text` |  |  |
| `ultimos4` | `text` |  |  |
| `estado` | `text` | not null, default: 'pendiente' |  |
| `token_inscripcion` | `text` |  |  |
| `id_trabajo_pendiente` | `text` |  |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |
| `actualizado_en` | `timestamptz` | not null, default: now() |  |
| `url_inscripcion` | `text` |  |  |
| `ticket_handoff` | `text` | unique |  |

CHECK:

- `metodos_pago_oneclick_estado_chk`: `CHECK ((estado = ANY (ARRAY['pendiente'::text, 'activa'::text, 'rechazada'::text])))`

Índices:

- `CREATE UNIQUE INDEX metodos_pago_oneclick_ticket_handoff_uidx ON public.metodos_pago_oneclick USING btree (ticket_handoff) WHERE (ticket_handoff IS NOT NULL)`
- `CREATE INDEX metodos_pago_oneclick_token_idx ON public.metodos_pago_oneclick USING btree (token_inscripcion) WHERE ((token_inscripcion IS NOT NULL) AND (length(TRIM(BOTH FROM token_inscripcion)) > 0))`

**RLS.** RLS activo. Política ALL con USING/CHECK false para anon y authenticated. Las tarjetas solo las maneja service_role (Edge Functions). Políticas: ALL «metodos_pago_oneclick_sin_acceso_cliente».

### 3.47 cuentas_bancarias

Datos bancarios del profesional para pagar la liquidación. RLS: solo el dueño y un administrador. No es un dato público.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_usuario` | `uuid` | pk, fk → perfiles.id, not null |  |
| `banco` | `text` | not null |  |
| `tipo_cuenta` | `text` | not null |  |
| `numero_cuenta` | `text` | not null |  |
| `rut_titular` | `text` | not null |  |
| `nombre_titular` | `text` | not null |  |
| `actualizado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `cuentas_bancarias_numero_chk`: `CHECK ((numero_cuenta ~ '^[0-9]{4,20}$'::text))`
- `cuentas_bancarias_tipo_chk`: `CHECK ((tipo_cuenta = ANY (ARRAY['vista'::text, 'corriente'::text, 'rut'::text, 'ahorro'::text])))`

**RLS.** RLS activo. ALL para el dueño o un administrador. No es un dato público. Políticas: ALL «cuentas_bancarias_propietario».

### 3.48 app_config

Pares clave/valor de configuración (demo_modo, admin_requiere_aal2, etc.). RLS niega el acceso a clientes; lo lee el backend.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `clave` | `text` | pk, not null |  |
| `valor` | `text` | not null |  |
| `actualizado_en` | `timestamptz` | not null, default: now() |  |

**RLS.** RLS activo. Política ALL con USING/CHECK false para anon y authenticated. Nadie del cliente lee ni escribe; solo service_role (bypass RLS) o funciones definer. Políticas: ALL «app_config_sin_acceso_cliente».

### 3.49 ranking_config

Una fila default. Pesos del listado de profesionales.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null, default: 'default' |  |
| `peso_calificacion` | `numeric` | not null, default: 0.32 |  |
| `peso_completados` | `numeric` | not null, default: 0.18 |  |
| `peso_rechazos` | `numeric` | not null, default: 0.12 |  |
| `peso_verificacion` | `numeric` | not null, default: 0.10 |  |
| `peso_impulso` | `numeric` | not null, default: 0.08 |  |
| `peso_recencia` | `numeric` | not null, default: 0.08 |  |
| `peso_confianza` | `numeric` | not null, default: 0.12 |  |
| `prior_bayes` | `numeric` | not null, default: 3.80 |  |
| `n_bayes` | `numeric` | not null, default: 8 |  |
| `umbral_revision` | `numeric` | not null, default: 0.55 |  |
| `umbral_auto_excluir` | `numeric` | not null, default: 0.90 |  |
| `aprendizaje_activo` | `integer` | not null, default: 1 |  |
| `tasa_aprendizaje` | `numeric` | not null, default: 0.15 |  |
| `pesos_senal` | `jsonb` | not null, default: '{"rafaga": 0.45, "outlier": 0.22, "auto_resena": 1.00, "cuenta_nueva": 0.25, "duplicado_texto": 0.40, "sin_trabajo_valido": 0.95, "texto_vacio_extremo": 0.20, "granja_cinco_estrellas": 0.50}' |  |
| `actualizado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `ranking_config_unica`: `CHECK ((id = 'default'::text))`

**RLS.** RLS activo. La lectura de la fila default está permitida a autenticados (para el listado). Solo un administrador la actualiza por RPC. Políticas: ALL «ranking_config_admin».

### 3.50 senales_resena

Señales de reseña dudosa. Un falso positivo baja el peso de esa señal.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_calificacion` | `text` | fk → calificaciones.id, not null |  |
| `tipo_senal` | `text` | not null |  |
| `puntaje` | `numeric` | not null |  |
| `detalle` | `text` |  |  |
| `estado` | `text` | not null, default: 'pendiente' |  |
| `resuelto_por` | `uuid` |  |  |
| `resuelto_en` | `timestamptz` |  |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `senales_resena_estado_chk`: `CHECK ((estado = ANY (ARRAY['pendiente'::text, 'fraude_confirmado'::text, 'falso_positivo'::text, 'descartada'::text])))`

Índices:

- `UNIQUE (id_calificacion, tipo_senal)`
- `CREATE INDEX senales_resena_estado_idx ON public.senales_resena USING btree (estado, creado_en DESC)`
- `CREATE UNIQUE INDEX senales_resena_unica ON public.senales_resena USING btree (id_calificacion, tipo_senal)`

**RLS.** RLS activo. Cola de reseñas dudosas: la ve y resuelve un administrador. Políticas: SELECT «senales_resena_admin».

### 3.51 ranking_aprendizaje

Ajuste de los pesos del ranking y las métricas de ese cambio.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `motivo` | `text` | not null |  |
| `pesos_antes` | `jsonb` | not null |  |
| `pesos_despues` | `jsonb` | not null |  |
| `metricas` | `jsonb` |  |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

**RLS.** RLS activo. Lectura de administración. La escritura la hace el aprendizaje de pesos. Políticas: SELECT «ranking_aprendizaje_admin».

### 3.52 eventos_ranking

Evento que alimenta el ranking de un profesional.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajador` | `uuid` | not null |  |
| `id_trabajo` | `text` |  |  |
| `tipo_evento` | `text` | not null |  |
| `factores` | `jsonb` | not null, default: '{}' |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

Índices:

- `CREATE INDEX eventos_ranking_trabajador_idx ON public.eventos_ranking USING btree (id_trabajador, tipo_evento)`

**RLS.** RLS activo. Lectura de administración; la escritura la hacen triggers y funciones definer. Políticas: SELECT «eventos_ranking_select_admin».

## 4. Relaciones (claves foráneas físicas)

Se listan solo las FK declaradas en Postgres. Algunas dependencias lógicas (por ejemplo `trabajador_precios.id_usuario` → `trabajadores.id_usuario`) no tienen FK física porque el tipo en la base viva es text y no uuid.

| Tabla | Columnas | Referencia | ON DELETE |
|-------|----------|------------|-----------|
| `notificaciones` | `id_usuario` | `perfiles(id)` | CASCADE |
| `suscripciones` | `id_usuario` | `perfiles(id)` | CASCADE |
| `consentimientos_usuario` | `id_usuario` | `perfiles(id)` | CASCADE |
| `eventos_abuso` | `id_usuario` | `perfiles(id)` | CASCADE |
| `acciones_pendientes` | `id_usuario` | `perfiles(id)` | CASCADE |
| `registros_error_app` | `id_usuario` | `perfiles(id)` | — |
| `dispositivos_push` | `id_usuario` | `perfiles(id)` | CASCADE |
| `verificacion_eventos` | `id_usuario` | `perfiles(id)` | CASCADE |
| `regiones` | `id_pais` | `paises(id)` | — |
| `comunas` | `id_region` | `regiones(id)` | — |
| `trabajadores` | `id_comuna` | `comunas(id)` | SET NULL |
| `trabajadores` | `id_region` | `regiones(id)` | SET NULL |
| `trabajadores` | `id_usuario` | `perfiles(id)` | CASCADE |
| `trabajador_servicios` | `id_trabajador` | `perfiles(id)` | CASCADE |
| `trabajador_horarios` | `id_usuario` | `trabajadores(id_usuario)` | CASCADE |
| `portafolio_trabajador` | `id_trabajador` | `perfiles(id)` | CASCADE |
| `impulsos` | `id_trabajador` | `perfiles(id)` | CASCADE |
| `configuraciones_servicio` | `id_servicio` | `servicios(id)` | CASCADE |
| `trabajos` | `id_servicio` | `servicios(id)` | SET NULL |
| `trabajos` | `id_usuario` | `perfiles(id)` | CASCADE |
| `trabajos` | `id_trabajador` | `perfiles(id)` | SET NULL |
| `trabajos` | `id_comuna` | `comunas(id)` | SET NULL |
| `mensajes` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `fotos_trabajo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `calificaciones` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `disputas` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `disputa_mensajes` | `id_autor` | `perfiles(id)` | — |
| `disputa_mensajes` | `id_disputa` | `disputas(id)` | CASCADE |
| `acuerdos_trabajo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `acuerdos_trabajo` | `propuesto_por` | `perfiles(id)` | — |
| `cancelaciones_trabajo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `ubicacion_en_vivo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `ubicacion_en_vivo` | `id_trabajador` | `trabajadores(id_usuario)` | CASCADE |
| `reprogramaciones_trabajo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `pines_inicio_trabajo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `bloqueos_pin_inicio` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `propuestas_cotizacion` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `propuestas_cotizacion` | `id_trabajador` | `perfiles(id)` | CASCADE |
| `pagos` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `ordenes_cambio` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `liquidaciones` | `id_pago` | `pagos(id)` | — |
| `liquidaciones` | `id_trabajo` | `trabajos(id)` | — |
| `cuentas_bancarias` | `id_usuario` | `perfiles(id)` | CASCADE |
| `senales_resena` | `id_calificacion` | `calificaciones(id)` | CASCADE |

## 5. Enums y vistas

El esquema `public` no define tipos ENUM ni vistas (ni materializadas). Los estados y conjuntos cerrados (rol de una reprogramación, tipo de acuerdo, estado de verificación, etc.) se restringen con CHECK sobre columnas `text` o `boolean`.

## 6. Funciones RPC y SECURITY DEFINER

Hay 140 funciones (o procedimientos) en `public`. 116 son SECURITY DEFINER. A continuación se documentan las que forman la API de cliente (GRANT a `anon` o `authenticated`) y, en un segundo listado, las de backend / disparadores (solo `service_role` o uso interno).

### 6.1 API de cliente (`anon` / `authenticated`)

| Función | Argumentos | Retorno | Seguridad | Quién ejecuta | Propósito |
|---------|------------|---------|-----------|---------------|-----------|
| `_hora_santiago` | p_ts timestamp with time zone | text | SECURITY INVOKER | authenticated | Convierte un timestamptz a la hora oficial de Chile (America/Santiago), con horario de verano. |
| `abrir_disputa` | p_id text, p_id_trabajo text, p_motivo text, p_descripcion text | void | SECURITY DEFINER | authenticated | El cliente o el profesional abre una disputa sobre un trabajo activo. |
| `acuerdo_pendiente` | p_id_trabajo text | TABLE(id text, tipo text, estado text, acepta_cliente boolean, acepta_trabajador boolean) | SECURITY DEFINER | authenticated | Devuelve el acuerdo aún pendiente de un trabajo, si existe. |
| `admin_actualizar_estado_disputa` | p_id text, p_estado text, p_resolucion text | void | SECURITY DEFINER | authenticated | Un administrador cambia el estado o la resolución de una disputa. |
| `admin_metricas_resumen` | — | json | SECURITY DEFINER | authenticated | Métricas del panel ejecutivo (solo administrador). |
| `aprender_pesos_ranking_admin` | — | jsonb | SECURITY DEFINER | authenticated | Un administrador dispara el aprendizaje de pesos. |
| `asignar_trabajador_trabajo` | p_trabajo_id text, p_trabajador_id text | trabajos | SECURITY DEFINER | authenticated | Acepta un trabajo abierto. El destino tiene que tener rol trabajador. Un cliente no puede autoasignarse. |
| `base_publica_profesional` | p_id uuid | TABLE(latitud_base double precision, longitud_base double precision) | SECURITY DEFINER | anon, authenticated | Ficha pública de un profesional para el catálogo (sin datos sensibles). Disponible también para anon. |
| `calificar_cliente` | p_trabajo_id text, p_puntaje integer, p_comentario text | numeric | SECURITY DEFINER | authenticated | El profesional califica al cliente al terminar el trabajo. |
| `categorias_con_disponibles` | — | SETOF text | SECURITY DEFINER | anon, authenticated | Categorías del catálogo que hoy tienen profesionales disponibles. También para anon. |
| `cerrar_trabajo_conforme` | p_trabajo_id text | trabajos | SECURITY DEFINER | authenticated | El cliente cierra el trabajo conforme y habilita la liberación del pago retenido. |
| `comentar_disputa` | p_id text, p_comentario text | void | SECURITY DEFINER | authenticated | Una de las partes agrega un comentario al hilo de la disputa. |
| `consola_disputas_abiertas` | — | TABLE(id text, id_trabajo text, motivo text, descripcion text, estado text, decision_sugerida text, motivo_regla text, vence_en timestamp with time zone, creado_en text, nombre_cliente text, nombre_profesional text, monto_retenido numeric) | SECURITY DEFINER | authenticated | Cola de disputas para la consola de escritorio (administrador, soporte o qa). qa no ve la evidencia del domicilio. |
| `crear_intencion_pago` | p_id_trabajo text, p_monto numeric, p_buy_order text | pagos | SECURITY DEFINER | authenticated | Crea la intención de pago (Webpay) del trabajo, con el monto que fija el servidor. |
| `crear_intencion_pago_orden_cambio` | p_id_trabajo text, p_id_orden_cambio text, p_monto numeric, p_buy_order text | pagos | SECURITY DEFINER | authenticated | Crea la intención de pago de una orden de cambio. |
| `enviar_verificacion_profesional` | p_nota text | void | SECURITY DEFINER | authenticated | El profesional envía o reenvía su solicitud de verificación. |
| `es_parte_trabajo` | p_trabajo_id text | boolean | SECURITY DEFINER | authenticated | True si el usuario autenticado es el cliente o el profesional del trabajo. |
| `es_rol_trabajador` | p_usuario_id text | boolean | SECURITY DEFINER | authenticated | True si el perfil indicado tiene rol de profesional. |
| `evidencia_disputa` | p_id_disputa text | TABLE(id text, imagen_base64 text) | SECURITY DEFINER | authenticated | Devuelve la evidencia del trabajo en disputa. Administrador o soporte; qa no la ve. |
| `fichas_sensibles_admin` | — | TABLE(id_usuario uuid, latitud_base double precision, longitud_base double precision, nota_verificacion text) | SECURITY DEFINER | authenticated | Lectura de fichas con datos sensibles, solo administrador. |
| `fijar_geo_trabajador` | — | trigger | SECURITY INVOKER | anon, authenticated | Normaliza la geografía (comuna, región, base) de la ficha del profesional. |
| `fijar_prioridad_trabajador` | p_id uuid, p_prioridad integer | void | SECURITY DEFINER | authenticated | Un administrador ajusta prioridad_manual (−50 a 50). |
| `fijar_verificacion_profesional` | p_id_usuario uuid, p_estado text, p_nota text | void | SECURITY DEFINER | authenticated | Un administrador cambia el estado de verificación y deja nota. |
| `guardar_config_ranking` | p_cfg jsonb | jsonb | SECURITY DEFINER | authenticated | Un administrador guarda los pesos y umbrales de ranking_config. |
| `guardar_horarios_propios` | p_horarios jsonb | jsonb | SECURITY DEFINER | authenticated | El profesional guarda su plantilla semanal (reemplazo atómico). |
| `horarios_disponibles_propios` | — | jsonb | SECURITY DEFINER | authenticated | El profesional lee su propia plantilla semanal. |
| `horarios_libres_profesional` | p_id_trabajador uuid, p_dias integer | TABLE(inicio timestamp with time zone) | SECURITY DEFINER | anon, authenticated | Huecos libres de un profesional en los próximos n días (también anon). No expone la tabla trabajador_horarios. |
| `intentar_pin_inicio` | p_trabajo_id text, p_pin text | jsonb | SECURITY DEFINER | authenticated | El profesional prueba el PIN del cliente. Tras 5 fallos, bloquea 15 minutos. |
| `is_admin` | — | boolean | SECURITY DEFINER | authenticated | True si el usuario autenticado tiene rol admin o administrador. |
| `listar_profesionales_catalogo` | p_categoria text, p_zona text, p_cursor_calificacion numeric, p_cursor_id uuid, p_limit integer | TABLE(id_usuario uuid, profesion text, descripcion text, calificacion numeric, tarifa_visita numeric, categoria_servicio text, zona_trabajo text, nombre text, ruta_foto_perfil text, latitud_base double precision, longitud_base double precision, radio_servicio_km numeric, origen_base text, trabajos_completados integer, score_listado numeric, prioridad_manual integer, radio_urbano_km numeric, tarifa_fuera_radio_clp integer, es_elite boolean) | SECURITY DEFINER | anon, authenticated | Listado paginado del marketplace (también anon), ordenado por el ranking. |
| `listar_senales_resena` | p_estado text, p_limit integer | TABLE(id text, id_calificacion text, tipo_senal text, puntaje numeric, detalle text, estado text, creado_en timestamp with time zone, puntaje_resena integer, comentario text, estado_revision text, peso_confianza numeric, id_trabajo text, id_trabajador uuid, nombre_trabajador text, nombre_cliente text) | SECURITY DEFINER | authenticated | Cola de señales de reseña para un administrador. |
| `listar_trabajos_marketplace` | p_limite integer | TABLE(id text, estado text, descripcion text, creado_en text, actualizado_en text, id_servicio text, modalidad_cobro text, metadatos_servicio text) | SECURITY DEFINER | authenticated | Trabajos abiertos que un profesional puede tomar. |
| `marcar_orden_cambio_pagada` | p_id_orden_cambio text, p_id_pago text | ordenes_cambio | SECURITY DEFINER | authenticated | Asocia el pago a la orden de cambio cuando Webpay confirma el cobro. |
| `mi_ficha_propia` | — | TABLE(latitud_base double precision, longitud_base double precision, radio_servicio_km numeric, origen_base text, estado_verificacion text, nota_verificacion text) | SECURITY DEFINER | authenticated | Devuelve la ficha del profesional autenticado, incluyendo campos no públicos. |
| `minuto_utc` | p_valor text | timestamp with time zone | SECURITY INVOKER | authenticated | Normaliza una fecha-hora en texto al minuto UTC; se usa en el índice único de agenda. |
| `obtener_config_ranking` | — | jsonb | SECURITY DEFINER | authenticated | Lee la configuración actual del ranking. |
| `obtener_pin_inicio` | p_trabajo_id text | text | SECURITY DEFINER | authenticated | El cliente (o un administrador) obtiene el PIN para mostrárselo al profesional. |
| `obtener_trabajo_sin_direccion` | p_id text | jsonb | SECURITY DEFINER | authenticated | Detalle de un trabajo sin exponer la dirección al que no corresponde. |
| `perfil_contacto_si_trabajo_activo` | p_perfil_id uuid | TABLE(id uuid, nombre text, correo text) | SECURITY DEFINER | authenticated | Entrega datos de contacto de un perfil solo si hay un trabajo activo conjunto. |
| `perfiles_publicos_por_ids` | p_ids uuid[] | TABLE(id uuid, nombre text, rol text, ruta_foto_perfil text) | SECURITY DEFINER | authenticated | Nombre y foto públicos de una lista de perfiles. |
| `profesionales_ocupados` | p_ids uuid[] | SETOF uuid | SECURITY DEFINER | authenticated | Indica, de una lista de profesionales, cuáles están ocupados ahora. |
| `proponer_acuerdo` | p_id text, p_id_trabajo text, p_tipo text | jsonb | SECURITY DEFINER | authenticated | Una de las partes propone rehacer, aceptar o anular un trabajo. |
| `proponer_reprogramacion` | p_trabajo_id text, p_fecha timestamp with time zone, p_motivo text | reprogramaciones_trabajo | SECURITY DEFINER | authenticated | El cliente o el profesional propone una nueva fecha (CU-33). Queda una sola pendiente por trabajo. |
| `publicar_ubicacion_trabajo` | p_trabajo_id text, p_lat double precision, p_lng double precision, p_precision double precision | void | SECURITY DEFINER | authenticated | El profesional publica su GPS durante un trabajo activo. |
| `quitar_dispositivo_push` | p_token text | void | SECURITY DEFINER | authenticated | El usuario elimina un token de notificaciones push. |
| `rechazar_trabajo_pendiente` | p_trabajo_id text, p_metadatos text | trabajos | SECURITY DEFINER | authenticated | Cancela un pendiente. Solo admin o el trabajador ya asignado. Sin id_trabajador el control no se salta. |
| `refrescar_ranking_todos_admin` | — | integer | SECURITY DEFINER | authenticated | Un administrador dispara el recálculo global del ranking. |
| `registrar_dispositivo_push` | p_token text, p_plataforma text | void | SECURITY DEFINER | authenticated | Registra o actualiza el token push del dispositivo del usuario. |
| `registrar_transferencia_profesional` | p_id_pago text, p_referencia text, p_notas text | jsonb | SECURITY DEFINER | authenticated | Un administrador confirma la transferencia de una liquidación (estado_transferencia). |
| `resolver_senal_resena` | p_id text, p_estado text | void | SECURITY DEFINER | authenticated | Un administrador resuelve una señal de reseña dudosa. |
| `responder_acuerdo` | p_id text, p_acepta boolean | jsonb | SECURITY DEFINER | authenticated | La contraparte acepta o rechaza un acuerdo pendiente. |
| `responder_reprogramacion` | p_id uuid, p_acepta boolean | reprogramaciones_trabajo | SECURITY DEFINER | authenticated | La contraparte acepta o rechaza la nueva fecha (CU-33). Si acepta, actualiza trabajos.fecha_programada. |
| `resumen_calificacion_clientes` | p_ids uuid[] | TABLE(id_usuario uuid, promedio numeric, cantidad integer) | SECURITY DEFINER | authenticated | Promedio y conteo de reputación de una lista de clientes. |
| `retirar_reprogramacion` | p_id uuid | reprogramaciones_trabajo | SECURITY DEFINER | authenticated | Quien propuso el cambio de fecha retira la propuesta pendiente (CU-33). |
| `rol_consola` | — | text | SECURITY DEFINER | authenticated | Devuelve administrador, soporte o qa si el usuario autenticado tiene un rol de la consola de escritorio; si no, null. |
| `seleccionar_cotizacion` | p_id_cotizacion text | trabajos | SECURITY DEFINER | authenticated | El cliente elige una cotización y queda asociada al trabajo. |
| `sincronizar_estado_pago_trabajo` | p_trabajo_id text | trabajos | SECURITY DEFINER | authenticated | Fuerza la copia del estado del pago principal al trabajo. |
| `slug_geo` | p_texto text | text | SECURITY INVOKER | anon, authenticated | Normaliza un texto a slug geográfico (comuna/región). También anon. |
| `soporte_comentar_disputa` | p_id text, p_comentario text | void | SECURITY DEFINER | authenticated | Un administrador o soporte deja una nota visible para las partes en el hilo de la disputa. qa no puede. |
| `texto_a_timestamptz` | p_valor text | timestamp with time zone | SECURITY INVOKER | authenticated | Interpreta un texto de fecha/hora como timestamptz (agenda y CU-33). |
| `texto_tiene_contacto` | p_texto text | boolean | SECURITY INVOKER | anon, authenticated | Detecta si un texto parece incluir teléfono o correo. También anon (validación de formularios). |
| `trabajador_reservable` | p_trabajador uuid | boolean | SECURITY DEFINER | authenticated | True si el profesional puede tomarse en la fecha consultada (horario y ocupación). |
| `trabajo_admite_disputa` | p_estado text | boolean | SECURITY INVOKER | authenticated | True si el estado del trabajo permite abrir una disputa. |
| `transicion_trabajo_permitida` | p_desde text, p_hacia text, p_modalidad text | boolean | SECURITY INVOKER | authenticated | Valida si un cambio de estado es legal según el estado actual y la modalidad. |
| `transicionar_trabajo` | p_trabajo_id text, p_nuevo_estado text, p_pin text | trabajos | SECURITY DEFINER | authenticated | Transición de estado. Iniciar (aceptado o en_camino -> en_curso) exige el PIN del cliente al profesional asignado. El admin no lo exige. Tras 5 PIN malos, 15 minutos de bloqueo. |
| `transiciones_trabajo_posibles` | p_desde text, p_modalidad text | text[] | SECURITY DEFINER | authenticated | Lista los estados siguientes permitidos desde el estado y la modalidad actuales. |
| `ver_reputacion_cliente` | p_cliente uuid | TABLE(reputacion numeric, calificaciones integer, disputas integer) | SECURITY DEFINER | authenticated | Devuelve la reputación pública de un cliente (promedio y conteo). |
| `vincular_trabajador_cotizacion` | p_trabajo_id text, p_trabajador_id text | trabajos | SECURITY DEFINER | authenticated | Asocia un profesional a un trabajo que está en cotización. |
| `vincular_trabajador_solicitud` | p_trabajo_id text, p_trabajador_id text | trabajos | SECURITY DEFINER | authenticated | Asocia un profesional a una solicitud de trabajo abierta. |

### 6.2 Backend, cron y disparadores (principalmente `service_role`)

| Función | Argumentos | Retorno | Seguridad | Propósito |
|---------|------------|---------|-----------|-----------|
| `_evaluar_resena_trigger` | — | trigger | SECURITY DEFINER | Disparador que encola la evaluación automática de una reseña nueva. |
| `_normalizar_pesos_ranking` | p_cal numeric, p_comp numeric, p_rech numeric, p_ver numeric, p_imp numeric, p_rec numeric, p_conf numeric | numeric[] | SECURITY INVOKER | Normaliza los pesos del ranking para que sumen 1. |
| `_notificar_reprogramacion` | p_destino uuid, p_id_trabajo text, p_titulo text, p_cuerpo text | void | SECURITY DEFINER | Crea la notificación de una propuesta, respuesta o retiro de reagendamiento. |
| `_ranking_cfg` | — | ranking_config | SECURITY DEFINER | Lee la fila default de ranking_config. |
| `_registrar_evento_ranking` | p_trabajador uuid, p_trabajo text, p_tipo text | void | SECURITY DEFINER | Inserta un evento en eventos_ranking. |
| `aplicar_cierre_disputa` | p_disputa_id text, p_operador text, p_decision text, p_resolucion text | jsonb | SECURITY DEFINER | Aplica la decisión de cierre de una disputa (uso interno / servicio). |
| `aprender_pesos_ranking` | — | jsonb | SECURITY DEFINER | Ajusta los pesos del ranking a partir de las señales (interno). |
| `asegurar_pin_inicio` | p_trabajo_id text | text | SECURITY DEFINER | Crea el PIN de un trabajo si todavía no existe (interno). |
| `borrar_gps_si_trabajo_cerrado` | — | trigger | SECURITY DEFINER | Trigger: borra ubicacion_en_vivo cuando el trabajo deja de estar activo. |
| `clasificar_disputa` | p_trabajo_id text, p_motivo text | TABLE(decision text, regla text, estado text, vence timestamp with time zone) | SECURITY DEFINER | Clasificación automática de una disputa (soporte automático, interno). |
| `confirmar_trabajo_tras_captura` | p_id_pago text | text | SECURITY DEFINER | Tras capturar el pago (Webpay/Oneclick), confirma el trabajo. Lo llama el backend. |
| `copiar_estado_pago_trabajo` | — | trigger | SECURITY DEFINER | Trigger: copia el estado del pago principal a trabajos.estado_pago. |
| `crear_intencion_pago_servicio` | p_id_usuario text, p_id_trabajo text, p_monto numeric | pagos | SECURITY DEFINER | Variante de servicio (Edge Function / service_role) para crear la intención de pago. |
| `disputa_esta_activa` | p_estado text | boolean | SECURITY INVOKER | Indica si el estado de una disputa se considera activo. |
| `evaluar_resena` | p_id text | numeric | SECURITY DEFINER | Evalúa una reseña y genera señales si parece dudosa (interno). |
| `expirar_pagos_abandonados` | — | integer | SECURITY DEFINER | Marca o limpia pagos abandonados (tarea de servicio / cron). |
| `explotar_oferta_trabajador` | — | trigger | SECURITY DEFINER | Parte los JSON de oferta a las tablas 4NF (trigger). |
| `fijar_correo_codigo` | — | trigger | SECURITY DEFINER | Trigger de apoyo para códigos de restablecimiento. |
| `fijar_liquidacion_desde_pago` | — | trigger | SECURITY DEFINER | Trigger: crea o actualiza la liquidación cuando el pago queda liberado. |
| `fijar_ticket_desde_trabajo` | — | trigger | SECURITY DEFINER | Trigger: abre o actualiza el ticket de soporte asociado. |
| `fotos_trabajo_exigir_webp` | — | trigger | SECURITY INVOKER | Trigger: valida el formato de la evidencia. |
| `handle_new_user` | — | trigger | SECURITY DEFINER | Trigger de auth: crea el perfil public al registrarse un usuario. |
| `km_entre_puntos` | p_lat1 double precision, p_lng1 double precision, p_lat2 double precision, p_lng2 double precision | double precision | SECURITY INVOKER | Distancia en kilómetros entre dos coordenadas (uso interno de recargo). |
| `liberar_escrow` | p_id_pago text | pagos | SECURITY DEFINER | Libera el pago retenido al profesional (backend, service_role). |
| `liberar_escrow_manual` | p_id_pago text, p_id_operador text, p_referencia text, p_notas text, p_proveedor text | jsonb | SECURITY DEFINER | Liberación manual de un pago retenido, con referencia y notas de un operador. |
| `liberar_trabajo_sistema` | p_trabajo_id text, p_nota text | void | SECURITY DEFINER | El sistema libera o cierra un trabajo (tarea interna). |
| `limpiar_alta_trabajo` | — | trigger | SECURITY INVOKER | Limpia los datos de alta de invitado ya consumidos o vencidos (servicio). |
| `limpiar_invitados_sin_pago` | — | integer | SECURITY DEFINER | Borra cuentas de invitado sin cobro retenido, liberado ni autorizado, pasadas 24 h (service_role). |
| `listar_cuentas_demo_acceso` | — | TABLE(id uuid, nombre text, correo text, rol text, profesion text, categoria_servicio text) | SECURITY DEFINER | Lista las cuentas demo permitidas (servicio / modo demo cerrado). |
| `marcar_pago_liberado` | p_id_pago text, p_id_operador text, p_referencia text, p_notas text | void | SECURITY DEFINER | Marca un pago como liberado (operación de backend / admin). |
| `marcar_reembolso_automatico` | p_id_pago text, p_modo text | text | SECURITY DEFINER | Registra un reembolso automático pedido a Transbank. |
| `mensajes_bloquear_contacto` | — | trigger | SECURITY DEFINER | Trigger: rechaza mensajes que parecen contener teléfono o correo. |
| `mensajes_solo_marcar_leido` | — | trigger | SECURITY DEFINER | Trigger: un destinatario solo puede marcar leído, no editar el cuerpo. |
| `metadatos_sin_pin` | p_raw text | text | SECURITY INVOKER | Quita el PIN de un JSON de metadatos antes de guardarlo o devolverlo. |
| `monto_esperado_trabajo` | p_job trabajos | numeric | SECURITY DEFINER | Calcula el monto que el servidor espera para el trabajo (no lo fija el cliente). |
| `normalizar_bloques_horario` | p_horarios jsonb | jsonb | SECURITY INVOKER | Normaliza el JSON de bloques horarios antes de guardarlo. |
| `perfiles_rol_inicial_seguro` | — | trigger | SECURITY INVOKER | Trigger: impide que un alta o un update se autoasigne rol administrador, soporte o qa. |
| `profesional_tiene_trabajo_activo` | p_id_trabajador uuid | boolean | SECURITY DEFINER | True si el profesional tiene un trabajo que aún no termina. |
| `protect_profile_sensitive_fields` | — | trigger | SECURITY DEFINER | Trigger: impide que el usuario se cambie rol o estado_cuenta. |
| `proteger_campos_trabajador` | — | trigger | SECURITY INVOKER | Trigger: impide que el profesional altere score, verificación o pausa por su cuenta. |
| `proteger_campos_trabajo` | — | trigger | SECURITY INVOKER | Trigger: impide cambios de estado o de pago que no vayan por RPC. |
| `proteger_monto_cotizacion` | — | trigger | SECURITY INVOKER | Trigger: el monto de la cotización no lo cambia el cliente. |
| `proteger_verificacion_profesional` | — | trigger | SECURITY DEFINER | Trigger: el estado de verificación solo lo cambia un administrador o la RPC. |
| `recargo_traslado_clp` | p_lat_trabajador double precision, p_lng_trabajador double precision, p_lat_trabajo double precision, p_lng_trabajo double precision, p_radio_km numeric | integer | SECURITY INVOKER | Calcula el recargo de traslado según el radio urbano y la tarifa fuera de radio. |
| `reclamar_cobro_oneclick` | p_id_pago text, p_buy_order text, p_monto numeric | text | SECURITY DEFINER | Inicia o registra una autorización Oneclick (backend). |
| `reconcile_secret_valido` | p_secret text | boolean | SECURITY DEFINER | Valida el secreto de la reconciliación Webpay (vault, service_role). |
| `reembolsar_escrow` | p_id_pago text | pagos | SECURITY DEFINER | Pide la devolución del pago retenido (backend). |
| `refrescar_calificacion_trabajador` | — | trigger | SECURITY DEFINER | Trigger: recalcula trabajadores.calificacion al cambiar una reseña. |
| `refrescar_ranking_ficha` | — | trigger | SECURITY DEFINER | Recalcula el score de una ficha (trigger). |
| `refrescar_ranking_por_impulso` | — | trigger | SECURITY DEFINER | Recalcula el score cuando cambia un impulso. |
| `refrescar_ranking_todos` | — | integer | SECURITY DEFINER | Recalcula el ranking de todos (interno / cron). |
| `refrescar_ranking_trabajador` | p_id uuid | void | SECURITY DEFINER | Recalcula el ranking de un profesional concreto. |
| `registrar_disputa_ranking` | — | trigger | SECURITY DEFINER | Trigger: registra en el ranking el efecto de una disputa. |
| `registrar_evento_verificacion` | — | trigger | SECURITY DEFINER | Trigger: inserta una fila en verificacion_eventos. |
| `registrar_resultado_trabajo` | — | trigger | SECURITY DEFINER | Trigger: actualiza completados, rechazos u otras señales al terminar un trabajo. |
| `resolver_soporte_automatico` | — | jsonb | SECURITY DEFINER | Intenta resolver una disputa con las reglas automáticas (interno). |
| `rls_auto_enable` | — | event_trigger | SECURITY DEFINER | Utilidad interna para asegurar RLS en tablas nuevas. |
| `simular_transicion_pago` | p_pago_id text, p_nuevo_estado text | pagos | SECURITY DEFINER | LEGACY — no usar desde clientes. Transiciones PSP vía Edge webpay-commit / liberar_escrow. |
| `soporte_numero` | p_clave text, p_default numeric | numeric | SECURITY DEFINER | Lee un número de configuración de soporte automático. |
| `trabajador_horarios_desde_alta` | — | trigger | SECURITY DEFINER | Trigger de apoyo al crear la plantilla semanal en el alta. |
| `trabajador_horarios_normalizar` | — | trigger | SECURITY INVOKER | Trigger: normaliza día y horas al guardar un horario. |
| `trabajadores_marcar_pausa_por_trabajo` | — | trigger | SECURITY DEFINER | Trigger: enciende o apaga pausa_por_trabajo y disponible según los trabajos activos. |
| `trabajo_tiene_evidencia` | p_trabajo_id text | boolean | SECURITY DEFINER | True si el trabajo ya tiene evidencia cargada. |
| `trabajos_bloquear_en_curso_directo` | — | trigger | SECURITY INVOKER | Trigger: no se puede pasar a en_curso sin el flujo del PIN. |
| `trabajos_contar_completados` | — | trigger | SECURITY DEFINER | Trigger: mantiene trabajadores.trabajos_completados. |
| `trabajos_crear_pin_inicio` | — | trigger | SECURITY DEFINER | Trigger: genera el PIN al quedar el trabajo en un estado que lo requiere. |
| `trabajos_exigir_evidencia` | — | trigger | SECURITY INVOKER | Trigger: exige evidencia antes de ciertos cierres. |
| `trabajos_fecha_solo_por_rpc` | — | trigger | SECURITY INVOKER | Trigger CU-33: la fecha programada solo cambia por las RPC de reagendamiento. |
| `trabajos_horario_unico` | — | trigger | SECURITY DEFINER | Apoyo al índice único de un trabajo activo por profesional y minuto. |
| `trabajos_restablecer_disponibilidad` | — | trigger | SECURITY DEFINER | Trigger: devuelve la disponibilidad del profesional al terminar o cancelar. |
| `trabajos_vencer_reprogramaciones` | — | trigger | SECURITY DEFINER | Marca como vencidas las propuestas de reagendamiento que ya no aplican (interno / al cambiar el trabajo). |

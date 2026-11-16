# Diccionario de base de datos — My Works App

> Generado por `docs/_gen_diccionario_desde_schema.py` el 2026-11-16 (America/Santiago) desde el esquema real de Supabase `wxqrfcqifkfgawrnqmnj`. No editar a mano: actualizar el snapshot o volver a introspectar y regenerar.

| Campo | Valor |
|-------|-------|
| Proyecto | My Works App |
| Motor | PostgreSQL (Supabase), esquema `public` |
| Convención | Nombres en español, `snake_case` |
| Modelo fuente | Modelo lógico v2.5 · 52 tablas public · 2026-11-16 (America/Santiago) · alineado a la BD viva wxqrfcqifkfgawrnqmnj hasta la migración 20261116044049 (stats_profesional_fuente_unica). Archivo de migración en el repo: 20261116044049_stats_profesional_fuente_unica.sql. Diccionario generado desde information_schema y pg_catalog (solo lectura). No hay tipos ENUM ni vistas en public: los estados se restringen con CHECK. No ejecutar el SQL de consulta contra producción. |
| Tablas en el esquema | 52 |
| Columnas | 437 |
| Claves foráneas físicas | 78 |
| Políticas RLS | 108 |
| Funciones public | 148 |
| Última migración aplicada | `20261116044049` — stats_profesional_fuente_unica |
| Archivo de migración (repo) | `20261116044049_stats_profesional_fuente_unica.sql` |
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
- `trabajador_precios`: `id_usuario` pasa de text a uuid con FK a trabajadores (auditoría 2026-11-16).
- `trabajador_servicios_extra`: Igual que precios: `id_usuario` pasa a uuid con FK.
- `metodos_pago_oneclick`: `id_usuario` pasa de text a uuid con FK a perfiles (auditoría 2026-11-16).
- `trabajadores`: Se agregan `usa_horario` y `pausa_por_trabajo`. `es_elite` se documenta como columna GENERATED ALWAYS.
- `perfiles`: Defaults en español (`'usuario'`, `'activo'`), CHECK de rol y estado, FK a auth.users y reputación protegida contra edición del propio usuario (auditoría 2026-11-16).
- `pagos`: Las columnas de alta de invitado (`alta_nonce_hash`, `alta_jti`, `alta_consumido_en`) ya estaban en el v2.3 (26 columnas). Se aclara su papel y el índice único de `alta_jti`.
- `trabajos`: Sigue con 20 columnas. Cambia el comportamiento: la fecha programada solo se altera por las RPC de CU-33 y hay un índice único de agenda por profesional y minuto.

Además se documentan, por primera vez en este diccionario, las políticas RLS (resumen en lenguaje natural), los CHECK, los índices únicos parciales y las funciones RPC / SECURITY DEFINER relevantes (reagendamiento CU-33, PIN de inicio, roles soporte/qa, alta de invitado, escrow Webpay).

## 2. Índice de tablas por grupo

| # | Grupo | Tabla | Columnas | RLS | Descripción |
|---|-------|-------|----------|-----|-------------|
| 1 | identidad | `perfiles` | 9 | sí | Identidad de la aplicación: perfiles.id coincide con auth.users.id (esquema auth de Supabase, fuera de public; clave foránea con ON DELETE CASCADE desde la auditoría 2026-11-16).… |
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
| 19 | catalogo_4nf | `trabajador_precios` | 3 | sí | Precio por código de servicio del profesional. id_usuario es uuid con clave foránea a trabajadores (ON DELETE CASCADE) desde la auditoría 2026-11-16; antes era text sin FK. |
| 20 | catalogo_4nf | `trabajador_servicios_extra` | 6 | sí | Servicio adicional definido por el profesional. id_usuario es uuid con clave foránea a trabajadores, igual que en trabajador_precios. |
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
| 40 | pedido | `bloqueos_pin_inicio` | 6 | sí | Contador de intentos fallidos del PIN, bloqueo temporal (15 minutos tras 5 fallos) y ventana en la que el PIN ya fue validado. Escriben solo las funciones SECURITY DEFINER o… |
| 41 | pedido | `intentos_pin_inicio` | 6 | sí | Auditoría de cada intento de PIN de inicio. Escriben solo funciones SECURITY DEFINER; un administrador puede leerla. |
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

Identidad de la aplicación: perfiles.id coincide con auth.users.id (esquema auth de Supabase, fuera de public; clave foránea con ON DELETE CASCADE desde la auditoría 2026-11-16). El default de rol es 'usuario' y el de estado_cuenta es 'activo'. Los CHECK perfiles_rol_chk y perfiles_estado_cuenta_chk cierran los conjuntos: usuario, trabajador, administrador, soporte y qa; activo, suspendido, bloqueado y eliminado. Los roles privilegiados (administrador, soporte, qa) no se pueden autoasignar: el trigger perfiles_rol_inicial_seguro y protect_profile_sensitive_fields lo impiden. reputacion_cliente y calificaciones_cliente los calcula calificar_cliente(); el usuario no puede editarlos (trigger protect_profile_sensitive_fields).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `uuid` | pk, fk → auth.users.id, not null, default: gen_random_uuid() |  |
| `nombre` | `text` | not null, default: '' |  |
| `correo` | `text` |  |  |
| `rol` | `text` | not null, default: 'usuario' | usuario \| trabajador \| administrador |
| `estado_cuenta` | `text` | not null, default: 'activo' | activo \| suspendido \| bloqueado \| eliminado |
| `ruta_foto_perfil` | `text` |  |  |
| `creado_en` | `text` | not null, default: to_char((now() AT TIME ZONE 'utc'::text), 'YYYY-MM-DD"T"HH24:MI:SS.US'::text) |  |
| `reputacion_cliente` | `numeric(3,2)` |  |  |
| `calificaciones_cliente` | `integer` | not null, default: 0 |  |

CHECK:

- `perfiles_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `perfiles_estado_cuenta_chk`: `CHECK ((estado_cuenta = ANY (ARRAY['activo'::text, 'suspendido'::text, 'bloqueado'::text, 'eliminado'::text])))`
- `perfiles_reputacion_cliente_chk`: `CHECK (((reputacion_cliente IS NULL) OR ((reputacion_cliente >= (1)::numeric) AND (reputacion_cliente <= (5)::numeric))))`
- `perfiles_rol_chk`: `CHECK ((rol = ANY (ARRAY['usuario'::text, 'trabajador'::text, 'administrador'::text, 'soporte'::text, 'qa'::text])))`

Índices:

- `CREATE INDEX idx_perfiles_rol ON public.perfiles USING btree (rol)`

**RLS.** RLS activo. El usuario lee su ficha y, con límites, fichas públicas (nombre y foto) de otros; no ve correo ajeno por esta vía. La escritura de campos sensibles (rol, estado_cuenta, reputacion_cliente, calificaciones_cliente) está protegida por trigger. El contacto completo solo se entrega con perfil_contacto_si_trabajo_activo. Políticas: INSERT «perfiles_insert», SELECT «perfiles_select», UPDATE «perfiles_update».

**Forma normal: BCNF.** La clave es el id de Auth. Los conjuntos de rol y estado están cerrados con CHECK y los valores por defecto ahora son los mismos que usa la aplicación (usuario, activo). Dato repetido a propósito: correo repite el correo de auth.users para mostrarlo y buscarlo sin salir de public (diferencias: 0). reputacion_cliente y calificaciones_cliente son totales calculados por calificar_cliente(); desde la auditoría un usuario no puede editarlos.

**Relaciones en palabras.** id apunta a auth.users (si se borra la fila de auth.users, también se borran las filas que la usan).

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

CHECK:

- `notificaciones_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `notificaciones_leido_bool_chk`: `CHECK (((leido IS NULL) OR (leido = ANY (ARRAY[0, 1]))))`

Índices:

- `CREATE INDEX notificaciones_usuario_creado_idx ON public.notificaciones USING btree (id_usuario, creado_en DESC)`

**RLS.** RLS activo. El usuario lee y marca las suyas. Políticas: DELETE «notificaciones_delete», INSERT «notificaciones_insert_participantes», SELECT «notificaciones_select», UPDATE «notificaciones_update».

**Forma normal: BCNF.** Cada aviso depende de su id. Dato repetido a propósito: id_relacionado apunta a un trabajo u otro objeto según el tipo de aviso (referencia polimórfica), por eso no tiene clave foránea física.

**Relaciones en palabras.** id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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

CHECK:

- `suscripciones_actualizado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(actualizado_en))`
- `suscripciones_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `suscripciones_fecha_fin_iso_chk`: `CHECK (es_marca_tiempo_iso(fecha_fin))`
- `suscripciones_fecha_inicio_iso_chk`: `CHECK (es_marca_tiempo_iso(fecha_inicio))`

Índices:

- `CREATE INDEX idx_suscripciones_id_usuario_fkey ON public.suscripciones USING btree (id_usuario)`

**RLS.** RLS activo. El usuario ve solo su plan; crear o cambiar una suscripción es de administración o del backend (antes de la auditoría 2026-11-16 un usuario podía activarse un plan premium). Políticas: DELETE «suscripciones_admin_delete», INSERT «suscripciones_admin_insert», UPDATE «suscripciones_admin_update», SELECT «suscripciones_select».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### 3.4 codigos_restablecimiento

Código temporal para restablecer la contraseña.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id, not null |  |
| `codigo` | `text` | not null |  |
| `correo` | `text` | not null |  |
| `expira_en` | `text` | not null |  |
| `usado` | `integer` | default: 0 |  |
| `creado_en` | `text` | not null |  |

CHECK:

- `codigos_restablecimiento_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `codigos_restablecimiento_expira_en_iso_chk`: `CHECK (es_marca_tiempo_iso(expira_en))`
- `codigos_restablecimiento_usado_bool_chk`: `CHECK (((usado IS NULL) OR (usado = ANY (ARRAY[0, 1]))))`

Índices:

- `CREATE INDEX idx_codigos_restablecimiento_id_usuario_fkey ON public.codigos_restablecimiento USING btree (id_usuario)`

**RLS.** RLS activo. Acceso acotado al dueño o al backend; no es un dato de catálogo. Políticas: ALL «codigos_reset_all».

**Forma normal: BCNF.** Cada código depende de su id. Dato repetido a propósito: correo copia el correo al que se envió el código: es un registro histórico, no se actualiza si el usuario cambia su correo.

**Relaciones en palabras.** id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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

CHECK:

- `consentimientos_usuario_aceptado_bool_chk`: `CHECK (((aceptado IS NULL) OR (aceptado = ANY (ARRAY[0, 1]))))`
- `consentimientos_usuario_aceptado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(aceptado_en))`

Índices:

- `CREATE INDEX idx_consentimientos_usuario_id_usuario_fkey ON public.consentimientos_usuario USING btree (id_usuario)`

**RLS.** RLS activo. El usuario ve y registra sus propios consentimientos. Políticas: ALL «consentimientos_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### 3.6 bloqueos_usuario

Bloqueo de un usuario hacia otro.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_bloqueador` | `uuid` | fk → perfiles.id, not null |  |
| `id_bloqueado` | `uuid` | fk → perfiles.id, not null |  |
| `creado_en` | `text` | not null |  |

CHECK:

- `bloqueos_usuario_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `bloqueos_usuario_distintos_chk`: `CHECK ((id_bloqueador <> id_bloqueado))`

Índices:

- `UNIQUE (id_bloqueador, id_bloqueado)`
- `CREATE INDEX idx_bloqueos_usuario_id_bloqueado_fkey ON public.bloqueos_usuario USING btree (id_bloqueado)`
- `CREATE UNIQUE INDEX "user_blocks_blockerId_blockedUserId_key" ON public.bloqueos_usuario USING btree (id_bloqueador, id_bloqueado)`

**RLS.** RLS activo. El usuario ve los bloqueos en los que participa; solo él (o un administrador) puede crearlos. Políticas: ALL «bloqueos_all».

**Forma normal: BCNF.** Clave propia id y además clave candidata (id_bloqueador, id_bloqueado), única. No hay otras dependencias.

**Relaciones en palabras.** id_bloqueado apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_bloqueador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### 3.7 reportes

Denuncia de un usuario contra otro.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_reportante` | `uuid` | fk → perfiles.id, not null |  |
| `id_usuario_reportado` | `uuid` | fk → perfiles.id, not null |  |
| `motivo` | `text` | not null |  |
| `descripcion` | `text` |  |  |
| `estado` | `text` | not null, default: 'pendiente' |  |
| `creado_en` | `text` | not null |  |

CHECK:

- `reportes_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`

Índices:

- `CREATE INDEX idx_reportes_id_reportante_fkey ON public.reportes USING btree (id_reportante)`
- `CREATE INDEX idx_reportes_id_usuario_reportado_fkey ON public.reportes USING btree (id_usuario_reportado)`

**RLS.** RLS activo. El reportante ve los suyos; un administrador gestiona la cola. Políticas: ALL «reportes_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_reportante apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_usuario_reportado apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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

CHECK:

- `eventos_abuso_accion_tomada_en_iso_chk`: `CHECK (es_marca_tiempo_iso(accion_tomada_en))`
- `eventos_abuso_detectado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(detectado_en))`
- `eventos_abuso_resuelto_bool_chk`: `CHECK (((resuelto IS NULL) OR (resuelto = ANY (ARRAY[0, 1]))))`

Índices:

- `CREATE INDEX idx_eventos_abuso_id_usuario_fkey ON public.eventos_abuso USING btree (id_usuario)`

**RLS.** RLS activo. Restringido a administración o al backend de moderación. Políticas: ALL «eventos_abuso_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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

CHECK:

- `acciones_pendientes_actualizado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(actualizado_en))`
- `acciones_pendientes_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`

Índices:

- `CREATE INDEX idx_acciones_pendientes_id_usuario_fkey ON public.acciones_pendientes USING btree (id_usuario)`

**RLS.** RLS activo. El dueño ve y gestiona sus propias acciones pendientes; un administrador ve todas. Políticas: ALL «acciones_pendientes_all».

**Forma normal: BCNF.** Una fila por acción hecha sin conexión. `datos` guarda el contenido completo de la acción como un solo documento: la base no lo consulta por partes, así que cuenta como un valor atómico.

**Relaciones en palabras.** id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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
| `estado` | `text` | not null, default: 'nuevo' |  |
| `version_app` | `text` |  |  |
| `plataforma` | `text` |  |  |
| `creado_en` | `text` | not null, default: to_char((now() AT TIME ZONE 'utc'::text), 'YYYY-MM-DD"T"HH24:MI:SS.US'::text) |  |

CHECK:

- `registros_error_app_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`

Índices:

- `CREATE INDEX idx_registros_error_app_id_usuario_fkey ON public.registros_error_app USING btree (id_usuario)`

**RLS.** RLS activo. El cliente informa sus propios errores; un administrador puede revisarlos. Políticas: INSERT «registros_error_app_insert», SELECT «registros_error_app_select», UPDATE «registros_error_app_update_admin».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_usuario apunta a perfiles (no se puede borrar la fila de perfiles mientras tenga registros asociados).

### 3.11 eventos_analitica

Evento de uso registrado por la aplicación.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `nombre_evento` | `text` | not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id |  |
| `rol` | `text` |  |  |
| `marca_tiempo` | `text` | not null |  |
| `metadatos` | `text` |  |  |

CHECK:

- `eventos_analitica_marca_tiempo_iso_chk`: `CHECK (es_marca_tiempo_iso(marca_tiempo))`

Índices:

- `CREATE INDEX idx_eventos_analitica_id_usuario_fkey ON public.eventos_analitica USING btree (id_usuario)`

**RLS.** RLS activo. El usuario o el backend registra eventos de uso; no es un listado público. Políticas: INSERT «analitica_insert», SELECT «analitica_select».

**Forma normal: BCNF.** Registro de eventos. rol es el rol que tenía el usuario cuando ocurrió el evento (dato histórico), no una copia que deba seguir al perfil.

**Relaciones en palabras.** id_usuario apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva).

### 3.12 banderas_funcionalidad

Interruptor de una función por versión, rol o usuario.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `nombre_bandera` | `text` | not null |  |
| `habilitada` | `integer` | not null, default: 0 |  |
| `version_app` | `text` |  |  |
| `rol` | `text` |  |  |
| `id_usuario` | `uuid` | fk → perfiles.id |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

CHECK:

- `banderas_funcionalidad_actualizado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(actualizado_en))`
- `banderas_funcionalidad_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `banderas_funcionalidad_habilitada_bool_chk`: `CHECK (((habilitada IS NULL) OR (habilitada = ANY (ARRAY[0, 1]))))`

Índices:

- `CREATE INDEX idx_banderas_funcionalidad_id_usuario_fkey ON public.banderas_funcionalidad USING btree (id_usuario)`

**RLS.** RLS activo. Lectura restringida a banderas activas aplicables al usuario, o a un administrador. Políticas: DELETE «banderas_funcionalidad_admin_delete», INSERT «banderas_funcionalidad_admin_insert», UPDATE «banderas_funcionalidad_admin_update», SELECT «banderas_select».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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

**Forma normal: BCNF.** La clave es el token del dispositivo; usuario y plataforma dependen de él.

**Relaciones en palabras.** id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### 3.14 verificacion_eventos

Historial de cambios del estado de verificación de un profesional (pendiente, en revisión, verificado, rechazado).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `uuid` | pk, not null, default: gen_random_uuid() |  |
| `id_usuario` | `uuid` | fk → perfiles.id, not null |  |
| `estado` | `text` | not null |  |
| `nota` | `text` |  |  |
| `id_actor` | `uuid` | fk → perfiles.id |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

Índices:

- `CREATE INDEX idx_verificacion_eventos_id_actor_fkey ON public.verificacion_eventos USING btree (id_actor)`
- `CREATE INDEX verificacion_eventos_usuario_idx ON public.verificacion_eventos USING btree (id_usuario, creado_en)`

**RLS.** RLS activo. El profesional ve su propio historial; un administrador ve todos. La escritura la hace el trigger al cambiar el estado de verificación. Políticas: SELECT «verificacion_eventos_select».

**Forma normal: BCNF.** Bitácora de cambios del estado de verificación.

**Relaciones en palabras.** id_actor apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva); id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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

**RLS.** RLS activo. Lectura pública del catálogo. Hoy solo CL. Políticas: DELETE «paises_admin_delete», INSERT «paises_admin_insert», UPDATE «paises_admin_update», SELECT «paises_select».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

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

**RLS.** RLS activo. Lectura pública del catálogo geográfico. Políticas: DELETE «regiones_admin_delete», INSERT «regiones_admin_insert», UPDATE «regiones_admin_update», SELECT «regiones_select».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_pais apunta a paises (no se puede borrar la fila de paises mientras tenga registros asociados).

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

- `comunas_activa_bool_chk`: `CHECK (((activa IS NULL) OR (activa = ANY (ARRAY[0, 1]))))`
- `comunas_lat_chk`: `CHECK (((latitud IS NULL) OR ((latitud >= ('-90'::integer)::double precision) AND (latitud <= (90)::double precision))))`
- `comunas_lng_chk`: `CHECK (((longitud IS NULL) OR ((longitud >= ('-180'::integer)::double precision) AND (longitud <= (180)::double precision))))`

Índices:

- `CREATE INDEX comunas_nombre_idx ON public.comunas USING btree (nombre)`
- `CREATE INDEX comunas_region_idx ON public.comunas USING btree (id_region)`
- `CREATE UNIQUE INDEX comunas_region_nombre_activa_uidx ON public.comunas USING btree (id_region, lower(nombre)) WHERE (activa = 1)`

**RLS.** RLS activo. Lectura pública del catálogo geográfico (comunas activas). La escritura es de administración o servicio. Políticas: DELETE «comunas_admin_delete», INSERT «comunas_admin_insert», UPDATE «comunas_admin_update», SELECT «comunas_select».

**Forma normal: BCNF.** La clave es el slug de la comuna. Desde la auditoría hay un índice único (región, nombre) entre las comunas activas, para que no existan dos comunas iguales visibles.

**Relaciones en palabras.** id_region apunta a regiones (no se puede borrar la fila de regiones mientras tenga registros asociados).

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
- `trabajadores_calificacion_chk`: `CHECK (((calificacion >= (0)::numeric) AND (calificacion <= (5)::numeric)))`
- `trabajadores_contadores_chk`: `CHECK (((trabajos_completados >= 0) AND (conteo_rechazos >= 0)))`
- `trabajadores_disponible_bool_chk`: `CHECK (((disponible IS NULL) OR (disponible = ANY (ARRAY[0, 1]))))`
- `trabajadores_estado_verificacion_check`: `CHECK ((estado_verificacion = ANY (ARRAY['pendiente'::text, 'en_revision'::text, 'verificado'::text, 'rechazado'::text])))`
- `trabajadores_origen_base_chk`: `CHECK (((origen_base IS NULL) OR (origen_base = ANY (ARRAY['mapa'::text, 'comuna'::text]))))`
- `trabajadores_precios_configurados_bool_chk`: `CHECK (((precios_configurados IS NULL) OR (precios_configurados = ANY (ARRAY[0, 1]))))`
- `trabajadores_prioridad_manual_chk`: `CHECK (((prioridad_manual >= '-50'::integer) AND (prioridad_manual <= 50)))`
- `trabajadores_radio_chk`: `CHECK (((radio_servicio_km >= (1)::numeric) AND (radio_servicio_km <= (80)::numeric)))`
- `trabajadores_radio_urbano_chk`: `CHECK (((radio_urbano_km >= (1)::numeric) AND (radio_urbano_km <= (40)::numeric)))`
- `trabajadores_tarifa_fuera_radio_chk`: `CHECK (((tarifa_fuera_radio_clp >= 0) AND (tarifa_fuera_radio_clp <= 200000)))`
- `trabajadores_tarifa_visita_chk`: `CHECK ((tarifa_visita >= (0)::numeric))`

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

**Forma normal: 2FN con datos derivados documentados.** Ficha 1:1 del profesional. Las listas (precios, servicios extra, oficios) viven en tablas hijas en 4FN. id_region depende de id_comuna (dependencia transitiva), así que en rigor la ficha no llega a 3FN. Dato repetido a propósito: niveles_precio y servicios_personalizados son el formato de escritura de la app; un trigger los parte en trabajador_precios y trabajador_servicios_extra. calificacion, trabajos_completados, score_listado y es_elite son valores calculados para ordenar el catálogo sin recalcular en cada consulta. id_region se deduce de id_comuna cuando hay comuna (diferencias: 0).

**Relaciones en palabras.** id_comuna apunta a comunas (si se borra la fila de comunas, la columna queda vacía y el registro se conserva); id_region apunta a regiones (si se borra la fila de regiones, la columna queda vacía y el registro se conserva); id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### 3.19 trabajador_precios

Precio por código de servicio del profesional. id_usuario es uuid con clave foránea a trabajadores (ON DELETE CASCADE) desde la auditoría 2026-11-16; antes era text sin FK.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_usuario` | `uuid` | pk, fk → trabajadores.id_usuario, not null |  |
| `codigo` | `text` | pk, not null |  |
| `monto_clp` | `numeric(12,0)` | not null |  |

CHECK:

- `trabajador_precios_monto_clp_check`: `CHECK ((monto_clp >= (0)::numeric))`

**RLS.** RLS activo. El dueño y el catálogo (según política de precios) leen los montos ya publicados; la escritura es del dueño o de un trigger que parte el JSON. Políticas: ALL «trabajador_precios_propio».

**Forma normal: 4FN.** Nace de separar la lista de precios del profesional (antes un JSON en trabajadores). Clave (id_usuario, codigo). Desde la auditoría id_usuario es uuid con clave foránea a trabajadores.

**Relaciones en palabras.** id_usuario apunta a trabajadores (si se borra la fila de trabajadores, también se borran las filas que la usan).

### 3.20 trabajador_servicios_extra

Servicio adicional definido por el profesional. id_usuario es uuid con clave foránea a trabajadores, igual que en trabajador_precios.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | pk, fk → trabajadores.id_usuario, not null |  |
| `titulo` | `text` | not null |  |
| `subtitulo` | `text` | not null, default: '' |  |
| `monto_clp` | `numeric(12,0)` | not null |  |
| `unidad` | `text` | not null, default: 'fijo' |  |

CHECK:

- `trabajador_servicios_extra_monto_clp_check`: `CHECK ((monto_clp >= (0)::numeric))`
- `trabajador_servicios_extra_unidad_check`: `CHECK ((unidad = ANY (ARRAY['fijo'::text, 'por_m2'::text])))`

**RLS.** RLS activo. Servicios extra del profesional; misma idea que los precios. Políticas: ALL «trabajador_servicios_extra_propio».

**Forma normal: 4FN.** Servicios adicionales del profesional, separados del JSON servicios_personalizados. Desde la auditoría id_usuario es uuid con clave foránea.

**Relaciones en palabras.** id_usuario apunta a trabajadores (si se borra la fila de trabajadores, también se borran las filas que la usan).

### 3.21 trabajador_servicios

Oficios del catálogo que el profesional declara atender.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_trabajador` | `uuid` | pk, fk → perfiles.id, not null |  |
| `categoria_servicio` | `text` | pk, not null |  |

**RLS.** RLS activo. Oficios declarados: lectura de catálogo y escritura del dueño. Políticas: DELETE «trabajador_servicios_delete», INSERT «trabajador_servicios_insert», SELECT «trabajador_servicios_select», UPDATE «trabajador_servicios_update».

**Forma normal: 4FN.** Lista de oficios del profesional separada de su ficha: un profesional atiende varios oficios, independiente de sus precios. Clave (id_trabajador, categoria_servicio).

**Relaciones en palabras.** id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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

**RLS.** RLS activo. SELECT y escritura solo para el dueño de la ficha (o un administrador). El cliente no lee esta tabla: usa horarios_libres_profesional. Políticas: DELETE «trabajador_horarios_delete», INSERT «trabajador_horarios_insert», SELECT «trabajador_horarios_select», UPDATE «trabajador_horarios_update».

**Forma normal: BCNF con una columna heredada.** La forma actual es una fila por día (id_usuario, dia_semana) con hora de inicio y fin: cumple BCNF. Dato repetido a propósito: horarios (jsonb) es el formato antiguo de la semana completa que aún leen versiones previas de la app; la fuente de verdad son las columnas por día.

**Relaciones en palabras.** id_usuario apunta a trabajadores (si se borra la fila de trabajadores, también se borran las filas que la usan).

### 3.23 portafolio_trabajador

Foto o medio del portafolio de un profesional.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajador` | `uuid` | fk → perfiles.id, not null |  |
| `ruta_foto` | `text` | not null |  |
| `descripcion` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `tipo_medio` | `text` | not null, default: 'foto' |  |

CHECK:

- `portafolio_tipo_medio_chk`: `CHECK ((tipo_medio = ANY (ARRAY['foto'::text, 'video'::text])))`
- `portafolio_trabajador_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`

Índices:

- `CREATE INDEX idx_portfolio_worker ON public.portafolio_trabajador USING btree (id_trabajador)`

**RLS.** RLS activo. El profesional gestiona su portafolio; hay lectura de catálogo de los ítems visibles. Políticas: DELETE «portafolio_delete», INSERT «portafolio_insert», SELECT «portafolio_select», UPDATE «portafolio_update».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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

CHECK:

- `impulsos_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `impulsos_fecha_fin_iso_chk`: `CHECK (es_marca_tiempo_iso(fecha_fin))`
- `impulsos_fecha_inicio_iso_chk`: `CHECK (es_marca_tiempo_iso(fecha_inicio))`

Índices:

- `CREATE INDEX idx_impulsos_id_trabajador_fkey ON public.impulsos USING btree (id_trabajador)`

**RLS.** RLS activo. Lectura para usuarios con sesión (el catálogo muestra los vigentes). Crear, cambiar o borrar un impulso es solo de administración: antes de la auditoría 2026-11-16 un profesional podía darse un impulso sin pagar. Políticas: DELETE «impulsos_admin_delete», INSERT «impulsos_admin_insert», UPDATE «impulsos_admin_update», SELECT «impulsos_select».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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
| `modelo_precio` | `text` | not null, default: 'por_hora' |  |
| `aviso_legal` | `text` |  |  |
| `creado_en` | `text` |  |  |
| `actualizado_en` | `text` |  |  |

CHECK:

- `servicios_activo_bool_chk`: `CHECK (((activo IS NULL) OR (activo = ANY (ARRAY[0, 1]))))`
- `servicios_actualizado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(actualizado_en))`
- `servicios_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `servicios_requiere_certificacion_bool_chk`: `CHECK (((requiere_certificacion IS NULL) OR (requiere_certificacion = ANY (ARRAY[0, 1]))))`

Índices:

- `CREATE INDEX idx_servicios_categoria ON public.servicios USING btree (categoria)`
- `CREATE INDEX servicios_activo_categoria_idx ON public.servicios USING btree (activo, categoria) WHERE (COALESCE(activo, 1) = 1)`

**RLS.** RLS activo. Lectura pública del catálogo de oficios. La escritura es de administración. Políticas: DELETE «servicios_admin_delete», INSERT «servicios_admin_insert», UPDATE «servicios_admin_update», SELECT «servicios_select», SELECT «servicios_select_authenticated».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

### 3.26 configuraciones_servicio

Esquema de configuración asociado a un servicio.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_servicio` | `text` | fk → servicios.id, not null, unique |  |
| `esquema_config` | `text` | not null |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

CHECK:

- `configuraciones_servicio_actualizado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(actualizado_en))`
- `configuraciones_servicio_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`

Índices:

- `UNIQUE (id_servicio)`
- `CREATE UNIQUE INDEX "service_configs_serviceId_key" ON public.configuraciones_servicio USING btree (id_servicio)`

**RLS.** RLS activo. Lectura del esquema de configuración del catálogo; escritura restringida. Políticas: SELECT «config_servicio_select», DELETE «configuraciones_servicio_admin_delete», INSERT «configuraciones_servicio_admin_insert», UPDATE «configuraciones_servicio_admin_update».

**Forma normal: BCNF.** esquema_config es el formulario completo de un servicio, guardado como un documento.

**Relaciones en palabras.** id_servicio apunta a servicios (si se borra la fila de servicios, también se borran las filas que la usan).

### 3.27 trabajos

Pedido de un cliente a un profesional (o abierto a cotizaciones). estado_pago es una copia derivada del pago principal. La fecha programada se guarda como texto y, desde CU-33, solo cambia por las RPC de reagendamiento (trabajos_fecha_solo_por_rpc). Hay un índice único que impide dos trabajos activos del mismo profesional en el mismo minuto (minuto_utc de fecha_programada).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id, not null |  |
| `id_trabajador` | `uuid` | fk → perfiles.id |  |
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
| `id_cotizacion_seleccionada` | `text` | fk → propuestas_cotizacion.id |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

CHECK:

- `trabajos_actualizado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(actualizado_en))`
- `trabajos_coordenadas_chk`: `CHECK ((((latitud IS NULL) OR ((latitud >= ('-90'::integer)::double precision) AND (latitud <= (90)::double precision))) AND ((longitud IS NULL) OR ((longitud >= ('-180'::integer)::double precision) AND (longitud <= (180)::double precision)))))`
- `trabajos_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `trabajos_estado_chk`: `CHECK ((estado = ANY (ARRAY['pendiente'::text, 'esperando_cotizaciones'::text, 'cotizacion_seleccionada'::text, 'esperando_pago'::text, 'aceptado'::text, 'en_camino'::text, 'en_curso'::text, 'pausado_orden_cambio'::text, 'esperando_aprobacion_cliente'::text, 'completado'::text, 'cancelado'::text, 'expirado'::text, 'no_asistio'::text])))`
- `trabajos_estado_pago_chk`: `CHECK (((estado_pago IS NULL) OR (estado_pago = ANY (ARRAY['ninguno'::text, 'pendiente'::text, 'autorizado'::text, 'retenido'::text, 'pagado_por_confirmar'::text, 'liberado'::text, 'reembolso_pendiente'::text, 'reembolsado'::text, 'reembolsado_auto'::text, 'anulado'::text, 'fallido'::text, 'rechazado'::text, 'expirado'::text, 'cancelado'::text]))))`
- `trabajos_fecha_programada_iso_chk`: `CHECK (es_marca_tiempo_iso(fecha_programada))`
- `trabajos_horas_bloque_chk`: `CHECK (((horas_bloque IS NULL) OR ((horas_bloque >= 1) AND (horas_bloque <= 24))))`
- `trabajos_modalidad_cobro_chk`: `CHECK (((modalidad_cobro IS NULL) OR (modalidad_cobro = ANY (ARRAY['legado'::text, 'precio_fijo'::text, 'bloque_horas'::text, 'cotizacion_abierta'::text]))))`

Índices:

- `CREATE INDEX idx_trabajos_creado_en ON public.trabajos USING btree (creado_en DESC)`
- `CREATE INDEX idx_trabajos_estado ON public.trabajos USING btree (estado)`
- `CREATE INDEX idx_trabajos_id_comuna_fkey ON public.trabajos USING btree (id_comuna)`
- `CREATE INDEX idx_trabajos_id_cotizacion_seleccionada_fkey ON public.trabajos USING btree (id_cotizacion_seleccionada)`
- `CREATE INDEX idx_trabajos_id_servicio_fkey ON public.trabajos USING btree (id_servicio)`
- `CREATE INDEX idx_trabajos_id_trabajador ON public.trabajos USING btree (id_trabajador)`
- `CREATE INDEX trabajos_trabajador_estado_idx ON public.trabajos USING btree (id_trabajador, estado) WHERE (id_trabajador IS NOT NULL)`
- `CREATE INDEX trabajos_trabajador_fecha_programada_idx ON public.trabajos USING btree (id_trabajador, fecha_programada) WHERE ((fecha_programada IS NOT NULL) AND (id_trabajador IS NOT NULL))`
- `CREATE UNIQUE INDEX trabajos_trabajador_minuto_activo_uidx ON public.trabajos USING btree (id_trabajador, minuto_utc(fecha_programada)) WHERE ((fecha_programada IS NOT NULL) AND (id_trabajador IS NOT NULL) AND (estado <> ALL (ARRAY['cancelado'::text, 'expirado'::text, 'completado'::text, 'no_asistio'::text])))`
- `CREATE INDEX trabajos_usuario_creado_idx ON public.trabajos USING btree (id_usuario, creado_en DESC)`

**RLS.** RLS activo. SELECT y UPDATE para el cliente, el profesional asignado o un administrador. El INSERT lo hace el cliente (o un admin) con reglas: sin cotización preseleccionada y con estado de pago inicial pendiente o ninguno. Varios triggers cuidan el PIN, la evidencia, la fecha (solo RPC) y la disponibilidad. Políticas: INSERT «trabajos_insert», SELECT «trabajos_select», UPDATE «trabajos_update».

**Forma normal: BCNF con una copia mantenida por trigger.** Cada columna describe el pedido. instantanea_precio es la foto del precio al pedir (dato histórico). Dato repetido a propósito: estado_pago copia el estado del pago principal (trigger copiar_estado_pago_trabajo) para filtrar listas sin unir con pagos. Diferencias: 0.

**Relaciones en palabras.** id_servicio apunta a servicios (si se borra la fila de servicios, la columna queda vacía y el registro se conserva); id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajador apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva); id_comuna apunta a comunas (si se borra la fila de comunas, la columna queda vacía y el registro se conserva); id_cotizacion_seleccionada apunta a propuestas_cotizacion (si se borra la fila de propuestas_cotizacion, la columna queda vacía y el registro se conserva).

### 3.28 mensajes

Mensaje del chat de un trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `id_remitente` | `uuid` | fk → perfiles.id, not null |  |
| `id_destinatario` | `uuid` | fk → perfiles.id, not null |  |
| `contenido` | `text` | not null |  |
| `tipo` | `text` | not null, default: 'texto' |  |
| `ruta_imagen` | `text` |  |  |
| `leido` | `integer` | not null, default: 0 |  |
| `creado_en` | `text` | not null |  |

CHECK:

- `mensajes_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `mensajes_leido_bool_chk`: `CHECK (((leido IS NULL) OR (leido = ANY (ARRAY[0, 1]))))`

Índices:

- `CREATE INDEX idx_mensajes_id_remitente_fkey ON public.mensajes USING btree (id_remitente)`
- `CREATE INDEX idx_messages_receiver ON public.mensajes USING btree (id_destinatario)`
- `CREATE INDEX mensajes_trabajo_creado_idx ON public.mensajes USING btree (id_trabajo, creado_en)`

**RLS.** RLS activo. Solo las partes del chat (remitente o destinatario) o un administrador. Un trigger bloquea datos de contacto en el cuerpo. Políticas: INSERT «mensajes_insert», SELECT «mensajes_select», UPDATE «mensajes_update_leido».

**Forma normal: 2FN con desnormalización controlada.** Cada mensaje depende de su id. id_destinatario se puede deducir del trabajo y del remitente (el otro participante): es una dependencia transitiva, así que en rigor la tabla no llega a 3FN. Dato repetido a propósito: Se guarda id_destinatario para filtrar en tiempo real (Realtime) y en RLS sin unir con trabajos; lo valida la política de inserción. Diferencias verificadas: 0.

**Relaciones en palabras.** id_destinatario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_remitente apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### 3.29 fotos_trabajo

Evidencia fotográfica o de video de un trabajo (bucket de evidencias).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `ruta_foto` | `text` | not null |  |
| `creado_en` | `text` | not null |  |
| `tipo_medio` | `text` | not null, default: 'foto' | photo or video evidence |
| `imagen_webp` | `bytea` |  | Imagen de evidencia en WebP. Se guarda en la fila para no depender de archivos locales y ocupar menos espacio que JPEG/PNG. |

CHECK:

- `fotos_trabajo_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `fotos_trabajo_tipo_medio_chk`: `CHECK ((tipo_medio = ANY (ARRAY['foto'::text, 'video'::text])))`

Índices:

- `CREATE INDEX idx_job_photos_job ON public.fotos_trabajo USING btree (id_trabajo)`

**RLS.** RLS activo. Las partes del trabajo o un administrador ven la evidencia. Hay reglas extra sobre el formato (p. ej. exigir webp/video). Políticas: ALL «fotos_trabajo_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### 3.30 calificaciones

Valoración de un trabajo. Desde la calificación bidireccional admite direccion cliente_a_trabajador o trabajador_a_cliente, con unicidad por (id_trabajo, direccion). Alimenta trabajadores.calificacion.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id |  |
| `puntaje` | `integer` | not null |  |
| `comentario` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `peso_confianza` | `numeric(4,3)` | not null, default: 1 |  |
| `estado_revision` | `text` | not null, default: 'vigente' |  |
| `motivo_revision` | `text` |  |  |
| `direccion` | `text` | not null, default: 'cliente_a_trabajador' |  |
| `id_calificado` | `uuid` | fk → perfiles.id, not null |  |

CHECK:

- `calificaciones_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `calificaciones_direccion_chk`: `CHECK ((direccion = ANY (ARRAY['cliente_a_trabajador'::text, 'trabajador_a_cliente'::text])))`
- `calificaciones_estado_revision_chk`: `CHECK ((estado_revision = ANY (ARRAY['vigente'::text, 'en_revision'::text, 'excluida'::text])))`
- `calificaciones_peso_confianza_chk`: `CHECK (((peso_confianza >= (0)::numeric) AND (peso_confianza <= (1)::numeric)))`
- `calificaciones_puntaje_chk`: `CHECK (((puntaje >= 1) AND (puntaje <= 5)))`

Índices:

- `CREATE INDEX calificaciones_calificado_idx ON public.calificaciones USING btree (id_calificado, direccion, creado_en DESC)`
- `CREATE INDEX calificaciones_estado_revision_idx ON public.calificaciones USING btree (estado_revision)`
- `CREATE UNIQUE INDEX calificaciones_trabajo_direccion_uidx ON public.calificaciones USING btree (id_trabajo, direccion)`
- `CREATE INDEX calificaciones_trabajo_idx ON public.calificaciones USING btree (id_trabajo)`
- `CREATE INDEX idx_calificaciones_id_usuario_fkey ON public.calificaciones USING btree (id_usuario)`

**RLS.** RLS activo. Se inserta una calificación propia, con direccion e id_calificado coherentes con el trabajo terminado. Se leen las de cliente_a_trabajador (públicas para el listado) y las propias o de un administrador. Políticas: INSERT «calificaciones_insert», SELECT «calificaciones_select».

**Forma normal: BCNF.** Claves candidatas: id y (id_trabajo, direccion). id_calificado depende de esa clave compuesta, por lo que la tabla cumple BCNF. Dato repetido a propósito: id_calificado repite a quién se calificó, dato que también se deduce de trabajos. Se guarda para filtrar reseñas por persona con índice y en RLS; lo fija la función que crea la reseña. Diferencias verificadas: 0.

**Relaciones en palabras.** id_calificado apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_usuario apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### 3.31 calificaciones_cliente

El profesional nota al cliente. 1:1 con el trabajo. Alimenta perfiles.reputacion_cliente. puntaje es smallint en la base viva.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null, unique |  |
| `id_cliente` | `uuid` | fk → perfiles.id, not null |  |
| `id_trabajador` | `uuid` | fk → perfiles.id, not null |  |
| `puntaje` | `smallint` | not null |  |
| `comentario` | `text` |  |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `calificaciones_cliente_puntaje_chk`: `CHECK (((puntaje >= 1) AND (puntaje <= 5)))`

Índices:

- `UNIQUE (id_trabajo)`
- `CREATE UNIQUE INDEX calificaciones_cliente_trabajo_unica ON public.calificaciones_cliente USING btree (id_trabajo)`
- `CREATE INDEX idx_calificaciones_cliente_id_cliente_fkey ON public.calificaciones_cliente USING btree (id_cliente)`
- `CREATE INDEX idx_calificaciones_cliente_id_trabajador_fkey ON public.calificaciones_cliente USING btree (id_trabajador)`

**RLS.** RLS activo. El profesional califica a su cliente en un trabajo 1:1; leen las partes o un administrador. Políticas: SELECT «calificaciones_cliente_select».

**Forma normal: BCNF.** Una calificación por trabajo; todas las columnas dependen del id. Dato repetido a propósito: id_trabajador también se deduce de trabajos; se guarda para RLS (el profesional ve lo que escribió). Diferencias: 0.

**Relaciones en palabras.** id_cliente apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### 3.32 disputas

Disputa abierta sobre un trabajo y su resolución (incluye sugerencia automática y vencimiento).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `abierta_por` | `uuid` | fk → perfiles.id, not null |  |
| `motivo` | `text` | not null |  |
| `descripcion` | `text` |  |  |
| `estado` | `text` | not null |  |
| `resolucion` | `text` |  |  |
| `resuelta_por` | `uuid` | fk → perfiles.id |  |
| `resuelta_en` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |
| `origen` | `text` | not null, default: 'admin' |  |
| `decision_sugerida` | `text` |  |  |
| `motivo_regla` | `text` |  |  |
| `vence_en` | `timestamptz` |  |  |

CHECK:

- `disputas_actualizado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(actualizado_en))`
- `disputas_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `disputas_decision_chk`: `CHECK (((decision_sugerida IS NULL) OR (decision_sugerida = ANY (ARRAY['liberar'::text, 'reembolsar'::text, 'humano'::text]))))`
- `disputas_origen_chk`: `CHECK ((origen = ANY (ARRAY['sistema'::text, 'acuerdo'::text, 'admin'::text])))`
- `disputas_resuelta_en_iso_chk`: `CHECK (es_marca_tiempo_iso(resuelta_en))`

Índices:

- `CREATE INDEX idx_disputas_abierta_por_fkey ON public.disputas USING btree (abierta_por)`
- `CREATE INDEX idx_disputas_estado ON public.disputas USING btree (estado)`
- `CREATE INDEX idx_disputas_resuelta_por_fkey ON public.disputas USING btree (resuelta_por)`
- `CREATE INDEX idx_disputes_job ON public.disputas USING btree (id_trabajo)`

**RLS.** RLS activo. Las partes del trabajo o un administrador leen la disputa. La apertura y los cambios de estado van por RPC. Políticas: INSERT «disputas_insert», SELECT «disputas_select», UPDATE «disputas_update».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** abierta_por apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); resuelta_por apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

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

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_autor apunta a perfiles (no se puede borrar la fila de perfiles mientras tenga registros asociados); id_disputa apunta a disputas (si se borra la fila de disputas, también se borran las filas que la usan).

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

**Forma normal: BCNF.** Cada acuerdo depende solo de su id; el índice único parcial impide dos acuerdos pendientes en el mismo trabajo.

**Relaciones en palabras.** id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan); propuesto_por apunta a perfiles (no se puede borrar la fila de perfiles mientras tenga registros asociados).

### 3.35 cancelaciones_trabajo

Como máximo una cancelación por trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null, unique |  |
| `cancelado_por` | `uuid` | fk → perfiles.id, not null |  |
| `motivo` | `text` | not null |  |
| `cancelado_en` | `text` | not null |  |

CHECK:

- `cancelaciones_trabajo_cancelado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(cancelado_en))`

Índices:

- `UNIQUE (id_trabajo)`
- `CREATE INDEX idx_cancelaciones_trabajo_cancelado_por_fkey ON public.cancelaciones_trabajo USING btree (cancelado_por)`
- `CREATE UNIQUE INDEX "job_cancellations_jobId_key" ON public.cancelaciones_trabajo USING btree (id_trabajo)`

**RLS.** RLS activo. Las partes del trabajo o un administrador leen la cancelación; se inserta según las reglas del flujo de cancelar. Políticas: ALL «cancelaciones_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** cancelado_por apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### 3.36 tickets_soporte

Ticket de soporte asociado a un trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null, default: (gen_random_uuid())::text |  |
| `id_trabajo` | `text` | fk → trabajos.id |  |
| `nombre_cliente` | `text` | not null |  |
| `nombre_trabajador` | `text` | not null |  |
| `asunto` | `text` | not null |  |
| `monto_escrow` | `integer` | not null |  |
| `estado` | `text` | default: 'Pending' |  |
| `creado_en` | `timestamptz` | default: now() |  |

CHECK:

- `tickets_monto_escrow_chk`: `CHECK ((monto_escrow >= 0))`
- `tickets_status_check`: `CHECK ((estado = ANY (ARRAY['Pending'::text, 'Resolved'::text])))`

Índices:

- `CREATE INDEX idx_tickets_soporte_id_trabajo_fkey ON public.tickets_soporte USING btree (id_trabajo)`

**RLS.** RLS activo. Las partes del trabajo o un administrador ven el ticket. Políticas: ALL «tickets_soporte_all».

**Forma normal: 2FN con desnormalización controlada.** Cada ticket depende de su id. Los nombres y el monto se pueden deducir del trabajo (dependencia transitiva id → id_trabajo → nombre). Dato repetido a propósito: nombre_cliente, nombre_trabajador y monto_escrow son la foto del caso al abrir el ticket (trigger fijar_ticket_desde_trabajo), para que la consola de soporte no cambie si después cambia el perfil o el pago.

**Relaciones en palabras.** id_trabajo apunta a trabajos (si se borra la fila de trabajos, la columna queda vacía y el registro se conserva).

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

**Forma normal: BCNF.** Extensión 1:1 de trabajos (clave id_trabajo). Dato repetido a propósito: id_trabajador repite el profesional del trabajo para autorizar la publicación en tiempo real. Diferencias: 0.

**Relaciones en palabras.** id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan); id_trabajador apunta a trabajadores (si se borra la fila de trabajadores, también se borran las filas que la usan).

### 3.38 reprogramaciones_trabajo

Historial de propuestas para reagendar un trabajo (CU-33). Como máximo una propuesta pendiente por trabajo. Solo se escribe por las RPC proponer_reprogramacion, responder_reprogramacion y retirar_reprogramacion.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `uuid` | pk, not null, default: gen_random_uuid() |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null, unique |  |
| `propuesta_por` | `uuid` | fk → perfiles.id, not null |  |
| `rol_proponente` | `text` | not null |  |
| `fecha_anterior` | `timestamptz` | not null |  |
| `fecha_propuesta` | `timestamptz` | not null |  |
| `motivo` | `text` |  |  |
| `estado` | `text` | not null, default: 'pendiente' |  |
| `respondida_por` | `uuid` | fk → perfiles.id |  |
| `respondida_en` | `timestamptz` |  |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `reprogramaciones_trabajo_check`: `CHECK ((fecha_propuesta <> fecha_anterior))`
- `reprogramaciones_trabajo_estado_check`: `CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'retirada'::text, 'vencida'::text])))`
- `reprogramaciones_trabajo_motivo_check`: `CHECK (((motivo IS NULL) OR (char_length(motivo) <= 300)))`
- `reprogramaciones_trabajo_rol_proponente_check`: `CHECK ((rol_proponente = ANY (ARRAY['cliente'::text, 'profesional'::text])))`

Índices:

- `CREATE INDEX idx_reprogramaciones_trabajo_propuesta_por_fkey ON public.reprogramaciones_trabajo USING btree (propuesta_por)`
- `CREATE INDEX idx_reprogramaciones_trabajo_respondida_por_fkey ON public.reprogramaciones_trabajo USING btree (respondida_por)`
- `CREATE INDEX reprogramaciones_por_trabajo ON public.reprogramaciones_trabajo USING btree (id_trabajo, creado_en DESC)`
- `CREATE UNIQUE INDEX reprogramaciones_una_pendiente ON public.reprogramaciones_trabajo USING btree (id_trabajo) WHERE (estado = 'pendiente'::text)`

**RLS.** RLS activo. SELECT para las partes del trabajo. El alta, la respuesta y el retiro se hacen solo por RPC (CU-33). Políticas: SELECT «reprogramaciones_select».

**Forma normal: BCNF.** fecha_anterior es la fecha que tenía el trabajo antes de la propuesta: dato histórico de la solicitud.

**Relaciones en palabras.** propuesta_por apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); respondida_por apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

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

**Forma normal: BCNF.** Extensión 1:1 de trabajos con el PIN de inicio.

**Relaciones en palabras.** id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### 3.40 bloqueos_pin_inicio

Contador de intentos fallidos del PIN, bloqueo temporal (15 minutos tras 5 fallos) y ventana en la que el PIN ya fue validado. Escriben solo las funciones SECURITY DEFINER o service_role; un administrador puede leerla.

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

**RLS.** RLS activo. Solo un administrador puede leer (política agregada en la auditoría 2026-11-16). Nadie escribe por la API; lo hacen funciones SECURITY DEFINER (intentar_pin_inicio, transicionar_trabajo) o service_role. Políticas: SELECT «bloqueos_pin_inicio_admin_select».

**Forma normal: BCNF.** Extensión 1:1 de trabajos (la clave es id_trabajo). Guarda el contador de PIN fallidos de ese trabajo.

**Relaciones en palabras.** id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### 3.41 intentos_pin_inicio

Auditoría de cada intento de PIN de inicio. Escriben solo funciones SECURITY DEFINER; un administrador puede leerla.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `bigint` | pk, not null, identity |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `id_usuario` | `uuid` | fk → perfiles.id |  |
| `resultado` | `text` | not null |  |
| `intentos_restantes` | `integer` | not null |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `intentos_pin_inicio_resultado_check`: `CHECK ((resultado = ANY (ARRAY['correcto'::text, 'incorrecto'::text, 'bloqueado'::text])))`

Índices:

- `CREATE INDEX idx_intentos_pin_inicio_id_usuario_fkey ON public.intentos_pin_inicio USING btree (id_usuario)`
- `CREATE INDEX intentos_pin_inicio_trabajo_idx ON public.intentos_pin_inicio USING btree (id_trabajo, creado_en DESC)`

**RLS.** RLS activo. Solo un administrador puede leer la bitácora (política agregada en la auditoría 2026-11-16). La escritura la hacen funciones SECURITY DEFINER. Políticas: SELECT «intentos_pin_inicio_admin_select».

**Forma normal: BCNF.** Bitácora de intentos de PIN; cada fila es un intento.

**Relaciones en palabras.** id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan); id_usuario apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva).

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

CHECK:

- `propuestas_cotizacion_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `propuestas_cotizacion_validez_hasta_iso_chk`: `CHECK (es_marca_tiempo_iso(validez_hasta))`
- `propuestas_monto_chk`: `CHECK ((monto_total_clp > 0))`

Índices:

- `CREATE INDEX idx_quotes_job ON public.propuestas_cotizacion USING btree (id_trabajo)`
- `CREATE INDEX idx_quotes_worker ON public.propuestas_cotizacion USING btree (id_trabajador)`

**RLS.** RLS activo. El cliente del trabajo, el profesional autor o un administrador leen la cotización. El monto no lo cambia el cliente (trigger). Políticas: INSERT «propuestas_insert», SELECT «propuestas_select», UPDATE «propuestas_update».

**Forma normal: BCNF.** desglose es el detalle de la cotización como un documento; el total vive en monto_total_clp.

**Relaciones en palabras.** id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan); id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### 3.43 pagos

Cobro asociado a un trabajo o a una orden de cambio, con retención (escrow) vía Transbank Webpay / Oneclick. Las columnas alta_nonce_hash, alta_jti y alta_consumido_en sustentan el alta del invitado después del pago: el nonce solo lo tiene el navegador y el jti es de un solo uso. El default de tipo_pago es 'primary' (inglés legado); el índice de un solo pago principal activo busca el valor 'principal'.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null, unique |  |
| `id_orden_cambio` | `text` | fk → ordenes_cambio.id |  |
| `tipo_pago` | `text` | not null, default: 'principal' |  |
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

CHECK:

- `pagos_actualizado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(actualizado_en))`
- `pagos_ambiente_chk`: `CHECK (((ambiente IS NULL) OR (ambiente = ANY (ARRAY['integration'::text, 'production'::text]))))`
- `pagos_autorizado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(autorizado_en))`
- `pagos_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `pagos_estado_chk`: `CHECK ((estado = ANY (ARRAY['pendiente'::text, 'autorizado'::text, 'retenido'::text, 'pagado_por_confirmar'::text, 'liberado'::text, 'reembolso_pendiente'::text, 'reembolsado'::text, 'reembolsado_auto'::text, 'anulado'::text, 'fallido'::text, 'rechazado'::text, 'expirado'::text, 'cancelado'::text])))`
- `pagos_liberado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(liberado_en))`
- `pagos_metodo_pago_chk`: `CHECK (((metodo_pago IS NULL) OR (metodo_pago = ANY (ARRAY['webpay'::text, 'oneclick'::text]))))`
- `pagos_moneda_chk`: `CHECK ((moneda = 'CLP'::text))`
- `pagos_monto_chk`: `CHECK ((monto >= (0)::numeric))`
- `pagos_reembolsado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(reembolsado_en))`
- `pagos_tipo_pago_chk`: `CHECK ((tipo_pago = ANY (ARRAY['principal'::text, 'orden_cambio'::text])))`

Índices:

- `CREATE INDEX idx_pagos_id_orden_cambio_fkey ON public.pagos USING btree (id_orden_cambio)`
- `CREATE UNIQUE INDEX pagos_alta_jti_uidx ON public.pagos USING btree (alta_jti) WHERE (alta_jti IS NOT NULL)`
- `CREATE INDEX pagos_buy_order_idx ON public.pagos USING btree (buy_order) WHERE ((buy_order IS NOT NULL) AND (length(TRIM(BOTH FROM buy_order)) > 0))`
- `CREATE INDEX pagos_por_confirmar_idx ON public.pagos USING btree (estado) WHERE (estado = 'pagado_por_confirmar'::text)`
- `CREATE INDEX pagos_token_tbk_idx ON public.pagos USING btree (token_tbk) WHERE ((token_tbk IS NOT NULL) AND (length(TRIM(BOTH FROM token_tbk)) > 0))`
- `CREATE INDEX pagos_trabajo_estado_idx ON public.pagos USING btree (id_trabajo, estado)`
- `CREATE UNIQUE INDEX pagos_un_principal_activo_uidx ON public.pagos USING btree (id_trabajo) WHERE ((tipo_pago = 'principal'::text) AND (estado = ANY (ARRAY['pendiente'::text, 'retenido'::text, 'autorizado'::text])))`

**RLS.** RLS activo. El cliente dueño del trabajo, el profesional asignado o un administrador pueden leer el pago. Tokens, URL de Webpay y datos de alta de invitado no se exponen al cliente (columnas acotadas o solo service_role en la práctica de las Edge Functions). La creación de la intención de pago es por RPC. Políticas: SELECT «pagos_select».

**Forma normal: BCNF.** Muchas columnas, pero todas describen el mismo cobro (montos, estado, datos de Transbank, alta de invitado). No hay columnas que dependan de otra que no sea clave.

**Relaciones en palabras.** id_orden_cambio apunta a ordenes_cambio (si se borra la fila de ordenes_cambio, la columna queda vacía y el registro se conserva); id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan).

### 3.44 ordenes_cambio

Cambio de alcance o de precio durante un trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id, not null |  |
| `id_trabajador` | `uuid` | fk → perfiles.id, not null |  |
| `tipo` | `text` | not null |  |
| `titulo` | `text` | not null |  |
| `descripcion` | `text` | not null |  |
| `monto_clp` | `integer` | not null |  |
| `estado` | `text` | not null, default: 'pendiente_cliente' |  |
| `id_pago` | `text` | fk → pagos.id |  |
| `creado_en` | `text` | not null |  |
| `respondido_en` | `text` |  |  |

CHECK:

- `ordenes_cambio_creado_en_iso_chk`: `CHECK (es_marca_tiempo_iso(creado_en))`
- `ordenes_cambio_monto_chk`: `CHECK ((monto_clp >= 0))`
- `ordenes_cambio_respondido_en_iso_chk`: `CHECK (es_marca_tiempo_iso(respondido_en))`

Índices:

- `CREATE INDEX idx_change_orders_job ON public.ordenes_cambio USING btree (id_trabajo)`
- `CREATE INDEX idx_ordenes_cambio_id_pago_fkey ON public.ordenes_cambio USING btree (id_pago)`
- `CREATE INDEX idx_ordenes_cambio_id_trabajador_fkey ON public.ordenes_cambio USING btree (id_trabajador)`

**RLS.** RLS activo. Las partes del trabajo o un administrador leen y proponen según el flujo; el cobro asociado va por RPC de pago. Políticas: ALL «ordenes_cambio_all».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_trabajo apunta a trabajos (si se borra la fila de trabajos, también se borran las filas que la usan); id_pago apunta a pagos (si se borra la fila de pagos, la columna queda vacía y el registro se conserva); id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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
- `liquidaciones_id_trabajador_uuid_chk`: `CHECK (((id_trabajador IS NULL) OR (id_trabajador ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'::text)))`
- `liquidaciones_monto_clp_check`: `CHECK ((monto_clp > (0)::numeric))`
- `liquidaciones_proveedor_check`: `CHECK ((proveedor = ANY (ARRAY['manual'::text, 'khipu'::text, 'fintoc'::text, 'conformidad'::text])))`

Índices:

- `CREATE INDEX idx_liquidaciones_id_trabajo_fkey ON public.liquidaciones USING btree (id_trabajo)`
- `CREATE INDEX liquidaciones_creado_idx ON public.liquidaciones USING btree (creado_en DESC)`
- `CREATE UNIQUE INDEX liquidaciones_pago_uidx ON public.liquidaciones USING btree (id_pago)`
- `CREATE INDEX liquidaciones_trabajador_creado_idx ON public.liquidaciones USING btree (id_trabajador, creado_en DESC)`

**RLS.** RLS activo. El profesional ve la liquidación de sus pagos; un administrador ve todas. La confirmación de transferencia es por RPC de admin. Políticas: DELETE «liquidaciones_admin_delete», INSERT «liquidaciones_admin_insert», UPDATE «liquidaciones_admin_update», SELECT «liquidaciones_select».

**Forma normal: BCNF.** id_pago es único (clave candidata) y determina el trabajo y el profesional, así que la tabla cumple BCNF. Dato repetido a propósito: id_trabajo e id_trabajador repiten datos del pago y del trabajo. Es un libro contable: debe conservar a quién se pagó aunque el trabajo cambie. Diferencias: 0.

**Relaciones en palabras.** id_pago apunta a pagos (no se puede borrar la fila de pagos mientras tenga registros asociados); id_trabajo apunta a trabajos (no se puede borrar la fila de trabajos mientras tenga registros asociados).

### 3.46 metodos_pago_oneclick

Tarjeta inscrita Oneclick. RLS niega el acceso a anon y authenticated: solo service_role (Edge Functions).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_usuario` | `uuid` | pk, fk → perfiles.id, not null |  |
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

**Forma normal: BCNF.** Extensión 1:1 del perfil (una tarjeta OneClick por usuario). Desde la auditoría id_usuario es uuid con clave foránea a perfiles.

**Relaciones en palabras.** id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

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

**Forma normal: BCNF.** Extensión 1:1 del perfil (la clave es id_usuario).

**Relaciones en palabras.** id_usuario apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan).

### 3.48 app_config

Pares clave/valor de configuración (demo_modo, admin_requiere_aal2, etc.). RLS niega el acceso a clientes; lo lee el backend.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `clave` | `text` | pk, not null |  |
| `valor` | `text` | not null |  |
| `actualizado_en` | `timestamptz` | not null, default: now() |  |

**RLS.** RLS activo. Política ALL con USING/CHECK false para anon y authenticated. Nadie del cliente lee ni escribe; solo service_role (bypass RLS) o funciones definer. Políticas: ALL «app_config_sin_acceso_cliente».

**Forma normal: BCNF.** Tabla clave-valor: la clave determina el valor y nada más.

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

- `ranking_config_aprendizaje_activo_bool_chk`: `CHECK (((aprendizaje_activo IS NULL) OR (aprendizaje_activo = ANY (ARRAY[0, 1]))))`
- `ranking_config_unica`: `CHECK ((id = 'default'::text))`

**RLS.** RLS activo. La lectura de la fila default está permitida a autenticados (para el listado). Solo un administrador la actualiza por RPC. Políticas: ALL «ranking_config_admin».

**Forma normal: BCNF.** Una sola fila de configuración del ranking.

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
| `resuelto_por` | `uuid` | fk → perfiles.id |  |
| `resuelto_en` | `timestamptz` |  |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

CHECK:

- `senales_resena_estado_chk`: `CHECK ((estado = ANY (ARRAY['pendiente'::text, 'fraude_confirmado'::text, 'falso_positivo'::text, 'descartada'::text])))`

Índices:

- `UNIQUE (id_calificacion, tipo_senal)`
- `CREATE INDEX idx_senales_resena_resuelto_por_fkey ON public.senales_resena USING btree (resuelto_por)`
- `CREATE INDEX senales_resena_estado_idx ON public.senales_resena USING btree (estado, creado_en DESC)`
- `CREATE UNIQUE INDEX senales_resena_unica ON public.senales_resena USING btree (id_calificacion, tipo_senal)`

**RLS.** RLS activo. Cola de reseñas dudosas: la ve y resuelve un administrador. Políticas: SELECT «senales_resena_admin».

**Forma normal: BCNF.** La clave primaria es un identificador propio y cada columna describe solo a esa fila; ninguna columna depende de otra que no sea clave.

**Relaciones en palabras.** id_calificacion apunta a calificaciones (si se borra la fila de calificaciones, también se borran las filas que la usan); resuelto_por apunta a perfiles (si se borra la fila de perfiles, la columna queda vacía y el registro se conserva).

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

**Forma normal: BCNF.** Bitácora: pesos antes y después de cada ajuste.

### 3.52 eventos_ranking

Evento que alimenta el ranking de un profesional.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, not null |  |
| `id_trabajador` | `uuid` | fk → perfiles.id, not null |  |
| `id_trabajo` | `text` | fk → trabajos.id |  |
| `tipo_evento` | `text` | not null |  |
| `factores` | `jsonb` | not null, default: '{}' |  |
| `creado_en` | `timestamptz` | not null, default: now() |  |

Índices:

- `CREATE INDEX eventos_ranking_trabajador_idx ON public.eventos_ranking USING btree (id_trabajador, tipo_evento)`
- `CREATE INDEX idx_eventos_ranking_id_trabajo_fkey ON public.eventos_ranking USING btree (id_trabajo)`

**RLS.** RLS activo. Lectura de administración; la escritura la hacen triggers y funciones definer. Políticas: SELECT «eventos_ranking_select_admin».

**Forma normal: BCNF.** Registro de eventos; factores es la foto de los factores al momento del evento.

**Relaciones en palabras.** id_trabajador apunta a perfiles (si se borra la fila de perfiles, también se borran las filas que la usan); id_trabajo apunta a trabajos (si se borra la fila de trabajos, la columna queda vacía y el registro se conserva).

## 4. Relaciones (claves foráneas físicas)

Se listan las FK declaradas en Postgres. La auditoría 2026-11-16 agregó las que faltaban (todas con 0 huérfanos verificados antes de validarlas). Las únicas referencias sin FK física son polimórficas (`notificaciones.id_relacionado`) o libros contables con id en texto (`liquidaciones.id_trabajador`).

| Tabla | Columnas | Referencia | ON DELETE |
|-------|----------|------------|-----------|
| `perfiles` | `id` | `auth.users(id)` | CASCADE NOT VALID |
| `notificaciones` | `id_usuario` | `perfiles(id)` | CASCADE |
| `suscripciones` | `id_usuario` | `perfiles(id)` | CASCADE |
| `codigos_restablecimiento` | `id_usuario` | `perfiles(id)` | CASCADE |
| `consentimientos_usuario` | `id_usuario` | `perfiles(id)` | CASCADE |
| `bloqueos_usuario` | `id_bloqueado` | `perfiles(id)` | CASCADE |
| `bloqueos_usuario` | `id_bloqueador` | `perfiles(id)` | CASCADE |
| `reportes` | `id_reportante` | `perfiles(id)` | CASCADE |
| `reportes` | `id_usuario_reportado` | `perfiles(id)` | CASCADE |
| `eventos_abuso` | `id_usuario` | `perfiles(id)` | CASCADE |
| `acciones_pendientes` | `id_usuario` | `perfiles(id)` | CASCADE |
| `registros_error_app` | `id_usuario` | `perfiles(id)` | — |
| `eventos_analitica` | `id_usuario` | `perfiles(id)` | SET NULL |
| `banderas_funcionalidad` | `id_usuario` | `perfiles(id)` | CASCADE |
| `dispositivos_push` | `id_usuario` | `perfiles(id)` | CASCADE |
| `verificacion_eventos` | `id_actor` | `perfiles(id)` | SET NULL |
| `verificacion_eventos` | `id_usuario` | `perfiles(id)` | CASCADE |
| `regiones` | `id_pais` | `paises(id)` | — |
| `comunas` | `id_region` | `regiones(id)` | — |
| `trabajadores` | `id_comuna` | `comunas(id)` | SET NULL |
| `trabajadores` | `id_region` | `regiones(id)` | SET NULL |
| `trabajadores` | `id_usuario` | `perfiles(id)` | CASCADE |
| `trabajador_precios` | `id_usuario` | `trabajadores(id_usuario)` | CASCADE |
| `trabajador_servicios_extra` | `id_usuario` | `trabajadores(id_usuario)` | CASCADE |
| `trabajador_servicios` | `id_trabajador` | `perfiles(id)` | CASCADE |
| `trabajador_horarios` | `id_usuario` | `trabajadores(id_usuario)` | CASCADE |
| `portafolio_trabajador` | `id_trabajador` | `perfiles(id)` | CASCADE |
| `impulsos` | `id_trabajador` | `perfiles(id)` | CASCADE |
| `configuraciones_servicio` | `id_servicio` | `servicios(id)` | CASCADE |
| `trabajos` | `id_servicio` | `servicios(id)` | SET NULL |
| `trabajos` | `id_usuario` | `perfiles(id)` | CASCADE |
| `trabajos` | `id_trabajador` | `perfiles(id)` | SET NULL |
| `trabajos` | `id_comuna` | `comunas(id)` | SET NULL |
| `trabajos` | `id_cotizacion_seleccionada` | `propuestas_cotizacion(id)` | SET NULL |
| `mensajes` | `id_destinatario` | `perfiles(id)` | CASCADE |
| `mensajes` | `id_remitente` | `perfiles(id)` | CASCADE |
| `mensajes` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `fotos_trabajo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `calificaciones` | `id_calificado` | `perfiles(id)` | CASCADE |
| `calificaciones` | `id_usuario` | `perfiles(id)` | SET NULL |
| `calificaciones` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `calificaciones_cliente` | `id_cliente` | `perfiles(id)` | CASCADE |
| `calificaciones_cliente` | `id_trabajador` | `perfiles(id)` | CASCADE |
| `calificaciones_cliente` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `disputas` | `abierta_por` | `perfiles(id)` | CASCADE |
| `disputas` | `resuelta_por` | `perfiles(id)` | SET NULL |
| `disputas` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `disputa_mensajes` | `id_autor` | `perfiles(id)` | — |
| `disputa_mensajes` | `id_disputa` | `disputas(id)` | CASCADE |
| `acuerdos_trabajo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `acuerdos_trabajo` | `propuesto_por` | `perfiles(id)` | — |
| `cancelaciones_trabajo` | `cancelado_por` | `perfiles(id)` | CASCADE |
| `cancelaciones_trabajo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `tickets_soporte` | `id_trabajo` | `trabajos(id)` | SET NULL |
| `ubicacion_en_vivo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `ubicacion_en_vivo` | `id_trabajador` | `trabajadores(id_usuario)` | CASCADE |
| `reprogramaciones_trabajo` | `propuesta_por` | `perfiles(id)` | CASCADE |
| `reprogramaciones_trabajo` | `respondida_por` | `perfiles(id)` | SET NULL |
| `reprogramaciones_trabajo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `pines_inicio_trabajo` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `bloqueos_pin_inicio` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `intentos_pin_inicio` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `intentos_pin_inicio` | `id_usuario` | `perfiles(id)` | SET NULL |
| `propuestas_cotizacion` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `propuestas_cotizacion` | `id_trabajador` | `perfiles(id)` | CASCADE |
| `pagos` | `id_orden_cambio` | `ordenes_cambio(id)` | SET NULL |
| `pagos` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `ordenes_cambio` | `id_trabajo` | `trabajos(id)` | CASCADE |
| `ordenes_cambio` | `id_pago` | `pagos(id)` | SET NULL |
| `ordenes_cambio` | `id_trabajador` | `perfiles(id)` | CASCADE |
| `liquidaciones` | `id_pago` | `pagos(id)` | — |
| `liquidaciones` | `id_trabajo` | `trabajos(id)` | — |
| `metodos_pago_oneclick` | `id_usuario` | `perfiles(id)` | CASCADE |
| `cuentas_bancarias` | `id_usuario` | `perfiles(id)` | CASCADE |
| `senales_resena` | `id_calificacion` | `calificaciones(id)` | CASCADE |
| `senales_resena` | `resuelto_por` | `perfiles(id)` | SET NULL |
| `eventos_ranking` | `id_trabajador` | `perfiles(id)` | CASCADE |
| `eventos_ranking` | `id_trabajo` | `trabajos(id)` | SET NULL |

## 4b. Normalización (auditoría 2026-11-16)

Cada tabla se revisó con las dependencias funcionales reales (qué columna determina a cuál). 1FN: cada celda guarda un solo valor y hay clave primaria. 2FN: ninguna columna depende solo de una parte de una clave compuesta. 3FN: ninguna columna que no es clave depende de otra columna que tampoco es clave. BCNF: todo lo que determina a otra columna es una clave candidata. 4FN: no se mezclan en una tabla dos listas independientes del mismo dueño. Las columnas JSON/text con un documento completo (payload de sincronización, desglose, configuración) se tratan como un valor atómico: la base no consulta su interior por separado. Cuando una tabla repite un dato de otra a propósito, se indica por qué y cómo se mantiene consistente; en todas se verificó 0 diferencias.

| Tabla | Forma normal | Dato repetido a propósito y cómo se mantiene |
|-------|--------------|-----------------------------------------------|
| `perfiles` | BCNF | correo repite el correo de auth.users para mostrarlo y buscarlo sin salir de public (diferencias: 0). reputacion_cliente y calificaciones_cliente son totales calculados por calificar_cliente(); desde la auditoría un usuario no puede editarlos. |
| `notificaciones` | BCNF | id_relacionado apunta a un trabajo u otro objeto según el tipo de aviso (referencia polimórfica), por eso no tiene clave foránea física. |
| `suscripciones` | BCNF | — |
| `codigos_restablecimiento` | BCNF | correo copia el correo al que se envió el código: es un registro histórico, no se actualiza si el usuario cambia su correo. |
| `consentimientos_usuario` | BCNF | — |
| `bloqueos_usuario` | BCNF | — |
| `reportes` | BCNF | — |
| `eventos_abuso` | BCNF | — |
| `acciones_pendientes` | BCNF | — |
| `registros_error_app` | BCNF | — |
| `eventos_analitica` | BCNF | — |
| `banderas_funcionalidad` | BCNF | — |
| `dispositivos_push` | BCNF | — |
| `verificacion_eventos` | BCNF | — |
| `paises` | BCNF | — |
| `regiones` | BCNF | — |
| `comunas` | BCNF | — |
| `trabajadores` | 2FN con datos derivados documentados | niveles_precio y servicios_personalizados son el formato de escritura de la app; un trigger los parte en trabajador_precios y trabajador_servicios_extra. calificacion, trabajos_completados, score_listado y es_elite son valores calculados para ordenar el catálogo sin recalcular en cada consulta. id_region se deduce de id_comuna cuando hay comuna (diferencias: 0). |
| `trabajador_precios` | 4FN | — |
| `trabajador_servicios_extra` | 4FN | — |
| `trabajador_servicios` | 4FN | — |
| `trabajador_horarios` | BCNF con una columna heredada | horarios (jsonb) es el formato antiguo de la semana completa que aún leen versiones previas de la app; la fuente de verdad son las columnas por día. |
| `portafolio_trabajador` | BCNF | — |
| `impulsos` | BCNF | — |
| `servicios` | BCNF | — |
| `configuraciones_servicio` | BCNF | — |
| `trabajos` | BCNF con una copia mantenida por trigger | estado_pago copia el estado del pago principal (trigger copiar_estado_pago_trabajo) para filtrar listas sin unir con pagos. Diferencias: 0. |
| `mensajes` | 2FN con desnormalización controlada | Se guarda id_destinatario para filtrar en tiempo real (Realtime) y en RLS sin unir con trabajos; lo valida la política de inserción. Diferencias verificadas: 0. |
| `fotos_trabajo` | BCNF | — |
| `calificaciones` | BCNF | id_calificado repite a quién se calificó, dato que también se deduce de trabajos. Se guarda para filtrar reseñas por persona con índice y en RLS; lo fija la función que crea la reseña. Diferencias verificadas: 0. |
| `calificaciones_cliente` | BCNF | id_trabajador también se deduce de trabajos; se guarda para RLS (el profesional ve lo que escribió). Diferencias: 0. |
| `disputas` | BCNF | — |
| `disputa_mensajes` | BCNF | — |
| `acuerdos_trabajo` | BCNF | — |
| `cancelaciones_trabajo` | BCNF | — |
| `tickets_soporte` | 2FN con desnormalización controlada | nombre_cliente, nombre_trabajador y monto_escrow son la foto del caso al abrir el ticket (trigger fijar_ticket_desde_trabajo), para que la consola de soporte no cambie si después cambia el perfil o el pago. |
| `ubicacion_en_vivo` | BCNF | id_trabajador repite el profesional del trabajo para autorizar la publicación en tiempo real. Diferencias: 0. |
| `reprogramaciones_trabajo` | BCNF | — |
| `pines_inicio_trabajo` | BCNF | — |
| `bloqueos_pin_inicio` | BCNF | — |
| `intentos_pin_inicio` | BCNF | — |
| `propuestas_cotizacion` | BCNF | — |
| `pagos` | BCNF | — |
| `ordenes_cambio` | BCNF | — |
| `liquidaciones` | BCNF | id_trabajo e id_trabajador repiten datos del pago y del trabajo. Es un libro contable: debe conservar a quién se pagó aunque el trabajo cambie. Diferencias: 0. |
| `metodos_pago_oneclick` | BCNF | — |
| `cuentas_bancarias` | BCNF | — |
| `app_config` | BCNF | — |
| `ranking_config` | BCNF | — |
| `senales_resena` | BCNF | — |
| `ranking_aprendizaje` | BCNF | — |
| `eventos_ranking` | BCNF | — |

Detalle del método, consultas de verificación y migraciones: `docs/pruebas/auditoria_base_datos.md`.

## 5. Enums y vistas

El esquema `public` no define tipos ENUM ni vistas (ni materializadas). Los estados y conjuntos cerrados (rol de una reprogramación, tipo de acuerdo, estado de verificación, etc.) se restringen con CHECK sobre columnas `text` o `boolean`.

## 6. Funciones RPC y SECURITY DEFINER

Hay 148 funciones (o procedimientos) en `public`. 119 son SECURITY DEFINER. A continuación se documentan las que forman la API de cliente (GRANT a `anon` o `authenticated`) y, en un segundo listado, las de backend / disparadores (solo `service_role` o uso interno).

### 6.1 API de cliente (`anon` / `authenticated`)

| Función | Argumentos | Retorno | Seguridad | Quién ejecuta | Propósito |
|---------|------------|---------|-----------|---------------|-----------|

### 6.2 Backend, cron y disparadores (principalmente `service_role`)

| Función | Argumentos | Retorno | Seguridad | Propósito |
|---------|------------|---------|-----------|-----------|
| `_evaluar_resena_trigger` | — | trigger | SECURITY DEFINER | Disparador que encola la evaluación automática de una reseña nueva. |
| `_hora_santiago` | p_ts timestamp with time zone | text | SECURITY INVOKER | Convierte un timestamptz a la hora oficial de Chile (America/Santiago), con horario de verano. |
| `_normalizar_pesos_ranking` | p_cal numeric, p_comp numeric, p_rech numeric, p_ver numeric, p_imp numeric, p_rec numeric, p_conf numeric | numeric[] | SECURITY INVOKER | Normaliza los pesos del ranking para que sumen 1. |
| `_notificar_reprogramacion` | p_destino uuid, p_id_trabajo text, p_titulo text, p_cuerpo text | void | SECURITY DEFINER | Crea la notificación de una propuesta, respuesta o retiro de reagendamiento. |
| `_ranking_cfg` | — | ranking_config | SECURITY DEFINER | Lee la fila default de ranking_config. |
| `_recomputar_agregados_por_calificacion` | — | trigger | SECURITY DEFINER | Función interna, disparador o tarea de servicio. |
| `_registrar_evento_ranking` | p_trabajador uuid, p_trabajo text, p_tipo text | void | SECURITY DEFINER | Inserta un evento en eventos_ranking. |
| `abrir_disputa` | p_id text, p_id_trabajo text, p_motivo text, p_descripcion text | void | SECURITY DEFINER | El cliente o el profesional abre una disputa sobre un trabajo activo. |
| `acuerdo_pendiente` | p_id_trabajo text | TABLE(id text, tipo text, estado text, acepta_cliente boolean, acepta_trabajador boolean) | SECURITY DEFINER | Devuelve el acuerdo aún pendiente de un trabajo, si existe. |
| `admin_actualizar_estado_disputa` | p_id text, p_estado text, p_resolucion text | void | SECURITY DEFINER | Un administrador cambia el estado o la resolución de una disputa. |
| `admin_metricas_resumen` | — | json | SECURITY DEFINER | Métricas del panel ejecutivo (solo administrador). |
| `aplicar_cierre_disputa` | p_disputa_id text, p_operador text, p_decision text, p_resolucion text | jsonb | SECURITY DEFINER | Aplica la decisión de cierre de una disputa (uso interno / servicio). |
| `aprender_pesos_ranking` | — | jsonb | SECURITY DEFINER | Ajusta los pesos del ranking a partir de las señales (interno). |
| `aprender_pesos_ranking_admin` | — | jsonb | SECURITY DEFINER | Un administrador dispara el aprendizaje de pesos. |
| `asegurar_pin_inicio` | p_trabajo_id text | text | SECURITY DEFINER | Crea el PIN de un trabajo si todavía no existe (interno). |
| `asignar_trabajador_trabajo` | p_trabajo_id text, p_trabajador_id text | trabajos | SECURITY DEFINER | Acepta un trabajo abierto. El destino tiene que tener rol trabajador. Un cliente no puede autoasignarse. |
| `base_publica_profesional` | p_id uuid | TABLE(latitud_base double precision, longitud_base double precision) | SECURITY DEFINER | Ficha pública de un profesional para el catálogo (sin datos sensibles). Disponible también para anon. |
| `borrar_gps_si_trabajo_cerrado` | — | trigger | SECURITY DEFINER | Trigger: borra ubicacion_en_vivo cuando el trabajo deja de estar activo. |
| `calificar_cliente` | p_trabajo_id text, p_puntaje integer, p_comentario text | numeric | SECURITY DEFINER | El profesional califica al cliente al terminar el trabajo. |
| `categorias_con_disponibles` | — | SETOF text | SECURITY DEFINER | Categorías del catálogo que hoy tienen profesionales disponibles. También para anon. |
| `cerrar_trabajo_conforme` | p_trabajo_id text | trabajos | SECURITY DEFINER | El cliente cierra el trabajo conforme y habilita la liberación del pago retenido. |
| `clasificar_disputa` | p_trabajo_id text, p_motivo text | TABLE(decision text, regla text, estado text, vence timestamp with time zone) | SECURITY DEFINER | Clasificación automática de una disputa (soporte automático, interno). |
| `comentar_disputa` | p_id text, p_comentario text | void | SECURITY DEFINER | Una de las partes agrega un comentario al hilo de la disputa. |
| `confirmar_trabajo_tras_captura` | p_id_pago text | text | SECURITY DEFINER | Tras capturar el pago (Webpay/Oneclick), confirma el trabajo. Lo llama el backend. |
| `consola_disputas_abiertas` | — | TABLE(id text, id_trabajo text, motivo text, descripcion text, estado text, decision_sugerida text, motivo_regla text, vence_en timestamp with time zone, creado_en text, nombre_cliente text, nombre_profesional text, monto_retenido numeric) | SECURITY DEFINER | Cola de disputas para la consola de escritorio (administrador, soporte o qa). qa no ve la evidencia del domicilio. |
| `copiar_estado_pago_trabajo` | — | trigger | SECURITY DEFINER | Trigger: copia el estado del pago principal a trabajos.estado_pago. |
| `crear_intencion_pago` | p_id_trabajo text, p_monto numeric, p_buy_order text | pagos | SECURITY DEFINER | Crea la intención de pago (Webpay) del trabajo, con el monto que fija el servidor. |
| `crear_intencion_pago_orden_cambio` | p_id_trabajo text, p_id_orden_cambio text, p_monto numeric, p_buy_order text | pagos | SECURITY DEFINER | Crea la intención de pago de una orden de cambio. |
| `crear_intencion_pago_servicio` | p_id_usuario text, p_id_trabajo text, p_monto numeric | pagos | SECURITY DEFINER | Variante de servicio (Edge Function / service_role) para crear la intención de pago. |
| `disputa_esta_activa` | p_estado text | boolean | SECURITY INVOKER | Indica si el estado de una disputa se considera activo. |
| `enviar_verificacion_profesional` | p_nota text | void | SECURITY DEFINER | El profesional envía o reenvía su solicitud de verificación. |
| `es_marca_tiempo_iso` | p_valor text | boolean | SECURITY INVOKER | true si el texto es una fecha u hora ISO-8601 (o NULL). Lo usan los CHECK de las columnas *_en guardadas como text. |
| `es_parte_trabajo` | p_trabajo_id text | boolean | SECURITY DEFINER | True si el usuario autenticado es el cliente o el profesional del trabajo. |
| `es_rol_trabajador` | p_usuario_id text | boolean | SECURITY DEFINER | True si el perfil indicado tiene rol de profesional. |
| `evaluar_resena` | p_id text | numeric | SECURITY DEFINER | Evalúa una reseña y genera señales si parece dudosa (interno). |
| `evidencia_disputa` | p_id_disputa text | TABLE(id text, imagen_base64 text) | SECURITY DEFINER | Devuelve la evidencia del trabajo en disputa. Administrador o soporte; qa no la ve. |
| `expirar_pagos_abandonados` | — | integer | SECURITY DEFINER | Marca o limpia pagos abandonados (tarea de servicio / cron). |
| `explotar_oferta_trabajador` | — | trigger | SECURITY DEFINER | Parte los JSON de oferta a las tablas 4NF (trigger). |
| `fichas_sensibles_admin` | — | TABLE(id_usuario uuid, latitud_base double precision, longitud_base double precision, nota_verificacion text) | SECURITY DEFINER | Lectura de fichas con datos sensibles, solo administrador. |
| `fijar_correo_codigo` | — | trigger | SECURITY DEFINER | Trigger de apoyo para códigos de restablecimiento. |
| `fijar_geo_trabajador` | — | trigger | SECURITY INVOKER | Normaliza la geografía (comuna, región, base) de la ficha del profesional. |
| `fijar_liquidacion_desde_pago` | — | trigger | SECURITY DEFINER | Trigger: crea o actualiza la liquidación cuando el pago queda liberado. |
| `fijar_prioridad_trabajador` | p_id uuid, p_prioridad integer | void | SECURITY DEFINER | Un administrador ajusta prioridad_manual (−50 a 50). |
| `fijar_ticket_desde_trabajo` | — | trigger | SECURITY DEFINER | Trigger: abre o actualiza el ticket de soporte asociado. |
| `fijar_verificacion_profesional` | p_id_usuario uuid, p_estado text, p_nota text | void | SECURITY DEFINER | Un administrador cambia el estado de verificación y deja nota. |
| `fotos_trabajo_exigir_webp` | — | trigger | SECURITY INVOKER | Trigger: valida el formato de la evidencia. |
| `guardar_config_ranking` | p_cfg jsonb | jsonb | SECURITY DEFINER | Un administrador guarda los pesos y umbrales de ranking_config. |
| `guardar_horarios_propios` | p_horarios jsonb | jsonb | SECURITY DEFINER | El profesional guarda su plantilla semanal (reemplazo atómico). |
| `handle_new_user` | — | trigger | SECURITY DEFINER | Trigger de auth: crea el perfil public al registrarse un usuario. |
| `horarios_disponibles_propios` | — | jsonb | SECURITY DEFINER | El profesional lee su propia plantilla semanal. |
| `horarios_libres_profesional` | p_id_trabajador uuid, p_dias integer | TABLE(inicio timestamp with time zone) | SECURITY DEFINER | Huecos libres de un profesional en los próximos n días (también anon). No expone la tabla trabajador_horarios. |
| `intentar_pin_inicio` | p_trabajo_id text, p_pin text | jsonb | SECURITY DEFINER | El profesional prueba el PIN del cliente. Tras 5 fallos, bloquea 15 minutos. |
| `is_admin` | — | boolean | SECURITY DEFINER | True si el usuario autenticado tiene rol admin o administrador. |
| `km_entre_puntos` | p_lat1 double precision, p_lng1 double precision, p_lat2 double precision, p_lng2 double precision | double precision | SECURITY INVOKER | Distancia en kilómetros entre dos coordenadas (uso interno de recargo). |
| `liberar_escrow` | p_id_pago text | pagos | SECURITY DEFINER | Libera el pago retenido al profesional (backend, service_role). |
| `liberar_escrow_manual` | p_id_pago text, p_id_operador text, p_referencia text, p_notas text, p_proveedor text | jsonb | SECURITY DEFINER | Liberación manual de un pago retenido, con referencia y notas de un operador. |
| `liberar_trabajo_sistema` | p_trabajo_id text, p_nota text | void | SECURITY DEFINER | El sistema libera o cierra un trabajo (tarea interna). |
| `limpiar_alta_trabajo` | — | trigger | SECURITY INVOKER | Limpia los datos de alta de invitado ya consumidos o vencidos (servicio). |
| `limpiar_invitados_sin_pago` | — | integer | SECURITY DEFINER | Borra cuentas de invitado sin cobro retenido, liberado ni autorizado, pasadas 24 h (service_role). |
| `listar_cuentas_demo_acceso` | — | TABLE(id uuid, nombre text, correo text, rol text, profesion text, categoria_servicio text) | SECURITY DEFINER | Lista las cuentas demo permitidas (servicio / modo demo cerrado). |
| `listar_profesionales_catalogo` | p_categoria text, p_zona text, p_cursor_calificacion numeric, p_cursor_id uuid, p_limit integer | TABLE(id_usuario uuid, profesion text, descripcion text, calificacion numeric, tarifa_visita numeric, categoria_servicio text, zona_trabajo text, nombre text, ruta_foto_perfil text, latitud_base double precision, longitud_base double precision, radio_servicio_km numeric, origen_base text, trabajos_completados integer, score_listado numeric, prioridad_manual integer, radio_urbano_km numeric, tarifa_fuera_radio_clp integer, es_elite boolean) | SECURITY DEFINER | Listado paginado del marketplace (también anon), ordenado por el ranking. |
| `listar_senales_resena` | p_estado text, p_limit integer | TABLE(id text, id_calificacion text, tipo_senal text, puntaje numeric, detalle text, estado text, creado_en timestamp with time zone, puntaje_resena integer, comentario text, estado_revision text, peso_confianza numeric, id_trabajo text, id_trabajador uuid, nombre_trabajador text, nombre_cliente text) | SECURITY DEFINER | Cola de señales de reseña para un administrador. |
| `listar_trabajos_marketplace` | p_limite integer | TABLE(id text, estado text, descripcion text, creado_en text, actualizado_en text, id_servicio text, modalidad_cobro text, metadatos_servicio text) | SECURITY DEFINER | Trabajos abiertos que un profesional puede tomar. |
| `marcar_orden_cambio_pagada` | p_id_orden_cambio text, p_id_pago text | ordenes_cambio | SECURITY DEFINER | Asocia el pago a la orden de cambio cuando Webpay confirma el cobro. |
| `marcar_pago_liberado` | p_id_pago text, p_id_operador text, p_referencia text, p_notas text | void | SECURITY DEFINER | Marca un pago como liberado (operación de backend / admin). |
| `marcar_reembolso_automatico` | p_id_pago text, p_modo text | text | SECURITY DEFINER | Registra un reembolso automático pedido a Transbank. |
| `mensajes_bloquear_contacto` | — | trigger | SECURITY DEFINER | Trigger: rechaza mensajes que parecen contener teléfono o correo. |
| `mensajes_solo_marcar_leido` | — | trigger | SECURITY DEFINER | Trigger: un destinatario solo puede marcar leído, no editar el cuerpo. |
| `metadatos_sin_pin` | p_raw text | text | SECURITY INVOKER | Quita el PIN de un JSON de metadatos antes de guardarlo o devolverlo. |
| `mi_ficha_propia` | — | TABLE(latitud_base double precision, longitud_base double precision, radio_servicio_km numeric, origen_base text, estado_verificacion text, nota_verificacion text) | SECURITY DEFINER | Devuelve la ficha del profesional autenticado, incluyendo campos no públicos. |
| `minuto_utc` | p_valor text | timestamp with time zone | SECURITY INVOKER | Normaliza una fecha-hora en texto al minuto UTC; se usa en el índice único de agenda. |
| `monto_esperado_trabajo` | p_job trabajos | numeric | SECURITY DEFINER | Calcula el monto que el servidor espera para el trabajo (no lo fija el cliente). |
| `normalizar_bloques_horario` | p_horarios jsonb | jsonb | SECURITY INVOKER | Normaliza el JSON de bloques horarios antes de guardarlo. |
| `obtener_config_ranking` | — | jsonb | SECURITY DEFINER | Lee la configuración actual del ranking. |
| `obtener_pin_inicio` | p_trabajo_id text | text | SECURITY DEFINER | El cliente (o un administrador) obtiene el PIN para mostrárselo al profesional. |
| `obtener_trabajo_sin_direccion` | p_id text | jsonb | SECURITY DEFINER | Detalle de un trabajo sin exponer la dirección al que no corresponde. |
| `perfil_contacto_si_trabajo_activo` | p_perfil_id uuid | TABLE(id uuid, nombre text, correo text) | SECURITY DEFINER | Entrega datos de contacto de un perfil solo si hay un trabajo activo conjunto. |
| `perfiles_publicos_por_ids` | p_ids uuid[] | TABLE(id uuid, nombre text, rol text, ruta_foto_perfil text) | SECURITY DEFINER | Nombre y foto públicos de una lista de perfiles. |
| `perfiles_reputacion_inicial_segura` | — | trigger | SECURITY INVOKER | Función interna, disparador o tarea de servicio. |
| `perfiles_rol_inicial_seguro` | — | trigger | SECURITY INVOKER | Trigger: impide que un alta o un update se autoasigne rol administrador, soporte o qa. |
| `profesional_tiene_trabajo_activo` | p_id_trabajador uuid | boolean | SECURITY DEFINER | True si el profesional tiene un trabajo que aún no termina. |
| `profesionales_ocupados` | p_ids uuid[] | SETOF uuid | SECURITY DEFINER | Indica, de una lista de profesionales, cuáles están ocupados ahora. |
| `proponer_acuerdo` | p_id text, p_id_trabajo text, p_tipo text | jsonb | SECURITY DEFINER | Una de las partes propone rehacer, aceptar o anular un trabajo. |
| `proponer_reprogramacion` | p_trabajo_id text, p_fecha timestamp with time zone, p_motivo text | reprogramaciones_trabajo | SECURITY DEFINER | El cliente o el profesional propone una nueva fecha (CU-33). Queda una sola pendiente por trabajo. |
| `protect_profile_sensitive_fields` | — | trigger | SECURITY INVOKER | Trigger: impide que el usuario se cambie rol o estado_cuenta. |
| `proteger_campos_trabajador` | — | trigger | SECURITY INVOKER | Trigger: impide que el profesional altere score, verificación o pausa por su cuenta. |
| `proteger_campos_trabajo` | — | trigger | SECURITY INVOKER | Trigger: impide cambios de estado o de pago que no vayan por RPC. |
| `proteger_monto_cotizacion` | — | trigger | SECURITY INVOKER | Trigger: el monto de la cotización no lo cambia el cliente. |
| `proteger_verificacion_profesional` | — | trigger | SECURITY DEFINER | Trigger: el estado de verificación solo lo cambia un administrador o la RPC. |
| `publicar_ubicacion_trabajo` | p_trabajo_id text, p_lat double precision, p_lng double precision, p_precision double precision | void | SECURITY DEFINER | El profesional publica su GPS durante un trabajo activo. |
| `quitar_dispositivo_push` | p_token text | void | SECURITY DEFINER | El usuario elimina un token de notificaciones push. |
| `recargo_traslado_clp` | p_lat_trabajador double precision, p_lng_trabajador double precision, p_lat_trabajo double precision, p_lng_trabajo double precision, p_radio_km numeric | integer | SECURITY INVOKER | Calcula el recargo de traslado según el radio urbano y la tarifa fuera de radio. |
| `rechazar_trabajo_pendiente` | p_trabajo_id text, p_metadatos text | trabajos | SECURITY DEFINER | Cancela un pendiente. Solo admin o el trabajador ya asignado. Sin id_trabajador el control no se salta. |
| `reclamar_cobro_oneclick` | p_id_pago text, p_buy_order text, p_monto numeric | text | SECURITY DEFINER | Inicia o registra una autorización Oneclick (backend). |
| `recomputar_agregados_profesional` | p_id uuid | void | SECURITY DEFINER | Función interna, disparador o tarea de servicio. |
| `recomputar_agregados_profesionales` | — | integer | SECURITY DEFINER | Función interna, disparador o tarea de servicio. |
| `reconcile_secret_valido` | p_secret text | boolean | SECURITY DEFINER | Valida el secreto de la reconciliación Webpay (vault, service_role). |
| `reembolsar_escrow` | p_id_pago text | pagos | SECURITY DEFINER | Pide la devolución del pago retenido (backend). |
| `refrescar_calificacion_trabajador` | — | trigger | SECURITY DEFINER | Trigger: recalcula trabajadores.calificacion al cambiar una reseña. |
| `refrescar_ranking_ficha` | — | trigger | SECURITY DEFINER | Recalcula el score de una ficha (trigger). |
| `refrescar_ranking_por_impulso` | — | trigger | SECURITY DEFINER | Recalcula el score cuando cambia un impulso. |
| `refrescar_ranking_todos` | — | integer | SECURITY DEFINER | Recalcula el ranking de todos (interno / cron). |
| `refrescar_ranking_todos_admin` | — | integer | SECURITY DEFINER | Un administrador dispara el recálculo global del ranking. |
| `refrescar_ranking_trabajador` | p_id uuid | void | SECURITY DEFINER | Recalcula el ranking de un profesional concreto. |
| `registrar_dispositivo_push` | p_token text, p_plataforma text | void | SECURITY DEFINER | Registra o actualiza el token push del dispositivo del usuario. |
| `registrar_disputa_ranking` | — | trigger | SECURITY DEFINER | Trigger: registra en el ranking el efecto de una disputa. |
| `registrar_evento_verificacion` | — | trigger | SECURITY DEFINER | Trigger: inserta una fila en verificacion_eventos. |
| `registrar_resultado_trabajo` | — | trigger | SECURITY DEFINER | Trigger: actualiza completados, rechazos u otras señales al terminar un trabajo. |
| `registrar_transferencia_profesional` | p_id_pago text, p_referencia text, p_notas text | jsonb | SECURITY DEFINER | Un administrador confirma la transferencia de una liquidación (estado_transferencia). |
| `resolver_senal_resena` | p_id text, p_estado text | void | SECURITY DEFINER | Un administrador resuelve una señal de reseña dudosa. |
| `resolver_soporte_automatico` | — | jsonb | SECURITY DEFINER | Intenta resolver una disputa con las reglas automáticas (interno). |
| `responder_acuerdo` | p_id text, p_acepta boolean | jsonb | SECURITY DEFINER | La contraparte acepta o rechaza un acuerdo pendiente. |
| `responder_reprogramacion` | p_id uuid, p_acepta boolean | reprogramaciones_trabajo | SECURITY DEFINER | La contraparte acepta o rechaza la nueva fecha (CU-33). Si acepta, actualiza trabajos.fecha_programada. |
| `resumen_calificacion_clientes` | p_ids uuid[] | TABLE(id_usuario uuid, promedio numeric, cantidad integer) | SECURITY DEFINER | Promedio y conteo de reputación de una lista de clientes. |
| `retirar_reprogramacion` | p_id uuid | reprogramaciones_trabajo | SECURITY DEFINER | Quien propuso el cambio de fecha retira la propuesta pendiente (CU-33). |
| `rls_auto_enable` | — | event_trigger | SECURITY DEFINER | Utilidad interna para asegurar RLS en tablas nuevas. |
| `rol_consola` | — | text | SECURITY DEFINER | Devuelve administrador, soporte o qa si el usuario autenticado tiene un rol de la consola de escritorio; si no, null. |
| `seleccionar_cotizacion` | p_id_cotizacion text | trabajos | SECURITY DEFINER | El cliente elige una cotización y queda asociada al trabajo. |
| `simular_transicion_pago` | p_pago_id text, p_nuevo_estado text | pagos | SECURITY DEFINER | LEGACY — no usar desde clientes. Transiciones PSP vía Edge webpay-commit / liberar_escrow. |
| `sincronizar_estado_pago_trabajo` | p_trabajo_id text | trabajos | SECURITY DEFINER | Fuerza la copia del estado del pago principal al trabajo. |
| `slug_geo` | p_texto text | text | SECURITY INVOKER | Normaliza un texto a slug geográfico (comuna/región). También anon. |
| `soporte_comentar_disputa` | p_id text, p_comentario text | void | SECURITY DEFINER | Un administrador o soporte deja una nota visible para las partes en el hilo de la disputa. qa no puede. |
| `soporte_numero` | p_clave text, p_default numeric | numeric | SECURITY DEFINER | Lee un número de configuración de soporte automático. |
| `stats_profesional` | p_id uuid | TABLE(id_usuario uuid, calificacion numeric, n_calificaciones integer, trabajos_completados integer, es_elite boolean) | SECURITY INVOKER | Nota, reseñas y trabajos completados reales de un profesional. Fuente única para app, web y panel. |
| `stats_profesionales` | p_ids uuid[] | TABLE(id_usuario uuid, calificacion numeric, n_calificaciones integer, trabajos_completados integer, es_elite boolean) | SECURITY INVOKER | Función interna, disparador o tarea de servicio. |
| `texto_a_timestamptz` | p_valor text | timestamp with time zone | SECURITY INVOKER | Interpreta un texto de fecha/hora como timestamptz (agenda y CU-33). |
| `texto_tiene_contacto` | p_texto text | boolean | SECURITY INVOKER | Detecta si un texto parece incluir teléfono o correo. También anon (validación de formularios). |
| `trabajador_horarios_desde_alta` | — | trigger | SECURITY DEFINER | Trigger de apoyo al crear la plantilla semanal en el alta. |
| `trabajador_horarios_normalizar` | — | trigger | SECURITY INVOKER | Trigger: normaliza día y horas al guardar un horario. |
| `trabajador_reservable` | p_trabajador uuid | boolean | SECURITY DEFINER | True si el profesional puede tomarse en la fecha consultada (horario y ocupación). |
| `trabajadores_marcar_pausa_por_trabajo` | — | trigger | SECURITY DEFINER | Trigger: enciende o apaga pausa_por_trabajo y disponible según los trabajos activos. |
| `trabajo_admite_disputa` | p_estado text | boolean | SECURITY INVOKER | True si el estado del trabajo permite abrir una disputa. |
| `trabajo_tiene_evidencia` | p_trabajo_id text | boolean | SECURITY DEFINER | True si el trabajo ya tiene evidencia cargada. |
| `trabajos_bloquear_en_curso_directo` | — | trigger | SECURITY INVOKER | Trigger: no se puede pasar a en_curso sin el flujo del PIN. |
| `trabajos_contar_completados` | — | trigger | SECURITY DEFINER | Trigger: mantiene trabajadores.trabajos_completados. |
| `trabajos_crear_pin_inicio` | — | trigger | SECURITY DEFINER | Trigger: genera el PIN al quedar el trabajo en un estado que lo requiere. |
| `trabajos_exigir_evidencia` | — | trigger | SECURITY INVOKER | Trigger: exige evidencia antes de ciertos cierres. |
| `trabajos_fecha_solo_por_rpc` | — | trigger | SECURITY INVOKER | Trigger CU-33: la fecha programada solo cambia por las RPC de reagendamiento. |
| `trabajos_horario_unico` | — | trigger | SECURITY DEFINER | Apoyo al índice único de un trabajo activo por profesional y minuto. |
| `trabajos_notificar_nuevo_pedido` | — | trigger | SECURITY DEFINER | Función interna, disparador o tarea de servicio. |
| `trabajos_restablecer_disponibilidad` | — | trigger | SECURITY DEFINER | Trigger: devuelve la disponibilidad del profesional al terminar o cancelar. |
| `trabajos_vencer_reprogramaciones` | — | trigger | SECURITY DEFINER | Marca como vencidas las propuestas de reagendamiento que ya no aplican (interno / al cambiar el trabajo). |
| `transicion_trabajo_permitida` | p_desde text, p_hacia text, p_modalidad text | boolean | SECURITY INVOKER | Valida si un cambio de estado es legal según el estado actual y la modalidad. |
| `transicionar_trabajo` | p_trabajo_id text, p_nuevo_estado text, p_pin text | trabajos | SECURITY DEFINER | Transición de estado. Iniciar (aceptado o en_camino -> en_curso) exige el PIN del cliente al profesional asignado. El admin no lo exige. Tras 5 PIN malos, 15 minutos de bloqueo. |
| `transiciones_trabajo_posibles` | p_desde text, p_modalidad text | text[] | SECURITY DEFINER | Lista los estados siguientes permitidos desde el estado y la modalidad actuales. |
| `ver_reputacion_cliente` | p_cliente uuid | TABLE(reputacion numeric, calificaciones integer, disputas integer) | SECURITY DEFINER | Devuelve la reputación pública de un cliente (promedio y conteo). |
| `vincular_trabajador_cotizacion` | p_trabajo_id text, p_trabajador_id text | trabajos | SECURITY DEFINER | Asocia un profesional a un trabajo que está en cotización. |
| `vincular_trabajador_solicitud` | p_trabajo_id text, p_trabajador_id text | trabajos | SECURITY DEFINER | Asocia un profesional a una solicitud de trabajo abierta. |

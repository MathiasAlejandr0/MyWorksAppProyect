# Diccionario de base de datos — My Works App

> Generado por `docs/_gen_diccionario_docx.py` desde `Fase 2/modelo_entidad_relacion.dbml`. No editar a mano: cambia el DBML y vuelve a generar.

| Campo | Valor |
|-------|-------|
| Proyecto | My Works App |
| Motor | PostgreSQL (Supabase), esquema `public` |
| Convención | Nombres en español, `snake_case` |
| Modelo fuente | Modelo lógico v2.3 · 43 tablas public · 2026-11-08 · alineado a la BD viva hasta 20261108000005. No ejecutar contra producción. |
| Tablas en el modelo | 43 |
| Relaciones (Ref) | 60 |

`perfiles.id` coincide con `auth.users.id` (Auth de Supabase, fuera de `public`).

## 1. Índice de tablas por grupo

| # | Grupo | Tabla | Columnas | Descripción |
|---|-------|-------|----------|-------------|
| 1 | identidad | `perfiles` | 9 | Identidad de app = auth.users.id. reputacion_cliente la actualiza el trigger al calificar al cliente. |
| 2 | identidad | `notificaciones` | 8 |  |
| 3 | identidad | `suscripciones` | 8 |  |
| 4 | identidad | `codigos_restablecimiento` | 7 |  |
| 5 | identidad | `consentimientos_usuario` | 7 |  |
| 6 | identidad | `bloqueos_usuario` | 4 |  |
| 7 | identidad | `reportes` | 7 |  |
| 8 | identidad | `eventos_abuso` | 8 |  |
| 9 | identidad | `acciones_pendientes` | 11 |  |
| 10 | identidad | `registros_error_app` | 10 |  |
| 11 | identidad | `eventos_analitica` | 6 |  |
| 12 | identidad | `banderas_funcionalidad` | 8 |  |
| 13 | territorio | `paises` | 3 | Hoy solo CL |
| 14 | territorio | `regiones` | 4 |  |
| 15 | territorio | `comunas` | 6 |  |
| 16 | catalogo_4nf | `trabajadores` | 28 | Ficha 1:1. Oferta 4NF en tablas hijas; JSON solo escritura. Agenda en trabajador_horarios (no sale en el REST del catálogo). |
| 17 | catalogo_4nf | `trabajador_precios` | 3 |  |
| 18 | catalogo_4nf | `trabajador_servicios_extra` | 6 |  |
| 19 | catalogo_4nf | `trabajador_servicios` | 2 |  |
| 20 | catalogo_4nf | `trabajador_horarios` | 3 | Plantilla semanal. Solo el dueño lee/escribe (RLS). El cliente usa RPC horarios_libres_profesional. |
| 21 | catalogo_4nf | `portafolio_trabajador` | 6 |  |
| 22 | catalogo_4nf | `impulsos` | 6 |  |
| 23 | catalogo_4nf | `servicios` | 10 |  |
| 24 | catalogo_4nf | `configuraciones_servicio` | 5 |  |
| 25 | pedido | `trabajos` | 20 |  |
| 26 | pedido | `mensajes` | 9 |  |
| 27 | pedido | `fotos_trabajo` | 6 |  |
| 28 | pedido | `calificaciones` | 9 | Fuente de trabajadores.calificacion (promedio ponderado) |
| 29 | pedido | `calificaciones_cliente` | 7 | Doble valoración: el profesional nota al cliente. 1:1 con el trabajo. Alimenta perfiles.reputacion_cliente. |
| 30 | pedido | `disputas` | 11 |  |
| 31 | pedido | `cancelaciones_trabajo` | 5 | Como máximo una cancelación por trabajo |
| 32 | pedido | `tickets_soporte` | 8 |  |
| 33 | pedido | `ubicacion_en_vivo` | 6 | GPS en vivo. 1:1 con el trabajo. |
| 34 | cobro | `propuestas_cotizacion` | 9 |  |
| 35 | cobro | `pagos` | 26 |  |
| 36 | cobro | `ordenes_cambio` | 11 |  |
| 37 | cobro | `liquidaciones` | 10 | Un pago → una liquidación |
| 38 | cobro | `metodos_pago_oneclick` | 12 | Tarjeta inscrita Oneclick. Solo service_role. |
| 39 | cobro | `app_config` | 3 | demo_modo, admin_requiere_aal2 |
| 40 | ranking | `ranking_config` | 16 | Una fila default. Pesos del listado. |
| 41 | ranking | `senales_resena` | 9 |  |
| 42 | ranking | `ranking_aprendizaje` | 6 |  |
| 43 | ranking | `eventos_ranking` | 6 |  |

## 2. Columnas por tabla

### 2.1 perfiles

Identidad de app = auth.users.id. reputacion_cliente la actualiza el trigger al calificar al cliente.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `uuid` | pk |  |
| `nombre` | `text` | not null, default: '' |  |
| `correo` | `text` |  |  |
| `rol` | `text` | not null, default: 'usuario' |  |
| `estado_cuenta` | `text` | not null, default: 'activo' |  |
| `ruta_foto_perfil` | `text` |  |  |
| `reputacion_cliente` | `numeric(3,2)` |  | Derivada: promedio de calificaciones_cliente |
| `calificaciones_cliente` | `integer` | not null, default: 0 |  |
| `creado_en` | `text` | not null |  |

### 2.2 notificaciones

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_usuario` | `uuid` | not null |  |
| `tipo` | `text` | not null |  |
| `titulo` | `text` | not null |  |
| `cuerpo` | `text` | not null |  |
| `id_relacionado` | `text` |  |  |
| `leido` | `integer` | not null, default: 0 |  |
| `creado_en` | `text` | not null |  |

### 2.3 suscripciones

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_usuario` | `uuid` | not null |  |
| `tipo_plan` | `text` | not null |  |
| `estado` | `text` | not null |  |
| `fecha_inicio` | `text` | not null |  |
| `fecha_fin` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

### 2.4 codigos_restablecimiento

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_usuario` | `uuid` | not null |  |
| `codigo` | `text` | not null |  |
| `correo` | `text` | not null |  |
| `expira_en` | `text` | not null |  |
| `usado` | `integer` | default: 0 |  |
| `creado_en` | `text` | not null |  |

### 2.5 consentimientos_usuario

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_usuario` | `uuid` | not null |  |
| `version_consentimiento` | `text` | not null |  |
| `aceptado` | `integer` | not null, default: 0 |  |
| `aceptado_en` | `text` | not null |  |
| `direccion_ip` | `text` |  |  |
| `agente_usuario` | `text` |  |  |

### 2.6 bloqueos_usuario

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_bloqueador` | `uuid` | not null |  |
| `id_bloqueado` | `uuid` | not null |  |
| `creado_en` | `text` | not null |  |

Índices: `(id_bloqueador, id_bloqueado) [unique]`

### 2.7 reportes

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_reportante` | `uuid` | not null |  |
| `id_usuario_reportado` | `uuid` | not null |  |
| `motivo` | `text` | not null |  |
| `descripcion` | `text` |  |  |
| `estado` | `text` | not null, default: 'pendiente' |  |
| `creado_en` | `text` | not null |  |

### 2.8 eventos_abuso

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_usuario` | `uuid` | not null |  |
| `tipo_abuso` | `text` | not null |  |
| `conteo` | `integer` | not null |  |
| `detectado_en` | `text` | not null |  |
| `accion_tomada` | `text` |  |  |
| `accion_tomada_en` | `text` |  |  |
| `resuelto` | `integer` | default: 0 |  |

### 2.9 acciones_pendientes

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_usuario` | `uuid` | not null |  |
| `tipo_accion` | `text` | not null |  |
| `tipo_entidad` | `text` | not null |  |
| `id_entidad` | `text` |  |  |
| `datos` | `text` | not null |  |
| `estado` | `text` | not null, default: 'pendiente_sync' |  |
| `conteo_reintentos` | `integer` | default: 0 |  |
| `mensaje_error` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

### 2.10 registros_error_app

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_usuario` | `uuid` |  |  |
| `tipo_error` | `text` | not null, default: 'error' |  |
| `mensaje` | `text` | not null |  |
| `traza_pila` | `text` |  |  |
| `metadatos` | `jsonb` |  |  |
| `estado` | `text` | not null, default: 'nuevo' |  |
| `version_app` | `text` |  |  |
| `plataforma` | `text` |  |  |
| `creado_en` | `text` | not null |  |

### 2.11 eventos_analitica

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `nombre_evento` | `text` | not null |  |
| `id_usuario` | `uuid` |  |  |
| `rol` | `text` |  |  |
| `marca_tiempo` | `text` | not null |  |
| `metadatos` | `text` |  |  |

### 2.12 banderas_funcionalidad

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `nombre_bandera` | `text` | not null |  |
| `habilitada` | `integer` | not null, default: 0 |  |
| `version_app` | `text` |  |  |
| `rol` | `text` |  |  |
| `id_usuario` | `uuid` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

### 2.13 paises

Hoy solo CL

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `nombre` | `text` | not null |  |
| `iso2` | `text` | not null, unique |  |

### 2.14 regiones

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_pais` | `text` | not null |  |
| `nombre` | `text` | not null |  |
| `codigo_oficial` | `text` |  |  |

### 2.15 comunas

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk | slug = trabajos.id_comuna |
| `id_region` | `text` | not null |  |
| `nombre` | `text` | not null |  |
| `latitud` | `double` |  |  |
| `longitud` | `double` |  |  |
| `activa` | `integer` | not null, default: 1 |  |

### 2.16 trabajadores

Ficha 1:1. Oferta 4NF en tablas hijas; JSON solo escritura. Agenda en trabajador_horarios (no sale en el REST del catálogo).

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_usuario` | `uuid` | pk |  |
| `profesion` | `text` | not null, default: '' |  |
| `descripcion` | `text` |  |  |
| `calificacion` | `numeric` | not null, default: 0 | Derivada: promedio ponderado |
| `disponible` | `integer` | not null, default: 1 |  |
| `tarifa_visita` | `numeric` | not null, default: 15000 |  |
| `categoria_servicio` | `text` | not null, default: 'general' |  |
| `niveles_precio` | `jsonb` | not null, default: '{}' | Escritura. 4NF: trabajador_precios |
| `servicios_personalizados` | `jsonb` | not null, default: '[]' | Escritura. 4NF: trabajador_servicios_extra |
| `precios_configurados` | `integer` | not null, default: 0 |  |
| `zona_trabajo` | `text` |  | Texto de UI; la FK es id_comuna / id_region |
| `conteo_rechazos` | `integer` | not null, default: 0 |  |
| `estado_verificacion` | `text` | not null, default: 'pendiente' |  |
| `nota_verificacion` | `text` |  |  |
| `latitud_base` | `double` |  |  |
| `longitud_base` | `double` |  |  |
| `radio_servicio_km` | `numeric` | not null, default: 15 |  |
| `origen_base` | `text` |  |  |
| `id_comuna` | `text` |  |  |
| `id_region` | `text` |  |  |
| `score_listado` | `numeric` | not null, default: 0 | Orden marketplace |
| `prioridad_manual` | `integer` | not null, default: 0 | Override admin -50..50 |
| `score_desglose` | `jsonb` | not null, default: '{}' |  |
| `ranking_actualizado_en` | `timestamptz` |  |  |
| `radio_urbano_km` | `numeric` | not null, default: 5 | Km alrededor de la base sin recargo |
| `tarifa_fuera_radio_clp` | `integer` | not null, default: 0 |  |
| `trabajos_completados` | `integer` | not null, default: 0 |  |
| `es_elite` | `boolean` |  | GENERATED STORED: calificacion ≥ 4.7 y trabajos_completados ≥ 5 |

### 2.17 trabajador_precios

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_usuario` | `uuid` | not null |  |
| `codigo` | `text` | not null |  |
| `monto_clp` | `numeric` | not null |  |

Índices: `(id_usuario, codigo) [pk]`

### 2.18 trabajador_servicios_extra

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | not null |  |
| `id_usuario` | `uuid` | not null |  |
| `titulo` | `text` | not null |  |
| `subtitulo` | `text` | not null, default: '' |  |
| `monto_clp` | `numeric` | not null |  |
| `unidad` | `text` | not null, default: 'fijo' |  |

Índices: `(id_usuario, id) [pk]`

### 2.19 trabajador_servicios

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_trabajador` | `uuid` | not null |  |
| `categoria_servicio` | `text` | not null |  |

Índices: `(id_trabajador, categoria_servicio) [pk]`

### 2.20 trabajador_horarios

Plantilla semanal. Solo el dueño lee/escribe (RLS). El cliente usa RPC horarios_libres_profesional.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_usuario` | `uuid` | pk |  |
| `horarios` | `jsonb` | not null, default: '[]' | [{dia:1-7 ISO, hora:HH:MM}, ...] |
| `actualizado_en` | `timestamptz` | not null |  |

### 2.21 portafolio_trabajador

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajador` | `uuid` | not null |  |
| `ruta_foto` | `text` | not null |  |
| `descripcion` | `text` |  |  |
| `tipo_medio` | `text` | default: 'foto' |  |
| `creado_en` | `text` | not null |  |

### 2.22 impulsos

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajador` | `uuid` | not null |  |
| `tipo_impulso` | `text` | not null |  |
| `fecha_inicio` | `text` | not null |  |
| `fecha_fin` | `text` | not null |  |
| `creado_en` | `text` | not null |  |

### 2.23 servicios

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `nombre` | `text` | not null |  |
| `descripcion` | `text` |  |  |
| `categoria` | `text` | not null, default: 'general' |  |
| `activo` | `integer` | not null, default: 1 |  |
| `requiere_certificacion` | `integer` | not null, default: 0 |  |
| `modelo_precio` | `text` | not null, default: 'por_hora' |  |
| `aviso_legal` | `text` |  |  |
| `creado_en` | `text` |  |  |
| `actualizado_en` | `text` |  |  |

### 2.24 configuraciones_servicio

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_servicio` | `text` | not null, unique |  |
| `esquema_config` | `text` | not null |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

### 2.25 trabajos

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_usuario` | `uuid` | not null |  |
| `id_trabajador` | `uuid` |  |  |
| `id_servicio` | `text` |  |  |
| `estado` | `text` | not null |  |
| `direccion` | `text` | not null, default: '' |  |
| `latitud` | `double` |  |  |
| `longitud` | `double` |  |  |
| `descripcion` | `text` |  |  |
| `fecha_programada` | `text` |  |  |
| `metadatos_servicio` | `text` |  |  |
| `modalidad_cobro` | `text` |  |  |
| `estado_pago` | `text` |  | Derivada: estado del pago principal |
| `id_comuna` | `text` |  |  |
| `instantanea_precio` | `text` |  |  |
| `id_sku_servicio` | `text` |  |  |
| `horas_bloque` | `integer` |  |  |
| `id_cotizacion_seleccionada` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

Índices: `(id_trabajador, fecha_programada) [unique, name: 'trabajos_trabajador_minuto_activo_uidx', note: 'Parcial: minuto UTC; excluye cancelado/expirado/completado/no_asistio']`

### 2.26 mensajes

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajo` | `text` | not null |  |
| `id_remitente` | `uuid` | not null |  |
| `id_destinatario` | `uuid` | not null |  |
| `contenido` | `text` | not null |  |
| `tipo` | `text` | not null, default: 'texto' |  |
| `ruta_imagen` | `text` |  |  |
| `leido` | `integer` | not null, default: 0 |  |
| `creado_en` | `text` | not null |  |

### 2.27 fotos_trabajo

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajo` | `text` | not null |  |
| `ruta_foto` | `text` | not null |  |
| `tipo_medio` | `text` | not null, default: 'foto' |  |
| `imagen_webp` | `bytea` |  |  |
| `creado_en` | `text` | not null |  |

### 2.28 calificaciones

Fuente de trabajadores.calificacion (promedio ponderado)

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajo` | `text` | not null |  |
| `id_usuario` | `uuid` |  |  |
| `puntaje` | `integer` | not null |  |
| `comentario` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `peso_confianza` | `numeric` | not null, default: 1 |  |
| `estado_revision` | `text` | not null, default: 'vigente' |  |
| `motivo_revision` | `text` |  |  |

### 2.29 calificaciones_cliente

Doble valoración: el profesional nota al cliente. 1:1 con el trabajo. Alimenta perfiles.reputacion_cliente.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajo` | `text` | not null, unique |  |
| `id_cliente` | `uuid` | not null |  |
| `id_trabajador` | `uuid` | not null |  |
| `puntaje` | `integer` | not null | 1..5 |
| `comentario` | `text` |  |  |
| `creado_en` | `timestamptz` | not null |  |

### 2.30 disputas

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajo` | `text` | not null |  |
| `abierta_por` | `uuid` | not null |  |
| `motivo` | `text` | not null |  |
| `descripcion` | `text` |  |  |
| `estado` | `text` | not null |  |
| `resolucion` | `text` |  |  |
| `resuelta_por` | `uuid` |  |  |
| `resuelta_en` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |

### 2.31 cancelaciones_trabajo

Como máximo una cancelación por trabajo

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajo` | `text` | not null, unique |  |
| `cancelado_por` | `uuid` | not null |  |
| `motivo` | `text` | not null |  |
| `cancelado_en` | `text` | not null |  |

### 2.32 tickets_soporte

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajo` | `text` |  |  |
| `nombre_cliente` | `text` | not null |  |
| `nombre_trabajador` | `text` | not null |  |
| `asunto` | `text` | not null |  |
| `monto_escrow` | `integer` | not null |  |
| `estado` | `text` | default: 'pendiente' |  |
| `creado_en` | `timestamptz` |  |  |

### 2.33 ubicacion_en_vivo

GPS en vivo. 1:1 con el trabajo.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_trabajo` | `text` | pk |  |
| `id_trabajador` | `uuid` | not null |  |
| `latitud` | `double` | not null |  |
| `longitud` | `double` | not null |  |
| `precision_metros` | `double` |  |  |
| `actualizado_en` | `timestamptz` | not null |  |

### 2.34 propuestas_cotizacion

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajo` | `text` | not null |  |
| `id_trabajador` | `uuid` | not null |  |
| `monto_total_clp` | `integer` | not null |  |
| `descripcion` | `text` | not null |  |
| `validez_hasta` | `text` |  |  |
| `desglose` | `text` |  |  |
| `estado` | `text` | not null |  |
| `creado_en` | `text` | not null |  |

### 2.35 pagos

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajo` | `text` | not null |  |
| `id_orden_cambio` | `text` |  |  |
| `tipo_pago` | `text` | not null, default: 'principal' |  |
| `monto` | `numeric` | not null |  |
| `moneda` | `text` | not null, default: 'CLP' |  |
| `estado` | `text` | not null |  |
| `metodo_pago` | `text` |  |  |
| `id_transaccion` | `text` |  |  |
| `autorizado_en` | `text` |  |  |
| `liberado_en` | `text` |  |  |
| `reembolsado_en` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `actualizado_en` | `text` | not null |  |
| `ambiente` | `text` |  |  |
| `token_tbk` | `text` |  | No sale al cliente |
| `url_tbk` | `text` |  | No sale al cliente |
| `buy_order` | `text` |  |  |
| `handoff_consumido_en` | `timestamptz` |  |  |
| `reembolso_solicitado_en` | `timestamptz` |  |  |
| `orden_detalle_oneclick` | `text` |  |  |
| `cobro_reclamado_en` | `timestamptz` |  |  |
| `origen_retorno` | `text` |  | Origen del navegador contrastado con la allowlist |
| `alta_nonce_hash` | `text` |  |  |
| `alta_jti` | `text` |  | Ticket de un solo uso para que el invitado cree su contraseña |
| `alta_consumido_en` | `timestamptz` |  |  |

Índices: `(id_trabajo) [unique, name: 'pagos_un_principal_activo_uidx', note: 'parcial: un principal vivo']`; `(alta_jti) [unique, name: 'pagos_alta_jti_uidx', note: 'parcial: alta_jti IS NOT NULL']`

### 2.36 ordenes_cambio

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajo` | `text` | not null |  |
| `id_trabajador` | `uuid` | not null |  |
| `tipo` | `text` | not null |  |
| `titulo` | `text` | not null |  |
| `descripcion` | `text` | not null |  |
| `monto_clp` | `integer` | not null |  |
| `estado` | `text` | not null, default: 'pendiente_cliente' |  |
| `id_pago` | `text` |  |  |
| `creado_en` | `text` | not null |  |
| `respondido_en` | `text` |  |  |

### 2.37 liquidaciones

Un pago → una liquidación

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_pago` | `text` | not null, unique |  |
| `id_trabajo` | `text` | not null |  |
| `id_trabajador` | `text` |  | text en la BD viva; no FK uuid |
| `monto_clp` | `numeric` | not null |  |
| `proveedor` | `text` | not null, default: 'manual' |  |
| `referencia_transferencia` | `text` | not null |  |
| `notas` | `text` |  |  |
| `id_operador` | `text` | not null |  |
| `creado_en` | `timestamptz` | not null |  |

### 2.38 metodos_pago_oneclick

Tarjeta inscrita Oneclick. Solo service_role.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id_usuario` | `text` | pk | auth.uid en text; sin FK a perfiles |
| `username` | `text` | not null |  |
| `tbk_user` | `text` |  | Solo service_role |
| `tipo_tarjeta` | `text` |  |  |
| `ultimos4` | `text` |  |  |
| `estado` | `text` | not null, default: 'pendiente' |  |
| `token_inscripcion` | `text` |  |  |
| `id_trabajo_pendiente` | `text` |  |  |
| `url_inscripcion` | `text` |  |  |
| `ticket_handoff` | `text` |  |  |
| `creado_en` | `timestamptz` | not null |  |
| `actualizado_en` | `timestamptz` | not null |  |

### 2.39 app_config

demo_modo, admin_requiere_aal2

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `clave` | `text` | pk |  |
| `valor` | `text` | not null |  |
| `actualizado_en` | `timestamptz` | not null |  |

### 2.40 ranking_config

Una fila default. Pesos del listado.

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk, default: 'default' |  |
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
| `pesos_senal` | `jsonb` | not null |  |
| `actualizado_en` | `timestamptz` | not null |  |

### 2.41 senales_resena

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_calificacion` | `text` | not null |  |
| `tipo_senal` | `text` | not null |  |
| `puntaje` | `numeric` | not null |  |
| `detalle` | `text` |  |  |
| `estado` | `text` | not null, default: 'pendiente' |  |
| `resuelto_por` | `uuid` |  |  |
| `resuelto_en` | `timestamptz` |  |  |
| `creado_en` | `timestamptz` | not null |  |

Índices: `(id_calificacion, tipo_senal) [unique]`

### 2.42 ranking_aprendizaje

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `motivo` | `text` | not null |  |
| `pesos_antes` | `jsonb` | not null |  |
| `pesos_despues` | `jsonb` | not null |  |
| `metricas` | `jsonb` |  |  |
| `creado_en` | `timestamptz` | not null |  |

### 2.43 eventos_ranking

| Columna | Tipo | Restricciones | Nota |
|---------|------|---------------|------|
| `id` | `text` | pk |  |
| `id_trabajador` | `uuid` | not null |  |
| `id_trabajo` | `text` |  |  |
| `tipo_evento` | `text` | not null |  |
| `factores` | `jsonb` | not null |  |
| `creado_en` | `timestamptz` | not null |  |

## 3. Relaciones

`>` muchos a uno · `-` uno a uno · `<` uno a muchos.

- `trabajadores.id_usuario - perfiles.id [delete: cascade]`
- `trabajadores.id_comuna > comunas.id [delete: set null]`
- `trabajadores.id_region > regiones.id [delete: set null]`
- `regiones.id_pais > paises.id`
- `comunas.id_region > regiones.id`
- `trabajador_precios.id_usuario > trabajadores.id_usuario [delete: cascade]`
- `trabajador_servicios_extra.id_usuario > trabajadores.id_usuario [delete: cascade]`
- `trabajador_servicios.id_trabajador > trabajadores.id_usuario [delete: cascade]`
- `trabajador_horarios.id_usuario - trabajadores.id_usuario [delete: cascade]`
- `portafolio_trabajador.id_trabajador > trabajadores.id_usuario [delete: cascade]`
- `impulsos.id_trabajador > trabajadores.id_usuario [delete: cascade]`
- `configuraciones_servicio.id_servicio - servicios.id [delete: cascade]`
- `trabajos.id_usuario > perfiles.id [delete: cascade]`
- `trabajos.id_trabajador > trabajadores.id_usuario [delete: set null]`
- `trabajos.id_servicio > servicios.id [delete: set null]`
- `trabajos.id_comuna > comunas.id [delete: set null]`
- `trabajos.id_cotizacion_seleccionada > propuestas_cotizacion.id`
- `propuestas_cotizacion.id_trabajo > trabajos.id [delete: cascade]`
- `propuestas_cotizacion.id_trabajador > trabajadores.id_usuario [delete: cascade]`
- `pagos.id_trabajo > trabajos.id [delete: cascade]`
- `pagos.id_orden_cambio > ordenes_cambio.id`
- `ordenes_cambio.id_trabajo > trabajos.id [delete: cascade]`
- `ordenes_cambio.id_trabajador > trabajadores.id_usuario`
- `ordenes_cambio.id_pago > pagos.id`
- `liquidaciones.id_pago - pagos.id`
- `liquidaciones.id_trabajo > trabajos.id`
- `mensajes.id_trabajo > trabajos.id [delete: cascade]`
- `mensajes.id_remitente > perfiles.id`
- `mensajes.id_destinatario > perfiles.id`
- `fotos_trabajo.id_trabajo > trabajos.id [delete: cascade]`
- `calificaciones.id_trabajo > trabajos.id [delete: cascade]`
- `calificaciones.id_usuario > perfiles.id`
- `calificaciones_cliente.id_trabajo - trabajos.id [delete: cascade]`
- `calificaciones_cliente.id_cliente > perfiles.id`
- `calificaciones_cliente.id_trabajador > trabajadores.id_usuario`
- `disputas.id_trabajo > trabajos.id [delete: cascade]`
- `disputas.abierta_por > perfiles.id`
- `disputas.resuelta_por > perfiles.id`
- `cancelaciones_trabajo.id_trabajo - trabajos.id [delete: cascade]`
- `cancelaciones_trabajo.cancelado_por > perfiles.id`
- `tickets_soporte.id_trabajo > trabajos.id`
- `ubicacion_en_vivo.id_trabajo - trabajos.id [delete: cascade]`
- `ubicacion_en_vivo.id_trabajador > trabajadores.id_usuario [delete: cascade]`
- `notificaciones.id_usuario > perfiles.id [delete: cascade]`
- `suscripciones.id_usuario > perfiles.id [delete: cascade]`
- `codigos_restablecimiento.id_usuario > perfiles.id`
- `consentimientos_usuario.id_usuario > perfiles.id [delete: cascade]`
- `bloqueos_usuario.id_bloqueador > perfiles.id`
- `bloqueos_usuario.id_bloqueado > perfiles.id`
- `reportes.id_reportante > perfiles.id`
- `reportes.id_usuario_reportado > perfiles.id`
- `eventos_abuso.id_usuario > perfiles.id [delete: cascade]`
- `acciones_pendientes.id_usuario > perfiles.id [delete: cascade]`
- `registros_error_app.id_usuario > perfiles.id`
- `eventos_analitica.id_usuario > perfiles.id`
- `banderas_funcionalidad.id_usuario > perfiles.id`
- `senales_resena.id_calificacion > calificaciones.id [delete: cascade]`
- `senales_resena.resuelto_por > perfiles.id`
- `eventos_ranking.id_trabajador > trabajadores.id_usuario`
- `eventos_ranking.id_trabajo > trabajos.id`

## 4. Dónde está el SQL

- Modelo lógico: `Fase 2/modelo_entidad_relacion.dbml` y `.sql`.
- Migraciones: `myworksapp_app/supabase/migrations/`.
- Detalle narrativo del modelo: `proyecto de titulo/Fase 2/MODELO_ENTIDAD_RELACION.md`.

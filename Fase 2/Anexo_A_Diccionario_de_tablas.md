# Anexo A. Diccionario de datos

A continuación se describe cada una de las 43 tablas del esquema public. Los atributos se listan con su tipo de dato y su restricción. PK indica la clave primaria y FK la clave foránea. perfiles.id coincide con el identificador de autenticación de Supabase (auth.users.id).

Fuente: elaboración propia a partir del modelo entidad-relación v2.3.

## Identidad y cuenta

### Tabla A-1. perfiles

Identidad de app = auth.users.id. reputacion_cliente la actualiza el trigger al calificar al cliente.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | uuid | PK, Obligatorio |
| `nombre` | text | Obligatorio |
| `correo` | text | Opcional |
| `rol` | text | Obligatorio |
| `estado_cuenta` | text | Obligatorio |
| `ruta_foto_perfil` | text | Opcional |
| `reputacion_cliente` | numeric(3,2) | Opcional. Derivada: promedio de calificaciones_cliente |
| `calificaciones_cliente` | integer | Obligatorio |
| `creado_en` | text | Obligatorio |

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
| `leido` | integer | Obligatorio |
| `creado_en` | text | Obligatorio |

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

### Tabla A-4. codigos_restablecimiento

Código temporal para restablecer la contraseña.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `codigo` | text | Obligatorio |
| `correo` | text | Obligatorio |
| `expira_en` | text | Obligatorio |
| `usado` | integer | Opcional |
| `creado_en` | text | Obligatorio |

### Tabla A-5. consentimientos_usuario

Registro de aceptación de una versión de consentimiento.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `version_consentimiento` | text | Obligatorio |
| `aceptado` | integer | Obligatorio |
| `aceptado_en` | text | Obligatorio |
| `direccion_ip` | text | Opcional |
| `agente_usuario` | text | Opcional |

### Tabla A-6. bloqueos_usuario

Bloqueo de un usuario hacia otro.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_bloqueador` | uuid | FK → perfiles.id, Obligatorio |
| `id_bloqueado` | uuid | FK → perfiles.id, Obligatorio |
| `creado_en` | text | Obligatorio |

### Tabla A-7. reportes

Denuncia de un usuario contra otro.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_reportante` | uuid | FK → perfiles.id, Obligatorio |
| `id_usuario_reportado` | uuid | FK → perfiles.id, Obligatorio |
| `motivo` | text | Obligatorio |
| `descripcion` | text | Opcional |
| `estado` | text | Obligatorio |
| `creado_en` | text | Obligatorio |

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
| `resuelto` | integer | Opcional |

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
| `estado` | text | Obligatorio |
| `conteo_reintentos` | integer | Opcional |
| `mensaje_error` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

### Tabla A-10. registros_error_app

Error de la aplicación informado por un cliente.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Opcional |
| `tipo_error` | text | Obligatorio |
| `mensaje` | text | Obligatorio |
| `traza_pila` | text | Opcional |
| `metadatos` | jsonb | Opcional |
| `estado` | text | Obligatorio |
| `version_app` | text | Opcional |
| `plataforma` | text | Opcional |
| `creado_en` | text | Obligatorio |

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

### Tabla A-12. banderas_funcionalidad

Interruptor de una función por versión, rol o usuario.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `nombre_bandera` | text | Obligatorio |
| `habilitada` | integer | Obligatorio |
| `version_app` | text | Opcional |
| `rol` | text | Opcional |
| `id_usuario` | uuid | FK → perfiles.id, Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

## Territorio

### Tabla A-13. paises

Hoy solo CL

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `nombre` | text | Obligatorio |
| `iso2` | text | Obligatorio, Único |

### Tabla A-14. regiones

Región administrativa de un país.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_pais` | text | FK → paises.id, Obligatorio |
| `nombre` | text | Obligatorio |
| `codigo_oficial` | text | Opcional |

### Tabla A-15. comunas

Comuna de cobertura. Su identificador es el slug usado por trabajos y trabajadores.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio. slug = trabajos.id_comuna |
| `id_region` | text | FK → regiones.id, Obligatorio |
| `nombre` | text | Obligatorio |
| `latitud` | double | Opcional |
| `longitud` | double | Opcional |
| `activa` | integer | Obligatorio |

## Catálogo del profesional

### Tabla A-16. trabajadores

Ficha 1:1. Oferta 4NF en tablas hijas; JSON solo escritura. Agenda en trabajador_horarios (no sale en el REST del catálogo).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_usuario` | uuid | PK, FK → perfiles.id, Obligatorio |
| `profesion` | text | Obligatorio |
| `descripcion` | text | Opcional |
| `calificacion` | numeric | Obligatorio. Derivada: promedio ponderado |
| `disponible` | integer | Obligatorio |
| `tarifa_visita` | numeric | Obligatorio |
| `categoria_servicio` | text | Obligatorio |
| `niveles_precio` | jsonb | Obligatorio. Escritura. 4NF: trabajador_precios |
| `servicios_personalizados` | jsonb | Obligatorio. Escritura. 4NF: trabajador_servicios_extra |
| `precios_configurados` | integer | Obligatorio |
| `zona_trabajo` | text | Opcional. Texto de UI; la FK es id_comuna / id_region |
| `conteo_rechazos` | integer | Obligatorio |
| `estado_verificacion` | text | Obligatorio |
| `nota_verificacion` | text | Opcional |
| `latitud_base` | double | Opcional |
| `longitud_base` | double | Opcional |
| `radio_servicio_km` | numeric | Obligatorio |
| `origen_base` | text | Opcional |
| `id_comuna` | text | FK → comunas.id, Opcional |
| `id_region` | text | FK → regiones.id, Opcional |
| `score_listado` | numeric | Obligatorio. Orden marketplace |
| `prioridad_manual` | integer | Obligatorio. Override admin -50..50 |
| `score_desglose` | jsonb | Obligatorio |
| `ranking_actualizado_en` | timestamptz | Opcional |
| `radio_urbano_km` | numeric | Obligatorio. Km alrededor de la base sin recargo |
| `tarifa_fuera_radio_clp` | integer | Obligatorio |
| `trabajos_completados` | integer | Obligatorio |
| `es_elite` | boolean | Opcional. GENERATED STORED: calificacion ≥ 4.7 y trabajos_completados ≥ 5 |

### Tabla A-17. trabajador_precios

4NF: un monto por código de tarifa

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_usuario` | uuid | PK, FK → trabajadores.id_usuario, Obligatorio |
| `codigo` | text | PK, Obligatorio |
| `monto_clp` | numeric | Obligatorio |

### Tabla A-18. trabajador_servicios_extra

4NF: extras tarifados (fijo | por_m2)

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | PK, FK → trabajadores.id_usuario, Obligatorio |
| `titulo` | text | Obligatorio |
| `subtitulo` | text | Obligatorio |
| `monto_clp` | numeric | Obligatorio |
| `unidad` | text | Obligatorio |

### Tabla A-19. trabajador_servicios

N:M por slug categoria, no por servicios.id

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_trabajador` | uuid | PK, FK → trabajadores.id_usuario, Obligatorio |
| `categoria_servicio` | text | PK, Obligatorio |

### Tabla A-20. trabajador_horarios

Plantilla semanal. Solo el dueño lee/escribe (RLS). El cliente usa RPC horarios_libres_profesional.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_usuario` | uuid | PK, FK → trabajadores.id_usuario, Obligatorio |
| `horarios` | jsonb | Obligatorio. [{dia:1-7 ISO, hora:HH:MM}, ...] |
| `actualizado_en` | timestamptz | Obligatorio |

### Tabla A-21. portafolio_trabajador

Foto o medio del portafolio de un profesional.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajador` | uuid | FK → trabajadores.id_usuario, Obligatorio |
| `ruta_foto` | text | Obligatorio |
| `descripcion` | text | Opcional |
| `tipo_medio` | text | Opcional |
| `creado_en` | text | Obligatorio |

### Tabla A-22. impulsos

Promoción temporal de visibilidad de un profesional.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajador` | uuid | FK → trabajadores.id_usuario, Obligatorio |
| `tipo_impulso` | text | Obligatorio |
| `fecha_inicio` | text | Obligatorio |
| `fecha_fin` | text | Obligatorio |
| `creado_en` | text | Obligatorio |

### Tabla A-23. servicios

Catálogo de oficios que la plataforma ofrece.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `nombre` | text | Obligatorio |
| `descripcion` | text | Opcional |
| `categoria` | text | Obligatorio |
| `activo` | integer | Obligatorio |
| `requiere_certificacion` | integer | Obligatorio |
| `modelo_precio` | text | Obligatorio |
| `aviso_legal` | text | Opcional |
| `creado_en` | text | Opcional |
| `actualizado_en` | text | Opcional |

### Tabla A-24. configuraciones_servicio

Esquema de configuración asociado a un servicio.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_servicio` | text | FK → servicios.id, Obligatorio, Único |
| `esquema_config` | text | Obligatorio |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

## Pedido y servicio

### Tabla A-25. trabajos

Pedido. Un minuto activo por profesional (índice parcial; en vivo usa minuto_utc()).

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Obligatorio |
| `id_trabajador` | uuid | FK → trabajadores.id_usuario, Opcional |
| `id_servicio` | text | FK → servicios.id, Opcional |
| `estado` | text | Obligatorio |
| `direccion` | text | Obligatorio |
| `latitud` | double | Opcional |
| `longitud` | double | Opcional |
| `descripcion` | text | Opcional |
| `fecha_programada` | text | Opcional |
| `metadatos_servicio` | text | Opcional |
| `modalidad_cobro` | text | Opcional |
| `estado_pago` | text | Opcional. Derivada: estado del pago principal |
| `id_comuna` | text | FK → comunas.id, Opcional |
| `instantanea_precio` | text | Opcional |
| `id_sku_servicio` | text | Opcional |
| `horas_bloque` | integer | Opcional |
| `id_cotizacion_seleccionada` | text | FK → propuestas_cotizacion.id, Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |

### Tabla A-26. mensajes

Mensaje del chat de un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_remitente` | uuid | FK → perfiles.id, Obligatorio |
| `id_destinatario` | uuid | FK → perfiles.id, Obligatorio |
| `contenido` | text | Obligatorio |
| `tipo` | text | Obligatorio |
| `ruta_imagen` | text | Opcional |
| `leido` | integer | Obligatorio |
| `creado_en` | text | Obligatorio |

### Tabla A-27. fotos_trabajo

Evidencia fotográfica o de video de un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `ruta_foto` | text | Obligatorio |
| `tipo_medio` | text | Obligatorio |
| `imagen_webp` | bytea | Opcional |
| `creado_en` | text | Obligatorio |

### Tabla A-28. calificaciones

Fuente de trabajadores.calificacion (promedio ponderado)

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_usuario` | uuid | FK → perfiles.id, Opcional |
| `puntaje` | integer | Obligatorio |
| `comentario` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `peso_confianza` | numeric | Obligatorio |
| `estado_revision` | text | Obligatorio |
| `motivo_revision` | text | Opcional |

### Tabla A-29. calificaciones_cliente

Doble valoración: el profesional nota al cliente. 1:1 con el trabajo. Alimenta perfiles.reputacion_cliente.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio, Único |
| `id_cliente` | uuid | FK → perfiles.id, Obligatorio |
| `id_trabajador` | uuid | FK → trabajadores.id_usuario, Obligatorio |
| `puntaje` | integer | Obligatorio. 1..5 |
| `comentario` | text | Opcional |
| `creado_en` | timestamptz | Obligatorio |

### Tabla A-30. disputas

Disputa abierta sobre un trabajo y su resolución.

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

### Tabla A-31. cancelaciones_trabajo

Como máximo una cancelación por trabajo

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio, Único |
| `cancelado_por` | uuid | FK → perfiles.id, Obligatorio |
| `motivo` | text | Obligatorio |
| `cancelado_en` | text | Obligatorio |

### Tabla A-32. tickets_soporte

Ticket de soporte asociado a un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Opcional |
| `nombre_cliente` | text | Obligatorio |
| `nombre_trabajador` | text | Obligatorio |
| `asunto` | text | Obligatorio |
| `monto_escrow` | integer | Obligatorio |
| `estado` | text | Opcional |
| `creado_en` | timestamptz | Opcional |

### Tabla A-33. ubicacion_en_vivo

GPS en vivo. 1:1 con el trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_trabajo` | text | PK, FK → trabajos.id, Obligatorio |
| `id_trabajador` | uuid | FK → trabajadores.id_usuario, Obligatorio |
| `latitud` | double | Obligatorio |
| `longitud` | double | Obligatorio |
| `precision_metros` | double | Opcional |
| `actualizado_en` | timestamptz | Obligatorio |

## Cobro

### Tabla A-34. propuestas_cotizacion

Cotización que un profesional envía para un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_trabajador` | uuid | FK → trabajadores.id_usuario, Obligatorio |
| `monto_total_clp` | integer | Obligatorio |
| `descripcion` | text | Obligatorio |
| `validez_hasta` | text | Opcional |
| `desglose` | text | Opcional |
| `estado` | text | Obligatorio |
| `creado_en` | text | Obligatorio |

### Tabla A-35. pagos

Escrow. Un principal vivo por trabajo (índice único parcial). origen_retorno lo escribe el service role.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_orden_cambio` | text | FK → ordenes_cambio.id, Opcional |
| `tipo_pago` | text | Obligatorio |
| `monto` | numeric | Obligatorio |
| `moneda` | text | Obligatorio |
| `estado` | text | Obligatorio |
| `metodo_pago` | text | Opcional |
| `id_transaccion` | text | Opcional |
| `autorizado_en` | text | Opcional |
| `liberado_en` | text | Opcional |
| `reembolsado_en` | text | Opcional |
| `creado_en` | text | Obligatorio |
| `actualizado_en` | text | Obligatorio |
| `ambiente` | text | Opcional |
| `token_tbk` | text | Opcional. No sale al cliente |
| `url_tbk` | text | Opcional. No sale al cliente |
| `buy_order` | text | Opcional |
| `handoff_consumido_en` | timestamptz | Opcional |
| `reembolso_solicitado_en` | timestamptz | Opcional |
| `orden_detalle_oneclick` | text | Opcional |
| `cobro_reclamado_en` | timestamptz | Opcional |
| `origen_retorno` | text | Opcional. Origen del navegador contrastado con la allowlist |
| `alta_nonce_hash` | text | Opcional |
| `alta_jti` | text | Opcional. Ticket de un solo uso para que el invitado cree su contraseña |
| `alta_consumido_en` | timestamptz | Opcional |

### Tabla A-36. ordenes_cambio

Cambio de alcance o de precio durante un trabajo.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_trabajador` | uuid | FK → trabajadores.id_usuario, Obligatorio |
| `tipo` | text | Obligatorio |
| `titulo` | text | Obligatorio |
| `descripcion` | text | Obligatorio |
| `monto_clp` | integer | Obligatorio |
| `estado` | text | Obligatorio |
| `id_pago` | text | FK → pagos.id, Opcional |
| `creado_en` | text | Obligatorio |
| `respondido_en` | text | Opcional |

### Tabla A-37. liquidaciones

Un pago → una liquidación

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_pago` | text | FK → pagos.id, Obligatorio, Único |
| `id_trabajo` | text | FK → trabajos.id, Obligatorio |
| `id_trabajador` | text | Opcional. text en la BD viva; no FK uuid |
| `monto_clp` | numeric | Obligatorio |
| `proveedor` | text | Obligatorio |
| `referencia_transferencia` | text | Obligatorio |
| `notas` | text | Opcional |
| `id_operador` | text | Obligatorio |
| `creado_en` | timestamptz | Obligatorio |

### Tabla A-38. metodos_pago_oneclick

Tarjeta inscrita Oneclick. Solo service_role.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id_usuario` | text | PK, Obligatorio. auth.uid en text; sin FK a perfiles |
| `username` | text | Obligatorio |
| `tbk_user` | text | Opcional. Solo service_role |
| `tipo_tarjeta` | text | Opcional |
| `ultimos4` | text | Opcional |
| `estado` | text | Obligatorio |
| `token_inscripcion` | text | Opcional |
| `id_trabajo_pendiente` | text | Opcional |
| `url_inscripcion` | text | Opcional |
| `ticket_handoff` | text | Opcional |
| `creado_en` | timestamptz | Obligatorio |
| `actualizado_en` | timestamptz | Obligatorio |

### Tabla A-39. app_config

demo_modo, admin_requiere_aal2

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `clave` | text | PK, Obligatorio |
| `valor` | text | Obligatorio |
| `actualizado_en` | timestamptz | Obligatorio |

## Ranking y reputación

### Tabla A-40. ranking_config

Una fila default. Pesos del listado.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `peso_calificacion` | numeric | Obligatorio |
| `peso_completados` | numeric | Obligatorio |
| `peso_rechazos` | numeric | Obligatorio |
| `peso_verificacion` | numeric | Obligatorio |
| `peso_impulso` | numeric | Obligatorio |
| `peso_recencia` | numeric | Obligatorio |
| `peso_confianza` | numeric | Obligatorio |
| `prior_bayes` | numeric | Obligatorio |
| `n_bayes` | numeric | Obligatorio |
| `umbral_revision` | numeric | Obligatorio |
| `umbral_auto_excluir` | numeric | Obligatorio |
| `aprendizaje_activo` | integer | Obligatorio |
| `tasa_aprendizaje` | numeric | Obligatorio |
| `pesos_senal` | jsonb | Obligatorio |
| `actualizado_en` | timestamptz | Obligatorio |

### Tabla A-41. senales_resena

Cola de reseñas dudosas. Falso positivo baja el peso de la señal.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_calificacion` | text | FK → calificaciones.id, Obligatorio |
| `tipo_senal` | text | Obligatorio |
| `puntaje` | numeric | Obligatorio |
| `detalle` | text | Opcional |
| `estado` | text | Obligatorio |
| `resuelto_por` | uuid | FK → perfiles.id, Opcional |
| `resuelto_en` | timestamptz | Opcional |
| `creado_en` | timestamptz | Obligatorio |

### Tabla A-42. ranking_aprendizaje

Ajuste de los pesos del ranking y las métricas de ese cambio.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `motivo` | text | Obligatorio |
| `pesos_antes` | jsonb | Obligatorio |
| `pesos_despues` | jsonb | Obligatorio |
| `metricas` | jsonb | Opcional |
| `creado_en` | timestamptz | Obligatorio |

### Tabla A-43. eventos_ranking

Evento que alimenta el ranking de un profesional.

| Atributo | Tipo de dato | Restricción |
|----------|--------------|-------------|
| `id` | text | PK, Obligatorio |
| `id_trabajador` | uuid | FK → trabajadores.id_usuario, Obligatorio |
| `id_trabajo` | text | FK → trabajos.id, Opcional |
| `tipo_evento` | text | Obligatorio |
| `factores` | jsonb | Obligatorio |
| `creado_en` | timestamptz | Obligatorio |

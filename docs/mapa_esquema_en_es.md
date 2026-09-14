# Mapa esquema EN → ES (MyWorksApp)

Fuente: modelos Dart + repositorios (dump OpenAPI remoto requiere service_role; no disponible con anon key).
Proyecto Supabase: `wxqrfcqifkfgawrnqmnj`
Fecha inventario: 2026-09-13

## Tablas

| EN | ES |
|----|-----|
| profiles | perfiles |
| workers | trabajadores |
| services | servicios |
| jobs | trabajos |
| payments | pagos |
| messages | mensajes |
| disputes | disputas |
| notifications | notificaciones |
| ratings | calificaciones |
| reports | reportes |
| quote_proposals | propuestas_cotizacion |
| change_orders | ordenes_cambio |
| job_photos | fotos_trabajo |
| worker_portfolio | portafolio_trabajador |
| worker_services | trabajador_servicios |
| job_cancellations | cancelaciones_trabajo |
| app_error_logs | registros_error_app |
| abuse_events | eventos_abuso |
| pending_actions | acciones_pendientes |
| user_blocks | bloqueos_usuario |
| user_consents | consentimientos_usuario |
| feature_flags | banderas_funcionalidad |
| subscriptions | suscripciones |
| boosts | impulsos |
| analytics_events | eventos_analitica |
| service_configs | configuraciones_servicio |

## Columnas comunes

| EN | ES |
|----|-----|
| id | id |
| userId | id_usuario |
| workerId | id_trabajador |
| serviceId | id_servicio |
| jobId | id_trabajo |
| createdAt | creado_en |
| updatedAt | actualizado_en |
| status | estado |
| description | descripcion |
| name | nombre |
| email | correo |
| role | rol |
| accountStatus | estado_cuenta |
| profilePhotoPath | ruta_foto_perfil |
| password | (eliminar / no migrar a uso) |

## perfiles

| EN | ES |
|----|-----|
| name | nombre |
| email | correo |
| role | rol |
| accountStatus | estado_cuenta |
| profilePhotoPath | ruta_foto_perfil |
| createdAt | creado_en |

## trabajadores

| EN | ES |
|----|-----|
| userId | id_usuario |
| profession | profesion |
| description | descripcion |
| rating | calificacion |
| isAvailable | disponible |
| visitFee | tarifa_visita |
| serviceCategory | categoria_servicio |
| pricingTiers | niveles_precio |
| customServices | servicios_personalizados |
| pricingConfigured | precios_configurados |
| workZone | zona_trabajo |
| rejectionCount | conteo_rechazos |

## servicios

| EN | ES |
|----|-----|
| name | nombre |
| description | descripcion |
| category | categoria |
| isActive | activo |
| requiresCertification | requiere_certificacion |
| pricingModel | modelo_precio |
| legalDisclaimer | aviso_legal |
| createdAt | creado_en |
| updatedAt | actualizado_en |

## trabajos

| EN | ES |
|----|-----|
| userId | id_usuario |
| workerId | id_trabajador |
| serviceId | id_servicio |
| status | estado |
| address | direccion |
| latitude | latitud |
| longitude | longitud |
| description | descripcion |
| scheduledDate | fecha_programada |
| serviceMetadata | metadatos_servicio |
| pricingMode | modalidad_cobro |
| paymentStatus | estado_pago |
| comunaId | id_comuna |
| pricingSnapshot | instantanea_precio |
| serviceSkuId | id_sku_servicio |
| hourlyBlockHours | horas_bloque |
| selectedQuoteId | id_cotizacion_seleccionada |
| createdAt | creado_en |
| updatedAt | actualizado_en |

## pagos

| EN | ES |
|----|-----|
| jobId | id_trabajo |
| changeOrderId | id_orden_cambio |
| paymentType | tipo_pago |
| amount | monto |
| currency | moneda |
| status | estado |
| paymentMethod | metodo_pago |
| transactionId | id_transaccion |
| authorizedAt | autorizado_en |
| releasedAt | liberado_en |
| refundedAt | reembolsado_en |
| createdAt | creado_en |
| updatedAt | actualizado_en |

## mensajes

| EN | ES |
|----|-----|
| jobId | id_trabajo |
| senderId | id_remitente |
| receiverId | id_destinatario |
| content | contenido |
| type | tipo |
| imagePath | ruta_imagen |
| isRead | leido |
| createdAt | creado_en |

## disputas

| EN | ES |
|----|-----|
| jobId | id_trabajo |
| openedBy | abierta_por |
| reason | motivo |
| description | descripcion |
| status | estado |
| resolution | resolucion |
| resolvedBy | resuelta_por |
| resolvedAt | resuelta_en |
| createdAt | creado_en |
| updatedAt | actualizado_en |

## notificaciones

| EN | ES |
|----|-----|
| userId | id_usuario |
| type | tipo |
| title | titulo |
| body | cuerpo |
| relatedId | id_relacionado |
| isRead | leido |
| createdAt | creado_en |

## calificaciones

| EN | ES |
|----|-----|
| jobId | id_trabajo |
| userId | id_usuario |
| score | puntaje |
| comment | comentario |
| createdAt | creado_en |

## reportes

| EN | ES |
|----|-----|
| reporterId | id_reportante |
| reportedUserId | id_usuario_reportado |
| reason | motivo |
| description | descripcion |
| status | estado |
| createdAt | creado_en |

## propuestas_cotizacion

| EN | ES |
|----|-----|
| jobId | id_trabajo |
| workerId | id_trabajador |
| montoTotalClp | monto_total_clp |
| descripcion | descripcion |
| validezHasta | validez_hasta |
| desglose | desglose |
| estado | estado |
| createdAt | creado_en |

## ordenes_cambio

| EN | ES |
|----|-----|
| jobId | id_trabajo |
| workerId | id_trabajador |
| tipo | tipo |
| titulo | titulo |
| descripcion | descripcion |
| montoClp | monto_clp |
| estado | estado |
| paymentId | id_pago |
| createdAt | creado_en |
| respondedAt | respondido_en |

## fotos_trabajo / portafolio_trabajador

| EN | ES |
|----|-----|
| jobId / workerId | id_trabajo / id_trabajador |
| photoPath | ruta_foto |
| mediaType | tipo_medio |
| description | descripcion |
| createdAt | creado_en |

## trabajador_servicios

| EN | ES |
|----|-----|
| workerId | id_trabajador |
| serviceCategory | categoria_servicio |

## cancelaciones_trabajo

| EN | ES |
|----|-----|
| jobId | id_trabajo |
| cancelledBy | cancelado_por |
| reason | motivo |
| cancelledAt | cancelado_en |

## registros_error_app

| EN | ES |
|----|-----|
| userId | id_usuario |
| errorType | tipo_error |
| message | mensaje |
| stackTrace | traza_pila |
| metadata | metadatos |
| status | estado |
| appVersion | version_app |
| platform | plataforma |
| createdAt | creado_en |

## eventos_abuso

| EN | ES |
|----|-----|
| userId | id_usuario |
| abuseType | tipo_abuso |
| count | conteo |
| detectedAt | detectado_en |
| actionTaken | accion_tomada |
| actionTakenAt | accion_tomada_en |
| isResolved | resuelto |

## acciones_pendientes

| EN | ES |
|----|-----|
| userId | id_usuario |
| actionType | tipo_accion |
| entityType | tipo_entidad |
| entityId | id_entidad |
| data | datos |
| status | estado |
| retryCount | conteo_reintentos |
| errorMessage | mensaje_error |
| createdAt | creado_en |
| updatedAt | actualizado_en |

## bloqueos_usuario

| EN | ES |
|----|-----|
| blockerId | id_bloqueador |
| blockedUserId | id_bloqueado |
| createdAt | creado_en |

## consentimientos_usuario

| EN | ES |
|----|-----|
| userId | id_usuario |
| consentVersion | version_consentimiento |
| accepted | aceptado |
| acceptedAt | aceptado_en |
| ipAddress | direccion_ip |
| userAgent | agente_usuario |

## banderas_funcionalidad

| EN | ES |
|----|-----|
| flagName | nombre_bandera |
| isEnabled | habilitada |
| appVersion | version_app |
| role | rol |
| userId | id_usuario |
| createdAt | creado_en |
| updatedAt | actualizado_en |

## suscripciones

| EN | ES |
|----|-----|
| userId | id_usuario |
| planType | tipo_plan |
| status | estado |
| startDate | fecha_inicio |
| endDate | fecha_fin |
| createdAt | creado_en |
| updatedAt | actualizado_en |

## impulsos

| EN | ES |
|----|-----|
| workerId | id_trabajador |
| boostType | tipo_impulso |
| startDate | fecha_inicio |
| endDate | fecha_fin |
| createdAt | creado_en |

## eventos_analitica

| EN | ES |
|----|-----|
| eventName | nombre_evento |
| userId | id_usuario |
| role | rol |
| timestamp | marca_tiempo |
| metadata | metadatos |

## configuraciones_servicio

| EN | ES |
|----|-----|
| serviceId | id_servicio |
| configSchema | esquema_config |
| createdAt | creado_en |
| updatedAt | actualizado_en |

## Valores (códigos)

### Roles
| EN | ES |
|----|-----|
| user | usuario |
| worker | trabajador |
| admin | administrador |

### Estado cuenta
| EN | ES |
|----|-----|
| active | activo |
| suspended | suspendido |
| blocked | bloqueado |

### Estado trabajo
| EN | ES |
|----|-----|
| pending | pendiente |
| accepted | aceptado |
| in_progress | en_curso |
| completed | completado |
| cancelled | cancelado |
| expired | expirado |
| no_show | no_asistio |
| awaiting_payment | esperando_pago |
| awaiting_quotes | esperando_cotizaciones |
| quote_selected | cotizacion_seleccionada |
| paused_change_order | pausado_orden_cambio |
| awaiting_client_approval | esperando_aprobacion_cliente |

### Estado pago / modalidad
| EN | ES |
|----|-----|
| none | ninguno |
| pending | pendiente |
| authorized | autorizado |
| held | retenido |
| released | liberado |
| refunded | reembolsado |
| legacy | legado |
| fixed_price | precio_fijo |
| hourly_block | bloque_horas |
| open_quote | cotizacion_abierta |
| primary | principal |
| change_order | orden_cambio |
| overtime | horas_extra |

### Disputa
| EN | ES |
|----|-----|
| open | abierta |
| under_review | en_revision |
| resolved | resuelta |
| quality | calidad |
| payment | pago |
| behavior | conducta |
| other | otro |

### Categorías servicio
| EN | ES |
|----|-----|
| construction | construccion |
| plumbing | plomeria |
| electrical | electricidad |
| cleaning | limpieza |
| assembly | ensamblaje |
| tech_support | soporte_tecnico |
| gardening | jardinera |
| moving | mudanza |
| general | general |

### Otros
| EN | ES |
|----|-----|
| photo / video | foto / video |
| text / image | texto / imagen |
| hourly / fixed / per_item | por_hora / fijo / por_item |
| submitted / withdrawn / accepted / rejected | enviada / retirada / aceptada / rechazada |
| pending_client / approved / rejected / paid / cancelled | pendiente_cliente / aprobada / rechazada / pagada / cancelada |
| new / acknowledged / resolved / ignored | nuevo / reconocido / resuelto / ignorado |
| pending_sync / syncing / synced / failed | pendiente_sync / sincronizando / sincronizado / fallido |
| free / basic / premium / enterprise | gratuito / basico / premium / empresarial |
| active / cancelled / expired (sub) | activa / cancelada / expirada |
| visibility / priority / featured | visibilidad / prioridad / destacado |

## FK PostgREST

| EN | ES |
|----|-----|
| workers_userId_fkey | trabajadores_id_usuario_fkey |

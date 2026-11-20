# Inventario de migraciones

La base viva es `wxqrfcqifkfgawrnqmnj`. Cada versión de
`supabase_migrations.schema_migrations` tiene su archivo en
`supabase/migrations/` con el mismo número, y cada archivo tiene su fila en la
base. Hubo 115 versiones en los dos lados al verificarlo el 18-nov-2026. Al
20-nov-2026 (`main` `08154dfc`) el repositorio tiene 125 archivos `.sql`; las 10
migraciones posteriores están al final de la tabla y su estado en vivo se indica
según el reporte de despliegue del 20-nov (no se consultó `schema_migrations`).

Los archivos se ordenan por número. Para un entorno nuevo basta `supabase db push`.
Para una base que ya tiene el historial no hay nada que reparar.

## Versiones que vinieron del PR #55

Estas migraciones se aplicaron con la fecha en que Supabase las anotó. Sus
archivos llevan ese mismo número.

| Versión | Archivo |
|---------|---------|
| 20261115051320 | `asesor_acuerdos_search_path_fk` |
| 20261115051455 | `bucket_evidencias` |
| 20261115051501 | `pago_por_confirmar` |
| 20261115051507 | `calificacion_bidireccional` |
| 20261115051513 | `pagos_cuenta_bancaria` |
| 20261115051520 | `horarios_semanales` |
| 20261115051527 | `verificacion_eventos` |
| 20261115051532 | `evidencias_video_20mb` |
| 20261115052827 | `trabajador_horarios_pk_por_dia` |
| 20261115060002 | `cron_webpay_reconcile` (el job `mwa_webpay_reconcile` corre cada 5 minutos) |
| 20261115171533 | `usa_horario_select_authenticated` |

## Aplicadas en vivo el 15 y 16-nov-2026

| Versión | Archivo | Qué hace |
|---------|---------|----------|
| 20261115140001 | `minuto_utc_execute_authenticated.sql` | `EXECUTE` de `minuto_utc(text)` y `texto_a_timestamptz(text)` para `authenticated`. Sin esto un cliente con sesión no puede crear un pedido (42501). |
| 20261115140002 | `agenda_jsonb_tras_pk.sql` | `usa_horario` se puede actualizar. Guardar y leer la plantilla jsonb funciona con la PK en `id` y una fila por día. |
| 20261115180001 | `inicio_trabajo_requiere_pin.sql` | Iniciar (`aceptado`/`en_camino` → `en_curso`) exige el PIN del cliente por RPC, con 5 intentos y 15 minutos de bloqueo. |
| 20261115232852 | `disputas_solo_trabajos_activos.sql` | Un trabajo cerrado (completado, cancelado, expirado) no admite disputas ni acuerdos nuevos. |
| 20261115232858 | `disponibilidad_tras_trabajo.sql` | Columna `trabajadores.pausa_por_trabajo`; al terminar el último trabajo activo el profesional vuelve a `disponible = 1`. Backfill solo de la bandera. |
| 20261115232900 | `reprogramar_trabajo.sql` | Tabla `reprogramaciones_trabajo` y RPC `proponer_reprogramacion`, `responder_reprogramacion`, `retirar_reprogramacion`; notificación `job_rescheduled`; `fecha_programada` solo cambia por RPC. Sin filas nuevas. |
| 20261115232902 | `consola_roles_soporte_qa.sql` | Roles de consola `soporte` y `qa` con mínimo privilegio (`rol_consola`, `consola_disputas_abiertas`, `evidencia_disputa`, `soporte_comentar_disputa`, trigger `perfiles_rol_inicial_seguro`). Sin filas nuevas. |
| 20261115234447 | `catalogo_plomeria_gasfiteria_distintos.sql` | Renombra los servicios para distinguir «Plomería» de «Gasfitería (gas)». Solo actualiza nombres; sin filas nuevas. |
| 20261116042559 | `auditoria_bd_integridad.sql` | Auditoría BD 1/5: valores por defecto en español, 24 CHECK de dominio, 12 CHECK de banderas 0/1, función `es_marca_tiempo_iso` con 46 CHECK de fechas ISO, 34 FK nuevas (31 aquí, 3 al pasar `id_usuario` de texto a uuid), desactiva la comuna duplicada `santiago_centro` e índice único de comunas activas. Sin filas nuevas. |
| 20261116042604 | `notificar_nuevo_pedido.sql` | E2E 16-nov: trigger `trabajos_notificar_nuevo_pedido` en `trabajos`. Cuando un trabajo con profesional queda `pendiente` (sale de `esperando_pago` o se inserta así) crea la notificación `new_job` «Nuevo pedido» con el monto retenido; `send-push` la manda al teléfono. Idempotente por trabajo; un error del aviso nunca bloquea el cobro. Aplicada en producción el 16-nov-2026. |
| 20261116042629 | `auditoria_bd_seguridad.sql` | Auditoría BD 2/5: `protect_profile_sensitive_fields` pasa a INVOKER y protege la reputación del cliente; trigger `perfiles_reputacion_inicial_segura`; `impulsos` y `suscripciones` solo admin escribe; revoca TRUNCATE/TRIGGER/REFERENCES y escrituras de `anon`; `listar_trabajos_marketplace` exige profesional o admin; lectura admin de los bloqueos e intentos de PIN. |
| 20261116042759 | `auditoria_bd_rendimiento.sql` | Auditoría BD 3/5: `is_admin` compara uuid con uuid; 20 políticas sin `::text`; políticas FOR ALL separadas por comando en 9 tablas; 4 índices compuestos nuevos y 5 índices redundantes eliminados. |
| 20261116043033 | `auditoria_bd_indices_fk.sql` | Auditoría BD 4/5: 24 índices para FK sin índice (`idx_<tabla>_<columna>_fkey`). |
| 20261116043212 | `auditoria_bd_rls_initplan.sql` | Auditoría BD 5/5: envuelve `is_admin()` en `(SELECT is_admin())` en 42 políticas (se evalúa una vez por consulta). Idempotente. |
| 20261116044049 | `stats_profesional_fuente_unica.sql` | RPC `stats_profesional` / `stats_profesionales` como fuente única de la nota (promedio simple de reseñas reales) y de los trabajos completados. El catálogo las calcula en vivo. Recalcula las columnas cacheadas (sin inventar filas). El cálculo definer vive en el esquema `privado`; las RPC públicas son INVOKER. Aplicada en producción el 16-nov-2026 con OK de Mathias. |
| 20261116051051 | `cita_en_aviso_nuevo_pedido.sql` | El aviso de nuevo pedido incluye la cita acordada. |
| 20261116051054 | `encuestas_testing.sql` | Primera versión de la encuesta de testing (respuestas SUS en una lista). La reemplaza `20261117214622`. |

## Normalización del 17-nov-2026

| Versión | Archivo | Qué hace |
|---------|---------|----------|
| 20261117213633 | `eliminar_respaldos_20261115.sql` | Elimina los esquemas de respaldo `backup_20261115*`. |
| 20261117213644 | `respaldo_20261117_normalizacion.sql` | Copia previa de las tablas que cambian, en el esquema `backup_20261117` (sin acceso para `anon` ni `authenticated`). |
| 20261117214120 | `normalizar_categorias_servicio.sql` | Tabla `categorias_servicio` con PK y FK desde `servicios` y `trabajador_servicios`. |
| 20261117214219 | `normalizar_oferta_profesional.sql` | Precios, servicios propios y oficio del profesional solo en `trabajador_precios`, `trabajador_servicios_extra` y `trabajador_servicios`. Quita de `trabajadores` las columnas `niveles_precio`, `servicios_personalizados`, `categoria_servicio` e `id_region`, y el trigger de sincronización. |
| 20261117214336 | `normalizar_horarios_publicados.sql` | Siete ventanas por profesional en `trabajador_horarios` (`dia_semana`, `hora_inicio`, `hora_fin`) y las horas reservables en `trabajador_horas_publicadas`. RPC `guardar_horarios_propios`. |
| 20261117214418 | `normalizar_cotizacion_items.sql` | `propuesta_cotizacion_items` y `propuestas_cotizacion.horas_estimadas` en lugar del JSON `desglose`. |
| 20261117214528 | `normalizar_liquidaciones_uuid.sql` | `liquidaciones.id_trabajador` e `id_operador` pasan a uuid con FK a `perfiles`; `liberada_por_sistema` marca las liberaciones automáticas. |
| 20261117214622 | `normalizar_encuesta_respuestas.sql` | `encuesta_testing_respuestas`, función `sus_puntaje`, vista `encuestas_testing_con_puntaje` y RPC `enviar_encuesta_testing`. |
| 20261117223850 | `quitar_indice_duplicado_servicios.sql` | Quita `servicios_categoria_idx`, que repetía `idx_servicios_categoria`. |
| 20261118050658 | `invitacion_tarifa_visita.sql` | `monto_esperado_trabajo`: la opción `visita` de una invitación por tarifa cobra `trabajadores.tarifa_visita`; las demás variantes salen de `trabajador_precios` o `trabajador_servicios_extra`. |
| 20261118053913 | `cobros_profesional_neto.sql` | Función `comision_servicio_clp` (5 %, mínimo $1.000, nunca mayor que el pago) y vista `cobros_profesional` (security invoker) con bruto, comisión y neto por pago; en órdenes de cambio el neto es el monto de la orden. |
| 20261118230000 | `agenda_por_defecto_trabajador_nuevo.sql` | El alta del profesional publica de lunes a viernes de 09:00 a 17:00 en `trabajador_horas_publicadas`. Estado en vivo no verificado. |
| 20261118233000 | `reserva_respeta_ventanas.sql` | Un día con `activo = false` no se ofrece ni se reserva; dos citas en el mismo minuto siguen chocando. Estado en vivo no verificado. |
| 20261119163000 | `resumen_cobro_trabajo.sql` | `resumen_cobro_trabajo`: el mismo entero en CLP que acepta el cobro, con la coordenada real del profesional. Estado en vivo no verificado. |
| 20261119170000 | `contacto_antes_de_garantia.sql` | El pago principal se frena si la descripción o un mensaje traen datos de contacto (`pagos_exigir_sin_contacto`). |
| 20261120120000 | `contacto_preciso.sql` | Precisa `texto_tiene_contacto`: redes solo con usuario, enlace o @; un RUT, una medida o un monto no es teléfono. El reporte del 20-nov indica que la migración del filtro de contacto se aplicó en vivo. |
| 20261120130000 | `auditoria_consola.sql` | Tabla inmutable `auditoria_consola`, tipo `accion_auditoria_consola`, `registrar_auditoria()`, 17 RPC `consola_*` y nota obligatoria al rechazar una verificación. Aplicada en vivo (reporte del 20-nov; la prueba de la consola vio la tabla con datos). |
| 20261120140000 | `ocultar_profesionales_demo.sql` | Columna `es_demo` y filtros de catálogo, reserva y cobro para cuentas demo cuando `demo_modo` no es 1. Aplicada en vivo (reporte del 20-nov). |
| 20261120150000 | `rate_limit_global.sql` | Tabla `rate_limit_ventana` y `rate_limit_consumir` (solo `service_role`). Aplicada en vivo (reporte del 20-nov). |
| 20261120160000 | `perfil_publico_profesional.sql` | `perfil_publico_profesional`, `horario_publico_profesional` y `resenas_publicas_profesional`. Aplicada en vivo (reporte del 20-nov). |
| 20261120170000 | `derechos_y_cobro_extra.sql` | `exportar_mis_datos`, `solicitar_eliminacion_cuenta`, tabla `direcciones_cliente`, `monto_a_cobrar_orden_cambio` y `rechazar_orden_cambio`. Aplicada en vivo (reporte del 20-nov). |

## Dump del esquema

Archivo: [`schema_remote_dump.sql`](./schema_remote_dump.sql). Es una copia
anterior del esquema `public`; el esquema vigente está en
`docs/DICCIONARIO_BASE_DATOS.md` y en `docs/modelo-datos.md`.

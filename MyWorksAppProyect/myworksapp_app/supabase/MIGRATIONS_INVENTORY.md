# Inventario de migraciones

## Unificación con el PR #55 (2026-11-15)

La base viva es `wxqrfcqifkfgawrnqmnj`. Las migraciones del equipo hasta
`20261115000001_base_solo_dueno_y_demo_cerrado.sql` ya están aplicadas con
el mismo número de versión que el archivo.

El PR #55 del otro repo se aplicó encima, con versiones que Supabase anotó
al subirlas. Esos archivos, en este repo, se nombraron para ordenar
**después** de `20261115000001`. El SQL ya está en vivo: no hay que volver
a ejecutarlo. Antes de un `supabase db push` hay que marcar las versiones
locales que no coinciden con `schema_migrations`.

| Versión en este repo | Archivo | En vivo |
|----------------------|---------|---------|
| 20261115050001 | `asesor_acuerdos_search_path_fk` | Una de `20261115051320`–`20261115051532` |
| 20261115050002 | `bucket_evidencias` | Una de `20261115051320`–`20261115051532` |
| 20261115050003 | `pago_por_confirmar` | Una de `20261115051320`–`20261115051532` |
| 20261115050004 | `calificacion_bidireccional` | Una de `20261115051320`–`20261115051532` |
| 20261115050005 | `pagos_cuenta_bancaria` | Una de `20261115051320`–`20261115051532` |
| 20261115050006 | `horarios_semanales` | Una de `20261115051320`–`20261115051532` |
| 20261115050007 | `verificacion_eventos` | Una de `20261115051320`–`20261115051532` |
| 20261115050008 | `evidencias_video_20mb` | Una de `20261115051320`–`20261115051532` |
| 20261115052827 | `trabajador_horarios_pk_por_dia` | **La misma** `20261115052827`. No reparar. |
| 20261115060002 | `cron_webpay_reconcile` | El job `mwa_webpay_reconcile` corre cada 5 minutos. No hay fila en `schema_migrations`. |

Las ocho versiones remotas `20261115051320`–`20261115051532` se quedan en el
historial sin archivo de ese número. Son el mismo SQL, no una segunda copia
para correr.

```bash
supabase migration repair --status applied 20261115050001
supabase migration repair --status applied 20261115050002
supabase migration repair --status applied 20261115050003
supabase migration repair --status applied 20261115050004
supabase migration repair --status applied 20261115050005
supabase migration repair --status applied 20261115050006
supabase migration repair --status applied 20261115050007
supabase migration repair --status applied 20261115050008
supabase migration repair --status applied 20261115060002
```

## Aplicadas en vivo el 15-nov-2026

Verificado en `supabase_migrations.schema_migrations` del proyecto `wxqrfcqifkfgawrnqmnj` (las tres primeras figuraban antes como pendientes y ya están aplicadas).

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

## Snapshot CLI (2026-09-07)

Generado tras `npx supabase login` + `npx supabase link --project-ref wxqrfcqifkfgawrnqmnj`
y `npx supabase migration list` (2026-09-07).

## Local (en repo) sin marca remota

| Version | Archivo |
|---------|---------|
| 20250607000001 | hardening roles/profiles |
| 20250607000002 | fix is_admin RLS |
| 20250607000003 | revoke trigger execute |
| 20250819120000 | oauth profile names |
| 20250907120000 | schema baseline documented |

## Remoto (historial en Supabase) sin archivo local

Estas versiones existen en el proyecto remoto `wxqrfcqifkfgawrnqmnj` pero **no** están como `.sql` en este repo (se aplicaron fuera de git o se perdieron):

`20260608002641`, `20260608005805`, `20260608010157`, `20260608014121`, `20260608022226`, `20260608023535`, `20260608031838`, `20260608041437`, `20260608045812`, `20260608050536`, `20260608154349`, `20260608154638`, `20260608155420`, `20260608155910`, `20260608160410`, `20260608234142`, `20260610154519`, `20260610154705`, `20260610163326`, `20260610163655`, `20260610164532`, `20260610164622`, `20260610171103`, `20260819180559`

## Dump oficial (completado)

Archivo: [`schema_remote_dump.sql`](./schema_remote_dump.sql)  
Generado con Docker + `npx supabase db dump --schema public` (proyecto `wxqrfcqifkfgawrnqmnj`).

Contenido aproximado del schema `public`:
- **28 tablas**: `abuse_events`, `analytics_events`, `app_error_logs`, `boosts`, `change_orders`, `disputes`, `feature_flags`, `job_cancellations`, `job_photos`, `jobs`, `messages`, `notifications`, `password_reset_codes`, `payments`, `pending_actions`, `profiles`, `quote_proposals`, `ratings`, `reports`, `service_configs`, `services`, `subscriptions`, `tickets`, `user_blocks`, `user_consents`, `worker_portfolio`, `worker_services`, `workers`
- Funciones clave: `handle_new_user`, `is_admin`, …
- ~75 RLS policies

**Nota:** el historial de migraciones remoto sigue desalineado respecto a los `.sql` locales; el dump es la fuente de verdad del schema actual. `db pull` puede seguir fallando por ese conflicto; no es necesario si el dump está versionado.

Para regenerar:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\supabase-db-pull.ps1
```

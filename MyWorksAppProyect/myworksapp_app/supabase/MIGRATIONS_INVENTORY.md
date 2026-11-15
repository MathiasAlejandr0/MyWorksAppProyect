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

## Todavía no están en vivo

| Versión | Archivo | Qué hace |
|---------|---------|----------|
| 20261115140001 | `minuto_utc_execute_authenticated.sql` | `EXECUTE` de `minuto_utc(text)` y `texto_a_timestamptz(text)` para `authenticated`. Sin esto un cliente con sesión no puede crear un pedido (42501). |
| 20261115140002 | `agenda_jsonb_tras_pk.sql` | `usa_horario` se puede actualizar. Guardar y leer la plantilla jsonb funciona con la PK en `id` y una fila por día. |

Esas dos se aplican con `supabase db push` (o el SQL a mano). No usar `migration repair` sobre ellas.

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

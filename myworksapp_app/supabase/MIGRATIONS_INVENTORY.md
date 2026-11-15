# Inventario de migraciones (snapshot CLI)

## Aplicadas en vivo con otra versión

Los archivos `20261114000001` … `20261114000008` **ya están en** `wxqrfcqifkfgawrnqmnj`. Supabase los anotó en `schema_migrations` con versiones propias del rango `20261115051320` … `20261115051532`. El nombre del archivo coincide; el timestamp no. No se renombran otra vez.

Antes de cualquier `supabase db push` hay que alinear el historial, si no el CLI intenta aplicar de nuevo lo que ya está:

```bash
supabase migration repair --status applied 20261114000001
supabase migration repair --status applied 20261114000002
supabase migration repair --status applied 20261114000003
supabase migration repair --status applied 20261114000004
supabase migration repair --status applied 20261114000005
supabase migration repair --status applied 20261114000006
supabase migration repair --status applied 20261114000007
supabase migration repair --status applied 20261114000008
```

Eso marca las versiones locales como aplicadas. Las versiones remotas `20261115051320`–`20261115051532` no tienen archivo en este repo.

| Version en el repo | Archivo | Qué hace |
|---------|---------|----------|
| 20261114000001 | `migrations/20261114000001_asesor_acuerdos_search_path_fk.sql` | EXECUTE de acuerdos, `search_path` e índices de FK |
| 20261114000002 | `migrations/20261114000002_bucket_evidencias.sql` | Bucket privado `evidencias` |
| 20261114000003 | `migrations/20261114000003_pago_por_confirmar.sql` | `pagado_por_confirmar` y reembolso automático |
| 20261114000004 | `migrations/20261114000004_calificacion_bidireccional.sql` | Calificación en los dos sentidos |
| 20261114000005 | `migrations/20261114000005_pagos_cuenta_bancaria.sql` | Cuenta bancaria, estado de transferencia y RPC del admin |
| 20261114000006 | `migrations/20261114000006_horarios_semanales.sql` | `usa_horario` y columnas de horario, sin cambiar la PK vieja |
| 20261114000007 | `migrations/20261114000007_verificacion_eventos.sql` | Historial de verificación |
| 20261114000008 | `migrations/20261114000008_evidencias_video_20mb.sql` | Tope del bucket en 20 MB |

## Pendiente de aplicar en `wxqrfcqifkfgawrnqmnj`

| Version | Archivo | Qué hace |
|---------|---------|----------|
| 20261115060001 | `migrations/20261115060001_trabajador_horarios_pk_por_dia.sql` | PK de horarios pasa a `id`. Una fila por día. RLS sin políticas permisivas solapadas. **No aplicada.** |
| 20261115060002 | `migrations/20261115060002_cron_webpay_reconcile.sql` | Cron `mwa_webpay_reconcile` cada 5 minutos. No trae el valor del secreto. **No aplicada.** |

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
| 20261114000001 | asesor acuerdos, aplicada en vivo como versión del rango 20261115051320–051532 |

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

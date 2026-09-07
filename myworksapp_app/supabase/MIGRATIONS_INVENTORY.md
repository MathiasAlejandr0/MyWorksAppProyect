# Inventario de migraciones (snapshot CLI)

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

# Plan para alinear migraciones con producción (13 nov 2026)

Proyecto: `wxqrfcqifkfgawrnqmnj` (MyWorksApp Proyect). **Nada de esto se ha
aplicado.** Lo corre el dueño del proyecto, a mano, después de revisar el PR.

## Diagnóstico (auditoría 12 nov 2026, solo lectura)

- El historial remoto termina en `20261009000005`. Los archivos
  `20261005000001` … `20261008000008` (16) se aplicaron con otros números
  (`20260930020745` … `20260930054613`, 17 filas: hay un
  `security_lockdown_rpc_repo_sync` extra).
- De los 14 archivos posteriores, el schema real muestra:

| Archivo | Estado real en producción |
|---|---|
| 20261009000001_catalogo_geografico | **No aplicado** (0 de 16 objetos) |
| 20261010000001_ranking_y_resenas | Aplicado a mano salvo `_evaluar_resena_trigger` y su trigger. Ojo: la versión del repo de `evaluar_resena` compara `creado_en` (text) con `timestamptz` y **rompe toda calificación nueva**; producción tiene la versión corregida |
| 20261023000001 … 20261108000005 (10) | Aplicados a mano (`recargo_traslado_clp` quedó sin el tope de 30 km) |
| 20261109000001_demo_modo_catalogo | No aplicado. Forzaba `demo_modo = 1` (expone correos demo a anon). **Neutralizado en este PR** |
| 20261109000002_orden_cambio_webpay | **No aplicado** |
| 20261112000001_soporte_automatico | **No aplicado** (falta la Edge Function `soporte-automatico`) |

`20261113000001_reconciliar_deriva_produccion` (nuevo) copia a git las
funciones corregidas a mano, crea el trigger de reseñas sin que pueda bloquear
una calificación, y deja el tope de 30 km en `recargo_traslado_clp`
(producción no tiene trabajos a más de 30 km, revisado 12 nov).

## Validación hecha

Réplica local del schema de producción (PostgreSQL 17, exportado del catálogo
en solo lectura) + stub de `auth`/`storage`:

- Las 14 migraciones + la de reconciliación corren sin error y son idempotentes
  (se corrieron dos veces).
- Con la versión del repo de 20261010000001 una calificación falla
  (`operator does not exist: text > timestamp with time zone`); con
  20261113000001 la calificación entra, queda marcada (`cuenta_nueva
  texto_vacio_extremo`, peso 0.6) y el ranking se refresca.
- `demo_modo` queda en `0`.
- No se probó en un branch de Supabase (los branches tienen costo).

## Pasos (en orden)

0. Backup: Dashboard → Database → Backups (o `npx supabase db dump -f backup_pre_reconciliar.sql`).
1. Enlazar el CLI: `npx supabase link --project-ref wxqrfcqifkfgawrnqmnj`
2. Quitar del historial las 17 versiones con número viejo (no toca el schema):

```bash
npx supabase migration repair --status reverted \
  20260930020745 20260930021534 20260930024539 20260930024640 20260930024705 \
  20260930024747 20260930025325 20260930025500 20260930025755 20260930032429 \
  20260930041921 20260930041930 20260930041959 20260930051355 20260930051424 \
  20260930051804 20260930054613
```

3. Marcar como aplicadas las que ya están en el schema (no las ejecuta):

```bash
npx supabase migration repair --status applied \
  20261005000001 20261005000002 20261006000001 20261006000002 \
  20261007000001 20261007000002 20261007000003 20261007000004 \
  20261008000001 20261008000002 20261008000003 20261008000004 \
  20261008000005 20261008000006 20261008000007 20261008000008 \
  20261010000001 20261023000001 20261023000002 20261025000001 \
  20261101000001 20261108000001 20261108000002 20261108000003 \
  20261108000004 20261108000005
```

   **No** re-ejecutes 20261108000002 en producción: vuelve a crear la columna
   vieja de horarios y 20261108000005 la copiaría encima de
   `trabajador_horarios`.

4. Revisar que solo queden pendientes las que tocan:
   `npx supabase migration list` → pendientes: 20261009000001, 20261109000001,
   20261109000002, 20261112000001, 20261113000001 (y 20261113000002 si ya se
   mergeó el PR de ubicación aproximada).
5. Aplicar en este orden (`--include-all` porque 20261009000001 es anterior a
   versiones ya aplicadas):

```bash
npx supabase db push --include-all --dry-run   # revisar la lista
npx supabase db push --include-all
```

   Orden resultante: 20261009000001 → 20261109000001 → 20261109000002 →
   20261112000001 → 20261113000001 → 20261113000002.
6. Edge Functions: `npx supabase functions deploy soporte-automatico` y
   `npx supabase functions deploy webpay-create` (cambió con la orden de
   cambio por Webpay).
7. Revisar el job de pg_cron `mwa_resolver_soporte_automatico` (cada 10 min)
   en `cron.job` y correr los advisors de seguridad del Dashboard.
8. `npx supabase migration list` debe quedar sin diferencias. Actualizar
   `MIGRATIONS_INVENTORY.md`.

# Backup inventario esquema (inferido)

> **Documento histórico.** Registra el estado del proyecto a la fecha de su última revisión (20-09-2026) y no se actualiza. Las cifras, URL y pantallas que nombra pueden haber cambiado. El estado vigente (20-11-2026, `main` `08154dfc`) está en [`ESTADO_DEL_PROYECTO.md`](../ESTADO_DEL_PROYECTO.md).

Proyecto: MyWorksApp / wxqrfcqifkfgawrnqmnj  
Fecha: 2026-09-13  
Método: inferencia desde modelos Dart + repos (OpenAPI REST requiere service_role).

## Tablas en producción (uso app)

26 tablas listadas en `mapa_esquema_en_es.md`.

## Observaciones pre-migración

- Columnas en camelCase quoted en Postgres.
- Bools almacenados como int 0/1.
- Fechas como text ISO en inserts de app.
- Mezcla ES parcial en quote_proposals / change_orders.
- DDL CREATE TABLE no versionado en repo (solo 4 migraciones hardening).
- FK confirmada en código: workers.userId → profiles.id (workers_userId_fkey).

## Acción de backup recomendada

Antes de aplicar rename en remoto: Dashboard Supabase → Database → Backups, o `pg_dump` con connection string del proyecto.

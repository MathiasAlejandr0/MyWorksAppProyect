# Verificación BD remota Supabase

Proyecto: `wxqrfcqifkfgawrnqmnj`  
Fecha: 2026-09-14

Checklist + resultado de probe REST. Sin service role el agente no puede aplicar SQL: pegar migraciones en el **SQL Editor**.

## Resultado probe (anon / publishable)

| Chequeo | Estado | Evidencia |
|---------|--------|-----------|
| Rename ES | OK | `profiles`/`jobs`/`payments` → 404 con hint a tablas ES |
| Tablas núcleo ES | OK | `perfiles`, `trabajadores`, `trabajos`, `servicios`, `disputas`, … |
| Catálogo `servicios` | FALTA DATOS | `GET /servicios` → `[]` (0 filas) |
| Trabajadores | OK | ~18 filas; columnas ES |
| Helpers / RPC `05` | OK | `es_parte_trabajo` responde; admin RPC → 400 sin admin (no 404) |
| `pagos` / `mensajes` anon | Esperable | 401 / sin acceso — no abrir a `anon` |

**Pendiente en remoto:** aplicar `20260914000006_seed_servicios_marketplace.sql` (seed 8 oficios + SELECT marketplace para `anon` en `servicios`/`trabajadores` + grants `authenticated` en tablas sensibles).

Orden: `04` → `05` → **`06`**. Guía: [APLICAR_MIGRACION_ES.md](APLICAR_MIGRACION_ES.md).

---

## 1. Cutover ES

```sql
SELECT
  to_regclass('public.profiles') AS profiles,
  to_regclass('public.perfiles') AS perfiles,
  to_regclass('public.workers') AS workers,
  to_regclass('public.trabajadores') AS trabajadores,
  to_regclass('public.jobs') AS jobs,
  to_regclass('public.trabajos') AS trabajos,
  to_regclass('public.services') AS services,
  to_regclass('public.servicios') AS servicios;
```

Esperado: EN en `null`; ES presentes.

## 2. Inventario 28 tablas

```sql
WITH esperadas(tabla) AS (
  VALUES
    ('perfiles'),('trabajadores'),('servicios'),('trabajos'),('pagos'),
    ('mensajes'),('disputas'),('notificaciones'),('calificaciones'),('reportes'),
    ('propuestas_cotizacion'),('ordenes_cambio'),('fotos_trabajo'),
    ('portafolio_trabajador'),('trabajador_servicios'),('cancelaciones_trabajo'),
    ('registros_error_app'),('eventos_abuso'),('acciones_pendientes'),
    ('bloqueos_usuario'),('consentimientos_usuario'),('banderas_funcionalidad'),
    ('suscripciones'),('impulsos'),('eventos_analitica'),
    ('configuraciones_servicio'),('codigos_restablecimiento'),('tickets_soporte')
)
SELECT
  count(*) FILTER (WHERE c.table_name IS NOT NULL) AS tablas_presentes,
  array_agg(e.tabla ORDER BY e.tabla) FILTER (WHERE c.table_name IS NULL) AS faltantes
FROM esperadas e
LEFT JOIN information_schema.tables c
  ON c.table_schema = 'public' AND c.table_name = e.tabla;
```

Esperado: `tablas_presentes = 28`, `faltantes = null`.

## 3. RLS

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'perfiles','trabajadores','servicios','trabajos','pagos','mensajes','disputas'
  )
ORDER BY tablename;
```

Esperado: `rowsecurity = true`.

## 4. RPCs

```sql
SELECT proname
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname IN (
    'admin_actualizar_estado_disputa',
    'admin_metricas_resumen',
    'es_parte_trabajo',
    'is_admin'
  )
ORDER BY proname;
```

Esperado: 4 funciones. HTTP: `400` = existe; `404` = falta.

## 5. Catálogo

```sql
SELECT count(*) AS servicios_total FROM public.servicios;
SELECT categoria, nombre FROM public.servicios ORDER BY categoria;
```

Esperado tras **`06`**: `>= 8` filas.  
(`02` solo hace UPDATE de nombres; si la tabla está vacía no alcanza.)

## 6. Grants / RLS (no romper seguridad)

- **OK abrir a `anon`:** solo lectura de marketplace (`servicios` activos, `trabajadores`) — lo hace `06`.
- **No abrir a `anon`:** `pagos`, `mensajes`, disputas, etc. Validar con sesión autenticada (parte del trabajo o admin).

```sql
SELECT count(*) AS servicios FROM public.servicios;
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('perfiles','trabajos','pagos','disputas','mensajes','servicios','trabajadores')
ORDER BY tablename;
```

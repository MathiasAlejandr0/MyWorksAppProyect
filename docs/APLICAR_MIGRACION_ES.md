# Aplicar migración ES

## Estado esperado antes

```sql
SELECT
  to_regclass('public.profiles') AS profiles,
  to_regclass('public.perfiles') AS perfiles,
  to_regclass('public.workers') AS workers,
  to_regclass('public.trabajadores') AS trabajadores;
```

Si ves `profiles` / `workers` y `perfiles` / `trabajadores` en null → BD aún en inglés. Sigue.

## Paso único (importante)

1. Abre el archivo:

   `myworksapp_app/supabase/migrations/20260914000004_aplicar_rename_es.sql`

2. **Selecciona TODO el archivo** (Ctrl+A), cópialo y pégalo en el SQL Editor de Supabase.
3. Run.

No pegues solo un trozo (si omites `DO $$`, Postgres falla con `syntax error at or near "IF"`).

## Después

1. Catálogo: `20260914000002_catalogo_datos_es.sql`
2. Verifica:

```sql
SELECT
  to_regclass('public.profiles') AS profiles,
  to_regclass('public.perfiles') AS perfiles,
  to_regclass('public.workers') AS workers,
  to_regclass('public.trabajadores') AS trabajadores;

SELECT id, correo, rol, estado_cuenta FROM public.perfiles LIMIT 5;
```

Esperado: `profiles`/`workers` = null; `perfiles`/`trabajadores` con nombre; roles en español (`usuario`, `trabajador`, `administrador`).

## Errores comunes

| Error | Causa | Qué hacer |
| --- | --- | --- |
| `relation "profiles" already exists` | Ejecutaste un `CREATE TABLE profiles` (dump) | Ignora el dump; usa solo el archivo `04` |
| `syntax error at or near "IF"` | Pegaste un fragmento sin `DO $$` | Vuelve a pegar el archivo `04` **completo** |
| `relation "public.profiles" does not exist` (en trigger) | `is_admin()` viejo durante UPDATE | El archivo `04` ya recrea `is_admin()` antes de los UPDATE |
| `relation "public.perfiles" does not exist` al inicio | `DROP TRIGGER … ON perfiles` cuando la tabla aún no existe | Ya corregido en `04`: dropea solo si la tabla existe |

## 5) RLS + RPC admin (obligatorio para seguridad)

Tras el rename y el catálogo, aplica:

`myworksapp_app/supabase/migrations/20260914000005_rls_politicas_negocio.sql`

Eso habilita RLS en tablas de negocio, policies por rol/parte del trabajo, y RPCs:
- `admin_metricas_resumen`
- `admin_actualizar_estado_disputa`

Sin este paso, desktop/shared pueden fallar al resolver disputas/métricas tras endurecer policies.

## Migración 05 — RLS + RPCs admin

Tras el rename ES (`04`) y el catálogo (`02`):

1. Abre `myworksapp_app/supabase/migrations/20260914000005_rls_politicas_negocio.sql`.
2. Selecciona **todo** el archivo, pégalo en el SQL Editor y Run.
3. Verifica:

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('perfiles', 'trabajos', 'pagos', 'disputas', 'mensajes')
ORDER BY tablename;

SELECT proname
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname IN ('admin_actualizar_estado_disputa', 'admin_metricas_resumen', 'es_parte_trabajo');
```

Esperado: `rowsecurity = true` y las tres funciones presentes.

Desktop/shared ya usa `rpc('admin_actualizar_estado_disputa')` y `rpc('admin_metricas_resumen')` (ver `shared/src/repositories/disputes.ts` y `metrics.ts`). Sin esta migración esos RPC fallan.

## 6) Seed catálogo + grants marketplace

Tras `05`, aplica:

`myworksapp_app/supabase/migrations/20260914000006_seed_servicios_marketplace.sql`

Inserta los 8 oficios si `servicios` está vacío y permite lectura `anon` del catálogo/trabajadores (landing web).

Verificación rápida:

```sql
SELECT categoria, nombre, activo FROM public.servicios ORDER BY categoria;
```

Esperado: 8 filas (`plomeria` … `construccion`).

Detalle de auditoría remota: `docs/VERIFICACION_BD_REMOTA.md`.

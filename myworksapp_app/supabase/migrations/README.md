# Migraciones Supabase (MyWorks App)

Este directorio documenta el schema y el hardening del proyecto Supabase.

## Qué hay aquí

1. **Baseline documentado (idempotente)**  
   `20250907120000_schema_baseline_documented.sql`  
   - Reconstruido desde modelos Dart (`lib/core/database/models/`) y nombres reales de tablas en repositorios.  
   - Seguro para el proyecto existente: solo `CREATE TABLE IF NOT EXISTS`, sin `DROP`, sin borrar datos.  
   - Columnas camelCase (`"userId"`, `"createdAt"`, …) alineadas al cliente Flutter.  
   - Si la tabla ya existe en remoto, el `IF NOT EXISTS` no altera su definición.

2. **Hardening / seguridad** (y ajustes puntuales), por ejemplo:  
   - endurecimiento de roles y perfiles  
   - correcciones de RLS / `EXECUTE` en funciones administrativas  
   - revocación de execute en funciones de trigger  
   - nombres de perfil OAuth  

El **schema productivo** sigue viviendo en el proyecto Supabase remoto; el baseline es documentación ejecutable para onboarding y entornos nuevos.

## Clonar schema remoto (`db pull`)

En Windows (el paquete winget puede no existir; preferí npm):

```bash
npx supabase login
npx supabase link --project-ref <TU_PROJECT_REF>
npx supabase db pull
```

Alternativa si tenés el CLI global:

```bash
supabase login
supabase link --project-ref <TU_PROJECT_REF>
supabase db pull
```

Esto descarga el schema productivo al directorio de migraciones (o genera un dump según la versión del CLI). Útil cuando el remoto es la fuente de verdad y querés alinear el repo.

## Onboarding de un entorno nuevo

```bash
# Aplicar migraciones (incluye baseline + hardening)
supabase db push

# O clonar el schema remoto si preferís el dump oficial
supabase db pull
# / o:
supabase db dump --schema public > schema_base.sql
```

Orden típico: baseline → migraciones de hardening posteriores.

## Notas

- No uses solo las migraciones de hardening (sin baseline) para recrear la BD desde cero.  
- El baseline no reemplaza un `db pull` si necesitás FKs, RLS, índices o columnas que existan solo en remoto.

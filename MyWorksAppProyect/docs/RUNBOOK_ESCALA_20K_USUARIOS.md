# Escalamiento hacia ≥ 20.000 usuarios — My Works App

| Campo | Valor |
|-------|--------|
| Meta | Soportar una base de **≥ 20.000 personas** (cuentas / usuarios de plataforma) y acercarse al **techo Free ~50k MAU** |
| Medición actual | **200 VUs** stress OK (20-09-2026). **free-ceiling 300 VUs**: 0 % error, p95 **263 ms**, ~302 RPS, sin 401 — 20-09-2026 |
| Informe Word | [`INFORME_PRUEBAS_CARGA_CAPACIDAD.docx`](INFORME_PRUEBAS_CARGA_CAPACIDAD.docx) |

## Aclaración (importante)

| Término | Meta práctica |
|---------|----------------|
| 20.000–50.000 MAU | Cuentas **autenticadas activas en el mes** (Auth MAU de Supabase). **No** son 50k concurrentes |
| Concurrentes razonables en Free | Cientos leyendo catálogo. Medido: **300 VUs** `free-ceiling` con p95 263 ms y 0 % error |
| Cuentas registradas | Capacidad de disco/filas (plan Free ~500 MB DB), no de concurrencia |
| Ya medido | 300 concurrentes lectura OK (`free-ceiling`) |

No stress-testear Webpay/Transbank ni `guest-checkout` masivo (crea usuarios Auth reales y cuenta MAU).

## Fase 0 (inmediato) — hecho

1. Fix `servicios` anon 401 (RLS + GRANT).
2. Índices de lectura marketplace (`servicios`, `trabajadores`, `trabajos`, `pagos`).
3. Re-medir k6 incluyendo `servicios` tras el fix.

Migración: `20260925000001_fix_servicios_anon_scale_indexes.sql`.

## Fase 1 — exprimir Free (20k cuentas → techo 50k MAU)

Sin subir a Pro **salvo** cuello medido (p95 sostenido, CPU, MAU, DB, egress o Edge).

- Caché de catálogo (TanStack Query: `staleTime` 5 min, `gcTime` 30 min, sin `refetchOnWindowFocus`).
- Paginación cursor/limit (RPC `listar_profesionales_catalogo`, REST fallback `limit` 20–40).
- CDN cache de `/assets` hashed (`vercel.json` / `public/_headers`).
- Rate-limit Edge IP+user + kill switches (ver más abajo).
- Pooler solo en URI Postgres server-side (no hace falta en supabase-js HTTP).
- No stress Webpay; pagos con sesiones controladas.

Migración: `20260926000001_catalog_rpc_anon_rls.sql` (aplicar en el proyecto).

## Fase 2 — si Free se satura (Pro)

- Subir **Supabase Pro** cuando el checklist de cuotas o k6 lo justifique (no de antemano).
- Más CPU / conexiones / invocaciones Edge.
- Alertas automáticas (Grafana / reports Pro) si el dashboard Free no basta.

## Fase 3 — crecimiento extra-Pro

- Réplicas de lectura si el p95 de catálogo sube con tráfico real.
- PostGIS / nearby por lat-lng (hoy solo `zona_trabajo` texto).
- Separar caminos lectura (home) vs escritura (pagos).

---

## Techo Free 50k MAU

### Qué cabe en Free (si se cuida el stack)

| Recurso | Cabe si… | Se rompe si… |
|---------|----------|----------------|
| **MAU 50k** | Catálogo y home **sin login**. Login solo para pedir/pagar/chat. No `signInAnonymously`. Guest-checkout es la vía que **sí** crea MAU | Forzar registro para mirar oficios; spam de guest-checkout; usuarios fantasma |
| **Concurrentes** | Cientos de lecturas REST del marketplace. Medido **300 VUs** (`free-ceiling`, 20-09-2026): 0 % error, p95 263 ms, ~302 req/s | Miles de VUs, Realtime abierto a todos, `SELECT` sin `limit` |
| **DB ~500 MB** | Filas de perfiles/trabajos acotadas; índices parciales; no duplicar fotos en Postgres | Guardar media en bytea; logs infinitos; 50k perfiles pesados + historial sin archivo |
| **Egress ~5 GB/mes** | Fotos de lista `w=200`; categorías `w=640`; cache Query 5 min; CDN de JS | Fotos full-res en listados; refetch al foco; prefetch de categorías no visibles |
| **Edge ~500k inv/mes** | Solo crear pago / guest / commit reales; rate-limit 5/min IP guest, 10/min user webpay | Loops de retry, status polling agresivo, stress a Transbank |
| **Storage ~1 GB** | Avatares comprimidos; no backups en el bucket público | Portafolios 4K sin límite |
| **Realtime** | Un canal `notificaciones:<userId>` con unsubscribe al logout | Canales globales de catálogo o GPS |

### Qué no cabe (aunque haya “50k MAU de marketing”)

- 50k personas **a la vez** en el home.
- Stress de Webpay / guest-checkout.
- Chat Realtime masivo o tracking GPS broadcast.
- Nearby geo real (no hay lat/lng en `trabajadores`; hace falta Pro+extensión o tabla nueva).
- p95 &lt; 200 ms con 1k+ RPS en CPU compartida.

### Cuándo subir a Pro (solo con medición)

Subir si **uno** de estos se sostiene 24–48 h o en k6 de lecturas:

1. MAU Dashboard &gt; ~40k (80 % del tope).
2. DB size &gt; ~400 MB.
3. Egress &gt; ~4 GB/mes.
4. Edge invocations &gt; ~400k/mes.
5. Catálogo público: error ≥ 1 % **o** p95 ≥ 500 ms en `PROFILE=free-ceiling` (y no es rate-limit transitorio).
6. CPU / “High compute” en Reports con el producto ya en uso real.

### Connection pooling (Supavisor)

El cliente web/app/desktop usa **HTTPS PostgREST** (`https://<ref>.supabase.co/rest/v1`), no una URI `postgres://`. El pooler **no aplica** ahí.

Usar el URI pooler **solo** en jobs/server que abran Postgres (scripts, ETL, `postgres.js`):

- Transaction mode: puerto **6543** (`postgres://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:6543/postgres`).
- Session mode: puerto **5432** del pooler si hace falta prepared statements.

Dashboard → Project Settings → Database → Connection string → **Mode: Transaction**. No commitear la password. Las Edge Functions actuales usan `serviceClient()` (HTTP); no cambiarlas al pooler.

### EXPLAIN (SQL editor, tras aplicar `20260926`)

```sql
EXPLAIN (FORMAT TEXT)
SELECT * FROM public.listar_profesionales_catalogo('electricidad', NULL, NULL, NULL, 20);

EXPLAIN (FORMAT TEXT)
SELECT id_usuario, profesion, calificacion
FROM public.trabajadores
WHERE COALESCE(disponible, 0) = 1
  AND COALESCE(precios_configurados, 0) = 1
  AND categoria_servicio = 'electricidad'
ORDER BY calificacion DESC NULLS LAST, id_usuario ASC
LIMIT 20;
```

Esperado: Index Scan / Bitmap sobre `trabajadores_catalog_list_idx` o `trabajadores_disponible_cat_idx`. Evitar Seq Scan con &gt;1k filas. `zona_trabajo ILIKE '%x%'` **no** usa el btree (`trabajadores_zona_trabajo_idx`); nearby lat/lng no existe en esta tabla.

### Cuotas Free — checklist de monitoreo (manual, semanal)

Dashboard → **Reports** / **Settings → Usage**. Anotar y actuar al **~70 %**:

| Cuota | Dónde | Alerta manual (~70 %) | Acción |
|-------|--------|------------------------|--------|
| MAU Auth | Auth → Users / Usage | ~35k | Cortar guest-checkout (`MWA_KILL_GUEST_CHECKOUT`); no campañas de registro |
| DB size | Database → Usage | ~350 MB | Vaciar logs, no subir media a Postgres |
| Egress | Usage | ~3,5 GB | Subir `staleTime`, bajar tamaño de fotos, CDN |
| Edge invocations | Edge Functions → Reports | ~350k | Kill Webpay no esencial; no poll |
| Storage | Storage | ~700 MB | Limpiar avatares huérfanos |
| Realtime messages | Realtime | pico anómalo | Desuscribir canales; modo solo lectura |

No hay alertas automáticas en Free: calendarizar revisión (p. ej. lunes) o un check humano post-demo.

### Kill switches (Dashboard → Edge Functions → Secrets)

Fail-closed. Valor `1` / `true` / `on`.

| Secret | Efecto | Cuándo |
|--------|--------|--------|
| `MWA_KILL_GUEST_CHECKOUT` | `guest-checkout` → 503 | Spam de invitados, MAU cerca del tope |
| `MWA_KILL_WEBPAY` | `webpay-create` → 503 | Abuso de intenciones de pago / cuota Edge |
| `MWA_READ_ONLY` | Guest + Webpay create → 503 | Incidente: catálogo sigue, no se cobra |
| `MWA_RATE_LIMIT_FAIL_CLOSED` | Niega si no hay IP (`unknown`) | Ataque sin `x-forwarded-for` |

App Flutter: Realtime ya es un canal por usuario (`notificaciones:<userId>`) con `unsubscribe` al logout. Para bajar Realtime del todo, no llamar `NotificationRealtimeService.subscribe` (feature flag local / build). Web no abre Realtime de catálogo.

UI: con 503 el cliente muestra toast; el marketplace sigue navegable sin login.

Rate-limit (in-memory por isolate, no global): guest **5/min/IP** + **3/min/email**; webpay-create **20/min/IP** + **10/min/user**. Transbank: timeout 12 s, 1 retry solo en 5xx/red.

### k6 techo Free

```powershell
k6 run -e SUPABASE_URL=$env:SUPABASE_URL -e SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY -e PROFILE=free-ceiling scripts/load/k6/catalog.js --summary-export=scripts/load/results/catalog-free-ceiling.json
```

Opcional RPC (después de migrar): `-e K6_USE_RPC=1`.

Corrida 20-09-2026 (REST anon, sin RPC, sin Webpay): umbrales OK. 300 VUs, 90 942 req, error **0 %**, p95 **263 ms**, ~302 RPS. Egress de **esta** prueba ≈ 196 MB — no repetir a diario en Free (cuota ~5 GB/mes).

### Checklist “listo para ~50k MAU Free”

- [x] Catálogo público anon (`servicios` + `trabajadores` marketplace) sin 401.
- [x] Índices de listado + RPC paginada sin correo.
- [x] Clientes: cache agresiva, sin refetch al foco, limit/cursor, fotos de lista chicas.
- [x] Auth no requerida para navegar oficios; sesión persistente; sin usuarios anónimos.
- [x] Edge: rate-limit + kill switches + errores cortos sin tokens; timeout TBK.
- [x] CDN cache `/assets`; code-split mapa Leaflet y checkout.
- [x] k6 `free-ceiling` documentado (solo lecturas).
- [x] Corrida `PROFILE=free-ceiling` 20-09-2026: 300 VUs, 0 % error, p95 263 ms.
- [ ] Aplicar migración `20260926000001_catalog_rpc_anon_rls.sql` en el proyecto.
- [ ] Revisión semanal de cuotas en Dashboard.

### Qué falta **solo** con Pro (o infra extra)

- CPU dedicado / techo de conexiones más alto si p95 Free no cumple con tráfico real.
- Más de 50k MAU Auth.
- DB &gt; 500 MB, egress &gt; 5 GB, Storage &gt; 1 GB, Edge &gt; 500k inv.
- Alertas automáticas y PITR.
- Read replicas / PostGIS nearby.
- Rate-limit Edge **global** (hoy es por isolate).

## Criterio de éxito para “listos para 20k cuentas”

- Catálogo k6 (`servicios` + `trabajadores`) ≥ **200 VUs** (hecho) y techo Free **300 VUs** (`free-ceiling`, 20-09-2026: 0 % error, p95 263 ms). Pro solo si esto deja de cumplirse con tráfico real.
- Pagos: runbook Transbank + kill switches, **sin** saturar integración.
- Informe Capstone actualizado con la nueva corrida.

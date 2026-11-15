# Anexo — Pruebas de rendimiento y carga (8 nov 2026)

Línea base medible **después** de `trabajador_horarios` (commit `5654833`). Sirve para comparar una mejora futura con los **mismos scripts**, umbrales y perfiles.

| Campo | Valor |
|---|---|
| Fecha | 2026-11-08, 16:46–17:30 America/Santiago |
| Git | `5654833` — `fix: ocultar la agenda semanal del catalogo REST` |
| Proyecto | `https://wxqrfcqifkfgawrnqmnj.supabase.co` |
| Cliente | Windows 10, k6 v2.2.0, Node v22.15.0 |
| Umbral catálogo | error &lt; 5 %, p95 &lt; 1500 ms |
| Umbral reserva | error &lt; 5 %, p95 &lt; 2000 ms |
| SLO histórico Free | error &lt; 1 %, p95 &lt; 500 ms (`free-ceiling` 20-09-2026) |

No se tocó Webpay ni `guest-checkout`. No se escribieron filas de negocio. La clave anon es la publicable del cliente. El JWT de Camila/Patricia se usó en memoria y **no** quedó en estos anexos.

## 1. Qué se midió

**Rendimiento (1 cliente, 30 muestras + 5 de calentamiento, pausa 200 ms):**

- REST `servicios`
- REST `trabajadores` (anon)
- RPC `categorias_con_disponibles`, `listar_profesionales_catalogo`, `horarios_libres_profesional`
- REST `trabajos` (Camila) y RPC `horarios_disponibles_propios` (Patricia)
- Bundle Vite producción + Navigation Timing / LCP en `vite preview` (localhost:4173, 1366×768)

**Carga (k6, think time 1 s):**

| Script | Perfiles corridos | Qué representa |
|---|---|---|
| `scripts/load/k6/catalog.js` | smoke, baseline, stress | Mismo script que sep-2026 |
| `catalog.js` + `K6_USE_RPC=1` | baseline | Catálogo real (`listar_profesionales_catalogo`) |
| `scripts/load/k6/booking-reads.js` | smoke, baseline, stress | Funnel de reserva (categorías + catálogo + huecos) |
| `scripts/load/k6/mixed-read.js` | baseline + JWT Camila | Catálogo anon + `trabajos` autenticados |

**No corrido a propósito**

- `PROFILE=free-ceiling` (300 VUs): en sep-2026 gastó ~196 MB de egress. Además, hoy el REST anon de `trabajadores` responde `[]` por RLS; inflaría el techo sin medir el catálogo real.
- Soak 10 min y `capacity-ceiling.js`.

El catálogo que ve el usuario está en el RPC, no en `GET /trabajadores`. `booking-reads.js` es la prueba honesta del funnel.

## 2. Cómo repetir (comparación justa)

Desde `MyWorksAppProyect/`:

```powershell
$env:SUPABASE_URL = "https://wxqrfcqifkfgawrnqmnj.supabase.co"
$env:SUPABASE_ANON_KEY = "<anon publicable>"
$env:GIT_SHA = (git rev-parse --short HEAD)

node scripts/load/rendimiento-latencia.mjs
# opcional: $env:SUPABASE_EMAIL / SUPABASE_PASSWORD / SUPABASE_WORKER_EMAIL

cd myworksapp_web; npm run build; cd ..
$env:WEB_ROOT = (Resolve-Path myworksapp_web).Path
node scripts/load/rendimiento-web.mjs

k6 run -e SUPABASE_URL=$env:SUPABASE_URL -e SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY -e PROFILE=stress --summary-export=docs/anexos/<fecha>/k6/catalog-stress.json scripts/load/k6/catalog.js
k6 run -e SUPABASE_URL=$env:SUPABASE_URL -e SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY -e PROFILE=stress --summary-export=docs/anexos/<fecha>/k6/booking-reads-stress.json scripts/load/k6/booking-reads.js
```

No cambies `THINK_TIME`, los `PROFILE` ni el `WORKER_ID` de Patricia (`…000206`) si quieres delta contra esta corrida. Copia `comparacion.csv` y agrega una fila.

## 3. Rendimiento (1 usuario)

Percentiles: interpolación lineal sobre 30 muestras. 0 errores.

| Endpoint | p50 (ms) | p95 (ms) | Bytes | Filas |
|---|---:|---:|---:|---:|
| REST servicios | 219.1 | 251.7 | 1206 | 13 |
| REST trabajadores listado (anon) | 219.2 | 229.0 | 2 | 0 (`[]` por RLS) |
| RPC categorías | 220.5 | 236.5 | 170 | 12 |
| RPC catálogo gasfitería | 218.9 | 231.0 | 4770 | 9 |
| RPC catálogo plomería | 219.9 | 229.4 | 544 | 1 |
| RPC huecos Patricia 14 días | 220.9 | 230.2 | 2098 | 50 |
| RPC huecos Pedro 14 días | 224.4 | 232.9 | 2098 | 50 |
| REST trabajos (Camila) | 234.4 | 287.5 | 2554 | 20 |
| RPC agenda propia (Patricia) | 230.1 | 281.4 | 725 | 25 bloques |

Vista cliente autenticada de Patricia (`SELECT *`): **1041 bytes**, 26 columnas, **sin** `horarios_disponibles`.

Web (preview local, no CDN de producción):

| Métrica | Valor |
|---|---|
| JS gzip | 210 365 bytes (~205 KB) |
| CSS gzip | 16 251 bytes (~16 KB) |
| Dist gzip total (incluye PNG de oficios) | 1 530 937 bytes |
| TTFB localhost | 2.2 ms |
| FCP | 3148 ms |
| LCP | 3192 ms |
| DCL / load | 2942 ms |

El LCP lo empujan las fotos de categoría (~230–300 KB PNG cada una). El JS principal gzip es `index` 79.9 KB + `supabaseClient` 55.1 KB + `map` 43.4 KB (este último no va en el primer paint).

## 4. Carga (k6)

Todos los umbrales **pasados**. Checks 100 %. `error_rate` = 0.

| Prueba | VUs | p95 (ms) | RPS | Peticiones | Recibido |
|---|---:|---:|---:|---:|---:|
| catalog smoke | 5 | 249 | 6.7 | 210 | 0.22 MB |
| catalog baseline | 50 | 233 | 47.6 | 8 600 | 8.3 MB |
| catalog stress | 200 | **237** | 174 | 62 834 | 60 MB |
| catalog + RPC baseline | 50 | 265 | 60.4 | 10 965 | 13 MB |
| booking smoke | 5 | 262 | 8.7 | 270 | 0.78 MB |
| booking baseline | 30 | **250** | 35.8 | 6 471 | 18 MB |
| booking stress | 80 | **249** | 95.3 | 24 402 | 69 MB |
| mixed baseline (JWT) | 40 | 240 | 43.6 | 7 905 | 12 MB |

En booking stress el **máximo** de `horarios_libres_profesional` fue 2.22 s; el p95 de ese RPC quedó en 252 ms. La cola existe; no rompe el umbral.

## 5. Comparación con 20-09-2026

| Prueba | Sep 2026 | Nov 2026 | Lectura |
|---|---|---|---|
| catalog smoke p95 | 303 ms | 249 ms | mismo orden, un poco más rápido |
| catalog stress 200 VUs p95 | ~220 ms | 237 ms | mismo orden; +17 ms |
| free-ceiling 300 VUs | 263 ms, 0 % error, ~302 RPS | no repetido | ver §1 |
| funnel reserva | no existía | 80 VUs, p95 249 ms, 0 % error | línea base nueva |

Cuidado: en noviembre el `GET trabajadores` anon devuelve `[]`. El stress de `catalog.js` **no** descarga el listado de profesionales. Para el marketplace real usar `booking-reads.js` o `K6_USE_RPC=1`.

## 6. Qué mirar en una mejora futura

No se optimizó nada en esta corrida. Si más adelante se toca índice, RPC, fotos o plan Supabase, el delta útil es:

1. `booking-reads` stress: p95 HTTP y `mwa_rpc_huecos_ms` (hoy 249 / 252 ms).
2. Latencia secuencial de `rpc_huecos_patricia` y `rpc_catalogo_gasfiteria` (hoy p95 230 / 231 ms).
3. LCP / peso de `/categories/*.png` (hoy LCP ~3.2 s en preview local).
4. JS gzip de `index` + `supabaseClient` (hoy ~135 KB gzip sumados).

JSON crudo: `k6/*.json`, `rendimiento/latencia-endpoints.json`, `rendimiento/web-bundle-navegacion.json`. Resumen: `resumen-k6.json` y `comparacion.csv`.

# Runbook — Pruebas de carga / capacidad (MVP)

| Campo | Valor |
|-------|--------|
| Objetivo | Estimar cuántos **usuarios concurrentes leyendo** aguanta el backend actual |
| Herramienta | [k6](https://k6.io) |
| Scripts | `scripts/load/k6/` |
| Fecha | 2026-09-20 |
| Alcance | Supabase REST (catálogo). **No** Webpay ni guest-checkout |

---

## 1. Qué estamos midiendo (y qué no)

### Sí medimos

- Lecturas del **home / búsqueda**: tablas `servicios` y `trabajadores` (como un visitante).
- Opcional: lecturas de `trabajos` con un JWT de prueba.
- Latencia (p95), tasa de errores y peticiones por segundo (RPS).

### No medimos (aún / a propósito)

| Escenario | Por qué no en este MVP |
|-----------|-------------------------|
| Miles de pagos Webpay | Martillaría Transbank y crearía intenciones reales |
| `guest-checkout` masivo | Crea usuarios Auth de verdad |
| “Usuarios registrados totales” | Eso es capacidad de disco/filas, no de concurrencia |
| GPS / chat / Tauri UI | No son el cuello de botella del servidor hoy |

**Frase para el profesor:**  
> “Estimamos usuarios *usando la app a la vez* (mirando catálogo), no cuántas cuentas puede guardar la base.”

---

## 2. Instalación de k6 (Windows)

```powershell
winget install GrafanaLabs.k6
k6 version
```

O descarga desde https://grafana.com/docs/k6/latest/set-up/install-k6/

---

## 3. Variables

Usa el proyecto Supabase de **desarrollo / integración** (el mismo de la demo).

```powershell
$env:SUPABASE_URL = "https://wxqrfcqifkfgawrnqmnj.supabase.co"
$env:SUPABASE_ANON_KEY = "<tu anon key>"   # Dashboard → Settings → API
# Opcional (usuario de prueba ya creado):
# $env:SUPABASE_USER_JWT = "<access_token>"
```

La anon key es pública en el cliente; no uses la **service_role** en estos scripts.

---

## 4. Batería completa (orden recomendado)

Desde la raíz del monorepo:

```powershell
cd D:\MyWorksAppProyect

# 1) Humo — ¿está vivo? (~30 s)
k6 run -e SUPABASE_URL=$env:SUPABASE_URL -e SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY -e PROFILE=smoke scripts/load/k6/catalog.js

# 2) Baseline — ~50 usuarios virtuales mirando catálogo (~3 min)
k6 run -e SUPABASE_URL=$env:SUPABASE_URL -e SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY -e PROFILE=baseline scripts/load/k6/catalog.js

# 3) Stress — hasta ~200 VUs (~6 min)
k6 run -e SUPABASE_URL=$env:SUPABASE_URL -e SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY -e PROFILE=stress scripts/load/k6/catalog.js

# 4) Techo de RPS — sube peticiones/segundo hasta notar degradación (~4 min)
k6 run -e SUPABASE_URL=$env:SUPABASE_URL -e SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY scripts/load/k6/capacity-ceiling.js

# 5) Opcional — mezcla con sesión
k6 run -e SUPABASE_URL=$env:SUPABASE_URL -e SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY -e SUPABASE_USER_JWT=$env:SUPABASE_USER_JWT -e PROFILE=baseline scripts/load/k6/mixed-read.js

# 6) Soak (estabilidad) — 40 VUs × 10 min (hazlo cuando tengas tiempo)
k6 run -e SUPABASE_URL=$env:SUPABASE_URL -e SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY -e PROFILE=soak scripts/load/k6/catalog.js
```

Guardar salida:

```powershell
k6 run ... --summary-export=scripts/load/results/baseline-summary.json
```

---

## 5. Cómo leer el resultado (para no informáticos)

| Indicador en k6 | Qué significa | Bueno (MVP) | Malo |
|-----------------|---------------|-------------|------|
| `http_req_failed` | % de peticiones fallidas | &lt; 1–5 % | &gt; 10 % |
| `http_req_duration` **p(95)** | El 95 % de las lecturas tardan menos que… | &lt; 1–1,5 s | &gt; 3 s |
| `vus` / stages | Usuarios virtuales simultáneos | El máximo donde aún “bueno” | — |
| checks ✓ | Respuestas 200 con datos | Casi 100 % | Muchos ✗ |

### Estimación simple de usuarios concurrentes

Cada usuario virtual hace ~2 lecturas y espera ~1 s (`THINK_TIME`).  
Si el **stress** aguanta **200 VUs** con p95 &lt; 1,5 s y errores &lt; 5 %:

> “Con el plan actual de Supabase, el catálogo sostiene del orden de **~150–200 personas mirando la app a la vez** en este escenario. Eso es mucho más que una demo de curso; para lanzamiento comercial regional habría que re-medir en plan Pro y con caché.”

Si se rompe a **50 VUs**:

> “Hoy el cuello está cerca de decenas de concurrentes en lecturas; antes de crecer marketing hay que subir plan Supabase, índices y caché.”

---

## 6. Plantilla de resultados (copiar a la bitácora)

| Prueba | Fecha | VUs máx | p95 (ms) | Error % | RPS aprox | Conclusión |
|--------|-------|---------|----------|---------|-----------|------------|
| smoke | | 5 | | | | |
| baseline | | 50 | | | | |
| stress | | 200 | | | | |
| ceiling | | (arrival-rate) | | | | |
| soak | | 40 | | | | |

---

## 7. Cómo hacer crecer la capacidad (hoja de ruta)

Orden práctico (de barato a caro):

1. **Medir** (esta batería) y anotar el techo actual.  
2. **Índices** en columnas filtradas (`activo`, `disponible`, `id_usuario` en trabajos) — ya hay varios; revisar en dashboard.  
3. **Plan Supabase** (Free → Pro): más CPU, conexiones y Edge.  
4. **Caché de catálogo** en web (TanStack Query ya ayuda; CDN / edge cache después).  
5. **Separar lecturas pesadas** de escrituras (pagos siguen en Edge, no en el path del home).  
6. **Read replicas / pooling** cuando el tráfico comercial lo justifique.  
7. Re-medir tras cada cambio (mismo script = comparación justa).

Pagos (Webpay): la capacidad la limitan **Transbank + Edge + rate limits**, no el `SELECT` del catálogo. Se prueba aparte, con pocas sesiones reales de integración, no con stress masivo.

---

## 8. Límites éticos / seguridad

- No usar `service_role` en k6.  
- No apuntar a producción de clientes reales sin ventana acordada.  
- No incluir `guest-checkout` ni `webpay-create` en rampas altas.  
- Si Supabase rate-limita, bajar VUs; eso **también** es un dato de capacidad.

---

## 9. Qué decir en la defensa Capstone

> “Implementamos pruebas de carga con k6 sobre el API de Supabase (catálogo). Hoy el MVP no está terminado, pero ya tenemos un **techo medido** de usuarios concurrentes en lecturas y una hoja de ruta (plan, caché, índices) para crecer por encima de la demanda esperada del piloto. No confundimos eso con stress de la pasarela de pago, que se valida con pruebas funcionales controladas en Transbank.”

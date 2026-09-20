# Escalamiento hacia ≥ 20.000 usuarios — My Works App

| Campo | Valor |
|-------|--------|
| Meta | Soportar una base de **≥ 20.000 personas** (cuentas / usuarios de plataforma) |
| Medición actual | ≥ **200 VUs** concurrentes en lectura de `trabajadores` (0 % error, p95 ≈ 220 ms) — 20-09-2026 |
| Informe Word | [`INFORME_PRUEBAS_CARGA_CAPACIDAD.docx`](INFORME_PRUEBAS_CARGA_CAPACIDAD.docx) |

## Aclaración (importante)

| Término | Meta práctica |
|---------|----------------|
| 20.000 usuarios | Cuentas registradas / base direccionable |
| Concurrentes en punta | ~200–1.000 (1–5 % de activos) |
| Ya medido | 200 concurrentes lectura OK |

## Fase 0 (inmediato) — hecho / en curso

1. Fix `servicios` anon 401 (RLS + GRANT).
2. Índices de lectura marketplace (`servicios`, `trabajadores`, `trabajos`, `pagos`).
3. Re-medir k6 incluyendo `servicios` tras el fix.

Migración: `20260925000001_fix_servicios_anon_scale_indexes.sql`.

## Fase 1 — corto plazo (piloto → 20k cuentas)

- Subir **Supabase Pro** (CPU, conexiones, Edge).
- Activar **connection pooling** (Supavisor / pooler).
- Caché de catálogo en web (TanStack Query + TTL; luego CDN).
- No stress-testear Webpay; validar pagos con sesiones controladas.

## Fase 2 — medio plazo

- Rate-limit endurecido en Edge (`guest-checkout`, `webpay-create`).
- Alertas de latencia/error (Grafana / Supabase reports).
- Revisar RLS de `perfiles` (evitar lecturas anónimas innecesarias).

## Fase 3 — crecimiento

- CDN para assets estáticos.
- Réplicas de lectura si el p95 de catálogo sube con tráfico real.
- Separar caminos lectura (home) vs escritura (pagos).

## Criterio de éxito para “listos para 20k”

- Stress k6 catálogo (`servicios` + `trabajadores`) ≥ **500 VUs** o ≥ **200 RPS** con error &lt; 1 % y p95 &lt; 500 ms en plan Pro.
- Pagos: runbook Transbank + monitoreo Edge, sin saturar integración.
- Informe Capstone actualizado con la nueva corrida.

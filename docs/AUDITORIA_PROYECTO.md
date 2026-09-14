# Auditoría MyWorksApp — reevaluación (post craft + probe remoto)

**Fecha:** 2026-09-14 (segunda pasada)  
**Baseline previa:** ~7.1 / 10  
**Nota global (código / repo):** **8.1 / 10**  
**Nota global si `06` seed aplicado + RLS confirmado en remoto:** **~8.7–9.0**

Aún **no** se declara 9/10 cerrado hasta: (1) seed `servicios` en remoto, (2) `rowsecurity=true` verificado por ti en SQL Editor.

---

## Notas por eje

| Eje | Antes (7.1) | Ahora | Comentario |
|-----|-------------|-------|------------|
| Arquitectura | 7.2 | **7.6** | Páginas adelgazadas; shared RPC; sin Edge Functions |
| Datos | 8.3 | **8.0 remoto / 8.8 repo** | Rename ES OK en vivo; catálogo `servicios` vacío en remoto |
| Seguridad | 7.0/? | **8.2 repo / ~7.5 remoto** | RPC 05 presentes; grants marketplace en migración `06` |
| Código limpio | 6.7 | **7.8** | worker_home ~840; widgets extraídos; keys release con dart-define |
| Diseño UX | 6.8 | **8.0** | Skeletons, menos teatro, desktop ops-first |
| Responsividad | 6.8 | **7.4** | Breakpoints + CSS fluid; QA dispositivo real pendiente |
| Honestidad producto | 8.6 | **8.9** | Demo etiquetada; GPS/pago simulados |
| Tests | 5.2 | **6.0** | Unitarios Flutter; falta E2E y shared |

## Notas por app

| App | Nota | Veredicto |
|-----|------|-----------|
| Flutter | **8.2** | Craft + skeletons + dart-define release; God-page detail aún grande |
| Web | **8.0** | Fluidez + copy honesto; `App.tsx` monolito |
| Desktop | **8.1** | Ops-first; demos colapsadas |

## Remoto (probe REST)

Ver `VERIFICACION_BD_REMOTA.md`. Resumen: rename ES OK; RPCs admin OK; **servicios = 0 filas** → aplicar `06`.

## Qué falta para declarar 9.0 sincero

1. Aplicar `20260914000006_seed_servicios_marketplace.sql` en SQL Editor  
2. Pegar resultado de `SELECT count(*) FROM servicios` (≥8)  
3. Confirmar `rowsecurity` en tablas núcleo  
4. (Opcional) tests shared + un smoke E2E

## Documentos

- [VERIFICACION_BD_REMOTA.md](VERIFICACION_BD_REMOTA.md)  
- [APLICAR_MIGRACION_ES.md](APLICAR_MIGRACION_ES.md)  
- Migraciones `04` → `05` → `06`

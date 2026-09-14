# Auditoría MyWorksApp — reevaluación post-remediación

**Fecha:** 2026-09-14  
**Baseline previa:** ~5.6 / 10  
**Nota global (código / repo):** **7.1 / 10**

Si la migración RLS `05` **no** está aplicada en Supabase remoto, la seguridad efectiva sigue ~3.5–4 y la nota global real cae a **~6.0–6.3**.

Subió de verdad. **No es 9.** La brecha sigue siendo deuda estructural, remoto no verificable desde aquí, y tests.

---

## Notas por eje

| Eje | Antes | Ahora | Comentario |
|-----|-------|-------|------------|
| Arquitectura | ~6.0 | **7.2** | `shared` + RPC admin; sin Edge Functions; Flutter no consume `shared` |
| Datos | ~7.0 | **8.3** | Cutover ES coherente; fallbacks legacy residuales |
| Seguridad | ~3.5 | **7.0 en repo** / **? remoto** | Migración 05 sólida; remoto = depende de aplicar el SQL |
| Código limpio | ~5.0 | **6.7** | Auth/labels limpios; God-pages intactas |
| Diseño UX | ~4.5 | **6.8** | Menos teatro en web; desktop aún consola demo |
| Responsividad | ~5.5 | **6.8** | Breakpoints + media queries; QA real débil |
| Honestidad producto | ~4.0 | **8.6** | Mejor salto relativo |
| Tests | ~4.5 | **5.2** | Solo unitarios Flutter; web/desktop/shared = 0 |

## Notas por app

| App | Nota | Veredicto |
|-----|------|-----------|
| Flutter | **7.3** | Drift ES bien; keys hardcodeadas; páginas monstruo |
| Web | **7.4** | Auth role + checkout honesto; monolito `App.tsx`; sin tests |
| Desktop | **7.0** | Honestidad OK; HR/Audit/DevSecOps siguen siendo teatro con badge |

---

## Qué mejoró (evidencia)

- Drift ES: `WorkerModel` → `calificacion`; `auth_provider` usa `isActive` (`activo`)
- RLS en repo: `20260914000005_rls_politicas_negocio.sql` (casts `::text`, RPC admin)
- Shared: `metrics.ts` / `disputes.ts` vía RPC
- Web: `enforceWebClientRole`, keys solo por `.env`, XSS PDF escapado, checkout **SIMULACIÓN / DEMO**
- Desktop: «Modo demostración académica»; paneles DEMO etiquetados
- Flutter escrow: simulación académica sin cobro real

## Lo que sigue mal (hacia 9.0)

1. Confirmar RLS `05` en remoto (`rowsecurity`)
2. Keys Flutter en `supabase_config.dart` (literales)
3. Sin Edge Functions; pagos = estados + UI simulada
4. God-pages (~1290–1310 LOC) y `App.tsx` monolito
5. Flutter no usa `@myworksapp/shared`
6. Tests: 0 en web/desktop/shared; sin E2E
7. Dead code spatial en web; paneles desktop inventados

## Veredicto

Las remediaciones no son cosméticas: cutover ES + RLS tipada + roles + honestidad de pagos = salto 5.6 → **~7.1**.

A **9.0** no se llega con más badges: hace falta RLS remoto, partir God-pages, keys Flutter por env/flavor, y tests que fallen si se rompe auth/pago/RLS.

## Documentos relacionados

- [DICCIONARIO_BASE_DATOS.md](DICCIONARIO_BASE_DATOS.md) · [DICCIONARIO_BASE_DATOS.docx](DICCIONARIO_BASE_DATOS.docx)
- [APLICAR_MIGRACION_ES.md](APLICAR_MIGRACION_ES.md)

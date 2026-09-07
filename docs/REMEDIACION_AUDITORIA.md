# Remediación auditoría

## Sprint 1 — Honestidad + UX
- [x] README MVP; demos etiquetados; secrets `.env`; tokens; hero; strict TS

## Sprint 2 — Schema + SoT + job_detail + tests
- [x] Baseline SQL documentado; `shared/domain.ts`; Vitest 6/6; job_detail 1403→398

## Sprint 3 — Drift CI + Riverpod + e2e + payment port
- [x] `scripts/check-domain-drift.mjs` + CI (`npm run check:domain`)
- [x] Providers: worker/payment/dispute/notification; migrados job_history, job_detail, worker_home
- [x] Playwright smoke web (`e2e/home.spec.ts`, 1 passed)
- [x] `PaymentGatewayPort` + `MockPaymentGateway` (scaffold; no PSP real)
- [x] Docs `db pull` en migraciones README
- [ ] `supabase db pull` ejecutado contra remoto (requiere CLI + login del usuario)

## Pendiente (sprint 4+)
- [ ] Aplicar `db pull` y versionar dump oficial
- [ ] Migrar más pantallas/services a Riverpod (acabar singletons)
- [ ] Integrar MockPaymentGateway en JobBookingService / EscrowCheckoutSheet
- [ ] Push remoto (FCM) y pasarela Webpay/MP real
- [ ] Design tokens package único Dart+CSS
- [ ] Codegen automático Dart desde domain.ts (hoy solo check de drift)

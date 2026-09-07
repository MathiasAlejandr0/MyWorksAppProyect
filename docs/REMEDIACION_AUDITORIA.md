# Remediación auditoría

## Sprint 1 — Honestidad + UX
- [x] README MVP; demos; secrets; tokens; hero; strict TS

## Sprint 2 — Schema + SoT + job_detail
- [x] Baseline SQL; domain.ts; Vitest; job_detail 1403→398

## Sprint 3 — Drift + Riverpod + e2e + payment port
- [x] check-domain-drift; providers; Playwright; PaymentGatewayPort

## Sprint 4 — Gateway wired + más Riverpod + push port
- [x] EscrowCheckoutSheet → MockPaymentGateway; Riverpod screens; push port; script db-pull

## Sprint 5 — Codegen + tokens package + DI services
- [x] `scripts/generate-domain-dart.mjs` → `generated_domain.dart`
- [x] `WorkerJobStatus` usa lista generada desde TS
- [x] `shared/design-tokens.json` + `design-tokens.css` + sync en web/desktop
- [x] DI constructores + `jobBookingServiceProvider` / `paymentServiceProvider`
- [x] Escrow y job_detail usan services vía Riverpod
- [ ] `db pull` autenticado (usuario debe pegar código en `npx supabase login`)

## Sprint 6 — Colors codegen + stubs FCM/Webpay + DI call sites
- [x] `scripts/generate-app-colors.mjs` → `generated_brand_colors.dart`
- [x] `AppColors.brandOrange` / `brandNavy` / `emerald`/`success` desde tokens
- [x] `npm run generate:colors` (+ integrado en `sync:tokens`)
- [x] `UnimplementedFcmPushNotifications` + pasos FCM en provider
- [x] `UnimplementedWebpayGateway` stub
- [x] `quick_booking_page` / `service_request_page` → `jobBookingServiceProvider` (+ `jobRepositoryProvider`)
- [ ] FCM real / Webpay real (stubs listos; sin integrar SDKs)
- [ ] Completar db pull y commitear dump oficial

## Pendiente (sprint 7+)
- [ ] Migrar resto de singletons a DI
- [ ] Integrar firebase_messaging detrás de PushNotificationPort
- [ ] Integrar Webpay/MP detrás de PaymentGatewayPort

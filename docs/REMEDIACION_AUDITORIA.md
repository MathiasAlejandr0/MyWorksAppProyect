# Remediación auditoría

## Sprint 1 — Honestidad + UX
- [x] README MVP; demos; secrets; tokens; hero; strict TS

## Sprint 2 — Schema + SoT + job_detail
- [x] Baseline SQL; domain.ts; Vitest; job_detail 1403→398

## Sprint 3 — Drift + Riverpod + e2e + payment port
- [x] check-domain-drift; providers; Playwright; PaymentGatewayPort

## Sprint 4 — Gateway wired + más Riverpod + push port
- [x] EscrowCheckoutSheet → authorizeHold (MockPaymentGateway) + banner simulado
- [x] Riverpod en rating / statistics / job_schedule
- [x] PushNotificationPort + LocalOnlyPushNotifications (sin FCM aún)
- [x] Script `scripts/supabase-db-pull.ps1` (requiere `npx supabase login` del usuario)
- [ ] Ejecutar db pull autenticado y commitear dump oficial

## Pendiente (sprint 5+)
- [ ] Integrar FCM real detrás de PushNotificationPort
- [ ] Implementar Webpay/MP detrás de PaymentGatewayPort
- [ ] Migrar services singletons restantes a DI
- [ ] Codegen Dart desde domain.ts
- [ ] Design tokens package único

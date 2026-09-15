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

## Sprint 6b — Supabase link + dump oficial
- [x] Login CLI OK (`npx supabase login`)
- [x] Link a `wxqrfcqifkfgawrnqmnj` (MyWorksApp Proyect)
- [x] `migration list` → inventario en `supabase/MIGRATIONS_INVENTORY.md`
- [x] Script pull actualizado (detecta falta de Docker; usa `powershell -File`)
- [x] Dump SQL oficial: `myworksapp_app/supabase/schema_remote_dump.sql` (~45 KB, 28 tablas, ~75 policies)

## Sprint 7 — Hardening seguridad sin PSP
- [x] `shared/src/domain.ts` → valores BD en español (roles, jobs, payments, pricing, disputes)
- [x] `shared` index sin conflicto UserRole/DisputeStatus; tests node:test + scripts check/generate
- [x] Migración `20260915000001_hardening_seguridad_sin_psp.sql`: drop políticas EN legacy, anon solo marketplace, pagos/mensajes/trabajos endurecidos
- [x] RPC `transicionar_trabajo`, `simular_transicion_pago` (mock escrow), `registrar_evento_abuso`
- [x] PIN servicio sin backdoors 1234/0000 + tests Flutter
- [x] Desktop: CSP Tauri estricta, supabaseClient fail-fast, `canAccessDesktopHub`
- [x] Web e2e: CTA/AuthModal resiliente
- [x] Clientes Flutter: `PaymentRepository` / `JobRepository` → RPC (sin UPDATE directo de estado)
- [x] Eliminado `job_detail_controller.dart` muerto; tokens CSS en web; lints Flutter más estrictos
- [ ] **PSP diferido** (Webpay/MercadoPago): empresa no formada — mock server-enforced vía `simular_transicion_pago` hasta integrar PaymentGatewayPort real
- [ ] Aplicar migración en remoto (ver `docs/APLICAR_HARDENING_20260915.md`)

## Pendiente (post constitución / sprint 8+)
- [ ] Integrar Webpay/MP detrás de PaymentGatewayPort (cuando exista entidad legal + cuentas PSP)
- [ ] Migrar resto de singletons a DI (incremental)
- [ ] Integrar firebase_messaging detrás de PushNotificationPort

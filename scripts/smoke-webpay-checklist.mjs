#!/usr/bin/env node
/**
 * Smoke checklist Webpay (integration) — no automatiza tarjeta TBK (requiere UI humana).
 * Uso: node scripts/smoke-webpay-checklist.mjs
 *
 * Opcional con env:
 *   SUPABASE_URL, SUPABASE_ANON_KEY — ping health de functions
 */
const checks = [
  '1. Login cliente (app o web) con cuenta real/staging (no demo en release).',
  '2. Crear trabajo → Pagar con Webpay (embed: popup/WebView; invitado: redirect).',
  '3. Completar tarjeta de prueba Transbank (integration).',
  '4. Verificar pagos.estado = retenido y trabajos.estado_pago = retenido.',
  '5. Admin desktop → Liquidación → referencia bancaria → liberar.',
  '6. Verificar pagos.estado = liberado + fila en liquidaciones.',
  '7. (Opcional) webpay-refund con pago retenido de prueba.',
];

console.log('=== Smoke Webpay / Escrow / Liquidación ===\n');
for (const line of checks) console.log(line);

const url = process.env.SUPABASE_URL;
if (url) {
  console.log(`\nSUPABASE_URL detectada: ${url}`);
  console.log('Functions esperadas: webpay-create, webpay-handoff, webpay-commit, webpay-status, webpay-release, webpay-refund, guest-checkout');
} else {
  console.log('\n(Sin SUPABASE_URL — solo checklist impresa.)');
}

console.log('\nOK: checklist listo. Ejecuta los pasos en staging y marca CI cuando tengas evidencia.');

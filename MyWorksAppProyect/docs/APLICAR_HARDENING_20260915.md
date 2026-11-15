# Aplicar hardening 20260915 (sin PSP)

Migración: `myworksapp_app/supabase/migrations/20260915000001_hardening_seguridad_sin_psp.sql`

## Orden recomendado

1. Confirmar que ya corrieron (remoto o local):
   - `20260914000004_aplicar_rename_es.sql` (o equivalente rename ES)
   - `20260914000005_rls_politicas_negocio.sql`
   - `20260914000006_seed_servicios_marketplace.sql`
2. Regenerar dominio Dart y verificar drift (opcional pero recomendado):
   ```bash
   node scripts/generate-domain-dart.mjs
   node scripts/check-domain-drift.mjs
   ```
3. Aplicar la migración nueva:
   - **SQL Editor** (Supabase Dashboard): pegar el contenido completo del archivo y Execute, **o**
   - CLI: `npx supabase db push` / `migration up` con el proyecto linkeado.
4. Smoke post-apply:
   - Anon: `SELECT` en `servicios` / `trabajadores` OK; otras tablas denegadas.
   - Authenticated: no `UPDATE` directo en `pagos` ni `trabajos` (partes); usar RPC:
     - `transicionar_trabajo(p_trabajo_id, p_nuevo_estado, p_pin)`
     - `asignar_trabajador_trabajo(p_trabajo_id, p_trabajador_id)`
     - `rechazar_trabajo_pendiente(p_trabajo_id, p_metadatos)`
     - `simular_transicion_pago(p_pago_id, p_nuevo_estado)` — **mock escrow**, no cobro real.
     - `registrar_evento_abuso(...)`
5. Clientes: Flutter ya llama esas RPC desde `JobRepository` / `PaymentRepository`. Desplegar web/desktop con domain ES + PIN sin backdoors + CSP.

## Nota PSP

No integrar Webpay/MercadoPago hasta tener entidad legal y cuentas. El mock queda **solo en servidor** vía `simular_transicion_pago`.

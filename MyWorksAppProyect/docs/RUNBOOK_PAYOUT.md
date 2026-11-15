# Liquidación al profesional (payout)

## Hoy (opción 1 — manual)

1. Cliente paga con Webpay → `pagos.estado = retenido`.
2. Trabajo aprobado / disputa resuelta a favor del profesional.
3. Admin transfiere CLP **fuera de la app** (banco / transferencia).
4. En desktop → **Liquidación**: elige el pago retenido, ingresa referencia del comprobante, confirma.
5. Edge `webpay-release` marca `liberado` y escribe fila en `liquidaciones` (`proveedor=manual`).

```bash
cd myworksapp_app
npx supabase db query --linked -f supabase/migrations/20260923000001_liquidaciones_manuales.sql
# o db push cuando el historial remoto esté alineado
npx supabase functions deploy webpay-release
```

## Futuro (opción 2 — Khipu / Fintoc)

Cuando exista la empresa y contratos:

| Proveedor | Uso típico | Estado en código |
|-----------|------------|------------------|
| `manual` | Transferencia bancaria confirmada por admin | **Listo** |
| `khipu` | Payout / cobranza Chile | Stub (`provider_not_ready` 501) |
| `fintoc` | Movimientos / cuentas | Stub (`provider_not_ready` 501) |

API de liberación ya acepta `provider: "khipu" | "fintoc"` y responde 501 hasta conectar keys:

```bash
npx supabase secrets set KHIPU_RECEIVER_ID=...
npx supabase secrets set KHIPU_SECRET=...
# o
npx supabase secrets set FINTOC_SECRET_KEY=...
```

Implementación pendiente: rama en `webpay-release` que llame al PSP y guarde `referencia_transferencia` del PSP.

## Contrato shared

- `listHeldPayments`, `releaseEscrowManual`, `listLiquidaciones`, `getPayoutProviderStatus`
- Tests: `shared/src/payments/payout.test.ts`

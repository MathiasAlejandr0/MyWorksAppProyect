# Flip a producción Transbank (cuando exista la empresa)

## Estado actual

- Ambiente por defecto: **integration** (`TBK_ENV=integration`).
- Edge Functions: `webpay-create`, `webpay-handoff`, `webpay-commit`, `webpay-status`, `webpay-refund`, `webpay-release`, `guest-checkout`.
- Migración: `myworksapp_app/supabase/migrations/20260322000001_webpay_escrow_hardening.sql` (+ reaffirm `20260922`).
- Clientes **no** capturan PAN.

## Regla UX de presentación

| Quién | Presentación |
|-------|----------------|
| App móvil (sesión) | WebView in-app — no browser externo |
| Web con sesión | Ventana controlada Transbank — la SPA **no** hace `location.assign` |
| Web **sin** sesión (urgencia / visita) | Formulario (nombre, correo, teléfono, dirección) → **redirect** completo a Webpay |

## 1. Aplicar migración

```bash
cd myworksapp_app
npx supabase db push
# o aplicar el SQL en el SQL Editor del dashboard
```

## 2. Desplegar Edge Functions

```bash
cd myworksapp_app
npx supabase functions deploy webpay-create
npx supabase functions deploy webpay-handoff
npx supabase functions deploy webpay-commit
npx supabase functions deploy webpay-status
npx supabase functions deploy webpay-refund
npx supabase functions deploy webpay-release
npx supabase functions deploy guest-checkout
```

## 3. Secrets (integración → producción)

```bash
npx supabase secrets set TBK_ENV=integration
npx supabase secrets set WEBPAY_HANDOFF_SECRET=<random-32-chars>
npx supabase secrets set WEBPAY_RETURN_URL=https://<project>.supabase.co/functions/v1/webpay-commit
# Opcional:
# npx supabase secrets set CORS_ALLOWED_ORIGINS=https://app.myworksapp.cl,http://localhost:5173
# npx supabase secrets set WEBPAY_ALLOWED_RETURN_ORIGINS=https://app.myworksapp.cl
```

Cuando Transbank entregue comercio real:

```bash
npx supabase secrets set TBK_ENV=production
npx supabase secrets set TBK_COMMERCE_CODE=<codigo_comercio>
npx supabase secrets set TBK_API_KEY=<api_key_secreta>
npx supabase secrets set WEBPAY_RETURN_URL=https://<project>.supabase.co/functions/v1/webpay-commit
npx supabase secrets set WEBPAY_WEB_RETURN_URL=https://app.myworksapp.cl/?pago=ok
npx supabase secrets set WEBPAY_APP_RETURN_URL=myworksapp://pago/retorno
```

## 4. Clientes

- Web: `VITE_PAYMENTS_MODE=production`
- Flutter release: `--dart-define=PAYMENTS_MODE=production`
- Nunca poner `TBK_API_KEY` en apps.

## 5. Checklist smoke

1. Login cliente real (sin demo123 en release).
2. Crear trabajo → “Pagar con Webpay” (ventana/WebView; SPA/app no navega fuera).
3. Invitado web: datos + dirección → redirect Transbank → retorno `?pago=ok`.
4. Verificar fila `pagos.estado` = `retenido`.
5. Admin libera con `webpay-release` / `liberar_escrow` tras trabajo completado.

## 6. Seguridad post-lanzamiento

- Rotar cuentas demo del proyecto staging; no usarlas en prod.
- Confirmar RLS: `simular_transicion_pago` sin EXECUTE para `authenticated`.
- CSP web activa (`index.html` + `public/_headers`).

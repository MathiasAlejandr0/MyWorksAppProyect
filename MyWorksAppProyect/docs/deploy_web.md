# Web de clientes: despliegue y configuración vigente

La guía de configuración sigue siendo la del 20 de noviembre de 2026. El 22-11-2026 `main` está en `a5f2f7d` y https://myworksapp.cl todavía servía el paquete anterior (última modificación de la portada a las 20:24, hora de Chile). Publicar ese `main` es un `npx vercel --prod` con la cuenta del proyecto `myworksapp`. Esta guía no contiene secretos.

## Dónde está publicada

| Qué | Valor |
|---|---|
| Hosting | Vercel, proyecto `myworksapp` |
| Producción | https://myworksapp.cl y https://www.myworksapp.cl. También responde https://myworksapp-cl.vercel.app |
| Canónico del HTML | El apex `https://myworksapp.cl` |
| DNS | Cloudflare (zona `myworksapp.cl`) |
| Orígenes aceptados por las Edge Functions | `https://myworksapp.cl`, `https://www.myworksapp.cl` y `https://myworksapp-cl.vercel.app`, más `CORS_ALLOWED_ORIGINS` (`_shared/cors_origin.ts`) |
| Cabeceras | HSTS de 180 días con `includeSubDomains` (sin `preload`), CSP, `X-Frame-Options: DENY`, `nosniff` y `Permissions-Policy` (`myworksapp_web/vercel.json`) |

## Turnstile (Cloudflare)

- El widget aparece en el registro (`AuthModal.tsx`) y en la compra como invitado (`GuestCheckoutForm.tsx`).
- `guest-checkout` valida el token en el servidor con `turnstileDecision`. Si falta `TURNSTILE_SECRET_KEY` responde 503 y no crea la cuenta ni el pago, con cualquier `TBK_ENV`. La única excepción es el flag `MWA_ALLOW_NO_CAPTCHA=1`, pensado para una base local; no debe existir en el proyecto publicado.
- En el build de producción, si `VITE_TURNSTILE_SITE_KEY` es una clave de prueba de Cloudflare (lista en `turnstileSitePolicy.ts`) o no existe, el widget no se monta.
- `VITE_TURNSTILE_SITE_KEY` (Vercel) y `TURNSTILE_SECRET_KEY` (secretos de Edge Functions) están configurados para `myworksapp.cl`.
- **El captcha de Supabase Auth no está activado.** Activarlo rompería hoy el login de la app y de la consola y la recuperación de clave, que no envían token. Mientras siga apagado, el token que la web manda en el registro no se valida en el servidor.

## Correo

- Supabase Auth envía por el SMTP de Resend. Dominio verificado con DKIM y SPF en `send.myworksapp.cl`, región sa-east-1, plan gratis de 100 correos al día.
- Remitente `no-responder@myworksapp.cl`. 13 plantillas en español: confirmación, enlace mágico, recuperación, invitación, cambio de correo, reautenticación y los avisos de contraseña cambiada, correo cambiado, teléfono cambiado, factor MFA agregado o quitado e identidad vinculada o desvinculada.
- `site_url` de Auth: `https://myworksapp.cl`.
- El formulario de registro tiene «Reenviar» con una espera de 60 segundos.
- `soporte@myworksapp.cl` reenvía con Cloudflare Email Routing: falta la prueba de punta a punta.
- Desde el PR #82 (20-nov) las Edge Functions envían correos transaccionales con Resend: pago recibido (al cliente y al profesional), alta de invitado («define tu contraseña»), reembolso y pago liberado, con un diseño común (`_shared/email_layout.ts`, `email_send.ts` y `payment_mail.ts`). Usan los secretos `RESEND_API_KEY` y `RESEND_FROM`; sin ellos no envían y el pago sigue. No escriben a cuentas demo.
- La invitación de colaboradores por Resend **no está activa**: falta el secreto `INVITE_PROVIDER=resend`. Hoy sale por Supabase Auth.

## Apple y Google

El botón de Apple se muestra solo si `auth/v1/settings` trae `external.apple = true` y Vercel tiene `VITE_AUTH_APPLE_ENABLED=1`. Si la consulta falla, no se muestra. Google se muestra solo si `external.google` es true. Ninguna de esas claves está en el repositorio.

## Migraciones de la web (aplicadas en vivo según el reporte del 20-nov)

1. `20261120140000_ocultar_profesionales_demo.sql`: marca `es_demo` en las cuentas `@demo.myworksapp.cl` y `@demo.com`. Con `app_config.demo_modo = 1`, el valor en vivo, siguen visibles en el catálogo; con otro valor se ocultan y no se pueden reservar ni cobrar.
2. `20261120150000_rate_limit_global.sql`: tabla `rate_limit_ventana` y `rate_limit_consumir`, solo para `service_role`.
3. `20261120160000_perfil_publico_profesional.sql`: perfil, horario y reseñas públicas (CU-06), sin abrir `calificaciones` a `anon`.
4. `20261120170000_derechos_y_cobro_extra.sql`: `exportar_mis_datos`, `solicitar_eliminacion_cuenta`, tabla `direcciones_cliente` y `rechazar_orden_cambio` (CU-04 y CU-15).

Las pruebas `supabase/tests/ocultar_profesionales_demo.sql` y `supabase/tests/rate_limit_global.sql` corren en una base local y terminan en `ROLLBACK`.

## Edge Functions que usa la web

Llamadas desde `myworksapp_web/src` o `shared/src`: `guest-checkout`, `definir-clave-invitado`, `webpay-create`, `webpay-handoff`, `webpay-commit`, `webpay-status`, `oneclick-charge` y `webpay-refund-cancellation`. `guest-checkout`, `definir-clave-invitado`, `webpay-create` y `oneclick-charge` usan el límite de tasa global.

## Pendiente

- Textos de términos, privacidad y aviso legal: están en `main` desde el 22-11-2026. El sitio publicado ese día todavía servía el paquete anterior.
- HSTS `preload`: no se agrega.
- Medir Lighthouse sobre el dominio propio.
- Probar a mano el registro: con Turnstile no se puede automatizar.

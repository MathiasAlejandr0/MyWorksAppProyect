# Web de clientes: lo que el código exige y lo que falta configurar

El sitio publicado hoy es https://myworksapp-cl.vercel.app. El dominio `myworksapp.cl` no se usa en el código: no resuelve. Esta guía describe el comportamiento actual del código. No configura Vercel, Supabase, SMTP, Apple ni Turnstile.

## Turnstile

`guest-checkout` llama a `turnstileDecision`. Si no existe `TURNSTILE_SECRET_KEY`, responde 503 y no crea la cuenta ni el pago. Da igual el valor de `TBK_ENV`. La única excepción es el flag explícito `MWA_ALLOW_NO_CAPTCHA=1`, pensado para una base local.

En el build de producción (`import.meta.env.PROD`), si `VITE_TURNSTILE_SITE_KEY` es una clave de prueba de Cloudflare (`1x00000000000000000000AA` y las otras de la lista en `turnstileSitePolicy.ts`), el widget no se monta y la consola deja un error. Sin clave, el widget tampoco se monta.

Falta que ponga Mathias, fuera de este repositorio:

1. Site key real en Vercel: `VITE_TURNSTILE_SITE_KEY`.
2. Secret real en los secretos de las Edge Functions: `TURNSTILE_SECRET_KEY`.
3. Captcha protection de Supabase Auth, con el mismo secret, para el registro y la recuperación.
4. No definir `MWA_ALLOW_NO_CAPTCHA` en el proyecto publicado.

## Correo

El código no configura SMTP. El formulario de registro tiene «Reenviar» con una espera de 60 segundos. La entrega del mensaje depende del SMTP de Supabase Auth, que hoy no está documentado como propio en este repositorio.

Cuando Mathias lo configure:

1. Host, puerto, usuario y contraseña en Authentication → SMTP Settings.
2. SPF, DKIM y DMARC del dominio del remitente.
3. Redirect URLs solo de `https://myworksapp-cl.vercel.app` y de los preview que autorice.
4. Probar a mano el registro, la recuperación de contraseña y la clave después de pagar como invitado.

## Apple

El botón se muestra solo si `auth/v1/settings` trae `external.apple = true` y Vercel tiene `VITE_AUTH_APPLE_ENABLED=1`. Si la consulta falla, no se muestra. Google se muestra solo si `external.google` es true. Ninguna de esas claves está en el repositorio.

## Migraciones de esta rama (no aplicadas)

Aplicar en este orden, antes de desplegar las Edge Functions que las usan:

1. `20261120140000_ocultar_profesionales_demo.sql`
2. `20261120150000_rate_limit_global.sql`
3. `20261120160000_perfil_publico_profesional.sql`
4. `20261120170000_derechos_y_cobro_extra.sql`

No usar `20261120120000` ni `20261120130000`. Las pruebas `supabase/tests/ocultar_profesionales_demo.sql` y `supabase/tests/rate_limit_global.sql` corren en una base local y terminan en `ROLLBACK`.

## HSTS

El sitio sigue en `myworksapp-cl.vercel.app`. No se agrega `preload` ni se sube el max-age a un año: eso queda para cuando el dominio definitivo responda.

## Lo que hay que desplegar después de aplicar las migraciones

`guest-checkout`, `definir-clave-invitado`, `webpay-create` y `oneclick-charge`. No se despliegan desde esta rama. No se tocan `webpay-release`, `webpay-resolve-dispute` ni `invitar-colaborador`.

## Lo que este cambio no hace

No despliega la web ni las Edge Functions, no aplica SQL, no cambia la comisión y no escribe secretos.

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

## Migraciones de esta rama (no aplicadas)

Hay que revisarlas y aplicarlas en este orden, antes de desplegar las Edge Functions que las llaman:

1. `20261120140000_ocultar_profesionales_demo.sql`
2. Las que se sumen después en esta misma rama, con versión `20261120140000` o mayor, y nunca `20261120120000` ni `20261120130000`.

La prueba `supabase/tests/ocultar_profesionales_demo.sql` se corre en una base local y termina en `ROLLBACK`. No se ejecuta contra producción desde aquí.

## Lo que este cambio no hace

No despliega la web ni las Edge Functions, no aplica SQL, no cambia la comisión y no escribe secretos.

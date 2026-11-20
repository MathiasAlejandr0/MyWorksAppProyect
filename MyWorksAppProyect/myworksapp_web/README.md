# Web de clientes

Sitio para que los clientes busquen, reserven, paguen y sigan su pedido. Hecho con React 19 y Vite 8. Es parte del monorepo [`MyWorksAppProyect/`](../README.md); el índice de toda la documentación está en [`docs/INDICE.md`](../../docs/INDICE.md).

## Contenido

- [Dónde está publicada](#dónde-está-publicada)
- [Páginas](#páginas)
- [Correo y cuenta](#correo-y-cuenta)
- [Pendiente](#pendiente)
- [Cómo correrla](#cómo-correrla)

## Dónde está publicada

https://myworksapp.cl y `www.myworksapp.cl`, en Vercel (proyecto `myworksapp`). También responde https://myworksapp-cl.vercel.app. El despliegue se explica en [`../docs/deploy_web.md`](../docs/deploy_web.md).

## Páginas

Las rutas están en `src/routing/paths.ts`: `/`, `/servicios`, `/servicios/:categoria`, `/profesional/:id`, `/pedido/:id`, `/pago/retorno`, `/cuenta`, `/trabaja`, `/terminos`, `/privacidad` y `/encuesta`. Cualquier otra muestra el 404.

- `/profesional/:id`: perfil público con horario y reseñas (`perfil_publico_profesional`, `resenas_publicas_profesional`, `horario_publico_profesional`).
- `/cuenta`: direcciones guardadas (`direcciones_cliente`), exportar mis datos (`exportar_mis_datos`) y pedir la eliminación de la cuenta (`solicitar_eliminacion_cuenta`).

## Correo y cuenta

- El correo de confirmación del alta vuelve al mismo sitio desde el que se registró la persona (`emailRedirectTo` con el origen de la página, PR #82). La recuperación de clave vuelve a `/?restablecer=1`.
- Si el enlace se abre en otro navegador, la web avisa que debe abrirse en el mismo (PKCE).
- Los correos de pago recibido, alta de invitado, reembolso y pago liberado los envían las Edge Functions, no la web.

## Pendiente

- `/terminos` y `/privacidad` dicen que el texto oficial todavía no está publicado. Los textos y `/aviso-legal` están en la rama `cursor/aviso-academico-duoc-v2`, **sin merge**.
- Turnstile aparece en el registro y en la compra como invitado. Solo `guest-checkout` lo valida en el servidor; en el registro la validación depende del captcha de Supabase Auth, que no está activado.

## Cómo correrla

```bash
npm install
npm run dev
npm run build
npm run lint
npm test --prefix ../shared
npm run test:e2e
```

Las variables `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` y `VITE_TURNSTILE_SITE_KEY` no van en el repositorio.

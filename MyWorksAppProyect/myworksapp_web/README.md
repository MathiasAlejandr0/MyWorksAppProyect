# Web de clientes

React 19 y Vite 8. Producción: https://myworksapp.cl y `www.myworksapp.cl` en Vercel (proyecto `myworksapp`). También responde https://myworksapp-cl.vercel.app.

Rutas (`src/routing/paths.ts`): `/`, `/servicios`, `/servicios/:categoria`, `/profesional/:id`, `/pedido/:id`, `/pago/retorno`, `/cuenta`, `/trabaja`, `/terminos`, `/privacidad`, `/encuesta`. Cualquier otra muestra el 404.

- `/profesional/:id`: perfil público con horario y reseñas (`perfil_publico_profesional`, `resenas_publicas_profesional`, `horario_publico_profesional`).
- `/cuenta`: direcciones guardadas (`direcciones_cliente`), exportar mis datos (`exportar_mis_datos`) y pedir la eliminación de la cuenta (`solicitar_eliminacion_cuenta`).
- `/terminos` y `/privacidad`: hoy dicen que el texto oficial todavía no está publicado. Los textos y `/aviso-legal` están en la rama `cursor/aviso-academico-duoc-v2`, **sin merge**.
- Turnstile aparece en el registro y en la compra como invitado. Solo `guest-checkout` lo valida en el servidor; en el registro la validación dependería del captcha de Supabase Auth, que no está activado.

```bash
npm install
npm run dev
npm run build
npm run lint
npm test --prefix ../shared
npm run test:e2e
```

Las variables `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` y `VITE_TURNSTILE_SITE_KEY` no van en el repositorio. El detalle del despliegue está en `../docs/deploy_web.md`.

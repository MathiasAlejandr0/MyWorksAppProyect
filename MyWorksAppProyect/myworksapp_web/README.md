# Web de clientes

React 19 y Vite. El sitio publicado es https://myworksapp-cl.vercel.app.

Rutas: `/`, `/servicios`, `/servicios/:categoria`, `/profesional/:id`, `/pedido/:id`, `/pago/retorno`, `/cuenta`, `/trabaja`, `/terminos`, `/privacidad`, `/encuesta`. Cualquier otra muestra el 404.

```bash
npm install
npm run dev
npm run build
npm run lint
npm test --prefix ../shared
npm run test:e2e
```

Las variables `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` y `VITE_TURNSTILE_SITE_KEY` no van en el repositorio. El detalle de lo que falta configurar está en `../docs/deploy_web.md`.

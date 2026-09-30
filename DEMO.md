# Demo en vivo — MyWorksApp

Guion para mostrar el marketplace con datos de prueba en el proyecto Supabase `wxqrfcqifkfgawrnqmnj`. Transbank queda en **integración**. No hay datos de producción.

El flujo de un pedido nuevo (pagar, aceptar, ir en camino, conformidad) se hace el día de la demo. El seed deja pedidos ya avanzados para que el mapa, el chat, las métricas y la disputa no partan vacíos.

## 1. Qué aplicar en la base, en este orden

En el SQL Editor del proyecto (no hace falta repetir migraciones ya aplicadas; la última aplicada es `20261005000001_verificacion_profesional`):

1. `myworksapp_app/supabase/migrations/20261006000001_gps_y_base_profesional.sql`
2. `myworksapp_app/supabase/migrations/20261007000001_rls_indices_asesores.sql`
3. `scripts/demo/seed_demo.sql`

`20261007` no revoca `EXECUTE`. Ese cierre lo estás aplicando aparte; cuando pases el SQL, se commitea tal cual, sin duplicarlo.

## 2. Edge Functions

No desplegar `webpay-create-transaction` ni `webpay-commit-transaction`. No están en el repo y ningún cliente las llama. El camino vigente es `webpay-create` y `webpay-commit`.

Desplegar la que aún no está en el proyecto:

```bash
cd myworksapp_app
npx supabase functions deploy invitar-colaborador --project-ref wxqrfcqifkfgawrnqmnj
```

Secretos de esa función:

| Secreto | Para la demo |
|---|---|
| `INVITE_PROVIDER` | `supabase` (por defecto). El correo sale por el SMTP de Auth. |
| `RESEND_API_KEY` y `RESEND_FROM` | Solo si `INVITE_PROVIDER=resend`. |
| `INVITE_REDIRECT_URL` | Opcional. Ej. `http://localhost:5173`. |

Secretos de pago (integración, no producción):

```bash
npx supabase secrets set TBK_ENV=integration --project-ref wxqrfcqifkfgawrnqmnj
npx supabase secrets set WEBPAY_HANDOFF_SECRET=<cadena-aleatoria-de-32-o-mas> --project-ref wxqrfcqifkfgawrnqmnj
npx supabase secrets set WEBPAY_RETURN_URL=https://wxqrfcqifkfgawrnqmnj.supabase.co/functions/v1/webpay-commit --project-ref wxqrfcqifkfgawrnqmnj
npx supabase secrets set WEBPAY_ALLOWED_RETURN_ORIGINS=http://localhost:5173,http://127.0.0.1:5173 --project-ref wxqrfcqifkfgawrnqmnj
```

Si `TBK_COMMERCE_CODE` y `TBK_API_KEY` no están definidos y `TBK_ENV` no es `production`, la función usa el comercio público de integración de Transbank (`597055555532`). No pongas esas claves en la web, el escritorio ni Flutter.

Funciones de pago que ya deben estar desplegadas (volver a desplegar solo si cambiaste su código): `webpay-create`, `webpay-commit`, `webpay-handoff`, `webpay-status`, `webpay-refund`, `webpay-refund-cancellation`, `webpay-refund-rejection`, `webpay-release`, `webpay-resolve-dispute`, `guest-checkout`, `oneclick-charge`, `oneclick-return`, `oneclick-handoff`.

## 3. Cuentas (contraseña `Demo2026!` en todas)

| Quién | Correo | Rol |
|---|---|---|
| Cliente | `camila.soto@demo.myworksapp.cl` | usuario |
| Cliente | `andres.pizarro@demo.myworksapp.cl` | usuario |
| Gasfíter, Providencia | `pedro.rojas@demo.myworksapp.cl` | trabajador verificado |
| Electricista, Las Condes | `maria.fuentes@demo.myworksapp.cl` | trabajador verificado |
| Pintor, La Florida | `jose.munoz@demo.myworksapp.cl` | trabajador verificado |
| Maestro, Maipú | `tomas.herrera@demo.myworksapp.cl` | trabajador verificado |
| Aseo, Ñuñoa | `ana.vidal@demo.myworksapp.cl` | trabajador verificado |
| Gasfíter en revisión, Santiago | `luis.contreras@demo.myworksapp.cl` | trabajador, no disponible |
| Admin escritorio | `admin.ops@demo.myworksapp.cl` | administrador |

El escritorio pide un segundo factor la primera vez: escanea el QR con una app de códigos (Authenticator o similar) y guarda ese dispositivo para la demo.

## 4. Tarjetas Transbank (integración)

En `https://webpay3gint.transbank.cl` cualquier fecha futura sirve. CVV `123` (American Express `1234`).

| Resultado | Marca | Número |
|---|---|---|
| Aprobada | Visa | `4051885600446623` |
| Aprobada | Mastercard | `5186059559590568` |
| Aprobada | Redcompra | `4051884239937763` |
| Aprobada | American Express | `370000000002032` |

En la página de autenticación de prueba: RUT `11.111.111-1`, clave `123`.

El commit deja el pago `retenido` en la base. **Recibo conforme** (web, en el seguimiento, o app) llama a `cerrar_trabajo_conforme` y el ledger pasa a `liberado`. Eso no es un segundo cargo. El reembolso de una disputa lo hace el admin con la función `webpay-resolve-dispute`.

## 5. Cómo levantar cada cliente

Clave publicable (no es la `service_role`): la misma que ya usa la app en debug. En release hay que pasarla con `--dart-define`. No la copies a un ticket.

Web:

```bash
cd myworksapp_web
printf '%s\n' 'VITE_SUPABASE_URL=https://wxqrfcqifkfgawrnqmnj.supabase.co' 'VITE_SUPABASE_ANON_KEY=<clave-publicable>' > .env.local
npm install
npm run dev
```

Abre `http://localhost:5173`.

Escritorio (hace falta Rust estable; el Cargo 1.83 del sistema no compila crates `edition2024`):

```bash
cd myworksapp_desktop
printf '%s\n' 'VITE_SUPABASE_URL=https://wxqrfcqifkfgawrnqmnj.supabase.co' 'VITE_SUPABASE_ANON_KEY=<clave-publicable>' > .env.local
npm install
npm run tauri:dev
```

Android (emulador o dispositivo con depuración USB):

```bash
cd myworksapp_app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://wxqrfcqifkfgawrnqmnj.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<clave-publicable>
```

En debug, si omites los `dart-define`, la app usa el proyecto de demo y la clave publicable que ya está en `lib/core/config/supabase_config.dart`. Un release sin esos defines se detiene a propósito.

## 6. Guion (unos 20 minutos)

### Cliente en la web — pedido nuevo

1. Entra como Camila.
2. **Buscar servicio** → **Plomería**. En el mapa está Pedro Rojas, pin en Providencia (no un punto inventado en Las Condes).
3. Elige a Pedro → **Continuar con la reserva**. Con sesión, el cobro usa la tarjeta inscrita o Webpay. Sin sesión, el formulario pide nombre, correo, teléfono y dirección, y no pide el número de tarjeta.
4. Paga con la Visa de prueba. Al volver, el trabajo queda pendiente y el pago `retenido`.

### Profesional en la app — aceptar y GPS

1. En el teléfono, entra como Pedro.
2. Abre el pedido pendiente de Camila y acéptalo.
3. **Voy en camino**. Acepta la ubicación solo en primer plano. El punto se publica como máximo cada 20 s o 40 m.
4. En la web, Camila abre el seguimiento: el pin del profesional se mueve y la llegada es una estimación a 28 km/h.
5. En el teléfono, pasa el trabajo a **en curso**. El GPS sigue mientras la app está abierta.
6. Escribe en el chat. Camila lo ve en la web (**Abrir chat**).

Para no depender del GPS del salón, el seed ya trae `demo-job-en-camino`: Camila puede abrir ese pedido en la app y ver a Pedro sobre el mapa, cerca de Irarrázaval.

### Conformidad y liberación

1. El pedido `demo-job-conforme` (Ana Vidal, aseo en Ñuñoa) está en `esperando_aprobacion_cliente` con pago retenido.
2. Camila lo abre en la app y toca **Recibo conforme**. En la web, el mismo botón aparece en el seguimiento cuando el pedido actual está en ese estado (el panel se refresca cada 8 s).
3. El trabajo pasa a completado y el pago a `liberado`.

### Escritorio

1. Entra como `admin.ops@demo.myworksapp.cl` y completa el segundo factor.
2. **Verificación:** Luis Contreras está `en_revision`. Apruébalo.
3. **Soporte:** disputa `demo-disputa-1` (Camila, trabajo eléctrico a medias). Ciérrala desde el panel; el dinero no se mueve solo mientras sigue abierta.
4. **Panel ejecutivo:** hay cobros retenidos y uno liberado (el muro de Tomás). Se ven GMV, comisión 15 %, completados, ticket y CSAT. En un rango sin datos el texto es «Sin cobros» o «Sin calificaciones».
5. **RRHH:** invita un correo de prueba. Si Auth no tiene SMTP, la pantalla muestra el error de la función; no inventa un envío.

## 7. Pedidos que deja el seed

| Id | Estado | Para mostrar |
|---|---|---|
| `demo-job-pendiente` | pendiente | Pedro recibe el pedido de Camila |
| `demo-job-aceptado` | aceptado | María ya aceptó a Andrés |
| `demo-job-en-camino` | en camino + GPS | Pin en vivo sin caminar de verdad |
| `demo-job-en-curso` | en curso + chat | Andrés y José |
| `demo-job-conforme` | esperando conformidad | Botón Recibo conforme |
| `demo-job-cerrado` | completado, pago liberado, nota 5 | Métricas |
| `demo-job-disputa` | en curso + disputa abierta | Escritorio |

Volver a correr `scripts/demo/seed_demo.sql` repone esos pedidos y la contraseña `Demo2026!`. No borra otras filas.

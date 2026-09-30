# Demo en vivo — MyWorksApp

Guion para mostrar el marketplace con datos de prueba en el proyecto Supabase `wxqrfcqifkfgawrnqmnj`. Transbank queda en **integración**. No hay datos de producción.

El flujo de un pedido nuevo (pagar, aceptar, ir en camino, conformidad) se hace el día de la demo. El seed deja pedidos ya avanzados para que el mapa, el chat, las métricas y la disputa no partan vacíos.

## 1. Qué aplicar en la base, en este orden

En el SQL Editor del proyecto. Ya están aplicadas, con otros nombres de versión en `supabase_migrations.schema_migrations`:

- `security_lockdown_rpc` y `security_lockdown_rpc_repo_sync` (repo: `20261005000002_security_lockdown_rpc.sql`)
- `gps_y_base_profesional` (`20261006000001`)
- `ocultar_pin_listados` (`20261006000002`)
- `rls_indices_asesores` (`20261007000001`)
- `rpc_uuid_trabajador` (`20261007000002`)
- `perfiles_rol_service_role` (`20261007000003`)
- `quitar_indices_fk_duplicados` (`20261007000004`)
- el seed `scripts/demo/seed_demo.sql`
- `20261008000001_cerrar_brechas_rls.sql` (ya en vivo, con la política de contraparte, la vista sin escritura anónima y las políticas de trabajadores, impulsos y errores)

Falta aplicar, en este orden, antes de la demo:

1. `myworksapp_app/supabase/migrations/20261008000002_perfiles_publicos_rpc.sql`
2. `myworksapp_app/supabase/migrations/20261008000003_origen_retorno_pago.sql`
3. `myworksapp_app/supabase/migrations/20261008000004_disputas_partes.sql`
4. Volver a correr `scripts/demo/seed_demo.sql` (deja no disponibles a Ana Volt, Marcelo Rivas, Pablo Maestro, Carolina Brillo y María Limpieza, y exige un demo verificado por categoría).

Después corre `docs/PRUEBAS_RLS_20261008.sql` en el SQL Editor. Tiene que terminar en `RLS 20261008 ok`.

### Antes de un `supabase db push`

El historial en vivo no usa los timestamps del repo. Un push intentaría volver a correr archivos que ya están aplicados y chocaría con las versiones de nombre corto. Primero mira las versiones reales:

```sql
SELECT version, name
FROM supabase_migrations.schema_migrations
ORDER BY version;
```

Para cada archivo local cuyo SQL ya está en la base, marca esa versión local como aplicada (no borres las filas de nombre corto):

```bash
cd myworksapp_app
npx supabase migration repair --status applied 20261005000002 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261006000001 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261006000002 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261007000001 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261007000002 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261007000003 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261007000004 --project-ref wxqrfcqifkfgawrnqmnj
```

`20261008000001` ya está aplicada: no la vuelvas a correr. Repara `20261008000002`, `20261008000003` y `20261008000004` solo después de aplicarlas. Si el dashboard muestra otra cadena de versión, usa esa en `migration repair` y no la de esta lista. No hagas push a `main`.

## 2. Edge Functions

No desplegar `webpay-create-transaction` ni `webpay-commit-transaction`. No están en el repo y ningún cliente las llama. El camino vigente es `webpay-create` y `webpay-commit`.

Volver a desplegar `invitar-colaborador`: ahora muestra el error si no puede dejar el perfil en `administrador`.

```bash
cd myworksapp_app
npx supabase functions deploy invitar-colaborador --project-ref wxqrfcqifkfgawrnqmnj
```

Secretos de esa función:

| Secreto | Para la demo |
|---|---|
| `INVITE_PROVIDER` | `supabase` (por defecto). El correo sale por el SMTP de Auth. |
| `RESEND_API_KEY` y `RESEND_FROM` | Solo si `INVITE_PROVIDER=resend`. |
| `INVITE_REDIRECT_URL` | `http://127.0.0.1:3001` (consola de escritorio). Ahí la persona invitada elige su contraseña antes del segundo factor. |

Secretos de pago (integración, no producción):

```bash
npx supabase secrets set TBK_ENV=integration --project-ref wxqrfcqifkfgawrnqmnj
npx supabase secrets set WEBPAY_HANDOFF_SECRET=<cadena-aleatoria-de-32-o-mas> --project-ref wxqrfcqifkfgawrnqmnj
npx supabase secrets set WEBPAY_RETURN_URL=https://wxqrfcqifkfgawrnqmnj.supabase.co/functions/v1/webpay-commit --project-ref wxqrfcqifkfgawrnqmnj
npx supabase secrets set WEBPAY_ALLOWED_RETURN_ORIGINS=http://localhost:5173,http://127.0.0.1:5173 --project-ref wxqrfcqifkfgawrnqmnj
```

Si `TBK_COMMERCE_CODE` y `TBK_API_KEY` no están definidos y `TBK_ENV=integration` (o la variable no está definida), la función usa el comercio público de integración de Transbank (`597055555532`). Oneclick Mall usa `597055555541` y la tienda `597055555542` (la tienda 2 oficial es `597055555543`). En `production`, si falta un secreto, la función falla. No pongas esas claves en la web, el escritorio ni Flutter.

`WEBPAY_WEB_RETURN_URL` no hace falta para la demo. `webpay-create` y `guest-checkout` guardan el Origin del navegador (`http://localhost:5173` o `http://127.0.0.1:5173` en integración, o lo que esté en `WEBPAY_ALLOWED_RETURN_ORIGINS` / `CORS_ALLOWED_ORIGINS`) y `webpay-commit` vuelve ahí.

El handoff ya no manda un HTML con auto-POST: Transbank recibe el token por GET (303). Hay que volver a desplegar:

`webpay-handoff`, `oneclick-handoff`, `webpay-commit`, `webpay-create`, `guest-checkout`, `definir-clave-invitado`.

```bash
cd myworksapp_app
npx supabase functions deploy webpay-handoff --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy oneclick-handoff --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy webpay-commit --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy webpay-create --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy guest-checkout --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy definir-clave-invitado --project-ref wxqrfcqifkfgawrnqmnj
```

`definir-clave-invitado` no pide JWT. Firma el alta con `WEBPAY_HANDOFF_SECRET` y guarda la clave con la API de admin, sin SMTP.

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

Registro (web y app) y cambio de clave piden al menos 8 caracteres, con una letra y un número. El login de estas cuentas no cambia: `Demo2026!` ya cumple. La misma regla está en `myworksapp_app/supabase/config.toml` (`minimum_password_length = 8`, `password_requirements = "letters_digits"`). Ese archivo no modifica el proyecto en la nube: en el dashboard, Authentication → Password, deja el mínimo en 8 y el requisito en letras y dígitos. Hasta que lo guardes ahí, el servidor puede aceptar una clave más débil; las pantallas de la demo ya no.

La invitación de RRHH abre la consola y pide esa contraseña antes del segundo factor. Si el enlace cae en otro puerto, la persona no ve esa pantalla.

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
3. Elige a Pedro → **Continuar con la reserva**. Con sesión y tarjeta inscrita en la app, se cobra Oneclick. Con sesión y sin tarjeta, el sitio abre Webpay Plus (la tarjeta se escribe en Transbank, el mismo escrow retenido). Sin sesión, el formulario pide nombre, correo, teléfono y dirección, y no pide el número de tarjeta.
4. Paga con la Visa de prueba. Transbank vuelve a `http://localhost:5173/?pago=ok&paymentId=…&jobId=…`. El trabajo queda pendiente y el pago `retenido`. Si el pago fue de invitado, la misma URL trae `invitado=1` y un token `alta`: la web muestra **Crea tu contraseña** (mínimo 8, letra y número) sin correo.

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

Volver a correr `scripts/demo/seed_demo.sql` repone esos pedidos y la contraseña `Demo2026!`. No borra otras filas. Deja `disponible = 0` en todo trabajador cuyo correo no termina en `@demo.myworksapp.cl`.

## 8. Plan B

Si algo del pago en vivo se traba, no improvises producción.

| Qué falló | Qué hacer |
|---|---|
| La página de Transbank muestra HTML crudo | Falta redesplegar `webpay-handoff` y `oneclick-handoff`. El 303 tiene que ir a `webpay3gint.transbank.cl` con `token_ws` o `TBK_TOKEN` en la query. |
| Al volver caes en otro puerto o en una página en blanco | El checkout tiene que abrirse en `http://localhost:5173` o `http://127.0.0.1:5173`. Esos orígenes se guardan en `pagos.origen_retorno` después de `20261008000003`. |
| 401 de Transbank | `TBK_ENV=integration` y sin secretos de comercio: la llave pública oficial ya está en el código. Redesplega las funciones de pago si el 401 sigue. |
| Camila no puede pagar sin tarjeta en la app | Con sesión, **Confirmar pedido** abre Webpay Plus. No hace falta inscribir la tarjeta antes. |
| El invitado no ve «Crea tu contraseña» | La URL tiene que traer `invitado=1` y `alta`. Hace falta `WEBPAY_HANDOFF_SECRET` y la función `definir-clave-invitado`. Sin ese secreto, el pago igual queda retenido; la cuenta entra después solo si Auth tiene SMTP de recuperación. |
| El catálogo muestra Ana Volt u otros nombres que no son `@demo` | Vuelve a correr el seed. Esos perfiles quedan no disponibles. |
| La disputa no se abre | Aplica `20261008000004`. Cliente y profesional usan **Abrir disputa**; el comentario va por `comentar_disputa`. Resolver solo desde el escritorio admin. |
| El mapa no tiene GPS del salón | Abre en la app el pedido `demo-job-en-camino` (Camila y Pedro, Irarrázaval). |
| El segundo factor del escritorio no está a mano | Entra con el dispositivo que ya escaneó el QR. No desactives MFA en la demo. |

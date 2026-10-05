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
- `20261008000001_cerrar_brechas_rls.sql` (ya en vivo)
- `20261008000002` a `20261008000006` (ya en vivo: perfiles públicos, origen de retorno, disputas, precios, pagos abandonados)
- `20261008000007_trabajadores_update_por_columna.sql` (ya en vivo: `REVOKE UPDATE` de tabla y `GRANT UPDATE` por columna, salvo calificación y verificación)
- `20261008000008_trabajos_insert_sin_recursion.sql` (ya en vivo: `trabajador_reservable` y `trabajos_insert` sin la recursión 42P17; `texto_a_timestamptz` con `search_path = public`)
- `20261008000009_catalogo_verificado_y_pago_bloqueado.sql` (ya en vivo) y el `REVOKE INSERT, DELETE, TRUNCATE` de `anon` sobre `trabajadores`
- `20261008000010_anon_referencias_y_tarifa_publicada.sql` (ya en vivo: `REFERENCES`/`TRIGGER` fuera de `anon`, `trabajos_completados`, tarifa publicada y el aviso de profesional sin verificar)

No vuelvas a correr `000007` a `000010`. Esta ronda no trae migración nueva ni función nueva.

Antes de la demo, vuelve a correr `scripts/demo/seed_demo.sql`. El `UPDATE` de `niveles_precio` ya no referencia la tabla de afuera dentro del `JOIN` (eso daba `42P01` y cortaba el seed). Restaura la calificación del seed y, si hay notas, la pisa con el promedio real. Pedro queda en 4.8 con 5 trabajos. Los perfiles ajenos a `@demo.myworksapp.cl` que estaban `pendiente` pasan a `rechazado` con la nota «Archivado para la demo»; Luis Contreras sigue `en_revision`.

Después corre `docs/PRUEBAS_RLS_20261008.sql`, `docs/PRUEBAS_RLS_20261009.sql`, `docs/PRUEBAS_RLS_20261010.sql` y `docs/PRUEBAS_RLS_20261011.sql`. Tienen que terminar en `RLS 20261008 ok`, `RLS 20261009 ok`, `RLS 20261010 ok` y `RLS 20261011 ok`. Los de 20261009, 20261010 y 20261011 hacen `ROLLBACK`. El de 20261011 falla si falta `000010`.

`20261008000005` deja dos interruptores en `public.app_config`:

| clave | valor que sale | antes del lanzamiento |
|---|---|---|
| `demo_modo` | `1` (el login de la app sigue listando correos `@demo.myworksapp.cl`) | `UPDATE public.app_config SET valor = '0', actualizado_en = now() WHERE clave = 'demo_modo';` y luego `REVOKE EXECUTE ON FUNCTION public.listar_cuentas_demo_acceso() FROM anon;` |
| `admin_requiere_aal2` | `0` (el panel no exige `aal2` en SQL, para que la demo de mañana no se trabe) | `UPDATE public.app_config SET valor = '1', actualizado_en = now() WHERE clave = 'admin_requiere_aal2';` después de que `admin.ops` tenga un TOTP verificado |

El escritorio ya pide el segundo factor antes de mostrar el panel (`AdminMfaGate`). El primer ingreso de `admin.ops` muestra el QR: escanéalo y confirma el código de 6 dígitos. Con el interruptor en `0` el panel funciona aunque esa sesión todavía no sea `aal2`. En producción el interruptor tiene que quedar en `1`: `is_admin()` solo es verdadero para `rol = administrador` y, con el flag, JWT `aal = aal2`. Soporte y QA invitados quedan en `soporte` y `qa`; no entran al hub ni pasan `is_admin()`.

### Checklist antes del lanzamiento

La demo de mañana se corre con Transbank en integración y `demo_modo = 1`. Esto se hace **después** de la demo, cuando el sitio público deje de ser de prueba:

1. `UPDATE public.app_config SET valor = '0', actualizado_en = now() WHERE clave = 'demo_modo';` Con eso el invitado que crea su clave **no** queda con el correo confirmado: recibe el correo de alta y el login ofrece reenviar la confirmación.
2. `REVOKE EXECUTE ON FUNCTION public.listar_cuentas_demo_acceso() FROM anon;` El login deja de listar los correos `@demo.myworksapp.cl`.
3. `UPDATE public.app_config SET valor = '1', actualizado_en = now() WHERE clave = 'admin_requiere_aal2';` Solo después de que `admin.ops` haya verificado el TOTP. Si se enciende antes, el panel deja de reconocer al admin.
4. `CORS_ALLOWED_ORIGINS` con el origen real de la web (y el del escritorio, si se publica). En integración ya se aceptan `localhost` y `127.0.0.1` en los puertos 5173 y 3001.
5. `TURNSTILE_SECRET_KEY` en las funciones y `VITE_TURNSTILE_SITE_KEY` al construir la web. En `production`, sin el secreto, el checkout de invitado responde 503.
6. Secretos de Transbank de producción: `TBK_ENV=production`, `TBK_COMMERCE_CODE` y `TBK_API_KEY` del comercio real. Producción rechaza los códigos de integración `597055555532`, `597055555541`, `597055555542` y `597055555543`, y una llave que empiece por `579B532A7440BB0C9079DED94D31EA1615BACEB566103322646`.
7. En el plan Pro de Supabase, activar la protección de contraseñas filtradas (leaked-password protection). El plan de la demo no la incluye.

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
npx supabase migration repair --status applied 20261008000001 --project-ref wxqrfcqifkfgawrnqmnj
```

`20261008000001` a `20261008000009` ya están aplicadas: no las vuelvas a correr. El `repair` solo marca el historial local; no ejecuta el SQL. Repara `20261008000010` **solo después** de aplicar ese archivo en el SQL Editor:

```bash
cd myworksapp_app
npx supabase migration repair --status applied 20261008000002 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261008000003 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261008000004 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261008000005 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261008000006 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261008000007 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261008000008 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261008000009 --project-ref wxqrfcqifkfgawrnqmnj
npx supabase migration repair --status applied 20261008000010 --project-ref wxqrfcqifkfgawrnqmnj
```

Si el dashboard muestra otra cadena de versión, usa esa en `migration repair` y no la de esta lista. No borres las filas de nombre corto. No hagas push a `main`.

## 2. Edge Functions

`webpay-create-transaction` y `webpay-commit-transaction` siguen vivas y el MCP no las puede borrar. En el repo hay un stub con el mismo nombre que responde **410 Gone**. Despliégalos para pisar las viejas. El camino vigente sigue siendo `webpay-create` y `webpay-commit`.

```bash
cd myworksapp_app
npx supabase functions deploy webpay-create-transaction --project-ref wxqrfcqifkfgawrnqmnj --no-verify-jwt
npx supabase functions deploy webpay-commit-transaction --project-ref wxqrfcqifkfgawrnqmnj --no-verify-jwt
```

Volver a desplegar `invitar-colaborador`: Admin queda `administrador`; Soporte queda `soporte` y QA queda `qa`. Esos dos no entran al hub.

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

Turnstile, para la demo de mañana, **no hace falta**. Si `TURNSTILE_SECRET_KEY` no está y `TBK_ENV=integration`, `guest-checkout` no pide captcha. Si falta `VITE_TURNSTILE_SITE_KEY` en la web, el widget no se muestra. En `production`, sin el secreto, el checkout de invitado responde 503.

```bash
# Solo cuando haya un sitio de Turnstile. No hace falta para la demo.
npx supabase secrets set TURNSTILE_SECRET_KEY=<secreto-del-widget> --project-ref wxqrfcqifkfgawrnqmnj
```

En la web, el mismo sitio va en `VITE_TURNSTILE_SITE_KEY` al construir. `CORS_ALLOWED_ORIGINS` es opcional en integración: ya se aceptan `localhost` y `127.0.0.1` en los puertos 5173 y 3001. Un origen `*.supabase.co` ya no se refleja.

Si `TBK_COMMERCE_CODE` y `TBK_API_KEY` no están definidos y `TBK_ENV=integration` (o la variable no está definida), la función usa el comercio público de integración de Transbank (`597055555532`). Oneclick Mall usa `597055555541` y la tienda `597055555542` (la tienda 2 oficial es `597055555543`). En `production`, si falta un secreto, la función falla. No pongas esas claves en la web, el escritorio ni Flutter.

`WEBPAY_WEB_RETURN_URL` no hace falta para la demo. `webpay-create` y `guest-checkout` guardan el Origin del navegador (`http://localhost:5173` o `http://127.0.0.1:5173` en integración, o lo que esté en `WEBPAY_ALLOWED_RETURN_ORIGINS` / `CORS_ALLOWED_ORIGINS`) y `webpay-commit` vuelve ahí.

Hay que volver a desplegar las funciones que comparten CORS o el ticket de invitado, y `oneclick-charge` porque el monto sale de la cotización elegida o de la tarifa:

```bash
cd myworksapp_app
npx supabase functions deploy webpay-handoff --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy webpay-commit --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy webpay-create --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy guest-checkout --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy definir-clave-invitado --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy invitar-colaborador --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy oneclick-charge --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy oneclick-return --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy webpay-status --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy webpay-release --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy webpay-refund --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy webpay-refund-cancellation --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy webpay-refund-rejection --project-ref wxqrfcqifkfgawrnqmnj
npx supabase functions deploy webpay-resolve-dispute --project-ref wxqrfcqifkfgawrnqmnj
```

`definir-clave-invitado` no pide JWT. El enlace dura 15 minutos y exige el nonce del `sessionStorage` del navegador que pagó. La cuenta se lee antes de tocar el ticket. Después un solo `UPDATE` con `alta_consumido_en` vacío se queda el enlace: dos pedidos a la vez no pueden guardar dos claves. Si guardar la clave o el correo de alta falla, ese `UPDATE` se revierte y el enlace sigue sirviendo.

Con `app_config.demo_modo = 1` (la demo y la integración) esa función marca el correo como confirmado. La pantalla dice «Contraseña lista. Entra con tu correo en la próxima visita.» Con `demo_modo = 0` el correo sigue sin confirmar, se dispara el correo de alta y la pantalla dice «Te enviamos un correo para confirmar.» En el login, si el correo no está confirmado, el aviso está en español y aparece **Reenviar correo de confirmación**.

`webpay-commit` (v21) y `definir-clave-invitado` (v5) ya están en vivo y esta ronda no los cambia. `guest-checkout` ahora guarda en `fecha_programada` la hora elegida en la barra: hay que volver a desplegarlo. Si se pierde la pestaña, el nonce no se puede recuperar: se vuelve a pedir la visita. Un error de la función (por ejemplo «Este profesional todavía no está verificado para cobrar») se muestra tal cual; la web ya no lo reemplaza por «Edge Function returned a non-2xx status code».

Un pago con tarjeta de prueba y la liberación de la garantía ya se probaron de punta a punta en vivo: Webpay autorizó, el cobro quedó `retenido` y la conformidad lo pasó a `liberado`. Ese camino no se anula.

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
| Armado, Santiago centro | `diego.salazar@demo.myworksapp.cl` | trabajador verificado |
| Gasfitería, San Miguel | `carmen.lagos@demo.myworksapp.cl` | trabajador verificado |
| Jardinería, La Reina | `felipe.araya@demo.myworksapp.cl` | trabajador verificado |
| Cerrajería, Estación Central | `rodrigo.pena@demo.myworksapp.cl` | trabajador verificado |
| Soporte técnico, Providencia | `isabel.campos@demo.myworksapp.cl` | trabajador verificado |
| Mudanza, Quinta Normal | `hugo.vargas@demo.myworksapp.cl` | trabajador verificado |
| Climatización, Las Condes | `paula.riquelme@demo.myworksapp.cl` | trabajador verificado |
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

Si la persona cancela en Webpay (`TBK_TOKEN` sin `token_ws`, o la vuelta `?pago=fail` de un cobro todavía pendiente), `webpay-commit` deja el pago en `anulado` (cancelación) o `fallido` (el banco rechazó o el monto no coincidió) y el trabajo en `cancelado`. Un pago `retenido` o `liberado` no se toca. Hay que volver a elegir al profesional: el pedido cancelado no se reutiliza.

`20261008000006` además cierra los `esperando_pago` de más de 30 minutos que no tienen garantía, y borra invitados con `guest_checkout` y sin pago retenido, autorizado o liberado cuando la cuenta tiene más de 24 horas. Las cuentas `@demo.myworksapp.cl` no entran en ese borrado.

Si `pg_cron` está en el proyecto, la migración deja el trabajo `mwa_expirar_pagos_abandonados` cada 10 minutos (`*/10 * * * *`). Si la extensión no se puede crear, el SQL igual deja la función y el aviso en el log. En ese caso programa a mano, o corre en el SQL Editor:

```sql
SELECT public.expirar_pagos_abandonados();
```

El commit deja el pago `retenido` en la base. **Recibo conforme** (web, en el seguimiento, o app) llama a `cerrar_trabajo_conforme` y el ledger pasa a `liberado`. Eso no es un segundo cargo. El reembolso de una disputa lo hace el admin con la función `webpay-resolve-dispute`.

## 5. Cómo levantar cada cliente

Clave publicable (no es la `service_role`): la misma que ya usa la app en debug. En release hay que pasarla con `--dart-define`. No la copies a un ticket.

Web, en bash:

```bash
cd myworksapp_web
cp .env.example .env.local
npm install
npm run dev
```

Web, en Windows PowerShell (el retorno de Webpay tiene que ser el puerto **5173**):

```powershell
cd myworksapp_web
Copy-Item .env.example .env.local
npm install
npm run dev
```

Abre `http://localhost:5173`. `.env.example` ya trae la URL del proyecto y la clave publicable.

Escritorio, en bash (hace falta Rust estable; el Cargo 1.83 del sistema no compila crates `edition2024`):

```bash
cd myworksapp_desktop
cp .env.example .env.local
npm install
npm run dev
```

Escritorio, en Windows PowerShell. El panel en el navegador queda en `http://127.0.0.1:3001`. `npm run tauri:dev` abre la ventana nativa en el mismo origen.

```powershell
cd myworksapp_desktop
Copy-Item .env.example .env.local
npm install
npm run dev
# o, con la ventana de escritorio:
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
2. **Buscar servicio** → **Plomería**. En el mapa está Pedro Rojas, pin en Providencia. La tarjeta dice **4.8**, **5 trabajos** y **Desde $35.000 / visita**. Con sesión, la portada dice **Hola, Camila**. El seguimiento muestra **Camila S.**. Los horarios de la barra son **10:00**, **14:00** y **18:00**.
3. Elige a Pedro → **Continuar con la reserva**. La barra repite **$35.000 / visita**. El diálogo **Confirmar pedido** muestra el total **35.000 CLP**. Con sesión y tarjeta inscrita en la app, se cobra Oneclick. Con sesión y sin tarjeta, el sitio abre Webpay Plus. Sin sesión, el formulario pide nombre, correo, teléfono y dirección, y no pide el número de tarjeta.
4. Paga con la Visa de prueba. Transbank vuelve a `http://localhost:5173/?pago=ok&paymentId=…&jobId=…`. El trabajo queda pendiente y el pago `retenido`. La hora de la barra (10:00, 14:00 o 18:00 del próximo viernes) queda en `fecha_programada`. Camila, que ya tenía sesión, entra directo al seguimiento. **Ver mi pedido** solo aparece en el retorno del invitado. Si lo toca antes de entrar, se abre **Ingresar** y, al entrar, el seguimiento de ese pedido. Si recarga, la portada tiene **Mis pedidos** y vuelve a abrir ese trabajo desde la base. **Mis pedidos** separa los que siguen abiertos de los completados recientes. Si el pago fue de invitado, la misma URL trae `invitado=1` y un token `alta`: la web muestra **Crea tu contraseña** y **Ver mi pedido**. Con `demo_modo = 1` el correo queda confirmado y el texto es «Contraseña lista. Entra con tu correo en la próxima visita.» El invitado entra con el correo y la clave que acaba de crear.
5. Si en Transbank se cancela, la vuelta es `http://localhost:5173/?pago=fail` y la portada muestra «Pago cancelado. No se realizó ningún cargo.» El pedido queda cancelado. Se elige de nuevo al profesional.

En la app, una invitación por tarifa cobra el precio publicado en `niveles_precio` (por ejemplo «Arreglo menor» de Pedro, $28.000), el mismo que valida el servidor. Luis Contreras sigue `en_revision`: intentar pagarle responde «Este profesional todavía no está verificado para cobrar», no un aviso de tarifa faltante.

### Profesional en la app — aceptar y GPS

1. En el teléfono, entra como Pedro.
2. Abre el pedido pendiente de Camila y acéptalo.
3. **Voy en camino**. Acepta la ubicación solo en primer plano. El punto se publica como máximo cada 20 s o 40 m.
4. En la web, Camila abre **Mis pedidos** y elige el trabajo en camino. El mapa sigue el pin en vivo del profesional. La llegada en minutos (estimación a 28 km/h) solo aparece si el pedido ya tiene coordenadas, como `demo-job-en-camino`. Un pedido nuevo de la web guarda la hora en `fecha_programada`. El invitado guarda la dirección que escribió. Con sesión el formulario no pide dirección, así que el pedido queda como «Dirección por confirmar». No guarda latitud ni longitud: el formulario no trae un punto y no hay geocodificación. El mapa muestra el pin del profesional, sin esa llegada. En un trabajo completado o cancelado no aparece el aviso de GPS «en camino o en curso».
5. En el teléfono, pasa el trabajo a **en curso**. El GPS sigue mientras la app está abierta.
6. Escribe en el chat. Camila lo ve en la web (**Abrir chat**).

Para no depender del GPS del salón, el seed ya trae `demo-job-en-camino`: Camila puede abrir ese pedido en la app y ver a Pedro sobre el mapa, cerca de Irarrázaval.

### Conformidad y liberación

1. El pedido `demo-job-conforme` (Ana Vidal, aseo en Ñuñoa) está en `esperando_aprobacion_cliente` con pago retenido.
2. Camila lo abre en la app y toca **Recibo conforme**. En la web, el mismo botón aparece en el seguimiento cuando el pedido actual está en ese estado (el panel se refresca cada 8 s).
3. El trabajo pasa a completado y el pago a `liberado`.

### Escritorio

1. Entra como `admin.ops@demo.myworksapp.cl` y completa el segundo factor. Si quedó un QR a medias, el panel borra ese factor sin verificar y muestra un código nuevo.
2. **Panel ejecutivo → Trabajadores.** Luis Contreras está **En revisión** y tiene **Aprobar** y **Rechazar**. Las filas ya verificadas no traen esos botones. La lista oculta a los `rechazado`. El seed deja así a Ana Volt, Felipe Ensambla y el resto de pendientes que no son `@demo`, así que Luis es el pendiente del guion.
3. **Soporte y disputas:** la tarjeta muestra **#DEMO-DIS** (los primeros 8 caracteres de `demo-disputa-1`, Camila, trabajo eléctrico a medias). Con un solo ticket la paginación muestra solo **1**. La hora es la de Chile. Ciérrala desde el panel; el dinero no se mueve solo mientras sigue abierta.
4. **Panel ejecutivo → Resumen.** El recuadro de arriba **GMV** usa el mismo monto que el período de **7 días** (retenido, liberado y autorizado). También se ven comisión 15 %, completados, ticket y CSAT. En un rango sin datos el texto es «Sin cobros» o «Sin calificaciones».
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

Volver a correr `scripts/demo/seed_demo.sql` repone esos pedidos y la contraseña `Demo2026!`. No borra otras filas. Deja `disponible = 0` en todo trabajador cuyo correo no termina en `@demo.myworksapp.cl`, y pasa a `rechazado` los que seguían `pendiente`.

## 8. Plan B

Si algo del pago en vivo se traba, no improvises producción.

| Qué falló | Qué hacer |
|---|---|
| La página de Transbank muestra HTML crudo | Falta redesplegar `webpay-handoff` y `oneclick-handoff`. El 303 tiene que ir a `webpay3gint.transbank.cl` con `token_ws` o `TBK_TOKEN` en la query. |
| Al volver caes en otro puerto o en una página en blanco | El checkout tiene que abrirse en `http://localhost:5173` o `http://127.0.0.1:5173`. Esos orígenes se guardan en `pagos.origen_retorno` después de `20261008000003`. |
| 401 de Transbank | `TBK_ENV=integration` y sin secretos de comercio: la llave pública oficial ya está en el código. Redesplega las funciones de pago si el 401 sigue. |
| Camila no puede pagar sin tarjeta en la app | Con sesión, **Confirmar pedido** abre Webpay Plus. No hace falta inscribir la tarjeta antes. |
| El invitado no ve «Crea tu contraseña» | La URL tiene que traer `invitado=1` y `alta`. Hace falta `WEBPAY_HANDOFF_SECRET` y la función `definir-clave-invitado`. Sin ese secreto, el pago igual queda retenido; la cuenta entra después solo si Auth tiene SMTP de recuperación. |
| Tras crear la clave, el login dice `Email not confirmed` | En la demo `demo_modo` tiene que estar en `1` y hay que redesplegar `definir-clave-invitado`. Con ese valor el correo queda confirmado. En producción (`demo_modo = 0`) el login ofrece **Reenviar correo de confirmación**. |
| La app rechaza el pedido con profesional | El alta con profesional va en `esperando_pago` (o `esperando_cotizaciones`) y después el pago. `pendiente` con profesional lo niega `trabajos_insert`. Hace falta `20261008000008` en vivo y esta rama de la app. |
| El catálogo muestra Ana Volt u otros nombres que no son `@demo` | Vuelve a correr el seed. Esos perfiles quedan no disponibles. |
| En Trabajadores salen muchos Pendiente (Ana Volt, Felipe Ensambla) | Vuelve a correr el seed de esta rama. Esos perfiles pasan a `rechazado` y la lista del escritorio los oculta. Luis queda **En revisión**. |
| El seed se cae con `42P01` al guardar `niveles_precio` | Corre el `scripts/demo/seed_demo.sql` de esta rama. El `UPDATE` ya no mete la tabla de afuera dentro del `JOIN`. |
| Armado, Gasfitería u otro oficio sale vacío | Vuelve a correr el seed después de `20261008000006`. Tiene que haber un profesional verificado por cada categoría de la web. Si una categoría queda en cero, la portada la oculta; al abrirla, el texto es «Todavía no hay profesionales». |
| Al cancelar en Webpay no aparece ningún aviso | La portada tiene que mostrar «Pago cancelado. No se realizó ningún cargo.» Hace falta esta rama de la web. El cobro queda `anulado` y el trabajo `cancelado` con `webpay-commit` ya desplegado. |
| Pagar a Luis dice que no hay tarifa | Aplica `20261008000010` y redesplega `guest-checkout`. El texto es «Este profesional todavía no está verificado para cobrar». |
| La app rechaza el pago de una tarifa publicada | Aplica `20261008000010` y vuelve a correr el seed, que llena `niveles_precio`. El monto del checkout es esa tarifa, sin recargo de comuna. |
| Pedro sale con 0 trabajos o la nota no es 4.8 | Vuelve a correr el seed. Tiene 5 trabajos completados y notas que promedian 4.8. |
| `definir-clave-invitado` responde 503 | Esa función en el proyecto es el stub viejo. Redesplega la de esta rama. |
| La disputa no se abre | Aplica `20261008000004`. Cliente y profesional usan **Abrir disputa**; el comentario va por `comentar_disputa`. Resolver solo desde el escritorio admin. |
| El mapa no tiene GPS del salón | Abre en la app el pedido `demo-job-en-camino` (Camila y Pedro, Irarrázaval). |
| El segundo factor del escritorio no está a mano | Entra con el dispositivo que ya escaneó el QR. No desactives MFA en la demo. |

# Qué hay que reparar

Auditoría del 27 sep 2026. No incluye lo ya cerrado: token de Transbank oculto al cliente, handoff sin clave de respaldo, cabeceras en `vercel.json` y tope del guest-checkout.

## Pago y los dos repos

- [x] Dejar un solo camino de Webpay. El repo principal usa `webpay-create`. El de título usa `webpay-create-transaction` y `webpay-commit-transaction`.
- [x] En `webpay-create`, leer el error al actualizar `pagos`. Si falla, no devolver éxito: Transbank ya puede tener el cobro abierto.
- [x] En `webpay-create-transaction`, si falla la firma del handoff, no responder 200 con token y url.
- [x] Unificar el largo del `buy_order` (20 caracteres en un create, 23 en el otro).
- [x] Copiar al repo principal la migración `20260927000001` de `transicion_trabajo_permitida`. En la base ya se ejecutó. En el código del producto no está.
- [x] Unir los dos árboles de `myworksapp_app`. El de título no tiene kill switch ni rate limit. El principal no tiene las pantallas de pago nuevas.

## El servidor no exige el pago

- [x] `transicionar_trabajo` no mira si hay un pago retenido. `PaymentGuard` solo corre en la app. Quien llama el RPC se salta el cobro.
- [x] El INSERT de trabajos solo exige que el usuario sea el dueño. No limita el estado. Se puede crear un trabajo ya aceptado, en curso o completado, y asignar a cualquier profesional.
- [x] Webpay guarda el pago como `retenido`. `PaymentGuard` del repo principal solo acepta `autorizado`. Después de un pago real la app no deja seguir. El repo de título sí acepta los dos.
- [x] Al elegir una cotización, el segundo `updateJob` no guarda al profesional. `id_trabajador` no se escribe.
- [x] `guest-checkout` confirma el correo y no entrega la contraseña. Quien pagó como invitado no puede entrar. Un tercero puede ver si un correo ya existe.
- [x] Cada clic en pagar inserta otra fila en `pagos`. Dos clics pueden abrir dos cobros en Transbank.
- [x] Después de pagar, la web muestra el pedido `MW-7821`, Las Condes, 18 minutos y 4,2 km fijos. El chat es local. El texto dice liberación automática y el release es manual.

## Estados del trabajo

- [x] `updateJob` recibe el trabajo completo y solo guarda el estado.
- [x] `rejectPendingJobByWorker` convierte cualquier fallo del RPC en `false`. Hay que mostrar el error.
- [x] Cancelar y reembolsar en un solo paso. Hoy el trabajo puede quedar cancelado con el dinero todavía retenido.
- [x] Una sola máquina de estados. Postgres debe mandar. Dart no debe duplicar `transicion_trabajo_permitida`.

## Lo que la interfaz afirma y no es cierto

- [x] Escritorio: el selector Admin/Soporte no se usa. Solo entra el rol exacto `administrador`. Cablearlo o quitarlo.
- [x] Quitar o marcar como demo las cifras de `ExecutiveWorkspace` y las personas de `HumanResourcesWorkspace`.
- [x] El mapa no es cercanía real. Los pines salen de un hash alrededor de Las Condes. Guardar coordenadas o no decir “cerca de ti”.
- [x] Confirmar que `demo123` y los correos `@demo.com` no entran en un build de release.
  - Auditoría 2026-10-05: solo estaba resuelto en el cliente. En la BD de la demo `admin@demo.com` seguía activo como `administrador` con la contraseña publicada. Quedó suspendido y baneado (migración `20261009000001`). El autocompletado de depuración ya usa las cuentas `@demo.myworksapp.cl`.
- [ ] Banear las otras 17 cuentas `@demo.com` (no administradoras) cuando termine la grabación de la demo. Ver `docs/AUDITORIA_2026-10-05.md`.

## Antes de salir de la demo

- [x] Partir `job_detail_page.dart` (más de 1.200 líneas) y el `App.tsx` de la web.
- [x] `guest-checkout` crea usuarios reales de Auth. No dejar cuentas huérfanas si el pago no termina.
- [x] Revisar si un usuario autenticado, al leer trabajos sin trabajador, se lleva la dirección.
- [x] No aplicar `schema_remote_dump.sql`. Está en inglés y no es el esquema actual.
- [x] Cuando exista dominio HTTPS, agregar HSTS. La CSP todavía permite estilos en línea e imágenes de cualquier https. HSTS ya está en `vercel.json` y `public/_headers`. `style-src` ya no lleva `unsafe-inline`. Las imágenes solo salen de Unsplash, el mapa y Supabase. Los atributos `style` del mapa Leaflet siguen permitidos.
- [x] MFA para el administrador antes de un uso que no sea la demo.
- [ ] Las claves públicas de integración sirven para la demo. No dejarlas cuando Transbank entregue el comercio real. Si `TBK_ENV=production` usa el código de integración, el servidor rechaza el cobro. Falta el código de comercio real.

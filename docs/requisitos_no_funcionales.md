# Requisitos no funcionales

## Seguridad

- Row Level Security activo en todas las tablas de `public` (60 en `main` `d9d2c7c`), entre ellas `perfiles`, `trabajos`, `mensajes`, `pagos`, `disputas`, `trabajador_horarios` / `trabajador_horas_publicadas` y `auditoria_consola`. `rate_limit_ventana` no tiene políticas: solo la usa `service_role`.
- El cliente autenticado lee pagos del trabajo en el que participa. No inserta ni actualiza `pagos` por PostgREST.
- Estado, profesional asignado y estado de pago del trabajo solo cambian por procedimientos del servidor.
- La base exacta del profesional no sale en el catálogo: se redondea a 2 decimales. El dueño la lee por `mi_ficha_propia`.
- No hay `service_role` ni llaves privadas en `lib/`. La app usa la clave anónima pública.
- La consola exige segundo factor TOTP (`aal2`), pide otra vez el código para mover dinero si el último tiene más de 5 minutos y cierra la sesión tras 15 minutos sin uso. Las Edge Functions de administrador llaman `is_admin()` con el JWT del usuario y cada acción queda en la bitácora inmutable `auditoria_consola`.
- Límite de tasa global en Postgres (`rate_limit_consumir`) para la compra como invitado, el alta de clave, Webpay y Oneclick. Turnstile se valida en el servidor en la compra como invitado.
- La web envía HSTS de 180 días con `includeSubDomains`, CSP, `X-Frame-Options: DENY` y `nosniff` (`myworksapp_web/vercel.json`).
- El chat, la descripción del pedido y el alta del pago principal rechazan teléfono chileno (móvil y fijo), correo, enlaces y un usuario o enlace de red social. Un RUT, una medida, un monto o la sola mención de una red no cuentan como contacto.

## Dinero

- Montos en pesos chilenos enteros. Tarifa publicada + traslado = total cobrado.
- Comisión del servicio: 5 % redondeado, mínimo $1.000, nunca mayor que el bruto, descontada del profesional.
- Un solo pago principal en estado pendiente, retenido o autorizado por trabajo.

## Experiencia

- Mensajes de error de negocio en español. Un fallo técnico de PostgREST no se muestra con el nombre de la función.
- Estados vacíos en el catálogo cuando no hay profesionales en la ciudad o el filtro no devuelve resultados.
- La búsqueda de demostración parte en Puerto Montt. La insignia «Élite del mes» y el formulario SII del perfil se renderizan con el resto de la ficha.

## Disponibilidad de la demo

- Transbank en integración. Las tarjetas de prueba están en `MyWorksAppProyect/DEMO.md`.
- La web se sirve desde Vercel en `myworksapp.cl`. El correo de Auth sale por Resend con el plan gratis de 100 correos al día.
- Si el GPS no responde, la app usa Puerto Montt como respaldo de la demostración.

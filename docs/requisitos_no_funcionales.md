# Requisitos no funcionales

## Seguridad

- Row Level Security activo en `perfiles`, `trabajos`, `mensajes`, `pagos`, `disputas` y `trabajador_horarios` / `trabajador_horas_publicadas`.
- El cliente autenticado lee pagos del trabajo en el que participa. No inserta ni actualiza `pagos` por PostgREST.
- Estado, profesional asignado y estado de pago del trabajo solo cambian por procedimientos del servidor.
- La base exacta del profesional no sale en el catálogo: se redondea a 2 decimales. El dueño la lee por `mi_ficha_propia`.
- No hay `service_role` ni llaves privadas en `lib/`. La app usa la clave anónima pública.
- El chat y el alta del pago principal rechazan teléfono, correo, enlaces y redes (WhatsApp, Instagram, Facebook, TikTok, Telegram, Snapchat, Twitter).

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
- Si el GPS no responde, la app usa Puerto Montt como respaldo de la demostración.

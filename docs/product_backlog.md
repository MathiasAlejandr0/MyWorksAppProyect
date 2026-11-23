# Product backlog

Ítems que el producto ya cubre para la evaluación, y los que quedan explícitamente fuera.

## Listo para demostrar

1. Catálogo de profesionales en Puerto Montt, ordenado por cercanía (bandas de 1 km), nota y precio.
2. Insignia de trabajador élite cuando la base marca `es_elite` o la nota y los trabajos cumplidos alcanzan el umbral público.
3. Agenda semanal del profesional y reserva de una hora publicada.
4. Cotización de tarifa más traslado con la ubicación real, en CLP enteros, antes de abrir Transbank.
5. Pago en garantía con Webpay Plus u Oneclick, sin un segundo cobro principal activo para el mismo trabajo.
6. PIN de inicio, evidencia fotográfica y conformidad del cliente para liberar el pago.
7. Disputa con motivos fijos y acuerdos, con el pago retenido mientras el caso sigue abierto.
8. Chat y descripción del pedido que rechazan teléfono, correo, enlaces y un usuario de red social, también al crear el pago.
9. Consola de escritorio con segundo factor TOTP: pedidos, disputas (abiertas y resueltas), pagos, liquidaciones, verificación con nota de rechazo obligatoria, equipo y roles, y bitácora inmutable `auditoria_consola`.
10. Perfil público del profesional con reseñas en la web (`/profesional/:id`).
11. Cuenta del cliente en la web: direcciones guardadas, exportar datos y eliminar la cuenta (`/cuenta`).
12. El cliente aprueba o rechaza un cobro adicional desde la web.
13. Web en el dominio propio `myworksapp.cl`, con Turnstile en el registro y en la compra como invitado, y correos de Auth por Resend.
14. Correos transaccionales de pago recibido, alta de invitado, reembolso y pago liberado, y enlaces de recuperación e invitación que vuelven a la app y a la consola (PR #82).

## Pendiente, fuera del MVP

- Payout automático al banco del profesional.
- Transbank en producción.
- MFA para clientes y profesionales.
- Invitación de colaboradores por Resend: falta el secreto `INVITE_PROVIDER=resend`.
- Carta de boleta del SII: el formulario existe en el código y guarda RUT, giro y tipo de documento solo en el teléfono. Desde el 22 de noviembre de 2026 (commit `19d1da3`, app 1.0.15) no se muestra en Mi Perfil, porque la boleta no está integrada. La aplicación no emite boletas.
- Publicar en Vercel el `main` que ya trae los textos legales y el aviso de proyecto de título.
- Arreglo de los 24 errores de la consola (rama `cursor/consola-bugs`, sin merge).
- Push FCM: `send-push` no está desplegada en vivo.
- Programar la llamada periódica a `soporte-automatico` (ya desplegada) para que las devoluciones del soporte automático salgan solas.

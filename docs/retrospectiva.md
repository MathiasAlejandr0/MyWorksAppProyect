# Retrospectiva — cierre antes de la evaluación

Fecha: 20 de noviembre de 2026. Equipo: Mathias Jara Alvarado, Gabriel Valderas y Nicolas Chiguay.

## Cómo está el producto

- Hay RLS en perfiles, trabajos, mensajes, pagos, disputas y horarios. El cliente lee los pagos de su trabajo y no los inserta ni los edita.
- Hay un solo pago principal activo por trabajo. Si se intenta otro, la app explica en español que ya hay un cobro en curso.
- El chat y la descripción del pedido rechazan teléfono chileno (móvil y fijo), correo, enlaces y un usuario o enlace de red social. Nombrar la red, un RUT, una medida o un monto no bloquea el texto.
- Al crear o reutilizar el pago principal, el servidor revisa la descripción, la dirección y los mensajes del cliente en ese trabajo. Un administrador puede registrar el pago si el caso es legítimo.
- Cerrar el trabajo exige al menos una evidencia, en la app y en el servidor. El pago sigue retenido hasta la conformidad.
- Los errores de negocio se muestran en español, sin el texto crudo de Postgres.

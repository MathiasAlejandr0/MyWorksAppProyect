# Retrospectiva — cierre antes de la evaluación

Fecha: 19 de noviembre de 2026. Equipo: Mathias Jara Alvarado, Gabriel Valderas y Nicolas Chiguay.

## Qué se sostiene

- La base tiene RLS en perfiles, trabajos, mensajes, pagos, disputas y horarios. El cliente no escribe pagos ni cambia el estado del trabajo por un update directo.
- El pago en garantía ya tenía un índice único de un solo cobro principal activo.
- El chat ya bloqueaba teléfono, correo y enlaces en la app y en un trigger de Postgres.
- La evidencia ya era obligatoria en el servidor al pasar a `esperando_aprobacion_cliente`.

## Qué apareció en la auditoría

- Facebook y TikTok no entraban en el filtro, y la descripción del trabajo no se revisaba al crear el pago.
- La app podía mostrar la excepción cruda de Postgres si fallaba un cambio de estado, y el cierre sin foto dependía solo del diálogo de la pantalla.
- Los artefactos Scrum pedidos para la evaluación no estaban como archivos sueltos en `docs/`, aunque la metodología sí estaba en `docs/metodologia.md`.

## Qué queda

Aplicar en el proyecto Supabase las migraciones nuevas de esta auditoría (`resumen_cobro_trabajo` y el freno de contacto antes del pago) para que el servidor y la app coincidan en la demostración.

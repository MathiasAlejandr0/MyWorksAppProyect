# Sprint backlog — preparación de la evaluación

Sprint de cierre antes de la defensa. El guion de [`MyWorksAppProyect/DEMO.md`](../MyWorksAppProyect/DEMO.md) se recorre con un solo paso de cobro y con evidencia antes de cerrar.

## En este sprint

| Ítem | Hecho de aceptación |
|------|---------------------|
| Cobro con tarjeta | El total que se muestra es el que acepta el servidor. Un solo toque abre Transbank. |
| Datos de contacto | El chat y la creación del pago rechazan teléfono, correo, enlace y un usuario de red social. Un RUT, una medida o un monto siguen siendo texto del oficio. |
| Cierre del trabajo | Sin al menos una evidencia no se pasa a conformidad ni a completado. |
| Segundo cobro | Un pago principal activo por trabajo. El aviso al usuario está en español. |
| Consola de escritorio | Back office con permisos por rol, segundo factor, motivo obligatorio y bitácora `auditoria_consola`. Las funciones de dinero e invitación exigen `is_admin()`. Hecho (PR #77, #79). |
| Web pública | Dominio `myworksapp.cl`, rutas compartibles, perfil público del profesional, cuenta del cliente y aprobación de cobros adicionales. Hecho (PR #78, #81). |
| Seguridad | Turnstile obligatorio en la compra como invitado, límite de tasa global y checkout sin enumerar correos. Hecho (PR #78). |
| Correo | Correos transaccionales con Resend y enlaces de recuperación e invitación para la app y la consola. Hecho (PR #82); `soporte-automatico` desplegada. |
| Documentación | Al 22-11-2026 el estado vigente está en `MyWorksAppProyect/ESTADO_DEL_PROYECTO.md`. El informe final incorpora P-18 en la rama `cursor/informe-cierre-5321`. El corte anterior era `main` `d9d2c7c`. |

## Pendiente para cerrar el sprint

- Corregir los 24 errores de la prueba de la consola del 20-nov; el más grave (Profesionales responde 403) impide verificar profesionales. Rama `cursor/consola-bugs`, sin merge.
- Textos legales: el aviso académico ya está en `main`. Falta desplegar ese paquete en https://myworksapp.cl.
- Activar la invitación por Resend (`INVITE_PROVIDER=resend`) y probar de punta a punta `soporte@myworksapp.cl`.
- Desplegar `send-push` y programar la llamada a `soporte-automatico`.

## Guion de la demostración

1. El cliente busca plomería en Puerto Montt y elige un profesional.
2. Agenda una hora publicada.
3. Paga en garantía con la tarjeta de integración de Transbank.
4. El profesional acepta, inicia con el PIN, sube evidencia y finaliza.
5. El cliente da conformidad y califica.

Cuentas y tarjetas de prueba: secciones 2 y 3 de `DEMO.md`.

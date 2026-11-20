# Especificación de casos de uso — MyWorksApp

| Campo | Valor |
|---|---|
| Versión del código analizada | `main` en `08154dfc` (20 de noviembre de 2026; app 1.0.11+12). Incluye la consola con bitácora `auditoria_consola` y 17 RPC `consola_*`, la web con perfil público, cuenta del cliente, rechazo de cobros adicionales y límite de tasa global, y la comisión de `comision_servicio_clp` |
| Fuentes | Código de `myworksapp_app` (Flutter), `myworksapp_web` (React/Vite), `myworksapp_desktop` (Tauri), `shared/` (TypeScript), `myworksapp_app/supabase/migrations` (SQL) y `myworksapp_app/supabase/functions` (Edge Functions). La web se publica en https://myworksapp.cl. Lo que depende de la configuración en vivo se toma del reporte de despliegue del 20-nov-2026 y se indica como tal |
| Diagrama | [`casos_de_uso_diagrama.png`](casos_de_uso_diagrama.png) (fuente Mermaid en §3) |

Cada caso de uso se escribió a partir de lo que el código **hace hoy**, no de lo que se planificó. Las rutas de la trazabilidad son relativas a `MyWorksAppProyect/`. Cuando un comportamiento depende de una regla del servidor, se cita la función SQL o la Edge Function que la impone, porque esa es la regla que no se puede saltar desde un cliente modificado.

---

## 1. Actores

| Actor | Tipo | Descripción | Cliente que usa |
|---|---|---|---|
| **Visitante** | Primario | Persona sin sesión que navega el catálogo | Web y app |
| **Cliente invitado** | Primario | Visitante que compra sin crear cuenta antes de pagar | Web |
| **Cliente registrado** | Primario | Usuario con rol `cliente` que contrata servicios | Web y app |
| **Profesional** (rol `trabajador`, «Especialista» en la app) | Primario | Ofrece y ejecuta servicios | Solo app móvil |
| **Administrador** (rol `administrador`) | Primario | Opera la plataforma: verificación, disputas, pagos y personal | Consola de escritorio (Tauri) |
| **Colaborador interno** (rol `soporte` o `qa`) | Primario | Persona invitada por RRHH. Entra a la consola con mínimo privilegio (CU-34) | Consola de escritorio |
| **Sistema (planificador)** | Secundario | Tareas `pg_cron` y Edge Functions automáticas | Backend Supabase |
| **Transbank Webpay** | Externo | Pasarela de pago (ambiente de integración) | — |
| **Supabase Auth / correo (Resend)** | Externo | Autenticación; correos de alta, recuperación e invitación por el SMTP de Resend, remitente `no-responder@myworksapp.cl` | — |
| **Cloudflare Turnstile** | Externo | Desafío anti-robots en el registro web y en la compra como invitado | — |

**Generalización.** Cliente invitado y Cliente registrado especializan a Visitante (heredan CU-05 y CU-06). Un Cliente invitado pasa a ser Cliente registrado al completar CU-10.

## 2. Resumen de casos de uso

| ID | Nombre | Actor principal | Módulo | Clientes |
|---|---|---|---|---|
| CU-01 | Registrarse | Visitante | Acceso | Web, app |
| CU-02 | Iniciar sesión | Cliente, Profesional | Acceso | Web, app |
| CU-03 | Recuperar contraseña | Cliente, Profesional | Acceso | Web, app |
| CU-04 | Ejercer derechos sobre los datos (exportar / eliminar cuenta) | Cliente, Profesional | Acceso | Web, app |
| CU-05 | Buscar profesionales con mapa y filtros | Visitante | Búsqueda | Web, app |
| CU-06 | Ver perfil público del profesional, reseñas y horas libres | Visitante | Búsqueda | Web, app |
| CU-07 | Solicitar servicio y reservar hora | Cliente registrado | Reserva | Web, app |
| CU-08 | Pagar con Webpay en garantía | Cliente registrado | Pago | Web, app |
| CU-09 | Comprar como invitado | Cliente invitado | Pago | Web |
| CU-10 | Definir contraseña tras pagar como invitado | Cliente invitado | Acceso / pago | Web |
| CU-11 | Aceptar o rechazar un pedido | Profesional | Ejecución | App |
| CU-12 | Avisar «voy en camino» y compartir ubicación | Profesional | Ejecución | App |
| CU-13 | Seguir el pedido en vivo | Cliente | Ejecución | Web, app |
| CU-14 | Iniciar el trabajo con PIN | Profesional | Ejecución | App |
| CU-15 | Solicitar y aprobar o rechazar un cobro adicional (orden de cambio) | Profesional, Cliente | Ejecución / pago | App (solicita); web y app (responde) |
| CU-16 | Subir evidencia y finalizar el trabajo | Profesional | Ejecución | App |
| CU-17 | Recibir conforme y liberar el pago | Cliente | Cierre / pago | Web, app |
| CU-18 | Calificar al profesional | Cliente | Reputación | Web, app |
| CU-19 | Calificar al cliente | Profesional | Reputación | App |
| CU-20 | Cancelar una solicitud con reembolso | Cliente | Excepción / pago | Web, app |
| CU-21 | Abrir disputa y proponer un acuerdo | Cliente, Profesional | Excepción | Web, app |
| CU-22 | Resolver una disputa | Administrador, Sistema | Excepción / pago | Escritorio, backend |
| CU-23 | Chatear sobre un trabajo | Cliente, Profesional | Comunicación | Web, app |
| CU-24 | Recibir y gestionar notificaciones | Cliente, Profesional | Comunicación | Web, app |
| CU-25 | Completar perfil y solicitar verificación | Profesional | Gestión del profesional | App |
| CU-26 | Configurar tarifas, horario y disponibilidad | Profesional | Gestión del profesional | App |
| CU-27 | Consultar cobros y registrar cuenta bancaria | Profesional | Gestión del profesional | App |
| CU-28 | Acceder a la consola con segundo factor | Administrador, Colaborador interno | Administración | Escritorio |
| CU-29 | Verificar profesionales | Administrador | Administración | Escritorio |
| CU-30 | Supervisar métricas, pagos y liquidar al profesional | Administrador | Administración | Escritorio |
| CU-31 | Invitar colaborador interno | Administrador | Administración | Escritorio |
| CU-32 | Ejecutar procesos automáticos de pagos y soporte | Sistema | Backend | — |
| CU-33 | Reagendar la visita | Cliente registrado, Profesional | Reserva | Web, app |
| CU-34 | Atender la cola de soporte con mínimo privilegio | Colaborador interno (`soporte`, `qa`) | Administración | Escritorio |

**Total: 34 casos de uso** (4 de acceso, 2 de búsqueda, 5 de reserva y pago, 9 de ejecución y cierre, 3 de excepciones, 2 de comunicación, 3 de gestión del profesional, 5 de administración y 1 de sistema).

## 3. Diagrama de casos de uso

![Diagrama de casos de uso de MyWorksApp](casos_de_uso_diagrama.png)

La imagen se genera con `docs/_gen_diagrama_casos_de_uso.py` (notación UML: actores, límite del sistema, asociaciones, generalización, «include» y «extend»). Esta vista general tiene líneas que se cruzan; para el informe final se dibujó un diagrama de contexto y uno por paquete, sin cruces, en [`uml/paquetes/`](uml/paquetes/) (generador `draw.py`). La misma estructura en Mermaid, editable y visible directamente en GitHub (también en `casos_de_uso.mmd`):

```mermaid
flowchart LR
  V([Visitante])
  CI([Cliente invitado])
  CR([Cliente registrado])
  P([Profesional])
  A([Administrador])
  C([Colaborador interno: soporte / QA])
  S([Sistema / cron])
  TBK[[Transbank Webpay]]

  CI -. especializa .-> V
  CR -. especializa .-> V

  subgraph MWA[MyWorksApp]
    direction TB
    subgraph ACC[Acceso]
      CU01(CU-01 Registrarse)
      CU02(CU-02 Iniciar sesión)
      CU03(CU-03 Recuperar contraseña)
      CU04(CU-04 Derechos sobre datos)
    end
    subgraph BUS[Búsqueda y reserva]
      CU05(CU-05 Buscar con mapa)
      CU06(CU-06 Ver perfil y horas)
      CU07(CU-07 Solicitar y reservar)
      CU08(CU-08 Pagar en garantía)
      CU09(CU-09 Comprar como invitado)
      CU10(CU-10 Definir contraseña)
      CU33(CU-33 Reagendar la visita)
    end
    subgraph EJE[Ejecución y cierre]
      CU11(CU-11 Aceptar / rechazar)
      CU12(CU-12 Voy en camino + GPS)
      CU13(CU-13 Seguir en vivo)
      CU14(CU-14 Iniciar con PIN)
      CU15(CU-15 Cobro adicional)
      CU16(CU-16 Evidencia y finalizar)
      CU17(CU-17 Recibir conforme)
      CU18(CU-18 Calificar profesional)
      CU19(CU-19 Calificar cliente)
    end
    subgraph EXC[Excepciones y comunicación]
      CU20(CU-20 Cancelar con reembolso)
      CU21(CU-21 Disputa y acuerdo)
      CU22(CU-22 Resolver disputa)
      CU23(CU-23 Chat)
      CU24(CU-24 Notificaciones)
    end
    subgraph GES[Gestión del profesional]
      CU25(CU-25 Perfil y verificación)
      CU26(CU-26 Tarifas y horario)
      CU27(CU-27 Cobros y cuenta)
    end
    subgraph ADM[Administración]
      CU28(CU-28 Consola con 2FA)
      CU29(CU-29 Verificar profesionales)
      CU30(CU-30 Métricas y liquidación)
      CU31(CU-31 Invitar colaborador)
      CU32(CU-32 Procesos automáticos)
      CU34(CU-34 Cola de soporte)
    end
  end

  V --- CU01 & CU05 & CU06
  CI --- CU09 & CU10
  CR --- CU02 & CU03 & CU04 & CU07 & CU13 & CU17 & CU18 & CU20 & CU21 & CU23 & CU24 & CU33
  P --- CU02 & CU11 & CU12 & CU14 & CU15 & CU16 & CU19 & CU21 & CU23 & CU25 & CU26 & CU27 & CU33
  A --- CU28 & CU29 & CU30 & CU31 & CU22
  C --- CU28 & CU34
  S --- CU32 & CU22
  CU08 --- TBK
  CU09 --- TBK

  CU07 -. include .-> CU08
  CU09 -. include .-> CU08
  CU10 -. extend .-> CU09
  CU18 -. extend .-> CU17
  CU21 -. extend .-> CU17
  CU22 -. extend .-> CU21
```

Notas del diagrama: «include» significa que el caso base siempre ejecuta al incluido (reservar siempre pasa por el pago en garantía). «extend» significa que el caso que extiende se agrega al base solo bajo una condición: definir la contraseña después de una compra como invitado, calificar o abrir una disputa al momento de recibir el trabajo, y resolver por un tercero cuando las partes no llegan a acuerdo. La flecha apunta al caso base. Las relaciones de precedencia (por ejemplo, que iniciar con PIN requiere que el cliente vea su seguimiento) se documentan como precondiciones, no como «include».

## 4. Estados del trabajo (referencia para todos los casos)

La única forma de cambiar el estado de un trabajo es el RPC `transicionar_trabajo` (`SECURITY DEFINER`). El `UPDATE` directo a `trabajos` está revocado y protegido por los triggers `trabajos_proteger_campos` y `trabajos_bloquear_en_curso_directo`. Las transiciones válidas las define `transicion_trabajo_permitida` (`supabase/migrations/20261006000001_gps_y_base_profesional.sql`):

```
esperando_pago → pendiente → aceptado → en_camino → en_curso → esperando_aprobacion_cliente → completado
                                  └──────────────→ en_curso ⇄ pausado_orden_cambio
Terminales: completado, cancelado, expirado, no_asistio
```

Reglas transversales que impone el servidor:

- **RN-01.** Solo el profesional del trabajo pasa a `aceptado`, `en_camino`, `esperando_aprobacion_cliente`, `pausado_orden_cambio` y `no_asistio`.
- **RN-02.** Nadie pasa a `completado` con `transicionar_trabajo` salvo el administrador. El cliente cierra con `cerrar_trabajo_conforme` (CU-17).
- **RN-03.** En las modalidades con cobro, `aceptado`, `en_curso` y `pendiente` exigen un pago en garantía (`retenido` o `autorizado`).
- **RN-04.** Con una disputa activa, solo el administrador puede mover el trabajo.
- **RN-05.** No se puede cancelar con el pago retenido: primero hay que devolverlo (CU-20).
- **RN-06.** Comisión de la plataforma: 5 % del pago principal, con un mínimo de $1.000 y nunca más que el pago; se descuenta al profesional (`comision_servicio_clp`, `PLATFORM_COMMISSION_RATE = 0.05` y `PLATFORM_COMMISSION_MIN_CLP = 1000` en `shared/src/metrics/period.ts`, `PricingService.serviceFeeFor` en la app). En una orden de cambio el cliente paga el monto más 8 %.

---

## 5. Especificación detallada

### CU-01 Registrarse

| Campo | Detalle |
|---|---|
| **Actor(es)** | Visitante (principal); Supabase Auth (secundario) |
| **Descripción** | La persona crea una cuenta como cliente (web o app) o como profesional (solo app). |
| **Precondiciones** | No tiene sesión. El correo no está registrado. |
| **Postcondiciones** | Se crean el usuario en `auth.users` y su fila en `perfiles` con el rol elegido. Si es profesional, su ficha en `trabajadores` se completa después, en CU-25, y parte sin verificar. |

**Flujo principal**
1. El visitante elige «Registrarse» (web: modal «Crear cuenta» en `AuthModal.tsx`; app: `register_page.dart`).
2. En la app elige el tipo de cuenta: Cliente («Busco servicios profesionales») o Especialista («Ofrezco servicios profesionales»).
3. Ingresa nombre completo, correo, contraseña y su confirmación, y acepta los Términos y la Política de Privacidad. En la web resuelve además el desafío de Cloudflare Turnstile.
4. El sistema valida la contraseña: al menos 8 caracteres, con una letra y un número.
5. El sistema crea la cuenta en Supabase Auth y el perfil.
6. Según la configuración del proyecto, el sistema inicia la sesión o envía el correo «Confirma tu correo en MyWorksApp» por el SMTP de Resend.

**Flujos alternativos / excepciones**
- 3a. El correo ya existe: el sistema muestra el error de Supabase traducido al español (`translateAuthError`) y no crea nada.
- 4a. La contraseña no cumple la regla: se indica qué falta y se vuelve al paso 3.
- 3b. No aceptó los términos: el botón «Registrarse» no avanza.
- 1a. En la web solo hay registro de clientes. El texto aclara: «Los trabajadores usan la app móvil».
- 3c. En la web, si el widget de Turnstile puede mostrarse y no hay token, el formulario no se envía.

**Observación**: la web envía el token de Turnstile a Supabase Auth, pero el captcha de Auth **no está activado** (reporte del 20-nov), así que hoy el servidor no lo valida en el registro.

**Reglas de negocio**: RN-07, contraseña mínima de 8 caracteres con letras y dígitos (`supabase/config.toml`: `minimum_password_length = 8`, `password_requirements = "letters_digits"`).

**Trazabilidad**: `myworksapp_web/src/components/AuthModal.tsx`; `myworksapp_app/lib/features/auth/presentation/pages/register_page.dart`; `myworksapp_app/lib/core/domain/user_role.dart`; `shared/src/auth.ts`.

---

### CU-02 Iniciar sesión

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado, Profesional |
| **Descripción** | El usuario entra con su correo y contraseña y llega a la vista de su rol. |
| **Precondiciones** | Tiene una cuenta activa. |
| **Postcondiciones** | Hay una sesión JWT de Supabase activa y el sistema cargó el perfil (`perfiles`). |

**Flujo principal**
1. El usuario abre «Ingresar» (web) o la pantalla «Iniciar sesión» (app), donde elige Cliente o Especialista.
2. Ingresa su correo y contraseña y presiona «Entrar».
3. Supabase Auth valida las credenciales y el sistema lee el perfil con `getProfile`.
4. El sistema dirige al usuario según su rol: cliente → inicio o «Mis pedidos»; profesional → panel del profesional.

**Flujos alternativos / excepciones**
- 3a. Credenciales inválidas: se muestra un mensaje en español y no se revela si el correo existe.
- 3b. Correo sin confirmar: se avisa y se ofrece «Reenviar correo de confirmación».
- 4a. Un profesional intenta entrar en la web: la web es solo para clientes y lo deriva a la app.
- 4b. Un cliente tenía un pedido abierto en esta pestaña (`sessionStorage` `mwa-active-job`): la web abre directo su seguimiento (CU-13).

**Reglas de negocio**: la consola de escritorio tiene su propio acceso (CU-28).

**Trazabilidad**: `shared/src/auth.ts` (`getSessionProfile`, `translateAuthError`); `myworksapp_app/lib/features/auth/presentation/pages/login_page.dart`; `myworksapp_web/src/App.tsx` (restaurar el pedido activo).

---

### CU-03 Recuperar contraseña

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado, Profesional; Supabase Auth (correo) |
| **Descripción** | El usuario pide un enlace para restablecer su contraseña y luego define una nueva. |
| **Precondiciones** | Tiene una cuenta. Supabase tiene configurado el envío de correos (SMTP propio; ver la observación). |
| **Postcondiciones** | Se envía un correo con el enlace. Al abrirlo, el usuario define una contraseña nueva que cumple RN-07. |

**Flujo principal**
1. En «Iniciar sesión» (app o web) el usuario toca «¿Olvidaste tu contraseña?».
2. Ingresa su correo y confirma («Enviar enlace» en la web).
3. El sistema valida el correo y llama a `auth.resetPasswordForEmail`. En la web el enlace vuelve al origen desde el que se pidió, con `/?restablecer=1` (`passwordResetRedirect`); en producción, `https://myworksapp.cl/?restablecer=1`.
4. El sistema confirma el envío sin revelar si el correo existe.
5. Al abrir el enlace, la web recibe el evento `PASSWORD_RECOVERY` y muestra «Crea tu nueva contraseña». El usuario la escribe dos veces y presiona «Guardar contraseña».
6. El sistema la guarda con `auth.updateUser` y muestra «Contraseña actualizada».

**Flujos alternativos / excepciones**
- 2a. El correo es de un dominio de ejemplo (`example.com`, etc.): «Ese correo es de ejemplo y no recibe mensajes…» y no se llama a Supabase.
- 3a. Supabase no puede enviar el correo (dirección inválida o SMTP no configurado): «No pudimos enviar el correo a esa dirección…».
- 3b. El límite de correos por hora está agotado: el sistema informa el error y el usuario reintenta más tarde.
- 5a. La contraseña nueva es igual a la anterior: «La nueva contraseña debe ser distinta a la anterior.»
- 5b. No cumple RN-07 o las dos no coinciden: el formulario lo indica antes de enviar.

**Observación**: Supabase Auth envía por el SMTP de Resend (plantilla «Restablece tu contraseña de MyWorksApp», plan gratis de 100 correos al día). En la web el enlace solo sirve si se abre en el mismo navegador (PKCE). En la app, el correo sale pero el enlace abre la web sin `redirectTo` propio, y la app no puede canjear el código: restablecer desde la app no funciona hoy. El arreglo del flujo está en la rama `cursor/correos-resend`, sin merge.

**Trazabilidad**: `myworksapp_app/lib/features/auth/presentation/pages/forgot_password_page.dart`; `myworksapp_web/src/components/AuthModal.tsx` (modo `forgot`), `PasswordRecoveryModal.tsx`, `src/context/AuthContext.tsx`; `shared/src/auth.ts` (`requestPasswordReset`, `passwordResetRedirect`), `shared/src/emailDomain.ts`.

---

### CU-04 Ejercer derechos sobre los datos (exportar / eliminar cuenta)

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado, Profesional |
| **Descripción** | El usuario exporta sus datos personales o elimina su cuenta («derecho al olvido»). |
| **Precondiciones** | Tiene una sesión iniciada en la web o en la app. |
| **Postcondiciones** | Exportar: se generan los datos exportados. Eliminar: el perfil queda anonimizado, con `estado_cuenta = eliminado`, sin consentimientos ni direcciones guardadas. En la app, además, los mensajes y reportes propios quedan anonimizados. |

**Flujo principal (eliminar)**
1. El usuario abre «Mis Derechos» desde Configuración.
2. Elige eliminar su cuenta. El sistema pide una primera confirmación («Confirmar Eliminación» → «Eliminar Permanentemente»).
3. El sistema pide una segunda confirmación («Última Confirmación»).
4. El sistema anonimiza los datos personales, elimina consentimientos y bloqueos, anonimiza mensajes y reportes, y marca la cuenta como eliminada.

**Flujo en la web (`/cuenta`)**
1. El cliente abre «Cuenta» y ve su nombre, sus direcciones guardadas (`direcciones_cliente`) y sus datos.
2. «Exportar mis datos» llama `exportar_mis_datos` y descarga `mis-datos-myworksapp.json`.
3. «Eliminar cuenta» llama `solicitar_eliminacion_cuenta`, que anonimiza el perfil (nombre «Usuario eliminado», correo `eliminado+<id>@invalid`, sin teléfono ni foto), marca `estado_cuenta = eliminado` y borra las direcciones y los consentimientos.

**Flujos alternativos / excepciones**
- 2a / 3a. El usuario cancela («Cancelar» o «No, cancelar»): no se modifica nada.
- 1a. Exportar sin sesión: «Debes iniciar sesión para exportar tus datos».
- 3b (web). Tiene un pedido abierto (esperando pago, aceptado, en camino, en curso, pausado por orden de cambio o esperando aprobación): el RPC lo rechaza y la web muestra «No se pudo eliminar la cuenta. Si tienes un pedido abierto, ciérralo primero.»

**Reglas de negocio**: se conserva la integridad histórica de trabajos y pagos (borrado lógico con anonimización, no físico).

**Trazabilidad**: `myworksapp_web/src/pages/AccountPage.tsx`; migración `20261120170000_derechos_y_cobro_extra.sql` (`exportar_mis_datos`, `solicitar_eliminacion_cuenta`, `direcciones_cliente`); `myworksapp_app/lib/features/gdpr/presentation/pages/user_rights_page.dart`; `lib/core/services/account_deletion_service.dart`; `lib/core/services/gdpr_service.dart`.

---

### CU-05 Buscar profesionales con mapa y filtros

| Campo | Detalle |
|---|---|
| **Actor(es)** | Visitante (incluye Cliente invitado y Cliente registrado) |
| **Descripción** | El usuario elige un oficio y ve los profesionales disponibles en tarjetas y en un mapa, con filtros y orden. |
| **Precondiciones** | Ninguna (funciona sin sesión). |
| **Postcondiciones** | Ninguna. Es solo lectura. |

**Flujo principal**
1. El sistema muestra los oficios que tienen al menos un profesional disponible y con precio (RPC `categorias_con_disponibles`). Los oficios sin profesionales se ocultan.
2. El usuario elige un oficio o escribe el problema («plomería»). La búsqueda no distingue mayúsculas ni tildes, en la web y en la app: «electrico» y «Eléctrico» llevan al oficio Electricidad.
3. El sistema pide la primera página del catálogo (RPC `listar_profesionales_catalogo`, máximo 20 por página, ordenada por `score_listado`, solo profesionales verificados, disponibles y con precios configurados).
4. El sistema muestra tarjetas con foto, nombre, oficio, nota, número de trabajos, «Desde $X / visita», «Disponible ahora» u «Ocupado» e insignia «Élite».
5. El sistema dibuja el mapa (OpenFreeMap Positron) con un pin por profesional en su ubicación aproximada.
6. El usuario fija la ubicación del trabajo: dirección («Buscar»), «Usar GPS» o un punto en el mapa.
7. El usuario filtra por calificación mínima (4,5 / 4,0 / 3,5), por «Disponible ahora», y ordena por relevancia, precio o calificación.

**Flujos alternativos / excepciones**
- 3a. Hay más resultados: el sistema pagina con cursor (`p_cursor_calificacion`, `p_cursor_id`).
- 3b. Falla el RPC: la consulta REST equivalente sobre `trabajadores` actúa como respaldo.
- 6a. El usuario niega el GPS: puede escribir la dirección o marcar en el mapa.
- 4a. Un profesional tiene un trabajo activo: aparece «Ocupado» (RPC `profesionales_ocupados`, que devuelve solo identificadores).

**Reglas de negocio**: el catálogo no expone correos ni la ubicación exacta (migración `20261113000002_catalogo_ubicacion_aproximada_anon.sql`). Fuera del radio sin recargo se cobra un recargo por km (`shared` → `transportSurcharge`, `withinTravelRange`).

**Trazabilidad**: `shared/src/repositories/workers.ts` (`fetchCategoriesWithPros`, `fetchWorkersCatalog`); `myworksapp_web/src/components/SearchResultsView.tsx`, `PremiumSearchMap.tsx`; `myworksapp_app/lib/features/user/presentation/pages/worker_list_page.dart`, `worker_search_map.dart`. Medido en la prueba de carga (`docs/pruebas/prueba_carga_rendimiento.md`).

---

### CU-06 Ver perfil del profesional y horas libres

| Campo | Detalle |
|---|---|
| **Actor(es)** | Visitante |
| **Descripción** | El usuario abre el perfil público de un profesional y ve su información, sus reseñas, su cobertura y las horas que tiene libres. |
| **Precondiciones** | CU-05 mostró al profesional. |
| **Postcondiciones** | Ninguna (solo lectura). |

**Flujo principal**
1. El usuario selecciona una tarjeta o un pin.
2. El sistema dibuja el círculo de cobertura (radio sin recargo) y muestra el resumen (nota, tarifa y radio).
3. En la web, `/profesional/:id` muestra el perfil público (`perfil_publico_profesional`), el horario (`horario_publico_profesional`) y las reseñas (`resenas_publicas_profesional`), sin abrir la tabla `calificaciones` a usuarios anónimos. En la app, el sistema muestra «Sobre mí», especialidad, portafolio (antes y después), «Opiniones de clientes» y cobertura.
4. El sistema consulta las horas libres de los próximos 14 días (RPC `horarios_libres_profesional`).
5. El sistema muestra solo las horas publicadas por el profesional que siguen libres. Cada bloque aparece una sola vez.

**Flujos alternativos / excepciones**
- 5a. El profesional no tiene horas libres: el selector queda vacío y no se puede continuar con la reserva rápida.
- 3a. El id no existe o el profesional es una cuenta demo con `demo_modo` distinto de 1: el perfil no se muestra.

**Reglas de negocio**: RN-08, solo se ofrecen horas publicadas y libres. El servidor vuelve a validarlo al reservar (trigger `trabajos_horario_unico`: «elige un horario publicado por el profesional»).

**Trazabilidad**: `shared/src/repositories/workers.ts` (`fetchWorkerFreeSlots`); `myworksapp_web/src/pages/ProfessionalProfilePage.tsx`, `src/components/QuickBookingBar.tsx`; migración `20261120160000_perfil_publico_profesional.sql`; `myworksapp_app/lib/features/user/presentation/pages/worker_detail_page.dart`, `time_slot_selector.dart`, `worker_reviews_section.dart`.

---

### CU-07 Solicitar servicio y reservar hora

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado |
| **Descripción** | El cliente define qué necesita, cuándo y dónde, y confirma el pedido. |
| **Precondiciones** | Tiene sesión. Eligió un profesional verificado y disponible y una hora libre (CU-06). |
| **Postcondiciones** | Hay un trabajo en `esperando_pago` asociado al cliente, al profesional, al servicio y a la hora (`fecha_programada`). Se continúa en CU-08. |

**Flujo principal**
1. El cliente elige una hora en «Reserva rápida» (web) o en «Agendar visita» (app: fecha, horario, dirección y notas).
2. Presiona «Continuar con la reserva» o «Continuar al pago».
3. El sistema muestra «Confirmar pedido» con el total y el aviso «El pago queda retenido hasta que recibas el trabajo».
4. El cliente confirma. El sistema crea el trabajo en `esperando_pago` (`createJob`). El servidor genera en ese momento el PIN de inicio (trigger `trabajos_crear_pin_inicio`).
5. Se incluye CU-08.

**Flujos alternativos / excepciones**
- 1a. App, «Solicitar Servicio»: descripción (mínimo 10 caracteres), ubicación en el mapa y cuestionario de forma de cobro (precio fijo, bloque de horas o cotización).
- 4a. Otra persona tomó la hora: el trigger `trabajos_horario_unico` rechaza el pedido y el cliente elige otra.
- 4b. El profesional no está verificado: «Este profesional todavía no está verificado para cobrar».
- 4c. El cliente no tiene sesión: el sistema ofrece iniciar sesión (CU-02) o comprar como invitado (CU-09).

**Reglas de negocio**: RN-03, RN-08. El trabajo no se ofrece al profesional hasta que el pago queda retenido.

**Trazabilidad**: `shared/src/repositories/jobs.ts` (`createJob`); `myworksapp_web/src/components/PaymentCheckoutModal.tsx`, `QuickBookingBar.tsx`; `myworksapp_app/lib/features/user/presentation/pages/quick_booking_page.dart`, `service_request_page.dart`; migración `20261115180001_inicio_trabajo_requiere_pin.sql`.

---

### CU-08 Pagar con Webpay en garantía (escrow)

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado (principal); Transbank Webpay (externo) |
| **Descripción** | El cliente paga en Transbank. El dinero queda **retenido** y se libera solo con su conformidad (CU-17), por plazo o por una disputa. |
| **Precondiciones** | Hay un trabajo en `esperando_pago` (CU-07). |
| **Postcondiciones** | Éxito: el pago queda en `retenido` y el trabajo en `pendiente`, visible para el profesional. Mientras el trabajo sigue en `esperando_pago`, el profesional no lo ve en sus listas ni en sus contadores. Rechazo o cancelación: el pago queda en `anulado` y el trabajo en `cancelado`. |

**Flujo principal**
1. El sistema invoca la Edge Function `webpay-create`, que valida el monto contra la tarifa, crea el pago `pendiente` y devuelve una URL firmada de traspaso. El `token_ws` no se entrega al cliente.
2. El cliente es redirigido al formulario de Transbank, ingresa la tarjeta y autoriza en el banco.
3. Transbank vuelve a `webpay-commit`, que confirma la transacción.
4. El sistema marca el pago como `retenido` y abre el trabajo: `esperando_pago` → `pendiente` (`open_job_after_hold.ts`).
5. El cliente vuelve a la web o la app y ve «Pedido confirmado · Pago protegido» o «Pago retenido en garantía».
6. Se notifica al profesional (CU-24).

**Flujos alternativos / excepciones**
- 2a. App, Oneclick: el cliente inscribe su tarjeta («Inscribir tarjeta en Transbank») y después confirma con la tarjeta guardada (`oneclick-charge`). La app no guarda el número de tarjeta. Al terminar el paso del banco, `oneclick-return` lleva al cliente a una dirección https del sitio (`?pago=ok` con el seguimiento, o `?pago=fail` / `?tarjeta=fail` con un aviso claro).
- 2b. El cliente cancela en Webpay: «Pago cancelado. No se realizó ningún cargo.» El pago queda `anulado` y el trabajo `cancelado`.
- 3a. El retorno se pierde (el cliente cierra el navegador): la reconciliación automática cada 5 min (CU-32) consulta a Transbank y fija el estado.
- 3b. Nadie paga en 30 min: el pedido `esperando_pago` se cierra solo (CU-32).
- 1a. Más de 20 intentos por minuto desde una IP o 10 por usuario: el servidor responde 429.

**Reglas de negocio**: RN-09, la plataforma nunca pide ni guarda el número de tarjeta. RN-10, el monto se valida en el servidor contra la tarifa del profesional. RN-03.

**Trazabilidad**: `supabase/functions/webpay-create`, `webpay-commit`, `webpay-handoff`, `webpay-status`, `oneclick-*`, `_shared/open_job_after_hold.ts`; `myworksapp_web/src/components/PaidReturnView.tsx`; `myworksapp_app/lib/core/widgets/escrow_checkout_sheet.dart`, `features/payments/...`.

---

### CU-09 Comprar como invitado

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente invitado (principal); Transbank (externo); Cloudflare Turnstile (secundario) |
| **Descripción** | Un visitante sin cuenta reserva y paga entregando solo sus datos de contacto. |
| **Precondiciones** | Eligió un profesional y una hora (CU-06). No tiene sesión. |
| **Postcondiciones** | Hay una cuenta de cliente creada para su correo, un trabajo `pendiente` y un pago `retenido`. El retorno trae un token de alta para CU-10. |

**Flujo principal**
1. En «Pedido sin sesión — Datos para la visita» el invitado ingresa nombre, correo, teléfono (+56 9) y dirección.
2. Resuelve la verificación anti-robots (Turnstile).
3. Presiona «Continuar a Webpay».
4. La Edge Function `guest-checkout` verifica Turnstile en el servidor, los límites de tasa (también el límite global en Postgres, `rate_limit_consumir`), que el profesional esté verificado y que el monto coincida con la tarifa. Después crea la cuenta, el trabajo y el pago. La respuesta no revela si el correo ya tenía cuenta.
5. Se incluye CU-08 desde el paso 2.
6. Al volver pagado, la web muestra «Crea tu contraseña» y «Ver mi pedido» (se extiende a CU-10).

**Flujos alternativos / excepciones**
- 4a. Más de 5 intentos por minuto desde la misma IP o más de 3 con el mismo correo: 429.
- 4b. Turnstile falla: no se crea nada. Si falta `TURNSTILE_SECRET_KEY` la función responde 503.
- 4e. El profesional es una cuenta demo y `demo_modo` no es 1: no se puede reservar ni cobrar.
- 4c. El monto no coincide con la tarifa: «Monto X no coincide con tarifa Y».
- 4d. El profesional no está verificado: «Este profesional todavía no está verificado para cobrar».

**Reglas de negocio**: RN-09, RN-10. El correo del invitado debe ser real, porque Supabase rechaza dominios reservados como `example.com`.

**Trazabilidad**: `myworksapp_web/src/components/GuestCheckoutForm.tsx`; `supabase/functions/guest-checkout/index.ts`, `_shared/turnstile_gate.ts`, `_shared/rate_limit.ts`, `_shared/rate_limit_db.ts`; migración `20261120150000_rate_limit_global.sql`.

---

### CU-10 Definir contraseña tras pagar como invitado

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente invitado |
| **Descripción** | El invitado elige una contraseña para su cuenta nueva y queda como cliente registrado. |
| **Precondiciones** | Completó CU-09. La URL de retorno trae `invitado=1` y un token `alta` firmado por `webpay-commit`. |
| **Postcondiciones** | La cuenta queda con contraseña. Con `demo_modo = 1` el correo se marca como confirmado; con `demo_modo = 0` se envía el correo de confirmación. |

**Flujo principal**
1. La web muestra «Crea tu contraseña».
2. El invitado escribe una contraseña que cumpla la regla y confirma.
3. La Edge Function `definir-clave-invitado` verifica el token firmado y fija la contraseña.
4. El sistema muestra «Contraseña lista. Entra con tu correo en la próxima visita.» o «Te enviamos un correo para confirmar.»

**Flujos alternativos / excepciones**
- 3a. Token inválido o vencido: no se cambia nada. El invitado puede usar CU-03 si hay SMTP configurado.
- 3b. Más de 8 intentos por minuto por IP: 429.
- 2a. La contraseña no cumple la regla: «Incluye al menos una letra / un número / 8 caracteres».

**Trazabilidad**: `myworksapp_web/src/components/PaidReturnView.tsx`; `supabase/functions/definir-clave-invitado/index.ts`; `app_config.demo_modo`.

---

### CU-11 Aceptar o rechazar un pedido

| Campo | Detalle |
|---|---|
| **Actor(es)** | Profesional |
| **Descripción** | El profesional revisa un pedido pendiente, con la reputación del cliente, y lo acepta o lo rechaza. |
| **Precondiciones** | Hay un trabajo `pendiente` con pago `retenido` asignado a él. |
| **Postcondiciones** | Aceptar: el trabajo pasa a `aceptado` y el cliente ve su PIN. Rechazar: el pago se devuelve a la tarjeta y el trabajo pasa a `cancelado`. |

**Flujo principal**
1. El profesional ve la tarjeta PENDIENTE en su panel y abre «Ver detalles del trabajo».
2. Revisa la descripción, la dirección, la hora y la reputación del cliente.
3. Presiona «Aceptar Trabajo».
4. `transicionar_trabajo(..., 'aceptado')` valida RN-01 y RN-03.
5. Se notifica al cliente.

**Flujos alternativos / excepciones**
- 3a. Rechazar: presiona «Rechazar» y confirma con «Sí, rechazar». La Edge Function `webpay-refund-rejection` devuelve el pago (una sola vez, `refund_once.ts`) y cancela el trabajo.
- 4a. Hay una disputa abierta: no se permite (RN-04).

**Trazabilidad**: `myworksapp_app/lib/features/jobs/presentation/widgets/job_detail_actions_section.dart`; `lib/features/worker/presentation/pages/worker_home_page.dart`; `supabase/functions/webpay-refund-rejection`; SQL `transicionar_trabajo`.

---

### CU-12 Avisar «voy en camino» y compartir ubicación

| Campo | Detalle |
|---|---|
| **Actor(es)** | Profesional |
| **Descripción** | El profesional indica que va al domicilio y la app publica su posición. |
| **Precondiciones** | El trabajo está en `aceptado`. Dio permiso de ubicación. |
| **Postcondiciones** | El trabajo queda en `en_camino` y hay posiciones en `ubicacion_en_vivo`. |

**Flujo principal**
1. El profesional presiona «Voy en camino».
2. `transicionar_trabajo(..., 'en_camino')`.
3. La app publica la posición GPS **solo en primer plano**, como máximo cada 20 s o cada 40 m.
4. El cliente ve el pin moverse (CU-13).

**Flujos alternativos / excepciones**
- 3a. Sin permiso de GPS: el cliente ve «Sin GPS» y el trabajo avanza igual.
- 3b. El profesional cierra la app: la publicación se detiene («Se detiene si cierras la app o termina el trabajo»).

**Reglas de negocio**: al terminar el trabajo se borra la ubicación (trigger `trabajos_borrar_gps`).

**Trazabilidad**: `myworksapp_app/lib/core/services/gps_publish_gate.dart`, `worker_gps_publisher.dart`; `myworksapp_web/src/hooks/useLiveJobLocation.ts`.

---

### CU-13 Seguir el pedido en vivo

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado (o el invitado ya con cuenta) |
| **Descripción** | El cliente ve el estado, la llegada estimada, al profesional, su PIN de inicio, la evidencia y el chat. |
| **Precondiciones** | Tiene un trabajo propio que no está cerrado. |
| **Postcondiciones** | Ninguna (lectura). |

**Flujo principal**
1. El cliente abre «Mis pedidos» y elige el trabajo (o vuelve directo desde el pago).
2. El sistema muestra el servicio, el ID, la dirección, la ficha del profesional y el «ESTADO ACTUAL».
3. Con el trabajo `en_camino`, el sistema calcula la llegada a 28 km/h («sin tráfico en vivo»).
4. Con el trabajo `aceptado` o `en_camino`, muestra «PIN PARA INICIAR» (4 dígitos, RPC `obtener_pin_inicio`).
5. La web refresca el estado cada 8 s.

**Flujos alternativos / excepciones**
- 4a. El trabajo está en `en_curso` o después: el PIN deja de mostrarse.
- 1a. El pedido no es del usuario: RLS no lo devuelve («No encontramos ese pedido»).

**Reglas de negocio**: RN-11, solo el cliente ve el PIN (`START_PIN_VISIBLE_STATUSES = ['aceptado','en_camino']`).

**Trazabilidad**: `myworksapp_web/src/components/TrackingDashboard.tsx`; `shared/src/jobs/startPin.ts`, `shared/src/geo/distance.ts`; `myworksapp_app/lib/features/jobs/.../client_start_pin_card.dart`, `client_live_tracking.dart`.

---

### CU-14 Iniciar el trabajo con PIN

| Campo | Detalle |
|---|---|
| **Actor(es)** | Profesional (principal); Cliente (le dicta el PIN) |
| **Descripción** | Al llegar, el profesional ingresa el PIN que le dice el cliente. Sin un PIN válido no puede pasar a «en curso». |
| **Precondiciones** | El trabajo está en `aceptado` o `en_camino`. El cliente tiene el PIN (CU-13). |
| **Postcondiciones** | El trabajo queda en `en_curso`. Cada intento queda registrado en `intentos_pin_inicio`. |

**Flujo principal**
1. El profesional presiona «Iniciar trabajo».
2. El sistema abre «Pide al cliente el PIN de 4 dígitos que aparece en su pedido».
3. El profesional ingresa los 4 dígitos y presiona «Confirmar PIN».
4. `intentar_pin_inicio` compara el PIN, guardado en una tabla privada que el profesional no puede leer.
5. Si es correcto, abre una **ventana de 2 minutos** (`pin_ok_hasta = now() + 2 min`).
6. La app llama a `transicionar_trabajo(..., 'en_curso')`, que verifica la ventana vigente para ese mismo profesional y la consume.

**Flujos alternativos / excepciones**
- 4a. PIN incorrecto: «PIN incorrecto», con los intentos restantes.
- 4b. **5 intentos fallidos**: bloqueo de **15 minutos** por trabajo («Demasiados intentos fallidos. Espera 15 minutos para volver a ingresar el PIN.»).
- 6a. La ventana de 2 min venció: hay que ingresar el PIN otra vez.
- 6b. Intento de `UPDATE` directo a `en_curso`: lo bloquea el trigger `trabajos_bloquear_en_curso_directo`.
- 6c. El administrador puede iniciar sin PIN (excepción operativa).

**Reglas de negocio**: RN-12 (PIN obligatorio, 5 intentos, bloqueo de 15 min, ventana de 2 min).

**Trazabilidad**: migración `supabase/migrations/20261115180001_inicio_trabajo_requiere_pin.sql` (`intentar_pin_inicio`, `obtener_pin_inicio`, `bloqueos_pin_inicio`); `shared/src/jobs/startPin.ts`; `myworksapp_app/lib/core/widgets/design_system/service_pin_dialog.dart`; pruebas `docs/PRUEBAS_PIN_INICIO.sql`.

---

### CU-15 Solicitar y aprobar un cobro adicional (orden de cambio)

| Campo | Detalle |
|---|---|
| **Actor(es)** | Profesional (solicita); Cliente registrado (aprueba o rechaza); Transbank |
| **Descripción** | Durante el trabajo, el profesional pide un cobro extra por trabajo adicional y el cliente lo paga aparte o lo rechaza. |
| **Precondiciones** | El trabajo está en `en_curso` y el usuario es el profesional asignado. |
| **Postcondiciones** | Aprobada: un segundo pago retenido vinculado a la orden (`id_orden_cambio`) y el trabajo de vuelta en `en_curso`. Rechazada: la orden queda rechazada (`rechazar_orden_cambio`) y el trabajo vuelve a `en_curso`. |

**Flujo principal**
1. El profesional presiona «Solicitar cobro adicional» (o «Solicitar horas extra» en bloques por hora) e ingresa título, descripción y monto.
2. El sistema crea la orden `pendiente` y el trabajo pasa a `pausado_orden_cambio`.
3. El cliente ve la orden, en la app o en el seguimiento de la web (`ChangeOrderPanel.tsx`), con el monto más la tarifa de plataforma (8 %) calculado por `monto_a_cobrar_orden_cambio`, y presiona «Aprobar y pagar» o «Rechazar».
4. Se incluye CU-08 con un pago de tipo orden de cambio.
5. Con el pago retenido, el trabajo vuelve a `en_curso`.

**Flujos alternativos / excepciones**
- 1a. El trabajo no está en curso: «Solo se pueden enviar órdenes de cambio con el trabajo en curso».
- 3a. El cliente rechaza: `rechazar_orden_cambio` deja la orden rechazada y el trabajo vuelve a `en_curso`.
- 3b. La orden ya fue respondida: «La orden de cambio ya fue respondida».

**Trazabilidad**: `myworksapp_app/lib/core/services/change_order_service.dart`; `features/jobs/presentation/pages/job_detail_workflows.dart`; `myworksapp_web/src/components/ChangeOrderPanel.tsx`; `supabase/functions/webpay-create`, `webpay-commit` (`id_orden_cambio`); migraciones `20261109000002_orden_cambio_webpay.sql` y `20261120170000_derechos_y_cobro_extra.sql`.

---

### CU-16 Subir evidencia y finalizar el trabajo

| Campo | Detalle |
|---|---|
| **Actor(es)** | Profesional |
| **Descripción** | El profesional sube fotos o videos del trabajo terminado y lo marca como finalizado. |
| **Precondiciones** | El trabajo está en `en_curso`. |
| **Postcondiciones** | Hay archivos en `fotos_trabajo` (depósito privado) y el trabajo queda en `esperando_aprobacion_cliente`. |

**Flujo principal**
1. El profesional abre «Subir evidencia» y elige «Tomar foto», «Elegir foto de galería» o «Elegir video».
2. El sistema convierte las fotos a WebP y las sube al depósito privado `evidencias` (videos de hasta 20 MB).
3. El profesional presiona «Finalizar Trabajo» y confirma.
4. `transicionar_trabajo(..., 'esperando_aprobacion_cliente')`.
5. Se notifica al cliente para que revise (CU-17).

**Flujos alternativos / excepciones**
- 3a. Finalizar sin evidencia: el trigger `trabajos_exigir_evidencia` lo impide («sube al menos una evidencia antes de declarar el trabajo terminado»).
- 2a. La foto no está en WebP: el trigger `fotos_trabajo_exigir_webp` la rechaza.
- 1a. El cliente no se presentó: el profesional puede marcar `no_asistio` si no hay pago retenido. Si lo hay, debe abrir una disputa.

**Trazabilidad**: `myworksapp_app/lib/features/jobs/presentation/pages/job_photos_page.dart`; `shared/src/evidence/save.ts`; migraciones `20261108000001_evidencia_webp.sql`, `20261115051455_bucket_evidencias.sql`, `20261115051532_evidencias_video_20mb.sql`.

---

### CU-17 Recibir conforme y liberar el pago

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado (principal); Sistema (liberación por plazo) |
| **Descripción** | El cliente revisa la evidencia y declara que recibió conforme. El pago retenido se libera al profesional. **No es un segundo cargo.** |
| **Precondiciones** | El trabajo está en `esperando_aprobacion_cliente`, con evidencia y un pago retenido. |
| **Postcondiciones** | El trabajo queda en `completado` y el pago en `liberado` (`marcar_pago_liberado`). El monto queda por transferir al profesional (CU-27 y CU-30). |

**Flujo principal**
1. El cliente abre «Ver evidencia (fotos y videos)», con enlaces temporales.
2. Presiona «Recibo conforme» (web) o «Segunda confirmación: recibo conforme» → «Liberar fondos» (app).
3. `cerrar_trabajo_conforme` verifica que sea el cliente, el estado, la evidencia, que no haya disputa y que exista un pago en garantía.
4. El sistema libera el pago y cierra el trabajo.
5. El sistema muestra «Pago liberado — Recibiste conforme».
6. Se ofrece calificar (se extiende a CU-18).

**Flujos alternativos / excepciones**
- 2a. «No estoy conforme»: se extiende a CU-21 (disputa). El pago sigue retenido.
- 3a. No hay evidencia: «falta la evidencia del especialista; el pago sigue retenido».
- 3b. Hay una disputa abierta: «hay una disputa abierta; el pago sigue retenido».
- 2b. **El cliente no responde en 48 h** y hay evidencia: el Sistema libera el pago («El cliente no respondió dentro del plazo. El pago queda liberado.», CU-32).

**Reglas de negocio**: RN-02, RN-13 (silencio de 48 h, `soporte_plazo_silencio_horas`). En estado `esperando_aprobacion_cliente` no se puede cancelar: hay que abrir una disputa.

**Trazabilidad**: SQL `cerrar_trabajo_conforme` (migración `20261112000001_soporte_automatico.sql`); `shared/src/repositories/jobs.ts`; `myworksapp_web/src/components/TrackingDashboard.tsx`; `myworksapp_app/lib/features/jobs/.../job_detail_client_approval_card.dart`.

---

### CU-18 Calificar al profesional

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado |
| **Descripción** | El cliente pone de 1 a 5 estrellas y un comentario. La nota alimenta el ranking y el «Élite del mes». |
| **Precondiciones** | El trabajo está `completado` y no hay una disputa abierta. |
| **Postcondiciones** | Hay una fila en `calificaciones` (`direccion = cliente_a_trabajador`). Los triggers recalculan la nota del profesional y evalúan la reseña (`senales_resena`). |

**Flujo principal**
1. El cliente abre «Calificar Trabajo — ¿Cómo fue tu experiencia?» en la app, o la tarjeta «Califica a …» en el seguimiento web de un trabajo completado.
2. Elige las estrellas y escribe un comentario opcional.
3. Presiona «Enviar calificación».
4. El sistema guarda la nota. Los triggers `calificaciones_refrescar_trabajador` y `calificaciones_evaluar_resena` actualizan la reputación.

**Flujos alternativos / excepciones**
- 1a. Hay una disputa abierta: la calificación queda bloqueada.
- 1b. La nota ya existe (por ejemplo, se puso desde la web): la app consulta `calificaciones` y en vez del botón muestra «Ya calificaste este trabajo».
- 4a. Una reseña sospechosa (por ejemplo, un 1 o un 5 con señales de abuso) queda `en_revision` con menor peso de confianza.
- 4b. El trabajo ya tiene una calificación del cliente: el índice único `calificaciones_trabajo_direccion_uidx` la rechaza y la web muestra la nota ya enviada.
- 4c. El trabajo no está completado (por ejemplo, cancelado): la política RLS de `calificaciones` rechaza la fila.

**Trazabilidad**: `myworksapp_app/lib/features/ratings/presentation/pages/rating_page.dart`; `myworksapp_web/src/components/JobClientActions.tsx`, `shared/src/jobs/clientActions.ts` (`rateJobAsClient`); tabla `calificaciones` y sus triggers; `docs/AUTOMATIZACION_RANKING_Y_RESENAS.md`.

---

### CU-19 Calificar al cliente

| Campo | Detalle |
|---|---|
| **Actor(es)** | Profesional |
| **Descripción** | El profesional califica al cliente. La nota se muestra a otros profesionales antes de aceptar. |
| **Precondiciones** | El trabajo está `completado`, es suyo y no hay una disputa abierta. |
| **Postcondiciones** | Una sola fila por trabajo en `calificaciones_cliente` (`UNIQUE (id_trabajo)`). Se actualiza `perfiles.reputacion_cliente`. |

**Flujo principal**
1. El profesional presiona «Calificar al cliente».
2. Elige de 1 a 5 y un comentario. La pantalla aclara: «Esta nota queda en el perfil del cliente. No mueve el pago.»
3. `calificar_cliente` valida y guarda.

**Flujos alternativos / excepciones**
- 3a. Nota fuera de 1–5: «la nota va de 1 a 5».
- 3b. El trabajo no está completado: «califica al cliente cuando el trabajo ya esta completado».
- 3c. Hay una disputa abierta: «la reputacion queda en pausa».

**Trazabilidad**: SQL `calificar_cliente` (migraciones `20261025000001_revision_patrocinante.sql` y `20261115051507_calificacion_bidireccional.sql`).

---

### CU-20 Cancelar una solicitud con reembolso

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado |
| **Descripción** | El cliente cancela un pedido que el profesional todavía no acepta y el dinero vuelve a su tarjeta. |
| **Precondiciones** | El trabajo está en `pendiente` y no hay una disputa abierta. |
| **Postcondiciones** | El pago queda reembolsado y el trabajo en `cancelado`. |

**Flujo principal**
1. En el detalle del trabajo en la app, o en el seguimiento web, el cliente presiona «Cancelar solicitud».
2. El sistema pregunta por el motivo («¿Por qué cancelas?») y el cliente presiona «Sí, cancelar».
3. La Edge Function `webpay-refund-cancellation` devuelve la garantía a la tarjeta (una sola vez).
4. `transicionar_trabajo(..., 'cancelado')` cierra el trabajo.

**Flujos alternativos / excepciones**
- 1a. El trabajo ya fue aceptado o va más avanzado: el botón no aparece para el cliente. Debe hablar con el profesional (CU-23) o abrir una disputa (CU-21).
- 4a. El reembolso no se completó: la transición falla («devuelve el pago a la tarjeta antes de cancelar», RN-05) y el sistema lo reintenta (CU-32).

**Postcondición adicional**: se registra el motivo en `cancelaciones_trabajo` y se notifica al profesional. En la web, el trabajo cancelado ya no ofrece reagendar, disputar ni subir evidencia.

**Trazabilidad**: `myworksapp_app/lib/features/jobs/presentation/widgets/job_detail_actions_section.dart` (condición `!isWorker && status == pendiente`); `myworksapp_web/src/components/JobClientActions.tsx`, `shared/src/jobs/clientActions.ts` (`cancelJobAsClient`); `supabase/functions/webpay-refund-cancellation`, `_shared/refund_once.ts`.

---

### CU-21 Abrir disputa y proponer un acuerdo

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado, Profesional |
| **Descripción** | Una de las partes reclama. El pago sigue retenido y las partes pueden resolverlo entre ellas. |
| **Precondiciones** | Hay un trabajo con pago retenido y sin una disputa activa. |
| **Postcondiciones** | Hay una disputa en `disputas`, clasificada automáticamente (resolución simple o `requiere_humano`). El trabajo queda congelado para las partes (RN-04). |

**Flujo principal**
1. La parte presiona «Abrir disputa» (o «No estoy conforme» → «Abrir ticket») e ingresa el motivo y la descripción.
2. `abrir_disputa` valida que sea una parte del trabajo, que haya motivo y que no exista otra disputa activa.
3. El sistema clasifica la disputa según el monto y el historial.
4. Una parte propone un acuerdo: «Aceptar la entrega», «Pedir que lo rehaga» o «Anular y devolver el pago» (`proponer_acuerdo`).
5. La otra parte acepta o rechaza (`responder_acuerdo`). Si acepta, el sistema aplica el resultado: liberar, volver a `en_curso` o reembolsar.

**Flujos alternativos / excepciones**
- 2a. Ya existe una disputa abierta: «Ya existe una disputa abierta para este trabajo».
- 4a. Ya hay un acuerdo pendiente: «ya hay un acuerdo pendiente».
- 5a. Sin acuerdo dentro del plazo: se extiende a CU-22.
- 1a. Comentar el expediente (`comentar_disputa`).

**Reglas de negocio**: RN-04. Con la disputa abierta, la calificación queda en pausa (CU-18 y CU-19).

**Trazabilidad**: SQL `abrir_disputa`, `proponer_acuerdo`, `responder_acuerdo`, `comentar_disputa` (migración `20261112000001_soporte_automatico.sql`); `myworksapp_web/src/App.tsx` (llamadas a esos RPC); `shared/src/repositories/disputes.ts`.

---

### CU-22 Resolver una disputa

| Campo | Detalle |
|---|---|
| **Actor(es)** | Administrador (principal); Sistema (cierre automático) |
| **Descripción** | Se decide si el pago retenido se libera al profesional o se devuelve al cliente. |
| **Precondiciones** | Hay una disputa activa. |
| **Postcondiciones** | La disputa queda cerrada, con el pago `liberado` (trabajo `completado`) o reembolsado (trabajo `cancelado`). |

**Flujo principal (humano)**
1. El administrador abre «Disputas» (pestaña Abiertas, `consola_disputas_abiertas`) y revisa el expediente y la evidencia (`evidencia_disputa`).
2. Elige liberar al profesional o devolver a la tarjeta y escribe un motivo (entre 10 y 2.000 caracteres). Si su último código TOTP tiene más de 5 minutos, la consola lo pide otra vez.
3. La Edge Function `webpay-resolve-dispute` comprueba `is_admin()` con el JWT del usuario, ejecuta la decisión y deja la acción `resolver_disputa` en `auditoria_consola`. El caso pasa a la pestaña Resueltas (`consola_disputas_resueltas`).

**Flujos alternativos / excepciones**
- 1a. **Cierre automático**: los casos simples (monto ≤ $80 000, sin señales de conducta ni reincidencia) se cierran solos al vencer el plazo de 24 h (`soporte_plazo_disputa_horas`, `soporte_monto_max_auto`), mediante el cron `mwa_resolver_soporte_automatico`.
- 3a. El reembolso falla en Transbank: queda pendiente y el cron lo reintenta.
- 3b. La sesión no es de administrador o el motivo es muy corto: la función responde 403 o 400 y no mueve dinero.

**Observación**: la devolución automática del cierre por plazo depende de la Edge Function `soporte-automatico`, que según el reporte del 20-nov no está desplegada en vivo.

**Trazabilidad**: `myworksapp_desktop/src/features/screens.tsx` (`DisputasPage`); `supabase/functions/webpay-resolve-dispute`, `_shared/require_admin.ts`, `soporte-automatico`; SQL `admin_actualizar_estado_disputa`, `consola_disputas_abiertas`, `consola_disputas_resueltas`, `registrar_auditoria`.

---

### CU-23 Chatear sobre un trabajo

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado, Profesional |
| **Descripción** | Las partes de un trabajo intercambian mensajes en tiempo real. |
| **Precondiciones** | Ambos son parte del trabajo. |
| **Postcondiciones** | Hay mensajes en `mensajes`, visibles solo para las partes (RLS). |

**Flujo principal**
1. Un usuario abre «Abrir chat» (web) o «Mensajes» (app).
2. Escribe y envía el mensaje.
3. El sistema lo guarda y la otra parte lo recibe por Supabase Realtime.
4. Al leerlo, el mensaje se marca como leído.

**Flujos alternativos / excepciones**
- 2a. El mensaje incluye datos de contacto u otro contenido no permitido: el trigger `mensajes_bloquear_contacto` lo rechaza («este tipo de contenido no esta permitido»). Esto evita que las partes se salten el pago protegido.
- 4a. Editar un mensaje: el trigger `mensajes_solo_marcar_leido` solo permite marcarlo como leído.

**Trazabilidad**: `shared/src/chat/messages.ts`; `myworksapp_web/src/components/LiveChatWidget.tsx`; `myworksapp_app/lib/features/chat/presentation/pages/chat_page.dart`.

---

### CU-24 Recibir y gestionar notificaciones

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado, Profesional |
| **Descripción** | El usuario recibe avisos de cambios en sus trabajos y pagos, y los marca como leídos. |
| **Precondiciones** | Tiene sesión. |
| **Postcondiciones** | Los avisos quedan con `leido = 1`. |

**Flujo principal**
1. Ante un evento (pedido nuevo, aceptado, en camino, finalizado, pago, disputa), la app o el servidor insertan una fila en `notificaciones`.
2. El usuario ve el contador en la campana (web) o en el centro de notificaciones (app).
3. Abre la lista (`fetchMyNotifications`, últimas 20) y toca una para ir al trabajo relacionado.
4. Opcional: «Marcar todas como leídas».

**Flujos alternativos / excepciones**
- 1a. Push: el código prevé que, con las variables `FCM_*`, un webhook de base de datos invoque `send-push` y llegue una notificación al teléfono. Según el reporte del 20-nov, `send-push` no está desplegada en vivo, así que hoy el aviso queda solo dentro de la app y la web.

**Trazabilidad**: `shared/src/repositories/notifications.ts`; `myworksapp_app/lib/core/services/notification_service.dart`, `job_service.dart`; `supabase/functions/send-push`; `docs/PUSH_NOTIFICACIONES.md`.

---

### CU-25 Completar perfil y solicitar verificación

| Campo | Detalle |
|---|---|
| **Actor(es)** | Profesional (principal); Administrador (revisa, CU-29) |
| **Descripción** | El profesional completa sus datos y envía su identidad a revisión. Sin verificación no aparece en el catálogo ni puede cobrar. |
| **Precondiciones** | Tiene una cuenta con rol `trabajador`. |
| **Postcondiciones** | `trabajadores.estado_verificacion = en_revision` y un evento en `verificacion_eventos`. |

**Flujo principal**
1. En «Completa tu perfil», ingresa su profesión, zona de trabajo, descripción y base geográfica.
2. En la tarjeta de verificación, ingresa RUT, oficio y comuna, o una foto del documento.
3. Presiona «Enviar a revisión».
4. El estado pasa a «En revisión»: «Hasta entonces no apareces como verificado».

**Flujos alternativos / excepciones**
- 4a. El administrador rechaza (CU-29): estado `rechazado` con una nota, y el profesional puede corregir y reenviar.
- 3a. Intenta cambiarse el estado él mismo: el trigger `trabajadores_proteger_verificacion` lo impide.

**Trazabilidad**: `myworksapp_app/lib/features/worker/presentation/pages/worker_register_page.dart`, `worker_verification_card.dart`; migración `20261115051527_verificacion_eventos.sql`.

---

### CU-26 Configurar tarifas, horario y disponibilidad

| Campo | Detalle |
|---|---|
| **Actor(es)** | Profesional |
| **Descripción** | El profesional define sus precios, su horario semanal y si acepta trabajos ahora. |
| **Precondiciones** | Tiene sesión como profesional. |
| **Postcondiciones** | Se actualizan `trabajador_precios`, `trabajador_horarios`, `trabajadores.precios_configurados`, `usa_horario` y `disponible`. |

**Flujo principal**
1. En «Configura tus precios», ingresa las tarifas por servicio, los adicionales y el cobro por m² para proyectos grandes, y presiona «Guardar tarifas».
2. En «Horario semanal», activa los días con su rango horario y presiona «Guardar horario».
3. En su panel, activa «Tu disponibilidad» («Estás disponible para nuevos trabajos»).

**Flujos alternativos / excepciones**
- 1a. Sin precios configurados: no aparece en el catálogo (`precios_configurados = 1` es condición del índice y del RPC del catálogo).
- 3a. Lo desactiva: deja de aparecer como «Disponible ahora».

**Reglas de negocio**: las horas libres del cliente (CU-06) salen de este horario menos los trabajos ya tomados.

**Trazabilidad**: `myworksapp_app/lib/features/worker/presentation/pages/worker_pricing_setup_page.dart`, `worker_schedule_page.dart`, `worker_home_page.dart`; migraciones `20261115051520_horarios_semanales.sql` y `20261115052827_trabajador_horarios_pk_por_dia.sql`.

---

### CU-27 Consultar cobros y registrar cuenta bancaria

| Campo | Detalle |
|---|---|
| **Actor(es)** | Profesional |
| **Descripción** | El profesional ve cuánto le deben, cuánto está en transferencia y cuánto ya recibió, y registra la cuenta donde le pagan. |
| **Precondiciones** | Tiene sesión como profesional. |
| **Postcondiciones** | La cuenta queda registrada en `cuentas_bancarias`. |

**Flujo principal**
1. Abre «Mis cobros».
2. Ve los montos «Por pagar», «Pendiente de transferencia» y «Transferido», calculados desde `liquidaciones`.
3. Registra o edita su cuenta bancaria: banco, tipo de cuenta y RUT del titular.
4. Opcional: revisa «Estadísticas».

**Flujos alternativos / excepciones**
- 2a. Sin trabajos completados: los montos aparecen en cero.

**Reglas de negocio**: hoy la transferencia la registra un administrador de forma manual (CU-30).

**Trazabilidad**: `myworksapp_app/lib/features/worker/presentation/pages/worker_payouts_page.dart`, `statistics_page.dart`; `shared/src/payments/payout.ts`; migración `20261115051513_pagos_cuenta_bancaria.sql`.

---

### CU-28 Acceder a la consola con segundo factor

| Campo | Detalle |
|---|---|
| **Actor(es)** | Administrador, Colaborador interno (`soporte`, `qa`) |
| **Descripción** | El personal entra a la consola de escritorio con contraseña y un código TOTP. |
| **Precondiciones** | Tiene rol `administrador`, `soporte` o `qa` y una app autenticadora. |
| **Postcondiciones** | Hay una sesión con nivel `aal2`. |

**Flujo principal**
1. Abre la consola («Consola operativa — Supervisa. Gestiona. Resuelve.»).
2. Ingresa su correo y contraseña.
3. El sistema verifica que el rol sea de consola (`administrador`, `soporte` o `qa`).
4. El sistema pide el código TOTP. La primera vez muestra un QR para enrolar.
5. Se abre «Inicio». La barra lateral solo muestra los módulos permitidos para su rol (`src/shell/nav.ts`).
6. Tras 13 minutos sin uso la consola avisa y a los 15 cierra la sesión (`src/lib/idle.ts`).

**Flujos alternativos / excepciones**
- 3a. Rol de cliente o profesional: el sistema rechaza el acceso y cierra la sesión.
- 4a. Código incorrecto: no se eleva la sesión y las vistas no cargan.

**Reglas de negocio**: `admin_requiere_aal2 = 1` en vivo. Las funciones administrativas y las de consola (`rol_consola`) exigen `aal2`; con `aal1` responden `forbidden`.

**Trazabilidad**: `myworksapp_desktop/src/components/DesktopLoginScreen.tsx`, `AdminMfaGate.tsx`, `InvitePasswordScreen.tsx`; `src/authAccess.ts`; `src/context/AuthContext.tsx`; `src/lib/idle.ts`, `src/lib/totp.ts`; deep link `myworksapp-admin://auth/callback` (`src-tauri/tauri.conf.json`).

---

### CU-29 Verificar profesionales

| Campo | Detalle |
|---|---|
| **Actor(es)** | Administrador |
| **Descripción** | El administrador aprueba o rechaza a los profesionales en revisión. |
| **Precondiciones** | CU-28 completado. Hay profesionales `en_revision`. |
| **Postcondiciones** | `estado_verificacion` pasa a `verificado`, `rechazado` o `en_revision` (pedir corrección), se registra el evento y la acción queda en `auditoria_consola`. |

**Flujo principal**
1. Abre «Profesionales» y ve la lista con oficio, estado de verificación y nota.
2. Abre la ficha: historial de `verificacion_eventos`, estadísticas (`stats_profesionales`) y el documento, que se abre con un enlace temporal de 60 segundos del bucket `verificacion-profesional`. El RUT aparece enmascarado; para verlo, «Mostrar dato enmascarado» deja la consulta en la bitácora (`consola_registrar_vista_sensible`).
3. Presiona «Aprobar», «Rechazar» o «Pedir corrección».
4. Si rechaza, escribe una **nota obligatoria de al menos 10 caracteres**, que se envía al profesional y queda en el historial.
5. `fijar_verificacion_profesional` actualiza el estado y registra `aprobar_verificacion`, `rechazar_verificacion` o `pedir_correccion` en `auditoria_consola`.

**Flujos alternativos / excepciones**
- 4a. Rechazo con una nota de menos de 10 caracteres: «La nota de rechazo debe tener al menos 10 caracteres» y no cambia nada.
- 5a. Lo intenta alguien que no es administrador: «Solo un administrador puede fijar la verificación».

**Estado conocido**: en la prueba de la consola del 20-nov sobre `08154df`, el módulo «Profesionales» respondió 403 al leer `trabajadores`, así que hoy no se puede ejecutar este caso desde la consola. El arreglo está en la rama `cursor/consola-bugs`, sin merge.

**Trazabilidad**: `myworksapp_desktop/src/features/screens.tsx` (`ProfesionalesPage`, `FichaProfesional`); migración `20261120130000_auditoria_consola.sql` (`fijar_verificacion_profesional`).

---

### CU-30 Supervisar métricas, pagos y liquidar al profesional

| Campo | Detalle |
|---|---|
| **Actor(es)** | Administrador |
| **Descripción** | El administrador revisa los indicadores del negocio y registra la transferencia al profesional. |
| **Precondiciones** | CU-28 completado. |
| **Postcondiciones** | Si liquida: la liquidación queda transferida (`liberar_escrow_manual`). |

**Flujo principal**
1. En «Inicio» o «Finanzas» elige el período (24 horas, 7, 30 o 90 días). Los indicadores salen de `consola_resumen_periodo`, comparados con el período anterior.
2. Revisa GMV, comisión, trabajos completados y activos, disputas abiertas y las colas. La comisión es la de `comision_servicio_clp`: 5 % del pago principal, mínimo $1.000 y nunca más que el pago, descontada al profesional (RN-06). «Pagos y escrow» y «Liquidaciones» muestran bruto, comisión y neto desde la vista `cobros_profesional`.
3. En «Liquidaciones» elige un pago retenido de un profesional con cuenta bancaria registrada y presiona «Liquidar garantía».
4. Escribe el motivo (entre 10 y 2.000 caracteres) y, si su último código TOTP tiene más de 5 minutos, lo ingresa otra vez.
5. La Edge Function `webpay-release` comprueba `is_admin()` con el JWT del usuario, ejecuta `liberar_escrow_manual` de forma atómica y registra `liquidar` en `auditoria_consola`.

**Flujos alternativos / excepciones**
- 3a. El profesional no registró su cuenta bancaria: «Liquidar» queda deshabilitado («El profesional no ha registrado su cuenta.»).
- 5a. La sesión no es de administrador: 403 «No autorizado» y no se mueve dinero.
- 2a. Revisa la salud del sistema en «Salud y monitoreo» (estado de las tareas `pg_cron`, `consola_cron_salud`) y «Errores de la app».

**Discrepancia documentada**: versiones anteriores de este caso decían «comisión (15 %)». El código cobra 5 % con mínimo de $1.000; este documento describe el código. La decisión sobre la tasa queda abierta para el responsable del proyecto.

**Trazabilidad**: `myworksapp_desktop/src/features/screens.tsx` (`ResumenPage`, `FinanzasPage`, `PagosPage`, `LiquidacionesPage`); `shared/src/metrics/period.ts`, `shared/src/metrics/fetchPeriod.ts`; `supabase/functions/webpay-release`, `_shared/require_admin.ts`; migraciones `20261118053913_cobros_profesional_neto.sql` y `20261120130000_auditoria_consola.sql`; `docs/RUNBOOK_PAYOUT.md`.

---

### CU-31 Invitar colaborador interno

| Campo | Detalle |
|---|---|
| **Actor(es)** | Administrador (principal); Colaborador interno (recibe) |
| **Descripción** | RRHH invita por correo a una persona con un rol de panel (Admin, Soporte o QA). |
| **Precondiciones** | CU-28 completado. |
| **Postcondiciones** | La persona queda invitada en Supabase Auth y su perfil con `rol` = `administrador`, `soporte` o `qa`. |

**Flujo principal**
1. En «Equipo y roles → Invitar», ingresa el nombre, el correo, el rol y una nota opcional.
2. La Edge Function `invitar-colaborador` llama `is_admin()` con el JWT de quien invita.
3. El sistema envía la invitación. Con `INVITE_PROVIDER` sin definir (valor en vivo) sale por Supabase Auth con la plantilla «Te invitaron a MyWorksApp» y el SMTP de Resend; el enlace vuelve a `INVITE_REDIRECT_URL` o al deep link `myworksapp-admin://auth/callback`. La acción queda en `auditoria_consola` (`invitar_colaborador`).
4. El sistema asigna el rol al perfil.
5. La persona abre el enlace, elige su contraseña y, si es administrador, enrola su segundo factor (CU-28).

**Flujos alternativos / excepciones**
- 2a. No es administrador: se rechaza.
- 1a. El rol no está permitido: «Rol no permitido».
- 4a. El perfil no existe o el trigger lo rechaza: «No se pudo asignar el rol del panel».
- 1b. El administrador revoca una invitación pendiente (`consola_revocar_invitacion`) o cambia el rol de un integrante (`consola_cambiar_rol`); ambas acciones quedan en la bitácora.

**Estado conocido**: según la revisión de correos del 20-nov, el enlace de la invitación vuelve a la consola con un fragmento `#access_token` que la consola de `main` no procesa, así que la persona invitada no queda con sesión para definir su clave. El arreglo está en la rama `cursor/correos-resend`, sin merge.

**Observación**: desde la versión 1.0.3 los colaboradores `soporte` y `qa` entran a la consola con mínimo privilegio (CU-34). El trigger `perfiles_rol_inicial_seguro` impide que un usuario se asigne un rol de consola al registrarse.

**Trazabilidad**: `myworksapp_desktop/src/features/screens.tsx` (`EquipoPage`), `src/components/InvitePasswordScreen.tsx`; `supabase/functions/invitar-colaborador/index.ts`, `_shared/require_admin.ts`.

---

### CU-32 Ejecutar procesos automáticos de pagos y soporte

| Campo | Detalle |
|---|---|
| **Actor(es)** | Sistema (planificador `pg_cron`) |
| **Descripción** | Tareas periódicas que mantienen los pagos y los casos de soporte consistentes sin intervención humana. |
| **Precondiciones** | Las tareas están programadas en `cron.job` (verificado en vivo). |
| **Postcondiciones** | Los estados de pagos y trabajos quedan consistentes con Transbank y con los plazos. |

**Flujo principal**

| Tarea | Frecuencia | Qué hace |
|---|---|---|
| `mwa_webpay_reconcile` | cada 5 min | Consulta a Transbank los pagos sin confirmar (retorno perdido) y fija `retenido` o `anulado` (`webpay-reconcile`) |
| `mwa_expirar_pagos_abandonados` | cada 10 min | Pedidos en `esperando_pago` con pago `pendiente` de más de 30 min: el pago pasa a `anulado` y el pedido se cierra |
| `mwa_resolver_soporte_automatico` | cada 10 min | Libera pagos por silencio del cliente (48 h con evidencia), cierra disputas simples vencidas (24 h, ≤ $80 000) y deja los reembolsos para la Edge Function `soporte-automatico` |

**Flujos alternativos / excepciones**
- Transbank no responde: el pago queda como estaba y se reintenta en la siguiente ejecución.

**Estado conocido**: según el reporte del 20-nov, la Edge Function `soporte-automatico` no está desplegada en vivo, así que las devoluciones a la tarjeta que decide el soporte automático no se ejecutan solas. La prueba de la consola del 20-nov vio 3 tareas `pg_cron` en estado «succeeded» y una disputa demo abierta desde el 19-oct que no se escaló.

**Trazabilidad**: migraciones `20261115060002_cron_webpay_reconcile.sql`, `20261115160001_reconcile_secret_vault.sql`, `20261112000001_soporte_automatico.sql`; `supabase/functions/webpay-reconcile`, `soporte-automatico`.

---

### CU-33 Reagendar la visita

| Campo | Detalle |
|---|---|
| **Actor(es)** | Cliente registrado, Profesional (uno propone, el otro responde) |
| **Descripción** | Una de las partes propone mover la visita a otra hora publicada por el profesional; la otra parte la acepta o la rechaza. |
| **Precondiciones** | El trabajo está en `pendiente` o `aceptado` (antes de `en_camino`), su hora todavía no llega y no hay una disputa activa. |
| **Postcondiciones** | Si se acepta, `trabajos.fecha_programada` cambia a la hora propuesta. El pago retenido (escrow) no cambia. Cada propuesta queda en `reprogramaciones_trabajo` y cada paso notifica a la otra parte (`job_rescheduled`). |

**Flujo principal**
1. En el seguimiento web («Cambiar la hora») o en el detalle del trabajo en la app, la parte elige una hora libre del profesional y un motivo opcional.
2. `proponer_reprogramacion` valida la regla y que la hora esté publicada y libre (misma fuente que `horarios_libres_profesional`), guarda la propuesta `pendiente` y notifica a la otra parte.
3. La otra parte ve «… propone mover la visita al …» y presiona «Aceptar nueva hora» o «Rechazar».
4. `responder_reprogramacion` registra la respuesta. Si acepta, cambia la hora; el trigger `trabajos_horario_unico` vuelve a validar que no choque con otro trabajo.
5. Ambas partes ven el «Historial de cambios de hora».

**Flujos alternativos / excepciones**
- 2a. La hora no está publicada o ya está tomada: «Esa hora no está publicada o ya está tomada por el profesional».
- 2b. El profesional ya salió en camino: «Solo se puede reagendar antes de que el profesional salga en camino».
- 3a. Quien propuso intenta aceptar su propia propuesta: «La otra parte debe responder tu propuesta». Puede «Retirar mi propuesta» (`retirar_reprogramacion`).
- 4a. El trabajo cambió de estado antes de responder: la propuesta vence (`trabajos_vencer_reprogramaciones`).
- 4b. Un cliente o profesional intenta cambiar `fecha_programada` con un `UPDATE` directo: el trigger `trabajos_fecha_solo_por_rpc` y los permisos lo rechazan.

**Reglas de negocio**: a lo más una propuesta pendiente por trabajo y 6 propuestas en total; el escrow no se toca (RN-17).

**Trazabilidad**: migración `20261115232900_reprogramar_trabajo.sql`; `shared/src/jobs/reschedule.ts`; `myworksapp_web/src/components/JobClientActions.tsx`; `myworksapp_app/lib/core/domain/reschedule_rules.dart`, `lib/core/database/repositories/reschedule_repository.dart`, `lib/features/jobs/presentation/widgets/reschedule_section.dart`.

---

### CU-34 Atender la cola de soporte con mínimo privilegio

| Campo | Detalle |
|---|---|
| **Actor(es)** | Colaborador interno (`soporte` o `qa`) |
| **Descripción** | El colaborador revisa las disputas que necesitan una persona. `soporte` además ve la evidencia y deja notas a las partes; `qa` solo lee. |
| **Precondiciones** | CU-28 completado con rol `soporte` o `qa` (sesión `aal2`). |
| **Postcondiciones** | Las notas de soporte quedan en el hilo de la disputa. Ningún pago cambia. |

**Flujo principal**
1. La consola abre «Disputas» y lista las disputas abiertas (`consola_disputas_abiertas`: nombres de las partes y monto retenido, sin correos ni direcciones). También ve «Tickets de soporte».
2. `soporte` abre la evidencia (`evidencia_disputa`). La base tiene además `soporte_comentar_disputa` para dejar una nota, pero la consola de `main` no ofrece hoy ese botón.
3. Las acciones de dinero no aparecen: solo un administrador libera o devuelve el pago.

**Flujos alternativos / excepciones**
- 2a. `qa` intenta ver evidencia o dejar notas: el botón no aparece y el RPC lo rechaza.
- 3a. `soporte` o `qa` intenta liberar un pago, verificar profesionales, ver métricas o invitar personal: la consola no muestra esos espacios y la base lo rechaza (`is_admin()`, «Solo administradores», `permission denied`).

**Observación**: la prueba del 20-nov simuló los roles `soporte` y `qa` solo en la interfaz, porque no hay cuentas con esos roles en la base; no demuestra la seguridad del backend para roles reales.

**Trazabilidad**: migración `20261115232902_consola_roles_soporte_qa.sql`; `myworksapp_desktop/src/authAccess.ts` (`consolePermissions`), `src/shell/nav.ts`, `src/features/screens.tsx` (`DisputasPage`, `TicketsPage`); `shared/src/repositories/disputes.ts`.

---

## 6. Matriz de trazabilidad (caso de uso → componente)

| CU | Web | App | Escritorio | Edge Function | RPC / trigger SQL principal |
|---|:-:|:-:|:-:|---|---|
| 01 | ✔ | ✔ | | — | Auth + `perfiles` |
| 02 | ✔ | ✔ | | — | `getProfile` |
| 03 | ✔ | ✔ | | — | `resetPasswordForEmail`, `updateUser` |
| 04 | ✔ | ✔ | | — | `exportar_mis_datos`, `solicitar_eliminacion_cuenta`, `account_deletion_service` |
| 05 | ✔ | ✔ | | — | `categorias_con_disponibles`, `listar_profesionales_catalogo`, `profesionales_ocupados` |
| 06 | ✔ | ✔ | | — | `perfil_publico_profesional`, `resenas_publicas_profesional`, `horarios_libres_profesional` |
| 07 | ✔ | ✔ | | — | `trabajos_horario_unico`, `trabajos_crear_pin_inicio` |
| 08 | ✔ | ✔ | | `webpay-create`, `webpay-commit`, `oneclick-*` | `pagos_copiar_estado_trabajo` |
| 09 | ✔ | | | `guest-checkout` | `rate_limit_consumir` |
| 10 | ✔ | | | `definir-clave-invitado` | — |
| 11 | | ✔ | | `webpay-refund-rejection` | `transicionar_trabajo` |
| 12 | | ✔ | | — | `ubicacion_en_vivo`, `trabajos_borrar_gps` |
| 13 | ✔ | ✔ | | `webpay-status` | `obtener_pin_inicio` |
| 14 | | ✔ | | — | `intentar_pin_inicio`, `trabajos_bloquear_en_curso_directo` |
| 15 | ✔ | ✔ | | `webpay-create`, `webpay-commit` | `ordenes_cambio`, `monto_a_cobrar_orden_cambio`, `rechazar_orden_cambio` |
| 16 | | ✔ | | — | `trabajos_exigir_evidencia`, `fotos_trabajo_exigir_webp` |
| 17 | ✔ | ✔ | | — | `cerrar_trabajo_conforme` |
| 18 | ✔ | ✔ | | — | `calificaciones_refrescar_trabajador`, `calificaciones_evaluar_resena` |
| 19 | | ✔ | | — | `calificar_cliente` |
| 20 | ✔ | ✔ | | `webpay-refund-cancellation` | `transicionar_trabajo` |
| 21 | ✔ | ✔ | | — | `abrir_disputa`, `proponer_acuerdo`, `responder_acuerdo` |
| 22 | | | ✔ | `webpay-resolve-dispute`, `soporte-automatico` | `admin_actualizar_estado_disputa`, `consola_disputas_resueltas`, `registrar_auditoria` |
| 23 | ✔ | ✔ | | — | `mensajes_bloquear_contacto` |
| 24 | ✔ | ✔ | | `send-push` | `notificaciones` |
| 25 | | ✔ | | — | `trabajadores_proteger_verificacion` |
| 26 | | ✔ | | — | `trabajador_precios`, `trabajador_horarios` |
| 27 | | ✔ | | — | `liquidaciones`, `cuentas_bancarias` |
| 28 | | | ✔ | — | MFA `aal2`, `rol_consola` |
| 29 | | | ✔ | — | `fijar_verificacion_profesional`, `consola_registrar_vista_sensible` |
| 30 | | | ✔ | `webpay-release` | `consola_resumen_periodo`, `cobros_profesional`, `liberar_escrow_manual` |
| 31 | | | ✔ | `invitar-colaborador` | `perfiles.rol`, `consola_listar_equipo`, `consola_revocar_invitacion`, `consola_cambiar_rol` |
| 32 | | | | `webpay-reconcile`, `soporte-automatico` | `expirar_pagos_abandonados` + `pg_cron` |
| 33 | ✔ | ✔ | | — | `proponer_reprogramacion`, `responder_reprogramacion`, `retirar_reprogramacion`, `trabajos_fecha_solo_por_rpc` |
| 34 | | | ✔ | — | `consola_disputas_abiertas`, `evidencia_disputa` |

## 7. Reglas de negocio consolidadas

| ID | Regla | Dónde se impone |
|---|---|---|
| RN-01 | Solo el profesional del trabajo avanza los estados de ejecución | `transicionar_trabajo` |
| RN-02 | El cierre `completado` lo hace el cliente (conformidad), el sistema o el administrador | `transicionar_trabajo`, `cerrar_trabajo_conforme` |
| RN-03 | Sin pago en garantía no se acepta ni se inicia | `transicionar_trabajo` |
| RN-04 | Con una disputa activa, solo el administrador mueve el trabajo | `transicionar_trabajo`, `disputa_esta_activa` |
| RN-05 | No se cancela con el pago retenido sin reembolsar antes | `transicionar_trabajo` |
| RN-06 | Comisión de la plataforma 5 % del pago principal, mínimo $1.000 y nunca más que el pago, descontada al profesional; en las órdenes de cambio el cliente paga el monto más 8 % | `comision_servicio_clp`, `cobros_profesional`, `period.ts`, `pricing_service.dart`, `change_order_service.dart` |
| RN-07 | Contraseña de al menos 8 caracteres, con letras y dígitos | `config.toml`, `definir-clave-invitado` |
| RN-08 | Solo se reservan horas publicadas y libres | `horarios_libres_profesional`, `trabajos_horario_unico` |
| RN-09 | Nunca se pide ni se guarda la tarjeta (Transbank la custodia) | `webpay-*`, `oneclick-*` |
| RN-10 | El monto se valida en el servidor contra la tarifa | `webpay-create`, `guest-checkout` |
| RN-11 | El PIN solo lo ve el cliente, en `aceptado` y `en_camino` | `obtener_pin_inicio`, `startPin.ts` |
| RN-12 | PIN obligatorio; 5 fallos bloquean 15 min; un acierto abre una ventana de 2 min | `intentar_pin_inicio` |
| RN-13 | 48 h de silencio del cliente con evidencia liberan el pago; las disputas simples (≤ $80 000) se cierran a las 24 h | `soporte_automatico`, `app_config` |
| RN-14 | Límites de tasa: invitado 5/min por IP y 3/min por correo; Webpay 20/min por IP y 10/min por usuario; alta de clave 8/min por IP | `_shared/rate_limit.ts` |
| RN-15 | El chat bloquea datos de contacto; el pago principal también se frena si la descripción, la dirección o los mensajes del cliente en ese trabajo traen contacto | `mensajes_bloquear_contacto`, `texto_tiene_contacto`, `pagos_exigir_sin_contacto` |
| RN-16 | La evidencia se guarda en un depósito privado, con fotos WebP y videos de hasta 20 MB | `fotos_trabajo_exigir_webp`, bucket `evidencias` |
| RN-17 | Reagendar solo antes de `en_camino`, a una hora publicada y libre, con aceptación de la otra parte; el escrow no cambia | `proponer_reprogramacion`, `responder_reprogramacion` |
| RN-18 | Un profesional que quedó «no disponible» por un trabajo vuelve a estar disponible al terminar su último trabajo activo | trigger de `pausa_por_trabajo` (`20261115232858`) |
| RN-19 | Un trabajo cerrado (completado, cancelado, expirado) no admite disputas ni acuerdos nuevos | `20261115232852` |
| RN-20 | La consola aplica mínimo privilegio: solo `administrador` mueve dinero, verifica, invita o ve métricas | `is_admin()`, `rol_consola`, `authAccess.ts`, `_shared/require_admin.ts` |
| RN-21 | Toda acción de la consola queda en una bitácora inmutable: solo `registrar_auditoria()` inserta y nadie actualiza ni borra | `auditoria_consola`, trigger `auditoria_consola_solo_rpc` |
| RN-22 | Rechazar una verificación exige una nota de al menos 10 caracteres; liberar, devolver, liquidar o invitar exige un motivo de 10 a 2.000 caracteres | `fijar_verificacion_profesional`, `motivoValido` |
| RN-23 | Las cuentas demo (`@demo.myworksapp.cl`, `@demo.com`) solo aparecen y se pueden reservar o cobrar con `app_config.demo_modo = 1` | `catalogo_muestra_profesional`, `trabajos_bloquear_demo`, `pagos_bloquear_demo` |

## 8. Observaciones encontradas al derivar los casos desde el código

Estado al 20-nov-2026 (`main` `08154dfc`):

1. **Comisión (RN-06, CU-30).** El código cobra 5 % con un mínimo de $1.000. Versiones anteriores de este documento y del informe decían 15 %. Se documenta el código; la tasa queda por decidir.
2. **CU-29.** El rechazo exige una nota de al menos 10 caracteres. En la prueba de la consola del 20-nov el módulo Profesionales respondió 403: el caso no se puede ejecutar hasta el merge de `cursor/consola-bugs`.
3. **CU-01.** El captcha de Supabase Auth no está activado: el token de Turnstile del registro no se valida en el servidor.
4. **CU-24 y CU-32.** `send-push` y `soporte-automatico` están en el repositorio, pero no desplegadas en vivo.
5. **CU-03 y CU-31.** Restablecer la clave desde la app y aceptar una invitación en la consola no terminan bien hoy; el arreglo está en `cursor/correos-resend`.

**En desarrollo (ramas sin merge, no forman parte de estos casos):** `cursor/aviso-academico-duoc-v2` (banner y páginas `/aviso-legal`, `/terminos`, `/privacidad`), `cursor/correos-resend` (correos transaccionales y flujo de definir contraseña) y `cursor/consola-bugs` (24 errores de la consola).

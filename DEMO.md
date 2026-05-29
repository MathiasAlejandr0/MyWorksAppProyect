# Guía de demostración — MyWorksApp

Documento para presentar la demo a **financistas**, **profesores**, **jurados** o **inversores**. La app es un **MVP funcional offline** en un solo dispositivo.

## Qué es (mensaje de 30 segundos)

> MyWorksApp conecta usuarios con trabajadores de oficios del hogar. Esta versión demuestra el flujo completo del marketplace — descubrimiento, reserva, ejecución, chat y reputación — en una app móvil real. Los datos viven en el teléfono (SQLite). Para escalar se necesita backend, pagos reales y sincronización en la nube.

---

## Credenciales demo

| Rol | Email | Contraseña |
|-----|-------|------------|
| Usuario | `usuario@demo.com` | `demo123` |
| Trabajador | `trabajador@demo.com` | `demo123` |

Otros trabajadores precargados: `pedro@demo.com`, `maria@demo.com` (misma contraseña).

En login: botón **Entrar con demo** o selector **Usuario / Trabajador**.

---

## Qué funciona en la demo

| Funcionalidad | Estado |
|---------------|--------|
| Registro e inicio de sesión (usuario / trabajador) | ✅ Local |
| 16 trabajadores demo con perfil, portafolio y tarifa | ✅ |
| Catálogo de 8 categorías de servicio | ✅ |
| Listado y filtro de trabajadores | ✅ |
| Perfil del trabajador + agendar visita | ✅ |
| Solicitud de servicio (mapa, fecha, descripción) | ✅ |
| Aceptar / iniciar / completar trabajo | ✅ |
| Chat por trabajo | ✅ |
| Calificaciones y estadísticas | ✅ |
| Notificaciones locales | ✅ |

---

## Limitaciones (decirlas con transparencia)

| Limitación | Explicación para la audiencia |
|------------|-------------------------------|
| **Un solo dispositivo** | Usuario y trabajador se demuestran cerrando sesión en el mismo teléfono |
| **Sin backend** | No hay sync entre dos teléfonos distintos |
| **Pagos mock (sin Webpay)** | Escrow simulado: garantía, liberación y reembolso en la app; no hay cobro bancario (Webpay en Chile requiere empresa constituida) |
| **Trabajador nuevo registrado** | Puede crear perfil, pero **no aparece** en listados por categoría como los 16 demos |
| **Videos del portafolio** | Miniaturas con icono play, no reproductor de video real |
| **Mapas** | Requieren clave Google Maps configurada localmente |

**Recomendación:** usa cuentas demo y trabajadores precargados (ej. **Tomás IKEA Pro** en Armado de muebles).

---

## Guión de demo (5–7 minutos)

### Parte 1 — Cliente (3 min)

1. Abre la app → **Login** → `usuario@demo.com` / `demo123`.
2. En el home elige **Armado de muebles** (u otra categoría).
3. Abre el perfil **Tomás IKEA Pro**.
4. Muestra: foto, rating, tarifa de visita, descripción, **trabajos anteriores** (portafolio).
5. Toca **Agendar visita** → confirma dirección y fecha.
   - Alternativa: **Solicitar servicio** con mapa y descripción detallada.
6. Menciona: *“El usuario ve precio de visita antes de confirmar.”*

### Parte 2 — Trabajador (3 min)

1. **Ajustes → Cerrar sesión**.
2. Login → `trabajador@demo.com` / `demo123`.
3. Pestaña **Pendientes** → acepta la solicitud creada (o la demo precargada).
4. Avanza: **Iniciar trabajo** → **Completar**.
5. Abre **Chat** con el cliente.
6. Muestra **Estadísticas** del trabajador.

### Parte 3 — Cierre (1 min)

1. Cierra sesión → vuelve como **usuario**.
2. **Califica** el trabajo completado.
3. Revisa **Historial** y **Notificaciones**.

**Frase de cierre:**

> “Hoy mostramos producto, modalidades de cobro y pago en garantía simulado. La siguiente fase es backend en la nube y, con empresa constituida, pasarela real (Webpay u otra).”

---

## Demo para financista (puntos clave)

Enfatiza el **modelo de negocio implícito**:

- **Tarifa de visita** visible antes de agendar (monetización por lead/visita).
- **Marketplace bilateral** (demanda + oferta en una app).
- **Reputación** (ratings, portafolio) como barrera de confianza.
- **Datos locales** = prototipo; en producción → métricas, retención, GMV.

No prometas: ingresos reales, usuarios activos en la nube, pagos procesados.

---

## Demo para universidad

| Opción | Cómo |
|--------|------|
| **Proyectar tu teléfono** | AirPlay / cable HDMI — más fiable |
| **QR Android** | Enlace al APK en GitHub Releases (ver [INSTALL.md](INSTALL.md)) |
| **QR iPhone** | TestFlight (requiere Apple Developer ~99 USD/año) |
| **Emulador en Mac** | `./scripts/run_ios.sh` proyectado |

Lleva una diapositiva con credenciales demo y el guión de arriba.

---

## Registro de cuentas nuevas

**Usuario nuevo:** funciona bien para mostrar onboarding. Tras registrarse, puede solicitar servicios y ver trabajadores demo.

**Trabajador nuevo:** completa profesión y descripción → entra al dashboard. Para la demo en vivo, **prefiere `trabajador@demo.com`** (perfil completo, trabajos de ejemplo).

---

## Checklist antes de la presentación

- [ ] App instalada y probada una vez completa
- [ ] Credenciales demo funcionando
- [ ] Batería del teléfono cargada
- [ ] Modo avión desactivado (portafolio usa imágenes de red)
- [ ] (Opcional) Clave Google Maps si mostrarás mapas
- [ ] Diapositiva o tarjeta con emails/contraseñas demo

---

## Más información

- Qué tiene y qué falta: [ESTADO_DEL_PROYECTO.md](ESTADO_DEL_PROYECTO.md)
- Instalación APK / iPhone: [INSTALL.md](INSTALL.md)
- Documentación técnica: [README.md](README.md)
